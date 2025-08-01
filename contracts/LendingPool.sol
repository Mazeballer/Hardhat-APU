// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendingPool {
    struct DepositInfo {
        uint256 id;
        uint256 amount;
        uint256 depositedAt;
        uint256 apyBps;       // snapshot APY in basis points (e.g. 500 = 5.00%)
    }

    mapping(address => DepositInfo[]) public deposits;
    uint256 public nextDepositId;

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
    event Debug(string label, uint256 value);

    /**
     * @notice Deposit ETH and snapshot an APY rate for this position.
     * @param apyBps The APY to apply, in basis points (max 10000 = 100%).
     */
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

    /**
     * @notice Withdraw a portion or all of a previously deposited position.
     * @param depositId The ID of the deposit to withdraw from.
     * @param amount The amount of principal to withdraw.
     */
    function withdraw(uint256 depositId, uint256 amount) external {
        DepositInfo[] storage userDeposits = deposits[msg.sender];
        bool found = false;

        for (uint256 i = 0; i < userDeposits.length; i++) {
            if (userDeposits[i].id == depositId) {
                DepositInfo storage d = userDeposits[i];

                require(d.amount > 0, "Nothing to withdraw");
                require(amount > 0 && amount <= d.amount, "Invalid withdraw amount");

                // Calculate total interest accrued on the full deposit
                uint256 elapsed = block.timestamp - d.depositedAt;
                uint256 totalInterest = (d.amount * d.apyBps * elapsed)
                    / (BPS_DIVISOR * SECONDS_IN_YEAR);
                // Prorate interest for the portion being withdrawn
                uint256 proratedInterest = (totalInterest * amount) / d.amount;
                uint256 payout = amount + proratedInterest;

                emit Debug("withdraw_amount", amount);
                emit Debug("prorated_interest", proratedInterest);
                emit Debug("total_payout", payout);

                // Update storage
                d.amount -= amount;
                d.depositedAt = (d.amount == 0 ? 0 : block.timestamp);

                // Transfer ETH
                (bool success, ) = payable(msg.sender).call{value: payout}("");
                require(success, "Transfer failed");

                emit Withdrawn(msg.sender, depositId, amount, proratedInterest);
                found = true;
                break;
            }
        }

        require(found, "Deposit ID not found");
    }

    /**
     * @notice View function to calculate interest for a given deposit.
     * @param d A DepositInfo struct (pass as memory).
     * @return interest The amount of interest earned since deposit.
     */
    function calculateInterest(DepositInfo memory d) public view returns (uint256 interest) {
        if (d.amount == 0 || d.depositedAt == 0) return 0;
        uint256 elapsed = block.timestamp - d.depositedAt;
        return (d.amount * d.apyBps * elapsed) / (BPS_DIVISOR * SECONDS_IN_YEAR);
    }

    receive() external payable {}

    /**
     * @notice Returns all active deposits for a user.
     * @param user The address of the depositor.
     */
    function getUserDeposits(address user) external view returns (DepositInfo[] memory) {
        return deposits[user];
    }
}
