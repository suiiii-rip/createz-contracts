// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SubLib} from "../SubLib.sol";

import {HasFlagSettings, FlagSettings} from "../../FlagSettings.sol";
import {Withdrawable, SubscriptionFlags} from "../ISubscription.sol";

import {HasPaymentToken, PaymentToken} from "../PaymentToken.sol";
import {Tips, HasTips} from "../Tips.sol";
import {HasRate, Rate} from "../Rate.sol";
import {HasUserData, UserData, MultiplierChange} from "../UserData.sol";
import {HasEpochs, Epochs} from "../Epochs.sol";
import {HasValidation, Validation} from "../Validation.sol";
import {HasBaseSubscription, BaseSubscription} from "../BaseSubscription.sol";
import {TimeAware, TimestampTimeAware} from "../TimeAware.sol";

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC721EnumerableUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

abstract contract AbstractWithdrawableFacet is
    Initializable,
    HasValidation,
    HasBaseSubscription,
    HasPaymentToken,
    HasRate,
    HasUserData,
    HasEpochs,
    ERC721EnumerableUpgradeable,
    HasFlagSettings,
    SubscriptionFlags,
    Withdrawable
{
    using SubLib for uint256;

    function withdraw(uint256 tokenId, uint256 amount) external requireExists(tokenId) {
        _withdraw(tokenId, _asInternal(amount));
    }

    function cancel(uint256 tokenId) external requireExists(tokenId) {
        _withdraw(tokenId, _withdrawableFromSubscription(tokenId));
    }

    /**
     * @param amount internal representation (18 decimals) of amount to withdraw
     *
     */
    function _withdraw(uint256 tokenId, uint256 amount) private requireIsAuthorized(tokenId) {
        // amount is checked in _withdrawFromSubscription
        (uint256 depositedAt, uint256 oldDeposit, uint256 newDeposit) = _withdrawFromSubscription(tokenId, amount);

        _reduceInEpochs(depositedAt, oldDeposit, newDeposit, _multiplier(tokenId), _rate());

        uint256 externalAmount = _asExternal(amount);
        _paymentTokenSend(payable(_msgSender()), externalAmount);

        emit SubscriptionWithdrawn(tokenId, externalAmount, _msgSender(), _totalDeposited(tokenId));
        emit MetadataUpdate(tokenId);
    }

    function burn(uint256 tokenId) external {
        // only owner of tokenId can burn
        require(_msgSender() == _ownerOf(tokenId), "SUB: not the owner");

        _deleteSubscription(tokenId);

        _burn(tokenId);
    }

    function withdrawable(uint256 tokenId) external view requireExists(tokenId) returns (uint256) {
        return _asExternal(_withdrawableFromSubscription(tokenId));
    }
}

contract WithdrawableFacet is
    TimestampTimeAware,
    Rate,
    PaymentToken,
    Epochs,
    UserData,
    FlagSettings,
    Validation,
    BaseSubscription,
    AbstractWithdrawableFacet
{}