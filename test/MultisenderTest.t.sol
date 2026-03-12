// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {Multisender} from "../src/Multisender.sol";
import {ERC20Mock} from "../test/mocks/MockUSDT.sol";
import {AddressesConfig} from "../src/AddressesConfig.sol";

contract MultisenderTest is Test {
    Multisender public multisender;
    ERC20Mock public usdt;
    ERC20Mock public token;

    uint256 constant FEE_PER_ADDRESS = 50000; // 0.05 USDT
    uint256 constant AIRDROP_AMOUNT = 1e6; // 10 tokens per recipient
    uint256 public constant USDT_MINT = 1000e6;
    address public user = makeAddr("user");

    function setUp() external {
        // 1. Get the contract instance
        multisender = new Multisender();
        ERC20Mock mock = new ERC20Mock();
        // for overwriting the bytecode at a specific address.
        vm.etch(AddressesConfig.USDT_ADDRESS, address(mock).code);
        // 2. IMPORTANT: Get the EXACT USDT address the contract is using
        usdt = ERC20Mock(address(multisender.USDT()));

        // 3. Your token is fine as a new instance since it's passed as an argument
        token = new ERC20Mock();

        // Mint and Approve as before
        usdt.mint(user, USDT_MINT);
        token.mint(user, USDT_MINT);

        vm.startPrank(user); // Using startPrank is cleaner for multiple calls
        usdt.approve(address(multisender), type(uint256).max);
        token.approve(address(multisender), type(uint256).max);
        vm.stopPrank();
    }

    function setRecipientsAndAmounts(
        uint256 numRecipients
    ) internal returns (address[] memory, uint256[] memory) {
        address[] memory recipients = new address[](numRecipients);
        uint256[] memory amounts = new uint256[](numRecipients);
        for (uint256 i = 0; i < numRecipients; i++) {
            recipients[i] = makeAddr(vm.toString(i));
            amounts[i] = AIRDROP_AMOUNT;
        }
        return (recipients, amounts);
    }

    function testDeployCreatesMultisender() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
        assert(address(multisender) != address(0));
        // Replace with meaningful assertions
        assertEq(token.balanceOf(recipients[0]), AIRDROP_AMOUNT);
        assertEq(token.balanceOf(recipients[1]), AIRDROP_AMOUNT);
        assertEq(token.balanceOf(recipients[2]), AIRDROP_AMOUNT);
        // Fee was taken
    }

    function testExecuteDistributesTokens() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
        for (uint256 i = 0; i < recipients.length; i++) {
            assertEq(token.balanceOf(recipients[i]), amounts[i]);
        }
    }

    function testRecipientsLengthGreaterThan250() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(253);
        vm.prank(user);
        vm.expectRevert();
        multisender.execute(address(token), recipients, amounts);
    }

    function testRecipientsLengthEqual250() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(250);
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
    }

    function testZeroAddressToken() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        vm.prank(user);
        vm.expectRevert();
        multisender.execute(address(0), recipients, amounts);
    }

    function testZeroAmountInArray() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        amounts[1] = 0;
        vm.prank(user);
        vm.expectRevert();
        multisender.execute(address(token), recipients, amounts);
    }

    function testZeroAddressInRecipients() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        recipients[1] = address(0);
        vm.prank(user);
        vm.expectRevert();
        multisender.execute(address(token), recipients, amounts);
    }

    function testEmptyRecipientsArray() public {
        (address[] memory recipients, ) = setRecipientsAndAmounts(3);
        uint256[] memory amounts = new uint256[](0);
        vm.prank(user);
        vm.expectRevert();
        multisender.execute(address(token), recipients, amounts);
    }

    function testMismatchedArrayLengths() public {
        (, uint256[] memory amounts) = setRecipientsAndAmounts(3);
        address[] memory newRecipients = new address[](1);
        vm.prank(user);
        vm.expectRevert();
        multisender.execute(address(token), newRecipients, amounts);
    }

    // Fee & Token Flow

    function testFeeRecipientReceivesFee() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        assertEq(usdt.balanceOf(multisender.FEE_RECIPIENT()), 0);
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
        assertEq(
            usdt.balanceOf(multisender.FEE_RECIPIENT()),
            FEE_PER_ADDRESS * recipients.length
        );
    }

    function testExactFeeAmountForMultipleRecipients() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(34);

        uint256 fee = FEE_PER_ADDRESS * recipients.length;

        uint256 oldUserBalance = usdt.balanceOf(user);
        uint256 oldRecipientBalance = usdt.balanceOf(
            multisender.FEE_RECIPIENT()
        );

        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);

        assertEq(usdt.balanceOf(user), oldUserBalance - fee);
        assertEq(
            usdt.balanceOf(multisender.FEE_RECIPIENT()),
            oldRecipientBalance + fee
        );
    }

    function testSenderBalanceDecreasesCorrectly() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        uint256 oldTokenBalance = token.balanceOf(user);
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
        uint256 total = 0;
        for (uint i = 0; i < amounts.length; i++) total += amounts[i];
        assertEq(
            usdt.balanceOf(user),
            USDT_MINT - FEE_PER_ADDRESS * recipients.length
        );
        assertEq(token.balanceOf(user), oldTokenBalance - total);
    }

    function testDifferentAmounts() public {
        (address[] memory recipients, ) = setRecipientsAndAmounts(3);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 25;
        amounts[2] = 4;
        uint256 total = 0;
        for (uint i = 0; i < amounts.length; i++) total += amounts[i];
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
        for (uint i = 0; i < amounts.length; i++) {
            assertEq(token.balanceOf(recipients[i]), amounts[i]);
        }
    }

    function testUserHasInsufficientUSDTForFees() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        address otherUser = makeAddr("otherUser");
        vm.startPrank(otherUser);
        usdt.approve(address(multisender), 100e6);
        vm.expectRevert();
        multisender.execute(address(token), recipients, amounts);
        vm.stopPrank();
    }

    function testUserHasInsufficientAirdropTokens() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        address otherUser = makeAddr("otherUser");
        usdt.mint(otherUser, 100e6);
        vm.startPrank(otherUser);
        usdt.approve(address(multisender), 100e6);
        token.approve(address(multisender), 100e6);
        vm.expectRevert();
        multisender.execute(address(token), recipients, amounts);
        vm.stopPrank();
    }

    function testUserDidntApproveUSDT() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        address otherUser = makeAddr("otherUser");
        usdt.mint(otherUser, 100e6);
        vm.prank(otherUser);
        vm.expectRevert();
        multisender.execute(address(token), recipients, amounts);
    }

    function testUserDidntApproveAirdropTokens() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        address otherUser = makeAddr("otherUser");
        usdt.mint(otherUser, 200e6);
        token.mint(otherUser, 100e6);
        vm.startPrank(otherUser);
        usdt.approve(address(multisender), 100e6);
        vm.expectRevert();
        multisender.execute(address(token), recipients, amounts);
        vm.stopPrank();
    }

    function testRecicpientIsTheSameAsTheRecipientAddress() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(1);
        recipients[0] = user;
        uint256 oldBalance = token.balanceOf(user);
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
        assertEq(oldBalance, token.balanceOf(user));
    }

    function testDuplicateRecipients() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        recipients[0] = user;
        recipients[2] = user;
        uint256 oldBalance = token.balanceOf(user);
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
        // user appears twice, so received 2 * AIRDROP_AMOUNT but also sent 2 * AIRDROP_AMOUNT
        // net token balance should be: oldBalance - AIRDROP_AMOUNT (sent 2, received 2, paid nothing extra in tokens)
        assertEq(token.balanceOf(user), oldBalance - AIRDROP_AMOUNT); // sent 3 total, got 2 back
        assertEq(token.balanceOf(recipients[1]), AIRDROP_AMOUNT); // middle recipient got theirs
    }

    function testRecicpientIsTheContract() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(1);
        recipients[0] = address(multisender);
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
        // Tokens are now stuck in the contract forever
        assertEq(token.balanceOf(address(multisender)), AIRDROP_AMOUNT);
    }

    function testFeeTokenAsAirdropToken() public {
        // SYNC THE ADDRESS: Ensure 'usdt' is the one the contract actually uses
        usdt = ERC20Mock(address(multisender.USDT()));

        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);

        // Now approve the CORRECT usdt contract
        vm.startPrank(user);
        usdt.approve(address(multisender), type(uint256).max);

        // We also need to approve the 'token' if it's different,
        // but here the token IS usdt!

        multisender.execute(address(usdt), recipients, amounts);
        vm.stopPrank();

        uint256 totalFee = FEE_PER_ADDRESS * 3;
        uint256 totalAirdrop = AIRDROP_AMOUNT * 3;
        assertEq(usdt.balanceOf(user), USDT_MINT - totalFee - totalAirdrop);
    }

    // Event

    function testAirdropEvent() public {
        (
            address[] memory recipients,
            uint256[] memory amounts
        ) = setRecipientsAndAmounts(3);
        uint256 totalAmount = 0; // 3 recipients * 10e6
        for (uint i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }

        // amenaverjiny expectEmit-i data-i hamara,i.e. stuguma vor datanery chisht en
        // datanery ayn parametrern en, voronq chunen indexed keyword eventum
        // amenaqichy 4 param, arajin 3y indexed paramneri hamar
        // qani vor chka indexed param, arajin 3y karox enq dnel false, vor chstugi
        vm.expectEmit(false, false, false, true);

        // 2. Emit the "expected" event manually (this is the reference point)
        emit Multisender.AirdropExecuted(address(token), user, recipients.length, totalAmount);

        // 3. Trigger the actual function that emits the event
        vm.prank(user);
        multisender.execute(address(token), recipients, amounts);
    }
}
