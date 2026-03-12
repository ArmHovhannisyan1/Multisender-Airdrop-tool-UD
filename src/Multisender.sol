// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AddressesConfig} from "./AddressesConfig.sol";

error InvalidRecipientsLength();
error InvalidAddress();
error InvalidAmount();

contract Multisender is ReentrancyGuard {
    using SafeERC20 for IERC20;
    // FEE_PER_ADDRESS = 50000 assumes USDT with 6 decimals = 0.05 USDT per address
    // If using a different token, adjust accordingly
    uint256 public constant FEE_PER_ADDRESS = 50000; // 0.05 USDT (6 decimals)
    address public constant FEE_RECIPIENT =
        AddressesConfig.FEE_RECIPIENT_ADDRESS;
    IERC20 public constant USDT = IERC20(AddressesConfig.USDT_ADDRESS);

    event AirdropExecuted(
        address token,
        address sender,
        uint256 totalRecipients,
        uint256 totalAmount
    );

    function execute(
        address _token,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) public nonReentrant {
        uint256 length = _recipients.length; // for not reading calldata every iteration
        if (_token == address(0)) revert InvalidAddress();

        if (length == 0 || length > 250 || length != _amounts.length)
            revert InvalidRecipientsLength();

        //require(_token != address(USDT), "Cannot transfer USDT!");

        uint256 totalFee = FEE_PER_ADDRESS * length;
        USDT.safeTransferFrom(msg.sender, FEE_RECIPIENT, totalFee);

        for (uint256 i = 0; i < length; i++) {
            if (_recipients[i] == address(0)) revert InvalidAddress();
            if (_amounts[i] <= 0) revert InvalidAmount();
        }

        uint256 totalAmount = 0;
        IERC20 token = IERC20(_token);

        for (uint256 i = 0; i < length; i++) {
            totalAmount += _amounts[i];
            token.safeTransferFrom(msg.sender, _recipients[i], _amounts[i]);
        }

        emit AirdropExecuted(_token, msg.sender, length, totalAmount);
    }
}
