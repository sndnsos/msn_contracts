pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {

    address contractOwner;
    bool exchange_open;  

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

    modifier MaintainerORExchangeOpen() {
        require(exchange_open == true || (bytes(maintainers[msg.sender]).length!=0 ), 
        'exchange closed && not contractOwner');
        _;
    }

    constructor() ERC20("MesonNetworkTestToken", "MSNTT") {
       contractOwner = msg.sender;
       maintainers[msg.sender]="ROOT";
       //exchange lock initially
       exchange_open=false;
        _mint(msg.sender, 500_000_000 * (10 ** uint256(decimals())));     
    }


    /////////begining of maintainer part///////////////////
    event add_maintainer_EVENT(address maintainer_addr,string maintainer_name);
    function add_maintainer(address maintainer_addr,string calldata name) public onlyContractOwner {
        require(bytes(name).length!=0, "No Name");
        maintainers[maintainer_addr]=name;
        emit add_maintainer_EVENT(maintainer_addr,name);
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

    event to_maintainer_EVENT(address indexed _from,address indexed _to, uint256 amount);
    function transfer_to_maintainer(address maintainer_addr,uint256 amount) public returns (bool) {
        require(bytes(maintainers[maintainer_addr]).length!=0, "NO SUCH MAINTAINER");
        bool result= super.transfer(maintainer_addr, amount);
        if(result){
                emit to_maintainer_EVENT(msg.sender,maintainer_addr, amount);
        }
        return result;
    }

    function is_maintainer(address maintainer_addr) public view returns (bool){
        return (bytes(maintainers[maintainer_addr]).length!=0);
    }


    struct MaintainerInfo {
        address addr;
        uint256 balance;
        string  name;
    }

    function get_maintainer(address maintainer_addr) external view returns ( MaintainerInfo memory){
        require(bytes(maintainers[maintainer_addr]).length!=0, "NO SUCH MAINTAINER");
        MaintainerInfo memory minfo;
        minfo.addr=maintainer_addr;
        minfo.balance=super.balanceOf(maintainer_addr);
        minfo.name=maintainers[maintainer_addr];
        return minfo;
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


