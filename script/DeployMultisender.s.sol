// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {Multisender} from "../src/Multisender.sol";

contract DeployMultisender is Script {
    function run() external returns (Multisender) {
        vm.startBroadcast();
        Multisender multisender = new Multisender();
        vm.stopBroadcast();
        return multisender;
    }
}
