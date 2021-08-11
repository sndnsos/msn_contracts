// SPDX-License-Identifier: GPL v3
// README: https://github.com/daqnext/msn_contracts/blob/main/assets/koa_static/contracts/v2/MSN.md

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {
    uint256 payable_amount;

    address contract_owner;
    bool exchange_open;
    mapping(address => uint8) special_list;

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
        special_list[msg.sender] = 1;
        exchange_open = false;
        _mint(msg.sender, inisupply * (10**uint256(decimals())));
    }

    event add_special_EVENT(address special_addr, uint8 _id);

    function add_special(address special_addr, uint8 _id)
        external
        onlyContractOwner
    {
        require(_id >= 0, "starting from 1");
        special_list[special_addr] = _id;
        emit add_special_EVENT(special_addr, _id);
    }

    event remove_special_EVENT(address special_addr, uint8 _special_id);

    function remove_special(address special_addr) external onlyContractOwner {
        require(special_list[special_addr] > 0, "No such special");
        require(
            special_addr != contract_owner,
            "Can not delete contract Owner"
        );
        uint8 special_id = special_list[special_addr];
        delete special_list[special_addr];
        emit remove_special_EVENT(special_addr, special_id);
    }

    function get_special(address special_addr) external view returns (uint8) {
        require(special_list[special_addr] > 0, "No such special");
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
                (special_list[owner] > 0) ||
                (special_list[spender] > 0),
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
                (special_list[sender] > 0) ||
                (special_list[recipient] > 0),
            "exchange closed && not special"
        );

        super._transfer(sender, recipient, amount);

        if ((special_list[sender] > 0) || (special_list[recipient] > 0)) {
            emit special_transfer_EVENT(
                sender,
                recipient,
                amount,
                block.timestamp
            );
        }
    }

    receive() external payable {
        payable_amount += msg.value;
    }

    fallback() external payable {
        payable_amount += msg.value;
    }

    function withdraw_eth() external onlyContractOwner {
        payable(msg.sender).transfer(address(this).balance);
        payable_amount = 0;
    }
}
