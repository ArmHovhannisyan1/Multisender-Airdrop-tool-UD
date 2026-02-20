// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "../src/MockUSDT.sol";

contract HelperConfig is Script {
    /* If we are on a local anvil chain,
    we deploy mocks, otherwise, we grab the
    existing address from the helperconfig */
    // uint256 constant BASE_FEE = 10e6; // 10 USDT
    // uint256 constant MINTABLE_FEE = 5e6; // 5 USDT
    // uint256 constant PAUSABLE_FEE = 3e6;
    // uint256 constant TAX_FEE = 7e6;
    // uint256 constant REVOKE_AUTHORITY_FEE = 2e6;

    struct NetworkConfig {
        address usdt;
        // uint256 _baseFee;
        // uint256 _mintableFee;
        // uint256 _pausableFee;
        // uint256 _taxFee;
        // uint256 _revokeAuthorityFee;
        // address feeSystems;
        // address treasury;
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
            // _baseFee: BASE_FEE,
            // _mintableFee: MINTABLE_FEE,
            // _pausableFee: PAUSABLE_FEE,
            // _taxFee: TAX_FEE,
            // _revokeAuthorityFee: REVOKE_AUTHORITY_FEE
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7
            // _baseFee: BASE_FEE,
            // _mintableFee: MINTABLE_FEE,
            // _pausableFee: PAUSABLE_FEE,
            // _taxFee: TAX_FEE,
            // _revokeAuthorityFee: REVOKE_AUTHORITY_FEE
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
            // _baseFee: BASE_FEE,
            // _mintableFee: MINTABLE_FEE,
            // _pausableFee: PAUSABLE_FEE,
            // _taxFee: TAX_FEE,
            // _revokeAuthorityFee: REVOKE_AUTHORITY_FEE
        });
        return anvilConfig;
    }
}
