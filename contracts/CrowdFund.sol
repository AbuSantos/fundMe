// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";

contract CrowdFund {
    struct Campaign {
        address creator;
        uint goal;
        //using uint32 because its smalleer and it last for over a 100years, so suitable for the auction
        uint32 startedAt;
        uint32 endedAt;
        bool claimed;
        uint pledged;
    }
    IERC20 public immutable i_token;
    uint public count;
    mapping(uint => Campaign) campaigns;
    mapping(uint => mapping(address => uint)) public amountPledged;

    error CrowdFund_NotStarted();
    error CrowdFund_AlreadyEnded();
    error CrowdFund_MaxDurationExceeded();

    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startedAt,
        uint32 endedAt
    );

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(uint goal, uint32 _startedAt, uint32 _endedAt) external {
        if (_startedAt >= block.timestamp) revert CrowdFund_NotStarted();
        if (_endedAt >= _startedAt) revert CrowdFund_AlreadyEnded();
        if (_endedAt <= block.timestamp + 40 days)
            revert CrowdFund_MaxDurationExceeded();

        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            startedAt: _startedAt,
            endedAt: _endedAt,
            pledged: 0,
            claimed: false
        });

        emit Launch(count, msg.sender, goal, _startedAt, _endedAt);
    }

    function cancel(uint _id) returns () {}

    function pledge(uint _id) returns () {}

    function unpledge(uint _id) returns () {}

    function claim(uint _id) returns () {}

    function refund(uint _id) returns () {}

    // function withdraw()  returns () {

    // }
}
