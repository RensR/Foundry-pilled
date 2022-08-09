// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";

contract TestSetup is Test {
    address internal constant OWNER = 0x00007e64E1fB0C487F25dd6D3601ff6aF8d32e4e;
    address internal constant STRANGER = 0x1111111111111111111111111111111111111111;

    uint256 internal constant BLOCK_TIME = 1234567890;

    function setUp() public virtual {
        // Send all calls from now on from the OWNER address
        vm.startPrank(OWNER);
        // Set the block time to BLOCK_TIME
        vm.warp(BLOCK_TIME);
    }
}