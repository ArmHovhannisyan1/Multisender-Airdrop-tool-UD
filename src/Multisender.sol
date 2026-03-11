// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error InvalidRecipientsLength();
error InvalidAddress();

contract Multisender is ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public immutable OWNER;
    address public immutable USDT_TOKEN;
    // FEE_PER_ADDRESS = 50000 assumes USDT with 6 decimals = 0.05 USDT per address
    // If using a different token, adjust accordingly
    uint256 public constant FEE_PER_ADDRESS = 50000; // 0.05 USDT (6 decimals)
    event AirdropExecuted(
        address token,
        address sender,
        uint256 totalRecipients,
        uint256 totalAmount
    );

    constructor(address _owner, address _usdtToken) {
        require(_owner != address(0), "Invalid owner");
        require(_usdtToken != address(0), "Invalid USDT token");
        OWNER = _owner;
        USDT_TOKEN = _usdtToken;
    }

    modifier onlySender() {
        _onlySender();
        _;
    }

    function _onlySender() internal view {
        require(msg.sender == OWNER, "Not authorized");
    }

    function execute(
        address _token,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) public nonReentrant {
        if (_token == address(0)) revert InvalidAddress();

        if (
            _recipients.length == 0 ||
            _recipients.length > 250 ||
            _recipients.length != _amounts.length
        ) {
            revert InvalidRecipientsLength();
        }
        uint256 totalFee = FEE_PER_ADDRESS * _recipients.length;
        IERC20(USDT_TOKEN).safeTransferFrom(
            msg.sender,
            address(this),
            totalFee
        );
        uint256 totalAmount = 0;
        /* 
            If 198 tx pass and #199 fails
            Those tokens are GONE, gas is wasted, and tx reverts
        */
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] == address(0)) revert InvalidAddress();
            require(_amounts[i] > 0, "Amount must be greater than 0");
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount += _amounts[i];
            // Transfer tokens to each recipient
            // In a real contract, this would involve calling the token contract's transfer function
            // For example: IERC20(token).transferFrom(sender, recipients[i], amounts[i]);
            // This is a placeholder and should be replaced with actual token transfer logic
            IERC20(_token).safeTransferFrom(
                msg.sender,
                _recipients[i],
                _amounts[i]
            );
        }
        emit AirdropExecuted(
            _token,
            msg.sender,
            _recipients.length,
            totalAmount
        );
    }

    function withdrawFees() public onlySender {
        uint256 balance = IERC20(USDT_TOKEN).balanceOf(address(this));
        require(balance > 0, "No fees to withdraw");
        IERC20(USDT_TOKEN).safeTransfer(OWNER, balance);
    }

    receive() external payable {
        revert("ETH not accepted");
    }
}
