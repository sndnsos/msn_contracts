// SPDX-License-Identifier: GPL v3

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface IMSN is IERC20{
//      function withdraw_from_maintainer(address recipient,uint256 amount) external returns (bool);
//      function deposit_amount(address maintainer_addr, address from) external returns(uint256);
//      function deposit_lasttime(address maintainer_addr, address from) external view returns(uint);
// }

contract DAO {

    struct Proposal {
        address creator;    // Address of the shareholder who created the proposal
        string name;        // name of this proposal
        uint deadline;      // A unix timestamp, denoting the end of the voting period

        // string description;  // offline A plain text description of the proposal    
        // bytes32[] options;   // offline only single option is allowed for each user
    }


    string  public  name;
    address private DAOOwner;
    address private MSNAddr;

    uint withdraw_keep_secs ; // how much time in seconds to keep before withdraw
    mapping (address=>string) private keepers;// how can create and manage proposals  

    mapping (string=>Proposal) private proposals;// name => proposal
    mapping (address=>mapping(string=>uint8)) private votes; // voter => ( proposalname=> selected option) ,selected option start from 1
    mapping (string=>mapping(uint8=>uint256)) private proposal_votes; // proposalname=>(option=>total_votes)


    constructor(string memory _name,address _MSNcontractAddr,uint256 _withdraw_keep_secs){
        name=_name;
        DAOOwner = msg.sender;       
        MSNAddr=_MSNcontractAddr;
        keepers[msg.sender]='DAOOwner';    
        withdraw_keep_secs=_withdraw_keep_secs;       
    }


    modifier onlyDAOOwner() {
        require(msg.sender == DAOOwner, 'only DAOOwner');
        _;
    }

    modifier onlyKeeper() {
        require(bytes(keepers[msg.sender]).length!=0, "NO SUCH Keeper");
        _;
    }


    function set_withdraw_keep_secs(uint secs) public onlyDAOOwner {
        withdraw_keep_secs=secs;
    }

    function get_withdraw_keep_secs() public view returns(uint){
        return withdraw_keep_secs;
    }


    event add_keeper_EVENT(address keeper_addr,string keeper_name);
    function add_keeper(address keeper_addr,string calldata keeper_name) public onlyDAOOwner {
        require(bytes(keeper_name).length!=0, "No Name");
        keepers[keeper_addr]=keeper_name;
        emit add_keeper_EVENT(keeper_addr,keeper_name);
    }


    event remove_keeper_EVENT(address keeper_addr,string keeper_name);
    function remove_keeper(address keeper_addr) public onlyDAOOwner {
        require(bytes(keepers[keeper_addr]).length!=0, "NO SUCH Keeper");
        require(keeper_addr!= DAOOwner, "CAN NOT DELETE DAOOwner");   
        string memory keeper_name=keepers[keeper_addr];
        delete keepers[keeper_addr];
        emit remove_keeper_EVENT(keeper_addr,keeper_name);
    }

 
 
    event add_proposal_EVENT( address _creator,string _name,uint _deadline);
    function add_proposal(string calldata _name,uint _deadline) external onlyKeeper() {
        require(bytes(proposals[_name].name).length==0, "Proposal already exist");
        require(bytes(_name).length==0, "Proposal name null");
        require(_deadline>block.timestamp, "deadline smaller then blocktime");
        proposals[_name]=Proposal(msg.sender,_name,_deadline);
        emit add_proposal_EVENT(msg.sender,_name,_deadline);
    }


    event remove_proposal_EVENT(address _from,string _name);
    function remove_proposal(string memory _name) external onlyKeeper() {
        require(bytes(proposals[_name].name).length!=0, "Proposal not exist");
        require( (proposals[_name].creator==msg.sender)||(msg.sender==DAOOwner), "Not Allowed");
        delete proposals[_name];
        emit remove_proposal_EVENT(msg.sender,_name);
    }


    function get_proposal(string memory _name) external view returns (address p_createor,string memory p_name,uint p_deadline){
         require(bytes(proposals[_name].name).length!=0, "Proposal not exist");
         p_createor=proposals[_name].creator;
         p_name=proposals[_name].name;
         p_deadline=proposals[_name].deadline;
    }


    event withdraw_deposit_EVENT (address _from, uint256 amount);
    function withdraw_deposit(uint256 amount) external {
        uint lastdt = IMSN(MSNAddr).deposit_lasttime(address(this), msg.sender);
        require(lastdt+withdraw_keep_secs >block.timestamp,"Not Enough Time" );
        IMSN(MSNAddr).withdraw_from_maintainer(msg.sender,amount);
        emit withdraw_deposit_EVENT(msg.sender,amount);
    }

    event vote_EVENT (string _proposal_name,address _voter,uint8 _option);
    function vote(string calldata _proposal_name,uint8 _option) external {
         require(bytes(proposals[_proposal_name].name).length!=0, "Proposal not exist");
         require(votes[msg.sender][_proposal_name]==0, "Vote already");
         require((_option>0)&&(_option<=proposals[_proposal_name].options.length), "Option overflow");

        votes[msg.sender][_proposal_name]=_option;
        proposal_votes[_proposal_name][_option]=proposal_votes[_proposal_name][_option]+
        IMSN(MSNAddr).deposit_amount(address(this), msg.sender);
        emit vote_EVENT(_proposal_name,msg.sender,_option);
    }


    function get_proposal_votes(string calldata _proposal_name,uint8 _option) external view  returns(uint256){
         require(bytes(proposals[_proposal_name].name).length!=0, "Proposal not exist");
         return  proposal_votes[_proposal_name][_option];
    }




}