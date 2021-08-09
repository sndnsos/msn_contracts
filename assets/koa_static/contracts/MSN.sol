// SPDX-License-Identifier: GPL v3

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {

    address contractOwner;
    bool exchange_open;  

    // maintainer address => (deposit address=> amout)
    mapping(address=>mapping(address=>uint256)) deposit ;
    // maintainer address => (deposit address=> lastupdate_time)  
    mapping(address=>mapping(address=>uint)) deposit_lastime;

    //maintainer is the person who maintains the contract 
    //like 'mining pool','DAO','poolx',etc
    mapping(address=>string) maintainers;
    

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, 'only contractOwner');
        _;
    }

    modifier onlyExchangeOpen() {
        require(exchange_open == true, 'exchange closed');
        _;
    }

     modifier onlyMaintainer() {
        require(bytes(maintainers[msg.sender]).length!=0, 'only Maintainer');
        _;
    }


    modifier MaintainerORExchangeOpen() {
        require(exchange_open == true || (bytes(maintainers[msg.sender]).length!=0 ), 'exchange closed && not contractOwner');
        _;
    }

    constructor(string memory  name ,string memory symbol) ERC20(name, symbol) {
       contractOwner = msg.sender;
       maintainers[msg.sender]="ROOT";
       exchange_open=false;//exchange lock initially
        _mint(msg.sender, 500_000_000 * (10 ** uint256(decimals())));     
    }


    /////////begining of maintainer part///////////////////
    event add_maintainer_EVENT(address maintainer_addr,string maintainer_name);
    function add_maintainer(address maintainer_addr,string calldata name) public onlyContractOwner {
        require(bytes(name).length!=0, "No Name");
        maintainers[maintainer_addr]=name;
        emit add_maintainer_EVENT(maintainer_addr,name);
    }

    function get_maintainer(address maintainer_addr) external view returns ( string memory){
        require(bytes(maintainers[maintainer_addr]).length!=0, "NO SUCH MAINTAINER");      
        return maintainers[maintainer_addr];
    }
    

    event remove_maintainer_EVENT(address maintainer_addr,string maintainer_name);
    function remove_maintainer(address maintainer_addr) public onlyContractOwner {
        require(bytes(maintainers[maintainer_addr]).length!=0, "NO SUCH MAINTAINER");
        require(maintainer_addr!= contractOwner, "CAN NOT DELETE ROOT");   
        string memory maintainer_name=maintainers[maintainer_addr];
        delete maintainers[maintainer_addr];
        emit remove_maintainer_EVENT(maintainer_addr,maintainer_name);
    }


    event withdraw_maintainer_EVENT(address maintainer_addr,uint256 amount);
    function withdraw_maintainer(address maintainer_addr,uint256 amount) public onlyContractOwner returns (bool){
        require(bytes(maintainers[maintainer_addr]).length!=0, "NO SUCH MAINTAINER");
        require(super.balanceOf(maintainer_addr) >= amount, "Not Enough Balance");
        bool result=super.transferFrom( maintainer_addr, contractOwner, amount);
        if(result){
            emit withdraw_maintainer_EVENT(maintainer_addr,amount);
        }
        return result;
    }



    event deposit_to_maintainer_EVENT(string indexed cookie,address indexed maintainer_addr,address indexed _from, uint256 amount,uint time);
    function deposit_to_maintainer(address maintainer_addr,uint256 amount,string calldata cookie) external returns (bool) {
        require(bytes(maintainers[maintainer_addr]).length!=0, "NO SUCH MAINTAINER");
        bool result= super.transfer(maintainer_addr, amount);
        if(result){
                deposit[maintainer_addr][msg.sender]=deposit[maintainer_addr][msg.sender]+amount;
                deposit_lastime[maintainer_addr][msg.sender]=block.timestamp;
                emit deposit_to_maintainer_EVENT(cookie,maintainer_addr,msg.sender,amount,block.timestamp);
        }
        return result;
    }

    //can only called by maintainer
    event withdraw_from_maintainer_EVENT(address indexed maintainer_addr,address indexed recipient,uint256 amount,uint time);
    function  withdraw_from_maintainer(address recipient,uint256 amount) external onlyMaintainer returns (bool){
        require(deposit[msg.sender][recipient] >= amount, 'withdraw overflow');
        bool result= super.transfer(recipient, amount);
        if(result){
                deposit[msg.sender][recipient]=deposit[msg.sender][recipient]-amount;
                emit withdraw_from_maintainer_EVENT(msg.sender,recipient,amount,block.timestamp);
        }
        return result;
    }


    function deposit_amount(address maintainer_addr, address from) external view returns(uint256){
        return deposit[maintainer_addr][from];
    }

    function deposit_lasttime(address maintainer_addr, address from) external view returns(uint){
        return deposit_lastime[maintainer_addr][from];
    }


    ////////end of maintainer part///////////////////

    //mint is open for mining Inflation increment
    function mint(uint256 amount) public onlyContractOwner {
        _mint(msg.sender,amount);
    }

    //anyone can burn hisown token
    function burn(uint256 amount) public  {
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

    
}


