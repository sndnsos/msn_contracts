// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO {
    struct Proposal {
        address creator; // Address of the shareholder who created the proposal
        string name; // name of this proposal
        uint256 deadline; // A unix timestamp, denoting the end of the voting period
        uint8 options; //option number >=1
    }

    string public name;
    address private DAOOwner;
    address private MSNAddr;

    uint256 withdraw_keep_secs; // how much time in seconds to keep before withdraw
    mapping(address => string) private keepers; // how can create and manage proposals

    mapping(string => Proposal) private proposals; // name => proposal
    mapping(address => mapping(string => uint8)) private votes; // voter => ( proposalname=> selected option) ,selected option start from 1
    mapping(string => mapping(uint8 => uint256)) private proposal_votes; // proposalname=>(option=>total_votes)
    mapping(address => uint256) private deposit; // from => amount
    mapping(address => uint256) private deposit_lasttime; //from =>last vote time

    constructor(
        string memory _name,
        address _MSNcontractAddr,
        uint256 _withdraw_keep_secs
    ) {
        name = _name;
        DAOOwner = msg.sender;
        MSNAddr = _MSNcontractAddr;
        keepers[msg.sender] = "DAOOwner";
        withdraw_keep_secs = _withdraw_keep_secs;
    }

    modifier onlyDAOOwner() {
        require(msg.sender == DAOOwner, "only DAOOwner");
        _;
    }

    event add_keeper_EVENT(address keeper_addr, string keeper_name);

    function add_keeper(address keeper_addr, string calldata keeper_name)
        public
        onlyDAOOwner
    {
        require(bytes(keeper_name).length != 0, "No Name");
        keepers[keeper_addr] = keeper_name;
        emit add_keeper_EVENT(keeper_addr, keeper_name);
    }

    event remove_keeper_EVENT(address keeper_addr, string keeper_name);

    function remove_keeper(address keeper_addr) public onlyDAOOwner {
        require(bytes(keepers[keeper_addr]).length != 0, "NO SUCH Keeper");
        require(keeper_addr != DAOOwner, "CAN NOT DELETE DAOOwner");
        string memory keeper_name = keepers[keeper_addr];
        delete keepers[keeper_addr];
        emit remove_keeper_EVENT(keeper_addr, keeper_name);
    }

    modifier onlyKeeper() {
        require(bytes(keepers[msg.sender]).length != 0, "NO SUCH Keeper");
        _;
    }

    function set_withdraw_keep_secs(uint256 secs) public onlyDAOOwner {
        withdraw_keep_secs = secs;
    }

    function get_withdraw_keep_secs() public view returns (uint256) {
        return withdraw_keep_secs;
    }

    event add_proposal_EVENT(
        address _creator,
        string _name,
        uint256 _deadline,
        uint8 _options
    );

    function add_proposal(
        string calldata _name,
        uint256 _deadline,
        uint8 _options
    ) external onlyKeeper {
        require(
            bytes(proposals[_name].name).length == 0,
            "Proposal already exist"
        );
        require(bytes(_name).length == 0, "Proposal name null");
        require(_options > 0, "at least one option");
        require(_deadline > block.timestamp, "deadline smaller then blocktime");
        proposals[_name] = Proposal(msg.sender, _name, _deadline, _options);
        emit add_proposal_EVENT(msg.sender, _name, _deadline, _options);
    }

    event remove_proposal_EVENT(address _from, string _name);

    function remove_proposal(string memory _name) external onlyKeeper {
        require(bytes(proposals[_name].name).length != 0, "Proposal not exist");
        require(
            (proposals[_name].creator == msg.sender) ||
                (msg.sender == DAOOwner),
            "Not Allowed"
        );
        delete proposals[_name];
        emit remove_proposal_EVENT(msg.sender, _name);
    }

    function get_proposal(string memory _name)
        external
        view
        returns (
            address p_createor,
            string memory p_name,
            uint256 p_deadline,
            uint8 p_options
        )
    {
        require(bytes(proposals[_name].name).length != 0, "Proposal not exist");
        p_createor = proposals[_name].creator;
        p_name = proposals[_name].name;
        p_deadline = proposals[_name].deadline;
        p_options = proposals[_name].options;
    }

    event deposite_all_EVENT(address _from, uint256 amount);

    function deposite_all() external {
        uint256 allowance = IERC20(MSNAddr).allowance(
            msg.sender,
            address(this)
        );
        require(allowance > 0, "nothing deposite");
        bool result = IERC20(MSNAddr).transferFrom(
            msg.sender,
            address(this),
            allowance
        );
        if (result) {
            deposit[msg.sender] = deposit[msg.sender] + allowance;
            deposit_lasttime[msg.sender] = block.timestamp;
            emit deposite_all_EVENT(msg.sender, allowance);
        }
    }

    event withdraw_all_EVENT(address _from, uint256 amount);

    function withdraw_all() external {
        require(
            deposit_lasttime[msg.sender] + withdraw_keep_secs >
                block.timestamp,
            "Not Enough Time"
        );
        uint256 d_amount = deposit[msg.sender];
        require(d_amount >= 0, "no deposite");
        deposit[msg.sender] = 0;
        IERC20(MSNAddr).transfer(msg.sender, d_amount);
        emit withdraw_all_EVENT(msg.sender, d_amount);
    }

    event vote_EVENT(
        string _proposal_name,
        address _voter,
        uint8 _option,
        uint256 _all_votes
    );

    function vote(string calldata _proposal_name, uint8 _option) external {
        require(
            bytes(proposals[_proposal_name].name).length != 0,
            "Proposal not exist"
        );
        require(votes[msg.sender][_proposal_name] == 0, "Vote already");
        require(
            (_option > 0) && (_option <= proposals[_proposal_name].options),
            "Option overflow"
        );

        votes[msg.sender][_proposal_name] = _option;
        proposal_votes[_proposal_name][_option] =
            proposal_votes[_proposal_name][_option] +
            deposit[msg.sender];
        emit vote_EVENT(
            _proposal_name,
            msg.sender,
            _option,
            proposal_votes[_proposal_name][_option]
        );
    }

    function get_proposal_votes(string calldata _proposal_name, uint8 _option)
        external
        view
        returns (uint256)
    {
        require(
            bytes(proposals[_proposal_name].name).length != 0,
            "Proposal not exist"
        );
        return proposal_votes[_proposal_name][_option];
    }
}
