// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract EmergencyMedicalFund {
    struct Member {
        bool exists;
        uint256 balance;
    }

    struct EmergencyRequest {
        address requester;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        bool active;
        mapping(address => bool) voted;
    }

    address public admin;
    uint256 public monthlyContribution;
    uint256 public requestCount;
    mapping(address => Member) public members;
    mapping(uint256 => EmergencyRequest) public requests;

    constructor(uint256 _monthlyContribution) {
        admin = msg.sender;
        monthlyContribution = _monthlyContribution;
    }

    function joinFund() external payable {
        require(!members[msg.sender].exists, "Already a member");
        require(msg.value == monthlyContribution, "Incorrect contribution");
        members[msg.sender] = Member(true, msg.value);
    }

    function contributeMonthly() external payable {
        require(members[msg.sender].exists, "Not a member");
        require(msg.value == monthlyContribution, "Incorrect contribution");
        members[msg.sender].balance += msg.value;
    }

    function requestEmergency(uint256 _amount) external {
        require(members[msg.sender].exists, "Not a member");
        require(_amount <= address(this).balance, "Insufficient fund balance");
        requestCount++;
        EmergencyRequest storage req = requests[requestCount];
        req.requester = msg.sender;
        req.amount = _amount;
        req.active = true;
    }

    function vote(uint256 _requestId, bool support) external {
        require(members[msg.sender].exists, "Not a member");
        EmergencyRequest storage req = requests[_requestId];
        require(req.active, "Request inactive");
        require(!req.voted[msg.sender], "Already voted");

        req.voted[msg.sender] = true;
        if (support) {
            req.votesFor++;
        } else {
            req.votesAgainst++;
        }
    }

    function finalizeRequest(uint256 _requestId) external {
        EmergencyRequest storage req = requests[_requestId];
        require(req.active, "Request inactive");
        if (req.votesFor > req.votesAgainst) {
            payable(req.requester).transfer(req.amount);
        }
        req.active = false;
    }

    function fundBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
