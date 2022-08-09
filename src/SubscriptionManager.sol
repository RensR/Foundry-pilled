// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/ISubscriptionManager.sol";

contract SubscriptionManager is ISubscriptionManager {
    address s_manager;

    constructor(address manager) {
        s_manager = manager;
    }

    function getSubscriptionManager() external view returns (address) {
        return s_manager;
    }
}