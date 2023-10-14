// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

interface FlagEvents {
    event FlagSet(address account, uint256 flag, uint256 newFlags);
    event FlagUnset(address account, uint256 flag, uint256 newFlags);
}

abstract contract HasFlagSettings {
    function _setFlags(uint256 flags) internal virtual;

    function _unsetFlags(uint256 flags) internal virtual;

    function flagsEnabled(uint256 flags) public view virtual returns (bool);

    function getFlags() public view virtual returns (uint256);

    function _requireDisabled(uint256 flag) internal view virtual {
        require(!flagsEnabled(flag), "Flag: setting enabled");
    }

    function _requireEnabled(uint256 flag) internal view virtual {
        require(flagsEnabled(flag), "Flag: setting disabled");
    }

    modifier whenDisabled(uint256 flags) virtual {
        _requireDisabled(flags);
        _;
    }

    modifier whenEnabled(uint256 flags) virtual {
        _requireEnabled(flags);
        _;
    }
}

abstract contract FlagSettings is Initializable, ContextUpgradeable, FlagEvents, HasFlagSettings {
    uint256 private _flags;

    function __FlagSettings_init() internal onlyInitializing {
        __FlagSettings_init_unchained();
    }

    function __FlagSettings_init_unchained() internal onlyInitializing {
        _flags = 0;
    }

    function _setFlags(uint256 flags) internal override {
        _flags = _flags | flags;
        emit FlagSet(_msgSender(), flags, _flags);
    }

    function _unsetFlags(uint256 flags) internal override {
        _flags = _flags ^ flags;
        emit FlagUnset(_msgSender(), flags, _flags);
    }

    function flagsEnabled(uint256 flags) public view override returns (bool) {
        return (_flags & flags) == flags;
    }

    function getFlags() public view override returns (uint256) {
        return _flags;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
