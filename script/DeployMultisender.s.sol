// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "../test/mocks/MockUSDT.sol";
import {Multisender} from "../src/Multisender.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMultisender is Script {
    function run() external returns (Multisender) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getActiveConfig();
        vm.startBroadcast();
        // address owner = vm.envAddress("OWNER_ADDRESS");
        Multisender multisender = new Multisender(
            msg.sender,
            address(ERC20Mock(config.usdt))
        );
        vm.stopBroadcast();
        return multisender;
    }
}
