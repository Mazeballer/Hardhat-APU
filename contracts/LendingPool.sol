// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendingBorrowingPool {
    struct DepositInfo {
        uint256 id;
        uint256 amount;
        uint256 depositedAt;
        uint256 apyBps;
    }

    struct Loan {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 collateral;
        string collateralToken;
        uint256 duration;
        uint256 startTime;
        bool active;
    }

    mapping(address => DepositInfo[]) public deposits;
    mapping(address => Loan[]) public loans;

    uint256 public nextDepositId;
    uint256 public nextLoanId = 1;

    uint256 public constant BPS_DIVISOR = 10_000;
    uint256 public constant SECONDS_IN_YEAR = 365 days;

    event Deposited(
        address indexed user,
        uint256 depositId,
        uint256 amount,
        uint256 apyBps,
        uint256 timestamp
    );

    event Withdrawn(
        address indexed user,
        uint256 depositId,
        uint256 amount,
        uint256 interest
    );

    event Borrowed(
        uint256 loanId,
        address indexed borrower,
        uint256 amount,
        uint256 collateral,
        string collateralToken,
        uint256 duration,
        uint256 startTime
    );

    event Debug(string label, uint256 value);

    function deposit(uint256 apyBps) external payable {
        require(msg.value > 0, "Send some ETH");
        require(apyBps <= BPS_DIVISOR, "Invalid APY");

        deposits[msg.sender].push(DepositInfo({
            id: nextDepositId,
            amount: msg.value,
            depositedAt: block.timestamp,
            apyBps: apyBps
        }));

        emit Deposited(msg.sender, nextDepositId, msg.value, apyBps, block.timestamp);
        nextDepositId++;
    }

    function withdraw(uint256 depositId, uint256 amount) external {
        DepositInfo[] storage userDeposits = deposits[msg.sender];
        bool found = false;

        for (uint256 i = 0; i < userDeposits.length; i++) {
            if (userDeposits[i].id == depositId) {
                DepositInfo storage d = userDeposits[i];
                require(d.amount > 0, "Nothing to withdraw");
                require(amount > 0 && amount <= d.amount, "Invalid withdraw amount");

                uint256 elapsed = block.timestamp - d.depositedAt;
                uint256 totalInterest = (d.amount * d.apyBps * elapsed) / (BPS_DIVISOR * SECONDS_IN_YEAR);
                uint256 proratedInterest = (totalInterest * amount) / d.amount;
                uint256 payout = amount + proratedInterest;

                emit Debug("withdraw_amount", amount);
                emit Debug("prorated_interest", proratedInterest);
                emit Debug("total_payout", payout);

                d.amount -= amount;
                d.depositedAt = (d.amount == 0 ? 0 : block.timestamp);

                (bool success, ) = payable(msg.sender).call{value: payout}("");
                require(success, "Transfer failed");

                emit Withdrawn(msg.sender, depositId, amount, proratedInterest);
                found = true;
                break;
            }
        }

        require(found, "Deposit ID not found");
    }

    function requestLoan(uint256 amount, string memory collateralToken, uint256 duration) external payable {
        require(amount > 0, "Invalid loan amount");
        require(msg.value > 0, "Collateral required");
        require(duration > 0, "Invalid loan duration");
        require(address(this).balance >= amount, "Not enough liquidity to lend");

        loans[msg.sender].push(Loan({
            id: nextLoanId,
            borrower: msg.sender,
            amount: amount,
            collateral: msg.value,
            collateralToken: collateralToken,
            duration: duration,
            startTime: block.timestamp,
            active: true
        }));

        emit Borrowed(nextLoanId, msg.sender, amount, msg.value, collateralToken, duration, block.timestamp);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Loan transfer failed");

        nextLoanId++;
    }

    function calculateInterest(DepositInfo memory d) public view returns (uint256 interest) {
        if (d.amount == 0 || d.depositedAt == 0) return 0;
        uint256 elapsed = block.timestamp - d.depositedAt;
        return (d.amount * d.apyBps * elapsed) / (BPS_DIVISOR * SECONDS_IN_YEAR);
    }

    function getUserDeposits(address user) external view returns (DepositInfo[] memory) {
        return deposits[user];
    }

    function getLoans(address user) external view returns (Loan[] memory) {
        return loans[user];
    }

    receive() external payable {}
}
