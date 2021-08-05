pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Example class - a mock class using delivering from ERC20
contract MSNTT is ERC20 {

  string greeting;

  constructor(uint256 initialBalance) ERC20("meson testnet token", "MSNTT") public {
      _mint(msg.sender, initialBalance);
  }

   function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }


}