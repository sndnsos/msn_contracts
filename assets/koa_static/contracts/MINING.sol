// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMSN is IERC20{
    function transfer_to_maintainer(address maintainer_addr,uint256 amount) external returns (bool);
}

contract MINING {

    string  public name;
    address private MSNAddr;
    address private MiningOwner;
 

    constructor(string memory _name){
       MiningOwner = msg.sender;    
       name=_name; 
    }


    modifier onlyMiningOwner() {
        require(msg.sender == MiningOwner, 'only MiningOwner');
        _;
    }

    function set_msn_addr(address _contractAddr) public  onlyMiningOwner {
       MSNAddr = _contractAddr;
    }

    function get_msn_addr() public view returns(address) {
        return MSNAddr;
    }

    function get_mining_owner() public view returns(address) {
        return MiningOwner;
    }

    function get_mining_balance() public view returns(uint256){
        return IMSN(MSNAddr).balanceOf(MiningOwner);
    }


    //cookie is the identifier of some off chain user
    event transfer_to_webtoken_EVENT(string indexed cookie,address indexed _from , address indexed _to, uint256 amount);
    function transfer_to_webtoken(string calldata cookie,uint256 amount) external returns (bool) {
        bool dresult= IMSN(MSNAddr).transfer_to_maintainer(MiningOwner,amount);
        if(dresult){
            emit transfer_to_webtoken_EVENT(cookie,msg.sender,MiningOwner,amount);
        }
        return dresult;
    }

    
    // function claim_erc20(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external{

    // }
 
}