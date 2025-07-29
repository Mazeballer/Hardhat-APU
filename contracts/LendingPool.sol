// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendingPool {
    struct DepositInfo {
        uint256 id;
        uint256 amount;
        uint256 depositedAt;
    }

    mapping(address => DepositInfo[]) public deposits;
    uint256 public nextDepositId;

    uint256 public constant APY_BPS = 800;
    uint256 public constant BPS_DIVISOR = 10000;
    uint256 public constant SECONDS_IN_YEAR = 365 days;

    event Deposited(address indexed user, uint256 depositId, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 depositId, uint256 amount, uint256 interest);
    
    // ✅ Debug event for internal value tracing
    event Debug(string label, uint256 value);

    function deposit() external payable {
        require(msg.value > 0, "Send some GO");

        deposits[msg.sender].push(DepositInfo({
            id: nextDepositId,
            amount: msg.value,
            depositedAt: block.timestamp
        }));

        emit Deposited(msg.sender, nextDepositId, msg.value, block.timestamp);
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

                uint256 totalInterest = calculateInterest(d);
                uint256 proportionalInterest = (totalInterest * amount) / d.amount;
                uint256 totalToWithdraw = amount + proportionalInterest;

                emit Debug("withdraw_amount", amount);
                emit Debug("proportional_interest", proportionalInterest);
                emit Debug("total_to_withdraw", totalToWithdraw);

                d.amount -= amount;
                d.depositedAt = (d.amount == 0) ? 0 : block.timestamp;

                // ✅ Use safe low-level call
                (bool success, ) = payable(msg.sender).call{value: totalToWithdraw}("");
                require(success, "Transfer failed");

                emit Withdrawn(msg.sender, depositId, amount, proportionalInterest);
                found = true;
                break;
            }
        }

        require(found, "Deposit ID not found");
    }

    function calculateInterest(DepositInfo memory d) public view returns (uint256) {
        if (d.amount == 0 || d.depositedAt == 0) return 0;

        uint256 timeElapsed = block.timestamp - d.depositedAt;
        uint256 interest = (d.amount * APY_BPS * timeElapsed) / (BPS_DIVISOR * SECONDS_IN_YEAR);
        return interest;
    }

    receive() external payable {}

    // ✅ Optional utility for frontend
    function getUserDeposits(address user) external view returns (DepositInfo[] memory) {
        return deposits[user];
    }
}
