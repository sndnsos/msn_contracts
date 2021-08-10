// SPDX-License-Identifier: GPL v3

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {
    address contract_owner;
    bool exchange_open;
    mapping(address => string) special_list; // address=>name ,name like 'mining pool','DAO' etc

    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "only contractOwner");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 inisupply
    ) ERC20(name, symbol) {
        contract_owner = msg.sender;
        special_list[msg.sender] = "ROOT";
        exchange_open = false;
        _mint(msg.sender, inisupply * (10**uint256(decimals())));
    }

    event add_special_EVENT(address special_addr, string _name);

    function add_special(address special_addr, string calldata _name)
        external
        onlyContractOwner
    {
        require(bytes(_name).length != 0, "No Name");
        special_list[special_addr] = _name;
        emit add_special_EVENT(special_addr, _name);
    }

    event remove_special_EVENT(address special_addr, string special_name);

    function remove_special(address special_addr) external onlyContractOwner {
        require(
            bytes(special_list[special_addr]).length != 0,
            "No such special"
        );
        require(special_addr != contract_owner, "Can not delete ROOT");
        string memory special_name = special_list[special_addr];
        delete special_list[special_addr];
        emit remove_special_EVENT(special_addr, special_name);
    }

    function get_special(address special_addr)
        external
        view
        returns (string memory)
    {
        require(
            bytes(special_list[special_addr]).length != 0,
            "No such special"
        );
        return special_list[special_addr];
    }

    //mint is open for mining Inflation increment
    function mint(uint256 amount) public onlyContractOwner {
        _mint(msg.sender, amount);
    }

    //anyone can burn hisown token
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function set_exchange_open(bool _exchange_open) external onlyContractOwner {
        exchange_open = _exchange_open;
    }

    function get_exchange_open() public view returns (bool) {
        return exchange_open;
    }

    /////overwrite to inject the modifer
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(
            exchange_open == true ||
                (bytes(special_list[owner]).length != 0) ||
                (bytes(special_list[spender]).length != 0),
            "exchange closed && not special"
        );

        super._approve(owner, spender, amount);
    }

    event special_transfer_EVENT(
        address _sender,
        address _recipient,
        uint256 _amount,
        uint256 _blocktime
    );

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(
            exchange_open == true ||
                (bytes(special_list[sender]).length != 0) ||
                (bytes(special_list[recipient]).length != 0),
            "exchange closed && not special"
        );

        super._transfer(sender, recipient, amount);

        if (
            (bytes(special_list[sender]).length != 0) ||
            (bytes(special_list[recipient]).length != 0)
        ) {
            emit special_transfer_EVENT(
                sender,
                recipient,
                amount,
                block.timestamp
            );
        }
    }
}
