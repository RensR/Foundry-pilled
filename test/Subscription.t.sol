// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../src/Subscription.sol";
import "../src/SubscriptionManager.sol";
import "../src/mocks/MockERC20.sol";
import "./TestSetup.t.sol";

contract SubscriptionSetup is TestSetup {
    uint32 internal constant WITHDRAWAL_DELAY = 2 * 60 * 60;
    uint256 internal constant APPROVED_AMOUNT = 100;

    event SubscriptionFunded(address receiver, uint256 funding);
    event SubscriptionCreated(address receiver);
    event PreparedWithdrawalRequest(address receiver, uint256 amount);
    event WithdrawalProcessed(address receiver, uint256 amount);

    IERC20 s_feeToken;
    ISubscriptionManager s_manager;
    Subscription s_subscriptionContract;

    function setUp() public virtual override {
        // Call the setup from the inherited contract
        TestSetup.setUp();

        // Deploy a new SubscriptionManager contract
        s_manager = new SubscriptionManager(OWNER);
        // Deploy a new ERC20 contract
        s_feeToken = new MockERC20("LINK", "LINK", OWNER, 2**256 - 1);

        s_subscriptionContract = new Subscription(
          ISubscription.SubscriptionConfig({
            withdrawalDelay: WITHDRAWAL_DELAY,
            feeToken: s_feeToken
          })
        );

        // Approve twice the APPROVED_AMOUNT because we create one subscription
        // just below and this way we'll have enough approved to create another
        // one in other tests.
        s_feeToken.approve(address(s_subscriptionContract), APPROVED_AMOUNT * 2);
        s_subscriptionContract.createSubscription(_generateSubscriptionForManager());
    }

    // @notice generateSubscriptionForManager is a helper method that generates SubscriptionDetails
    // @return SubscriptionDetails with a known balance and s_manager as the receiver contract
    function _generateSubscriptionForManager() internal view returns (ISubscription.SubscriptionDetails memory) {
        return ISubscription.SubscriptionDetails({receiver: s_manager, balance: APPROVED_AMOUNT});
    }
}

/// @notice #getSubscription
contract Subscription_getSubscription is SubscriptionSetup {
    // Success
    function testSuccess() public {
        // Assert that the subscription exists by checking the balance
        assertEq(s_subscriptionContract.getSubscription(address(s_manager)).balance, APPROVED_AMOUNT);
    }

    function testNonExistentReceiverSuccess() public {
        // When no subscription exists the balance should always be 0
        assertEq(s_subscriptionContract.getSubscription(address(STRANGER)).balance, 0);
    }
}

/// @notice #getFeeToken
contract Subscription_getFeeToken is SubscriptionSetup {
    // Success
    function testSuccess() public {
        // The fee token should always be equal to the s_feeToken
        assertEq(address(s_subscriptionContract.getFeeToken()), address(s_feeToken));
    }
}

/// @notice #createSubscription
contract Subscription_createSubscription is SubscriptionSetup {
    // Success
    function testSuccess() public {
        // Cache the user & contract balances
        uint256 ownerBalancePre = s_feeToken.balanceOf(OWNER);
        uint256 contractBalancePre = s_feeToken.balanceOf(address(s_subscriptionContract));

        // Create a new subscription struct
        ISubscription.SubscriptionDetails memory subscription = _generateSubscriptionForManager();
        subscription.receiver = new SubscriptionManager(OWNER);

        // Expect a SubscriptionCreated event to be emitted
        vm.expectEmit(false, false, false, true);
        emit SubscriptionCreated(address(subscription.receiver));

        // Act
        s_subscriptionContract.createSubscription(subscription);

        // Assert the subscription balance tokens have been sent
        assertEq(ownerBalancePre - subscription.balance, s_feeToken.balanceOf(OWNER));
        // Assert the subscription balance tokens have been received
        assertEq(contractBalancePre + subscription.balance, s_feeToken.balanceOf(address(s_subscriptionContract)));
    }

    // Reverts
    function testInvalidManagerReverts() public {
        // Stop sending from the OWNER address
        vm.stopPrank();

        // Expect a revert because only the subscription manager can
        // modify a subscription.
        vm.expectRevert(ISubscription.InvalidManager.selector);

        // Act
        s_subscriptionContract.createSubscription(_generateSubscriptionForManager());
    }

    function testSubscriptionAlreadyExistsReverts() public {
        // Since we already created a subscription for the s_manager, any
        // new createSubscription calls will revert with SubscriptionAlreadyExists
        vm.expectRevert(ISubscription.SubscriptionAlreadyExists.selector);

        // Act
        s_subscriptionContract.createSubscription(_generateSubscriptionForManager());
    }

    function testApproveTooLowReverts() public {
        // Create a new subscription struct
        ISubscription.SubscriptionDetails memory subscription = _generateSubscriptionForManager();
        subscription.receiver = new SubscriptionManager(OWNER);
        // Since the current approved amount is equal to APPROVED_AMOUNT we choose a
        // value above that so the call should fail.
        subscription.balance = APPROVED_AMOUNT + 1;

        // Expect a generic ERC20 error with the following message
        vm.expectRevert("ERC20: transfer amount exceeds allowance");

        // Act
        s_subscriptionContract.createSubscription(subscription);
    }
}

