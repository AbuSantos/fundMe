// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

contract CrowdFund {
    // STATE VARIABLE
    struct Campaign {
        address creator;
        uint goal;
        //using uint32 because its smaller and it last for over a 100years, so suitable for the auction
        uint32 startedAt;
        uint32 endedAt;
        bool claimed;
        uint pledged;
    }
    IERC20 public immutable i_token;
    uint public count;
    mapping(uint => Campaign) campaigns;
    mapping(uint => mapping(address => uint)) public amountPledged;

    // ERRORS
    error CrowdFund_NotStarted();
    error CrowdFund_AlreadyEnded();
    error CrowdFund_MaxDurationExceeded();
    error CrowdFund_NotOwner();
    // error CrowdFund_NotStarted();
    // error CrowdFund_AlreadyEnded();
    //EVENTS
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startedAt,
        uint32 endedAt
    );
    event CampaignCanceled(uint id);
    event Pledged(uint indexed id, address indexed caller, uint amount);
    event UnPledged(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    constructor(address i_i_token) {
        i_i_token = IERC20(i_i_token);
    }

    function launch(uint goal, uint32 _startedAt, uint32 _endedAt) external {
        if (_startedAt >= block.timestamp) revert CrowdFund_NotStarted();
        if (_endedAt >= _startedAt) revert CrowdFund_AlreadyEnded();
        if (_endedAt <= block.timestamp + 40 days)
            revert CrowdFund_MaxDurationExceeded();
        //increasing the campaign count
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

    function cancel(uint _id) external {
        // using memory cause we're just reading from the struct
        Campaign memory campaign = campaigns[_id];
        if (msg.sender != campaign.creator) {
            revert CrowdFund_NotOwner();
        }
        //checking if the current time is less than the campaign starting time
        if (block.timestamp < campaign.startedAt) {
            revert CrowdFund_CampaignNotStarted();
        }
        delete campaigns[_id];

        emit CampaignCanceled(_id);
    }

    function pledge(uint _id, uint _amount) external {
        //using storage because we'll modify the struct
        Campaign storage campaign = campaigns[_id];
        if (block.timeStamp >= campaign.startedAt) {
            revert CrowdFund_NotStarted();
        }
        if (block.timeStamp <= campaign.endedAt) {
            revert CrowdFund_AlreadyEnded();
        }

        campaign.pledged += _amount;
        amountPledged[_id][msg.sender] += _amount;
        i_token.transferFrom(msg.sender, address(this), _amount);

        emit Pledged(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        //using storage because we'll modify the struct
        Campaign storage campaign = campaigns[_id];
        if (block.timeStamp <= campaign.endedAt) {
            revert CrowdFund_AlreadyEnded();
        }

        campaign.pledged -= _amount;
        amountPledged[_id][msg.sender] -= _amount;
        i_token.transferFrom(msg.sender, _amount);

        emit UnPledged(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        //using storage because we'll modify the struct
        Campaign storage campaign = campaigns[_id];

        require(msg.msg.sender == campaign.creator, "Not Creator");
        //making sure the campaign has ended before funds can be claimed;
        require(block.timeStamp > campaign.endedAt, "Campaign has not Ended");
        require(
            campaign.pledged >= campaign.goal,
            "Campaign goal has yet to be met"
        );
        require(!campaign.claimed, "Claimed");

        campaign.claimed = true;
        i_token.transferFrom(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint _id) external {
        //using storage because we'll modify the struct
        Campaign storage campaign = campaigns[_id];
        require(block.timeStamp > campaign.endedAt, "Not Ended");
        require(
            campaign.pledged < campaign.goal,
            "The campaign Pledged is less than the goal"
        );

        uint bal = amountPledged[_id][msg.sender];
        i_token.transferFrom(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }

    // function withdraw()  returns () {

    // }
}
