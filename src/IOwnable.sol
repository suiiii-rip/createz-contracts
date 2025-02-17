// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Ownable interface
 */
interface IOwnable {
    function owner() external view returns (address);
}
