//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ERC20Mock is Ownable, ERC20 {

    // address public minter;

    // constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_)  {
    //     minter = owner();
    // }

    // function setMinter(address _minter) external onlyOwner returns(bool) {
    //     minter = _minter;
    //     return true;
    // }


    function mint(address _to, uint256 _value) external returns(bool) {
        // require(msg.sender==minter);
        _mint(_to, _value);
        return true;
    }
}
