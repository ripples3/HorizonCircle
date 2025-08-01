// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Velodrome Universal Router Interface
interface IVelodromeUniversalRouter {
    // Universal Router execute method
    function execute(bytes calldata commands, bytes[] calldata inputs) external payable;
    
    // Common Universal Router commands
    // 0x00: V3_SWAP_EXACT_IN
    // 0x01: V3_SWAP_EXACT_OUT
    // 0x02: PERMIT2_TRANSFER_FROM
    // 0x03: PERMIT2_PERMIT_BATCH
    // 0x04: SWEEP
    // 0x05: TRANSFER
    // 0x06: PAY_PORTION
    // 0x08: V2_SWAP_EXACT_IN
    // 0x09: V2_SWAP_EXACT_OUT
    // 0x0a: PERMIT2_PERMIT
    // 0x0b: WRAP_ETH
    // 0x0c: UNWRAP_WETH
    // 0x0d: PERMIT2_TRANSFER_FROM_BATCH
    // 0x0e: BALANCE_CHECK_ERC20
    // 0x0f: V3_POSITION_MANAGER_PERMIT
    // 0x10: V3_POSITION_MANAGER_CALL
    // 0x11: V4_SWAP
    // 0x12: V4_POSITION_CALL
}