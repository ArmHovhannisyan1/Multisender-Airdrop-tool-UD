// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "../test/mocks/MockUSDT.sol";

contract HelperConfig is Script {
    /* If we are on a local anvil chain,
    we deploy mocks, otherwise, we grab the
    existing address from the helperconfig */

    struct NetworkConfig {
        address usdt;
    }

    NetworkConfig public activeNetwork;

    function getActiveConfig() public returns (NetworkConfig memory) {
        if (block.chainid == 11155111) activeNetwork = getSepoliaEthConfig();
        else if (block.chainid == 1) activeNetwork = getMainnetEthConfig();
        else activeNetwork = getAnvilEthConfig();
        return activeNetwork;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            usdt: 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7
        });
        return mainnetConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetwork.usdt != address(0)) {
            return activeNetwork;
        }
        vm.startBroadcast();
        ERC20Mock mockUsdt = new ERC20Mock();
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            usdt: address(mockUsdt)
        });
        return anvilConfig;
    }
}
