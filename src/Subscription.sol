// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/ISubscription.sol";
import "./vendor/SafeERC20.sol";

contract Subscription is ISubscription {
    using SafeERC20 for IERC20;

    // The subscription config
    SubscriptionConfig s_config;

    // A mapping from receiver to subscription
    mapping(address => SubscriptionDetails) internal s_subscriptions;
    // A mapping from receiver to a prepared withdrawal
    mapping(address => PreparedWithdrawal) internal s_preparedWithdrawals;

    constructor(SubscriptionConfig memory config) {
        s_config = config;
    }

    /// @inheritdoc ISubscription
    function getSubscription(address receiver) public view returns (SubscriptionDetails memory) {
        return s_subscriptions[receiver];
    }

    /// @inheritdoc ISubscription
    function getFeeToken() public view returns (IERC20) {
        return s_config.feeToken;
    }

    /// @inheritdoc ISubscription
    function createSubscription(SubscriptionDetails memory subscription)
        external
        onlySubscriptionManager(subscription.receiver)
    {
        address receiver = address(subscription.receiver);
        if (address(s_subscriptions[receiver].receiver) != address(0)) {
            revert SubscriptionAlreadyExists();
        }
        s_subscriptions[receiver] = subscription;

        if (subscription.balance > 0) {
            s_config.feeToken.safeTransferFrom(msg.sender, address(this), subscription.balance);
        }

        emit SubscriptionCreated(receiver);
    }

    /// @inheritdoc ISubscription
    function fundSubscription(address receiver, uint256 amount) external {
        if (amount <= 0) {
            revert FundingAmountNotPositive();
        }
        s_subscriptions[receiver].balance += amount;
        s_config.feeToken.safeTransferFrom(msg.sender, address(this), amount);

        emit SubscriptionFunded(receiver, amount);
    }

    /// @inheritdoc ISubscription
    function prepareWithdrawal(address receiver, uint256 amount)
        external
        onlySubscriptionManager(ISubscriptionManager(receiver))
    {
        if (amount > s_subscriptions[receiver].balance) {
            revert BalanceTooLow();
        }
        s_preparedWithdrawals[receiver] =
            PreparedWithdrawal({amount: amount, timestamp: block.timestamp + s_config.withdrawalDelay});

        emit PreparedWithdrawalRequest(receiver, amount);
    }

    /// @inheritdoc ISubscription
    function withdrawal(address receiver, uint256 amount)
        external
        onlySubscriptionManager(ISubscriptionManager(receiver))
    {
        PreparedWithdrawal memory prepared = s_preparedWithdrawals[receiver];
        if (prepared.timestamp > block.timestamp) {
            revert DelayNotPassedYet(prepared.timestamp);
        }
        if (prepared.amount != amount) {
            revert AmountMismatch(prepared.amount, amount);
        }
        if (amount > s_subscriptions[receiver].balance) {
            revert BalanceTooLow();
        }
        s_subscriptions[receiver].balance -= amount;
        delete s_preparedWithdrawals[receiver];
        s_config.feeToken.safeTransfer(msg.sender, amount);

        emit WithdrawalProcessed(receiver, amount);
    }

    /// @inheritdoc ISubscription
    function getSubscriptionConfig() external view returns (SubscriptionConfig memory) {
        return s_config;
    }

    modifier onlySubscriptionManager(ISubscriptionManager subscriptionManager) {
        if (subscriptionManager.getSubscriptionManager() != msg.sender) {
            revert InvalidManager();
        }
        _;
    }
}