// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {MultisenderFactory} from "../src/MultisenderFactory.sol";
import {Multisender} from "../src/Multisender.sol";
import {ERC20Mock} from "../src/MockUSDT.sol";
import {DeployMultisender} from "../script/DeployMultisender.s.sol";
import {console} from "forge-std/console.sol";

contract MultisenderTest is Test {
    DeployMultisender public deployer;
    MultisenderFactory public factory;
    // Multisender public multisender;
    ERC20Mock public usdt;
    ERC20Mock public token;

    uint256 constant FEE_PER_ADDRESS = 50000; // 0.05 USDT
    uint256 constant AIRDROP_AMOUNT = 10e6; // 10 tokens per recipient

    address public user = makeAddr("user");

    function setUp() external {
        deployer = new DeployMultisender();
        factory = deployer.run();

        usdt = ERC20Mock(address(deployer.usdtToken()));
        token = new ERC20Mock();

        // Mint USDT to USER for fees
        usdt.mint(user, 100e6); // 100 USDT

        // Mint airdrop tokens to USER
        token.mint(user, 1000e6); // 1000 tokens

        // USER approves factory to spend USDT for fees
        vm.prank(user);
        usdt.approve(address(factory), type(uint256).max);
    }


    function testDeployCreatesMultisender() public {
        address[] memory recipients = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i] = makeAddr(vm.toString(i));
            amounts[i] = AIRDROP_AMOUNT;
        }
        vm.prank(user);
        address multisenderAddress = factory.deploy(
            address(token),
            recipients,
            amounts
        );
        assert(multisenderAddress != address(0));
        assertEq(factory.getUserDeployments(user).length, 1);
        assertEq(factory.getUserDeployments(user)[0], multisenderAddress);
    }

    function testFeeIsCollectedCorrectly() public {
        address[] memory recipients = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i] = makeAddr(vm.toString(i));
            amounts[i] = AIRDROP_AMOUNT;
        }
        vm.prank(user);
        factory.deploy(address(token), recipients, amounts);
        uint256 currentBalance = usdt.balanceOf(address(factory));
        console.log(currentBalance);
        assertEq(currentBalance, FEE_PER_ADDRESS * recipients.length);
    }

    function testExecuteDistributesTokens() public {
        address[] memory recipients = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i] = makeAddr(vm.toString(i));
            amounts[i] = AIRDROP_AMOUNT;
        }
        vm.startPrank(user);
        address multisender = factory.deploy(
            address(token),
            recipients,
            amounts
        );
        token.approve(multisender, AIRDROP_AMOUNT * recipients.length);
        Multisender(multisender).execute();
        vm.stopPrank();
        for (uint256 i = 0; i < recipients.length; i++) {
            assertEq(token.balanceOf(recipients[i]), AIRDROP_AMOUNT);
        }
    }

    function testCannotExecuteTwice() public {
        address[] memory recipients = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i] = makeAddr(vm.toString(i));
            amounts[i] = AIRDROP_AMOUNT;
        }
        vm.startPrank(user);
        address multisender = factory.deploy(
            address(token),
            recipients,
            amounts
        );
        token.approve(multisender, AIRDROP_AMOUNT * recipients.length);
        Multisender(multisender).execute();
        vm.expectRevert("Already executed");
        Multisender(multisender).execute();
        vm.stopPrank();
    }

    function testOnlyOwnerCanWithdrawFees() public {
        address[] memory recipients = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i] = makeAddr(vm.toString(i));
            amounts[i] = AIRDROP_AMOUNT;
        }
        vm.startPrank(user);
        factory.deploy(address(token), recipients, amounts);
        console.log("Factory address:", address(factory));
        console.log("Factory USDT balance:", usdt.balanceOf(address(factory)));
        console.log("Owner:", factory.OWNER());
        console.log("Test contract:", address(this));
        console.log(usdt.balanceOf(address(factory.OWNER())));
        vm.expectRevert();
        factory.withdrawFees();
        vm.stopPrank();
        console.log("Reverted");
        // vm.startPrank(address(factory.OWNER()));
        factory.withdrawFees();
        assert(usdt.balanceOf(address(factory)) == 0);
        assert(
            usdt.balanceOf(factory.OWNER()) ==
                FEE_PER_ADDRESS * recipients.length
        );
        vm.stopPrank();
    }

    function testRevertOnTooManyReceipents() public {
        address[] memory recipients = new address[](251);
        uint256[] memory amounts = new uint256[](251);
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i] = makeAddr(vm.toString(i));
            amounts[i] = AIRDROP_AMOUNT;
        }
        vm.prank(user);
        vm.expectRevert();
        factory.deploy(address(token), recipients, amounts);
    }

    function testGetTotal() public {
        uint256 sum = 0;
        address[] memory recipients = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i] = makeAddr(vm.toString(i));
            amounts[i] = AIRDROP_AMOUNT;
            sum += AIRDROP_AMOUNT;
        }
        vm.prank(user);
        address multisender = factory.deploy(
            address(token),
            recipients,
            amounts
        );
        assertEq(Multisender(multisender).getTotal(), sum);
    }
}
