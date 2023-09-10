// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import {EntryPoint, NonceManager, UserOperation} from "account-abstraction/core/EntryPoint.sol";
import {CommunityCounter} from "../src/CommunityCounter.sol";

contract CommunityCounterScript is Script {
    function sendIncrement(address entrypoint, address communityCounter) public {
        EntryPoint entryPoint = EntryPoint(payable(entrypoint));
        NonceManager nonceManager = NonceManager(payable(entrypoint));

        uint256 nonce = nonceManager.getNonce(communityCounter, 0);
        UserOperation memory userOp = UserOperation({
            sender: communityCounter,
            nonce: nonce,
            initCode: bytes(""),
            callData: abi.encodeWithSelector(CommunityCounter.increment.selector),
            callGasLimit: 24_000,
            verificationGasLimit: 26_000,
            preVerificationGas: 20_000,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        vm.broadcast();
        entryPoint.handleOps(ops, payable(msg.sender));
    }
}
