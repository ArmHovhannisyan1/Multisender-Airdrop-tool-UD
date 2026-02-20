// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Multisender {
    using SafeERC20 for IERC20;
    address public token;
    address public sender;
    address[] public recipients;
    uint256[] public amounts;
    bool private executed;

    event AirdropExecuted(
        address token,
        address sender,
        uint256 totalRecipients,
        uint256 totalAmount
    );

    constructor(
        address _token,
        address _sender,
        address[] memory _recipients,
        uint256[] memory _amounts
    ) {
        token = _token;
        sender = _sender;
        recipients = _recipients;
        require(
            (recipients.length > 0 && recipients.length <= 250),
            "Invalid recipients length"
        );
        amounts = _amounts;
    }

    modifier onlySender() {
        _onlySender();
        _;
    }

    function _onlySender() view internal {
        require(msg.sender == sender, "Not authorized");
    }

    function execute() public onlySender {
        require(!executed, "Already executed");
        executed = true;
        require(
            recipients.length == amounts.length,
            "Recipients and amounts length mismatch"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            // Transfer tokens to each recipient
            // In a real contract, this would involve calling the token contract's transfer function
            // For example: IERC20(token).transferFrom(sender, recipients[i], amounts[i]);
            // This is a placeholder and should be replaced with actual token transfer logic
            IERC20(token).safeTransferFrom(sender, recipients[i], amounts[i]);
        }
        emit AirdropExecuted(token, sender, recipients.length, getTotal());
    }

    function getTotal() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }
}
