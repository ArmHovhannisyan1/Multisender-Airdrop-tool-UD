// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {MultisenderFactory} from "../src/MultisenderFactory.sol";
import {ERC20Mock} from "../src/MockUSDT.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMultisender is Script {
    ERC20Mock public usdtToken;

    function run() external returns (MultisenderFactory) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getActiveConfig();
        vm.startBroadcast();
        usdtToken = ERC20Mock(config.usdt);
        MultisenderFactory factory = new MultisenderFactory(
            msg.sender,
            address(usdtToken)
        );
        console.log("MockUSDT deployed at:", address(usdtToken));
        console.log("MultisenderFactory deployed at:", address(factory));
        vm.stopBroadcast();
        return factory;
    }
}
