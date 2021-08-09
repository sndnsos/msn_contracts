// SPDX-License-Identifier: GPL v3

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";  


contract MINING {

    string  public name;
    address private MSNAddr;
    address private MiningOwner;

    mapping(bytes32=>uint256) merkleRoots;// merkleRoot=>balance
    mapping(bytes32 => mapping(uint256 => bool)) claimed; //bytes32 merkleRoot => (index => true|false)
     

    constructor(string memory _name,address _MSNcontractAddr){
       MiningOwner = msg.sender;    
       name=_name; 
       MSNAddr = _MSNcontractAddr;
    }


    modifier onlyMiningOwner() {
        require(msg.sender == MiningOwner, 'only MiningOwner');
        _;
    }

    function get_msn_addr() public view returns(address) {
        return MSNAddr;
    }

    function get_contract_owner() public view returns(address) {
        return MiningOwner;
    }

    function get_contract_balance() public view returns(uint256){
        return IERC20(MSNAddr).balanceOf(address(this));
    }


    event withdraw_contract_EVENT (address _from ,address _to ,uint256 amount,uint time);
    function withdraw_contract() public onlyMiningOwner {
        uint256 left = IERC20(MSNAddr).balanceOf(address(this));
        require(left > 0, "No Balance");
        IERC20(MSNAddr).transfer(msg.sender, left);
        emit withdraw_contract_EVENT(address(this),msg.sender,left,block.timestamp);
    }


    event add_merkle_root_EVENT(bytes32 merkleRoot,uint blocktime);
    function  add_merkle_root(bytes32 merkleRoot,uint256 amount) public onlyMiningOwner{
         merkleRoots[merkleRoot]=amount+1;//+1 for never to 0 again
         emit add_merkle_root_EVENT(merkleRoot,merkleRoots[merkleRoot]);
    }


    function get_merkle_root(bytes32 merkleRoot) public  view returns(uint256) {
        return merkleRoots[merkleRoot];
    }


    event claim_erc20_EVENT(bytes32 merkleRoot,address to, uint256 amount, uint time );
    function claim_erc20(bytes32 merkleRoot,uint256 index, uint256 amount, bytes32[] calldata merkleProof) external{
        require(merkleRoots[merkleRoot]!=0, "merkleRoot not exist");
        require(claimed[merkleRoot][index]==false, "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'Not Verified');

        require(merkleRoots[merkleRoot]>amount, "Not Enough Balance");
        merkleRoots[merkleRoot]=merkleRoots[merkleRoot]-amount;
        
        claimed[merkleRoot][index]=true;
        bool result=IERC20(MSNAddr).transfer(msg.sender,amount);
        if(result){      
            emit claim_erc20_EVENT(merkleRoot,msg.sender,amount,block.timestamp);
        }else{
            claimed[merkleRoot][index]=false;
        }
    }
 
}