/// @notice #fundSubscription
contract Subscription_fundSubscriptionFuzzing is SubscriptionSetup {
    function setUp() public virtual override {
        // Call the setup from the inherited contract
        TestSetup.setUp();

        // Create a new token to make sure we have access to uint256.Max()
        s_feeToken = new MockERC20("LNK", "LNK", OWNER, 2**256 - 1);

        // Deploy a new contract with the new fee token
        s_subscriptionContract = new Subscription(
            ISubscription.SubscriptionConfig({
                withdrawalDelay: WITHDRAWAL_DELAY,
                feeToken: s_feeToken
            })
        );

        // Create a subscription with a 0 balance
        s_subscriptionContract.createSubscription(
            ISubscription.SubscriptionDetails({receiver: new SubscriptionManager(OWNER), balance: 0})
        );
    }

    function testFuzzSuccess(uint256 amount) public {
        // Zero amount funding always fails and is covered in another test
        vm.assume(amount > 0);

        // change gas usage for testing
        s_feeToken.approve(address(s_subscriptionContract), amount);

        // Approve the amount
        s_feeToken.approve(address(s_subscriptionContract), amount);

        // Act
        s_subscriptionContract.fundSubscription(OWNER, amount);
    }

    function testFuzz2Success(uint256 amount) public {
        // Zero amount funding always fails and is covered in another test
        vm.assume(amount > 0);

        amount -= 1;
        amount += 1;

        // Approve the amount
        s_feeToken.approve(address(s_subscriptionContract), amount);

        // Act
        s_subscriptionContract.fundSubscription(OWNER, amount);
    }

    function testFuzzLeafsSuccess(bytes32 leaf1, bytes32 leaf2, bytes32 leaf3, bytes32 leaf4)
        public
        returns (uint256)
    {
        uint256 val1 = uint256(leaf1);
        uint256 val2 = uint256(leaf2);
        uint256 val3 = uint256(leaf3);
        uint256 val4 = uint256(leaf4);

        for (; val1 < val2 && val1 < 2 ** 63; val1 *= 2) {}

        return val4;
    }
}

/// @notice #fundSubscription
contract Subscription_fundSubscription is SubscriptionSetup {
    // Success
    function testSuccess() public {
        // Cache the user & contract balances
        uint256 ownerBalancePre = s_feeToken.balanceOf(OWNER);
        uint256 contractBalancePre = s_feeToken.balanceOf(address(s_subscriptionContract));

        // Expect a SubscriptionFunded event to be emitted
        vm.expectEmit(false, false, false, true);
        emit SubscriptionFunded(address(s_manager), APPROVED_AMOUNT);

        // Act
        s_subscriptionContract.fundSubscription(address(s_manager), APPROVED_AMOUNT);

        // Assert the subscription balance tokens have been sent
        assertEq(ownerBalancePre - APPROVED_AMOUNT, s_feeToken.balanceOf(OWNER));
        // Assert the subscription balance tokens have been received
        assertEq(contractBalancePre + APPROVED_AMOUNT, s_feeToken.balanceOf(address(s_subscriptionContract)));
    }

    // Reverts
    function testFundingAmountNotPositiveReverts() public {
        // When a user tries to use a funding amount < 1 it should revert
        vm.expectRevert(ISubscription.FundingAmountNotPositive.selector);

        // Act
        s_subscriptionContract.fundSubscription(address(s_manager), 0);
    }
}

