// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PiOne is ERC20 {
    constructor() ERC20("PiOne", "PiOPiO") {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals()); 
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
