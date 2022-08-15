## Tests

This directory houses the Solidity test files for the subscription contract.
The `TestSetup.t.sol` file contains a generic setup suitable for any test.
The `Subscription.t.sol` file contains a more specific setup that inherits from the generic setup. 

The subscription test file contains a separate contract for each method in the subscription contract.
This way, we can do specific setups when needed, it's always clear where tests go and we have a nicely grouped `gas-snapshot` file.
The contracts are named `CONTRACTNAME_METHODNAME` resulting in a gas snapshot that looks like this

```
Subscription_createSubscription:testSuccess() (gas: 169585)
Subscription_fundSubscription:testFundingAmountNotPositiveReverts() (gas: 10459)
Subscription_fundSubscription:testSuccess() (gas: 46578)
Subscription_fundSubscriptionFuzzing:testFuzzSuccess(uint256) (runs: 256, μ: 77717, ~: 77951)
Subscription_getFeeToken:testSuccess() (gas: 9704)
Subscription_getSubscription:testNonExistentReceiverSuccess() (gas: 10116)
Subscription_getSubscription:testSuccess() (gas: 12257)
Subscription_getSubscriptionConfig:testSuccess() (gas: 10034)
```

Tests end with either `Success` or `Reverts` depending on the desired outcome of the transaction.
The tests are grouped to have all success cases before the reverts.

### events

We see events being declared in the `SubscriptionSetup`, this is because we need to emit those for the `expectEmit` calls. 
Since we cannot reference the events in the ISubscription interface we have to duplicate them.