/// @notice #prepareWithdrawal
contract Subscription_prepareWithdrawal is SubscriptionSetup {
    // Success
    function testSuccess() public {
        // Expect a PreparedWithdrawalRequest event to be emitted
        vm.expectEmit(false, false, false, true);
        emit PreparedWithdrawalRequest(address(s_manager), APPROVED_AMOUNT);

        // Act
        s_subscriptionContract.prepareWithdrawal(address(s_manager), APPROVED_AMOUNT);
    }

    // Reverts
    function testBalanceTooLowReverts() public {
        // Expect the call to revert because the given withdrawal amount
        // would exceed the current balance.
        vm.expectRevert(ISubscription.BalanceTooLow.selector);

        // Act
        s_subscriptionContract.prepareWithdrawal(address(s_manager), 2 * APPROVED_AMOUNT);
    }

    function testInvalidManagerReverts() public {
        // Stop sending from the OWNER address
        vm.stopPrank();

        // Expect the call to revert because of an invalid manager account
        // trying to initiate the call.
        vm.expectRevert(ISubscription.InvalidManager.selector);

        // Act
        s_subscriptionContract.prepareWithdrawal(address(s_manager), APPROVED_AMOUNT);
    }
}

/// @notice #withdrawal
contract Subscription_withdrawal is SubscriptionSetup {
    // Success
    function testSuccess() public {
        // Cache the user & contract balances
        uint256 ownerBalancePre = s_feeToken.balanceOf(OWNER);
        uint256 contractBalancePre = s_feeToken.balanceOf(address(s_subscriptionContract));

        // Setup the  prepareWithdrawal
        uint256 withdrawalAmount = APPROVED_AMOUNT;
        s_subscriptionContract.prepareWithdrawal(address(s_manager), withdrawalAmount);

        // Change the block time forward by the WITHDRAWAL_DELAY so the
        // withdrawal is allowed to proceed.
        vm.warp(BLOCK_TIME + WITHDRAWAL_DELAY);

        // Expect a WithdrawalProcessed event to be emitted
        vm.expectEmit(false, false, false, true);
        emit WithdrawalProcessed(address(s_manager), withdrawalAmount);

        // Act
        s_subscriptionContract.withdrawal(address(s_manager), withdrawalAmount);

        // Assert the subscription balance tokens have been received
        assertEq(ownerBalancePre + withdrawalAmount, s_feeToken.balanceOf(OWNER));
        // Assert the subscription balance tokens have been sent
        assertEq(contractBalancePre - withdrawalAmount, s_feeToken.balanceOf(address(s_subscriptionContract)));
    }

    // Reverts
    function testInvalidManagerReverts() public {
        // Stop sending from the OWNER address
        vm.stopPrank();

        // Expect a revert because only the subscription manager can
        // modify a subscription.
        vm.expectRevert(ISubscription.InvalidManager.selector);

        // Act
        s_subscriptionContract.withdrawal(address(s_manager), APPROVED_AMOUNT);
    }

    function testDelayNotPassedYetReverts() public {
        uint256 amount = APPROVED_AMOUNT;
        // Setup a withdrawal preparation
        s_subscriptionContract.prepareWithdrawal(address(s_manager), amount);

        // Expect a DelayNotPassedYet revert with the block time where the
        // prepared withdrawal would be allowed.
        vm.expectRevert(abi.encodeWithSelector(ISubscription.DelayNotPassedYet.selector, BLOCK_TIME + WITHDRAWAL_DELAY));

        // Act
        s_subscriptionContract.withdrawal(address(s_manager), amount);
    }

    function testAmountMismatchReverts() public {
        uint256 amount = APPROVED_AMOUNT;
        // Setup a withdrawal preparation
        s_subscriptionContract.prepareWithdrawal(address(s_manager), amount);
        // Warp to a block time where the withdrawal would be allowed
        vm.warp(BLOCK_TIME + WITHDRAWAL_DELAY);
        // Change the amount to not match the prepared amount
        amount = amount - 1;
        // Expect a AmountMismatch revert with both the prepared and the given amount
        // as parameters.
        vm.expectRevert(abi.encodeWithSelector(ISubscription.AmountMismatch.selector, APPROVED_AMOUNT, amount));
        // Act
        s_subscriptionContract.withdrawal(address(s_manager), amount);
    }
}

/// @notice #getSubscriptionConfig
contract Subscription_getSubscriptionConfig is SubscriptionSetup {
    // Success
    function testSuccess() public {
        // Act
        ISubscription.SubscriptionConfig memory subscriptionConfig = s_subscriptionContract.getSubscriptionConfig();

        // Assert the WITHDRAWAL_DELAY and s_feeToken address are correct
        assertEq(WITHDRAWAL_DELAY, subscriptionConfig.withdrawalDelay);
        assertEq(address(s_feeToken), address(subscriptionConfig.feeToken));
    }
}
