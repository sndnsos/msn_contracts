// SPDX-License-Identifier: GPL v3

pragma solidity ^0.7.6;

contract DAO {

    string  public name;
    address private DAOOwner;

    constructor(string memory _name){
       DAOOwner = msg.sender;    
       name=_name;
    }

}