// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {INonceManager, IAccount, UserOperation} from "./interfaces/IERC4337.sol";

interface CommunityCounterEvents {
    event Incremented(uint256 indexed number);
    event Decremented(uint256 indexed number);
}

/// @title CommunityCounter
/// @notice A counter contract which is community owned, optionally anonymous, with socialized costs. It is a reaction
/// to permissioned counter contracts such as SafeCounter.
contract CommunityCounter is CommunityCounterEvents {
    error GasFeeTooHigh(uint256 gasFee);
    error GasLimitTooHigh();
    error NotFromEntryPoint();
    error NotIncrementOrDecrement();

    INonceManager internal _entryPoint;
    uint256 internal _maxGasFee;
    uint256 public current;

    constructor(INonceManager entryPoint, uint256 maxGasFee) {
        _entryPoint = entryPoint;
        _maxGasFee = maxGasFee;

        // Increment the initial nonce to reduce gas cost for every other sequential nonce
        // for the 0 key.
        _entryPoint.incrementNonce(0);
    }

    /// @notice Increment the counter.
    /// @dev This function is only callable by the entrypoint.
    function increment() external onlyEntryPoint {
        ++current;
        emit Incremented(current);
    }

    /// @notice Decrement the counter.
    /// @dev This function is only callable by the entrypoint.
    function decrement() external onlyEntryPoint {
        --current;
        emit Decremented(current);
    }

    /// @notice Validate a user operation which can only call the increment or decrement methods
    /// on this contract.
    /// @dev This function is only callable by the entrypoint. Note: the hash is not checked
    /// as we allow anyone to call this function as long as it passes the entrypoint checks.
    /// @param userOp The user operation to validate.
    /// @param missingAccountFunds The amount of funds required to pay for the user operation if there isn't
    /// enough deposited to the entrypoint contract.
    function validateUserOp(UserOperation calldata userOp, bytes32, uint256 missingAccountFunds)
        external
        onlyEntryPoint
        returns (uint256)
    {
        bytes4 method = bytes4(userOp.callData);
        if (userOp.callData.length != 4 || (method != this.increment.selector && method != this.decrement.selector)) {
            revert NotIncrementOrDecrement();
        }

        // We want to enforce a maximum gas cost (limit * gas fee) for each UserOp to restrict malicious users from
        // abusing socialized gas costs by benevolent users.
        uint256 gasLimit = userOp.callGasLimit + userOp.verificationGasLimit + userOp.preVerificationGas;
        if (gasLimit > 70_000) {
            revert GasLimitTooHigh();
        }

        uint256 gasFee = userOp.maxFeePerGas + userOp.maxPriorityFeePerGas;
        if (gasFee > _maxGasFee) {
            revert GasFeeTooHigh(gasFee);
        }

        _payMissingFunds(missingAccountFunds);
        return 0;
    }

    /// @dev Pay the missing funds to the entrypoint contract if there is not enough deposited.
    /// @param missingAccountFunds The amount of funds required to pay.
    function _payMissingFunds(uint256 missingAccountFunds) internal {
        if (missingAccountFunds == 0) {
            return;
        }
        // Up to the entrypoint to decide how to handle the error.
        (bool ok,) = address(_entryPoint).call{value: missingAccountFunds}("");
        (ok);
    }

    modifier onlyEntryPoint() {
        if (msg.sender != address(_entryPoint)) {
            revert NotFromEntryPoint();
        }
        _;
    }
}
