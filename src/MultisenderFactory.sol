// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Multisender} from "./Multisender.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";

contract MultisenderFactory {
    using SafeERC20 for IERC20;
    address public immutable OWNER;
    address public usdtToken;
    uint256 public constant FEE_PER_ADDRESS = 50000; // 0.05 USDT
    mapping(address => address[]) public userDeployments;

    event MultisenderDeployed(
        address indexed deployer,
        address multisenderAddress,
        uint256 recipientCount,
        uint256 feePaid
    );

    constructor(address _owner, address _usdtToken) {
        OWNER = _owner;
        usdtToken = _usdtToken;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() view internal {
        require(msg.sender == OWNER, "Not authorized");
    }

    function deploy(
        address _token,
        address[] calldata _recipients,
        uint256[] calldata amounts
    ) public returns (address) {
        uint256 totalFee = FEE_PER_ADDRESS * _recipients.length;
        IERC20(usdtToken).safeTransferFrom(msg.sender, address(this), totalFee);
        Multisender multisender = new Multisender(
            _token,
            msg.sender,
            _recipients,
            amounts
        );
        userDeployments[msg.sender].push(address(multisender));
        emit MultisenderDeployed(
            msg.sender,
            address(multisender),
            _recipients.length,
            totalFee
        );
        return address(multisender);
    }

    function getUserDeployments(
        address _user
    ) public view returns (address[] memory) {
        return userDeployments[_user];
    }

    function withdrawFees() public onlyOwner {
        uint256 balance = IERC20(usdtToken).balanceOf(address(this));
        console.log(balance);
        require(balance > 0, "No fees to withdraw");
        IERC20(usdtToken).safeTransfer(OWNER, balance);
    }
}
