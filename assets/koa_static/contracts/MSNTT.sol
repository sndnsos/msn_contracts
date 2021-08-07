pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSNTT is ERC20 {

    //test-token exchange lock, no one can exchange at present 
    bool exchange_open;  
    address contractOwner;

    mapping(address=>bool) maintainers;

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, 'only contractOwner');
        _;
    }

    modifier onlyExchangeOpen() {
        require(exchange_open == true, 'exchange closed');
        _;
    }

    modifier MaintainerORExchangeOpen() {
        require(exchange_open == true || maintainers[msg.sender]==true, 
        'exchange closed && not contractOwner');
        _;
    }

    constructor() ERC20("MesonNetworkTestToken", "MSNTT") {
       contractOwner = msg.sender;
       maintainers[msg.sender]=true;
       exchange_open=false;
        _mint(msg.sender, 500_000_000 * (10 ** uint256(decimals())));     
    }

    function add_maintainer(address maintainer) public onlyContractOwner {
        maintainers[maintainer]=true;
    }

    function remove_maintainer(address maintainer) public onlyContractOwner {
        if(maintainer!=contractOwner){
               delete maintainers[maintainer];
        }
    }

    function is_maintainer(address maintainer) public view returns (bool){
        return maintainers[maintainer];
    }

    //make sure totalsupply keep synchronized to meson.network
    function mint(uint256 amount) public onlyContractOwner {
        _mint(msg.sender,amount);
    }

    function burn(uint256 amount) public onlyContractOwner {
        _burn(msg.sender,amount);
    }


    function set_exchange_open(bool _exchange_open) external onlyContractOwner  {
          exchange_open=_exchange_open;
    }

    function get_exchange_open() public view returns (bool){
          return exchange_open;
    }

    function transfer(address recipient, uint256 amount) public override  MaintainerORExchangeOpen returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom( address sender, address recipient, uint256 amount ) public override MaintainerORExchangeOpen returns (bool){
        return super.transferFrom( sender, recipient, amount);
    }

    function  approve(address spender, uint256 amount) public override MaintainerORExchangeOpen returns (bool) {
         return super.approve( spender, amount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override MaintainerORExchangeOpen returns (bool){
        return super.decreaseAllowance( spender, subtractedValue);
    }

    function increaseAllowance(address spender, uint256 addedValue) public override MaintainerORExchangeOpen returns (bool){
        return super.increaseAllowance( spender, addedValue);
    }
 
    ///when user deposit here ,web test token will be added in meson.network
    event DepositEVENT(address indexed _from, uint256 amount);
 
    function Deposit(uint256 amount) public returns (bool) {
        bool result= super.transfer(contractOwner, amount);
        if(result){
             emit DepositEVENT(msg.sender, amount);
        }
        return result;
    }

    
}


