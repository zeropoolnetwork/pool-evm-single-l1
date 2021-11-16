//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ERC20Mock is Ownable, ERC20 {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_)  {
    }

    function mint(address _to, uint256 _value) external returns(bool) {
        _mint(_to, _value);
        return true;
    }
}
