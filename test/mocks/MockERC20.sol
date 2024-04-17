//SPDX-License-Identifer: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20{
    constructor(uint256 initialSupply)ERC20("DamnValuableToken", "DVT"){
        _mint(msg.sender, initialSupply);
    }
}