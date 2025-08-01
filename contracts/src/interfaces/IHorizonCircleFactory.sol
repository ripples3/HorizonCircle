// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IHorizonCircleFactory {
    function updateCircleStats(
        address circle,
        uint256 totalDeposits,
        uint256 totalShares,
        uint256 memberCount
    ) external;
}