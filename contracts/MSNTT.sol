pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSNTT is ERC20 {
    
    bool exchange_open; //test-token lock , can only be exchanged after main-net
    address contractOwner;

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, 'This function could only be used by contractOwner');
        _;
    }

    modifier onlyExchangeOpen() {
        require(exchange_open == true, 'This function could only be used after exchange open ');
        _;
    }

    constructor() ERC20("MesonNetworkTestToken", "MSNTT") {
       contractOwner = msg.sender;
       exchange_open=false;
        _mint(msg.sender, 500_000_000 * (10 ** uint256(decimals())));     
    }

    //make sure totalsupply keep updated and sync to meson.network
    function mint(uint256 amount) public onlyContractOwner {
        _mint(msg.sender,amount);
    }

    function burn(uint256 amount) public onlyContractOwner {
        _burn(msg.sender,amount);
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if(msg.sender!=contractOwner&&!exchange_open){
            return false; 
        } 
        return super.transfer(recipient, amount);
    }


    function set_exchange_open(bool _exchange_open) external onlyContractOwner  {
          exchange_open=_exchange_open;
    }

    function get_exchange_open() public view returns (bool){
          return exchange_open;
    }

    function  approve(address spender, uint256 amount) public override onlyExchangeOpen returns (bool) {
         return super.approve( spender, amount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override onlyExchangeOpen returns (bool){
        return super.decreaseAllowance( spender, subtractedValue);
    }

    function increaseAllowance(address spender, uint256 addedValue) public override onlyExchangeOpen returns (bool){
        return super.increaseAllowance( spender, addedValue);
    }

    function transferFrom( address sender, address recipient, uint256 amount ) public override onlyExchangeOpen returns (bool){
        return super.transferFrom( sender, recipient, amount);
    }
}


