// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/subscription/handle/ISubscriptionHandle.sol";
import "../../../src/subscription/handle/SubscriptionHandle.sol";
import "../../../src/subscription/ISubscription.sol";

import "../../mocks/TestSubscription.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract TestSubscriptionHandle is SubscriptionHandle {
    struct Details {
        bool set;
        bool managed;
    }

    address public deployAddress;
    mapping(address => Details) public registry;

    using Strings for string;

    function setDeployAddress(address addr) public {
        deployAddress = addr;
    }

    function _addToRegistry(address addr, bool isManaged_) internal override returns (bool set) {
        set = !registry[addr].set;
        registry[addr].set = true;
        registry[addr].managed = isManaged_;
    }

    function _isManaged(address addr) internal view override returns (bool) {
        return registry[addr].managed;
    }

    function _isRegistered(address addr) internal view override returns (bool) {
        return registry[addr].set;
    }

    function setManaged(address addr, bool managed) external {
        registry[addr].managed = managed;
    }

    function register(address) external pure returns (uint256) {
        revert("Not implemented for test");
    }

    function isManaged(uint256 tokenId) external view returns (bool) {
        return _isManaged(address(uint160(tokenId)));
    }

    function contractOf(uint256 tokenId) external view returns (address) {
        revert("not implemented");
    }

    function _deploySubscription(string calldata _name, string calldata, MetadataStruct calldata, SubSettings calldata)
        internal
        view
        override
        returns (address)
    {
        require(!_name.equal("fail"), "Deployment failed");
        return deployAddress;
    }
}

contract SubscriptionHandleTest is Test, SubscriptionHandleEvents {
    TestSubscriptionHandle private handle;

    address private user;

    MetadataStruct private metadata;
    SubSettings private settings;

    function setUp() public {
        user = address(1000);
        metadata = MetadataStruct("test", "test", "test");
        settings.token = IERC20Metadata(address(0));
        settings.rate = 1;
        settings.lock = 10;
        settings.epochSize = 100;

        handle = new TestSubscriptionHandle();
        handle.setDeployAddress(address(1234));
    }

    function testMint() public {
        vm.startPrank(user); // not a contract!
        vm.expectEmit();
        emit SubscriptionContractCreated(uint256(uint160(handle.deployAddress())), handle.deployAddress());

        address result = handle.mint("", "", metadata, settings);
        assertEq(result, handle.deployAddress(), "address of contract returned");
        assertTrue(handle.isManaged(uint256(uint160(result))), "minted contract marked as managed");

        assertEq(handle.balanceOf(user), 1, "sender has 1 token");
        assertEq(handle.ownerOf(uint256(uint160(result))), user, "tokenId/address minted to sender");
        assertEq(handle.totalSupply(), 1, "1 token minted to supply");
    }

    function testMint_deployFail() public {
        vm.expectRevert();
        handle.mint("fail", "", metadata, settings);
    }

    function testBurn() public {
        vm.startPrank(user); // not a contract!

        address result = handle.mint("", "", metadata, settings);
        uint256 tokenId = uint256(uint160(result));

        assertEq(handle.balanceOf(user), 1, "sender has 1 token");
        assertEq(handle.ownerOf(tokenId), user, "tokenId/address minted to sender");
        assertEq(handle.totalSupply(), 1, "1 token minted to supply");

        handle.burn(tokenId);
        assertEq(handle.balanceOf(user), 0, "sender has no tokens");
        assertEq(handle.totalSupply(), 0, "no tokens existing");

        vm.expectRevert();
        handle.ownerOf(tokenId);
    }

    function testRegister_existingMint() public {
        vm.startPrank(user); // not a contract!

        address addr = handle.mint("", "", metadata, settings);

        vm.expectRevert();
        handle.register(addr);
    }

    function testManaged(address addr, bool managed) public {
        handle.setManaged(addr, managed);

        assertEq(handle.isManaged(uint256(uint160(addr))), managed, "managed value set");
    }

    function testManaged_largeValue(uint256 tokenId) public {
        tokenId = bound(tokenId, uint256(type(uint160).max) + 1, type(uint256).max);

        assertFalse(handle.isManaged(tokenId), "out of bounds tokenId is always false");
    }
}
