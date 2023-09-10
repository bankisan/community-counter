// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {UserOperation as InternalUserOperation, INonceManager} from "../src/interfaces/IERC4337.sol";

import {EntryPoint, IEntryPoint, UserOperation} from "account-abstraction/core/EntryPoint.sol";

import {CommunityCounter, CommunityCounterEvents} from "../src/CommunityCounter.sol";

contract CommunityCounterTest is Test, CommunityCounterEvents {
    address public immutable beneficiary = makeAddr("beneficiary");
    EntryPoint public immutable entryPoint;
    CommunityCounter public immutable counter;

    constructor() {
        entryPoint = new EntryPoint();
        counter = new CommunityCounter(INonceManager(address(entryPoint)), 50);

        // Fund the counter with 1 ether.
        vm.deal(address(this), 1 ether);
        entryPoint.depositTo{value: 1 ether}(address(counter));
    }
}

contract BaseTest is CommunityCounterTest {
    function _buildUserOp(bytes memory _data) internal view returns (UserOperation memory) {
        UserOperation memory userOp = UserOperation({
            sender: address(counter),
            nonce: 1,
            initCode: bytes(""),
            callData: _data,
            callGasLimit: 24_000,
            verificationGasLimit: 26_000,
            preVerificationGas: 20_000,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
        return userOp;
    }

    function testIncrement() public {
        bytes memory increment = abi.encodeWithSelector(CommunityCounter.increment.selector);
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _buildUserOp(increment);

        entryPoint.handleOps(ops, payable(beneficiary));
        assertEq(counter.current(), 1);

        ops[0].nonce = 2;
        entryPoint.handleOps(ops, payable(beneficiary));
        assertEq(counter.current(), 2);
    }

    function testDecrement() public {
        vm.startPrank(address(entryPoint));
        counter.increment();
        counter.increment();
        vm.stopPrank();

        bytes memory decrement = abi.encodeWithSelector(CommunityCounter.decrement.selector);
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _buildUserOp(decrement);

        entryPoint.handleOps(ops, payable(beneficiary));
        assertEq(counter.current(), 1);

        ops[0].nonce = 2;
        entryPoint.handleOps(ops, payable(beneficiary));
        assertEq(counter.current(), 0);
    }

    function testWrongMethod() public {
        bytes memory wrong = abi.encodeWithSelector(bytes4(keccak256("wrong()")));
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _buildUserOp(wrong);

        vm.expectRevert();
        entryPoint.handleOps(ops, payable(beneficiary));
    }
}

contract ValidateUserOpTest is CommunityCounterTest {
    address public immutable vandal = makeAddr("vandal");

    function _buildInternalUserOp() internal view returns (InternalUserOperation memory) {
        InternalUserOperation memory userOp = InternalUserOperation({
            sender: address(counter),
            nonce: 1,
            initCode: bytes(""),
            callData: abi.encodeWithSelector(CommunityCounter.decrement.selector),
            callGasLimit: 24_000,
            verificationGasLimit: 26_000,
            preVerificationGas: 20_000,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
        return userOp;
    }

    function testWrongMethod() public {
        bytes memory wrong = abi.encodeWithSelector(bytes4(keccak256("wrong()")));
        InternalUserOperation memory userOp = _buildInternalUserOp();
        userOp.callData = wrong;

        vm.expectRevert(CommunityCounter.NotIncrementOrDecrement.selector);
        vm.prank(address(entryPoint));
        counter.validateUserOp(userOp, bytes32(0), 0);
    }

    function testGasFeeLimitHigh() public {
        InternalUserOperation memory userOp = _buildInternalUserOp();
        userOp.callGasLimit = 70_001;

        vm.expectRevert(CommunityCounter.GasLimitTooHigh.selector);
        vm.prank(address(entryPoint));
        counter.validateUserOp(userOp, bytes32(0), 0);
    }

    function testGasFeeTooHigh() public {
        InternalUserOperation memory userOp = _buildInternalUserOp();
        userOp.maxFeePerGas = 51;

        vm.expectRevert(abi.encodeWithSelector(CommunityCounter.GasFeeTooHigh.selector, 51 + 1));
        vm.prank(address(entryPoint));
        counter.validateUserOp(userOp, bytes32(0), 0);
    }
}

contract VandalTest is CommunityCounterTest {
    address public immutable vandal = makeAddr("vandal");

    function testIncrement() public {
        vm.expectRevert(CommunityCounter.NotFromEntryPoint.selector);
        counter.increment();
    }

    function testDecrement() public {
        vm.expectRevert(CommunityCounter.NotFromEntryPoint.selector);
        counter.decrement();
    }

    function testValidateUserOp() public {
        InternalUserOperation memory userOp;

        vm.expectRevert(CommunityCounter.NotFromEntryPoint.selector);
        counter.validateUserOp(userOp, bytes32(0), 0);
    }
}
