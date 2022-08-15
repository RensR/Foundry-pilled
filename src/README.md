## Demo contract

This directory houses the Solidity source code of a small subscription management contract.
The contract offers the following features

- Creating subscriptions
- Funding subscriptions
- Withdrawal funds from subscriptions in a 2 step process

Please go through the `ISubscription` interface for detailed information on all the methods.

### SubscriptionManager

The subscription manager contract is required for the `Subscription` contract to function properly and is not the focus of this repository.

## Vendor

We use some vendor contracts for `(I)ERC20` logic, these files are not tested and are only here to support the `Subscription` contract.