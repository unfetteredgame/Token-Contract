// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Manageable is Ownable {
    address manager1;
    address manager2;
    address manager3;
    address manager4;
    address manager5;

    struct Topic {
        string title;
        uint256 approveCount;
    }
    struct Vote {
        bool voted;
        bytes32 value;
    }
    Topic[] public activeTopics;
    mapping(string => mapping(address => Vote)) public managerApprovalsForTopic;

    function setManagers(
        address _manager1,
        address _manager2,
        address _manager3,
        address _manager4,
        address _manager5
    ) external onlyOwner {
        manager1 = _manager1;
        manager2 = _manager2;
        manager3 = _manager3;
        manager4 = _manager4;
        manager5 = _manager5;
    }

    modifier onlyManagers(address _caller) {
        require(
            _caller == manager1 ||
                _caller == manager2 ||
                _caller == manager3 ||
                _caller == manager4 ||
                _caller == manager5,
            "Not authorized"
        );
        _;
    }

    function vote(string memory _title, bytes32 _valueInBytes) internal onlyManagers(msg.sender) {
        require(managerApprovalsForTopic[_title][msg.sender].voted == false, "Already voted");
        managerApprovalsForTopic[_title][msg.sender].voted = true;

        managerApprovalsForTopic[_title][msg.sender].value = _valueInBytes;

        (bool _titleExists, uint256 _topicIndex) = indexOfTopic(_title);

        if (!_titleExists) {
            activeTopics.push(Topic({title: _title, approveCount: 1}));
        } else {
            activeTopics[_topicIndex].approveCount++;
        }
    }

    function cancelVote(string memory _title) external onlyManagers(msg.sender) {
        (bool _titleExists, uint256 _topicIndex) = indexOfTopic(_title);
        require(_titleExists, "Topic not found");
        require(managerApprovalsForTopic[_title][msg.sender].voted == true, "Not voted");

        activeTopics[_topicIndex].approveCount--;
        if (activeTopics[_topicIndex].approveCount == 0) {
            _deleteTopic(_title);
        } else {
            managerApprovalsForTopic[_title][msg.sender].voted = false;
        }
    }

    function _deleteTopic(string memory _title) internal {
        (bool _titleExists, uint256 _topicIndex) = indexOfTopic(_title);
        require(_titleExists, "Topic not found");
        managerApprovalsForTopic[_title][manager1].voted = false;
        managerApprovalsForTopic[_title][manager2].voted = false;
        managerApprovalsForTopic[_title][manager3].voted = false;
        managerApprovalsForTopic[_title][manager4].voted = false;
        managerApprovalsForTopic[_title][manager5].voted = false;
        if (_topicIndex < activeTopics.length - 1) {
            activeTopics[_topicIndex] = activeTopics[activeTopics.length - 1];
        }
        activeTopics.pop();
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /// @dev returns the index + 1 because must be unsigned integer instead of `-1` for not found element.
    function indexOfTopic(string memory _element) internal view returns (bool found, uint256 i) {
        for (i = 0; i < activeTopics.length; i++) {
            if (compareStrings(activeTopics[i].title, _element)) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function isApproved(string memory _title, bytes32 _value) public view returns (bool) {
        uint256 _totalValidVotes = 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager1].voted &&
            managerApprovalsForTopic[_title][manager1].value == _value
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager2].voted &&
            managerApprovalsForTopic[_title][manager2].value == _value
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager3].voted &&
            managerApprovalsForTopic[_title][manager3].value == _value
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager4].voted &&
            managerApprovalsForTopic[_title][manager4].value == _value
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager5].voted &&
            managerApprovalsForTopic[_title][manager5].value == _value
            ? 1
            : 0;
        return _totalValidVotes >= 3;
    }

	 function changeManager1(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager1, "Can not set own address");

        string memory _title = "changeManager1";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        vote(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager1 = _newAddress;
            _deleteTopic(_title);
        }
    }

    function changeManager2(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager2, "Can not set own address");

        string memory _title = "changeManager2";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        vote(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager2 = _newAddress;
            _deleteTopic(_title);
        }
    }

    function changeManager3(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager3, "Can not set own address");

        string memory _title = "changeManager3";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        vote(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager3 = _newAddress;
            _deleteTopic(_title);
        }
    }

    function changeManager4(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager4, "Can not set own address");

        string memory _title = "changeManager4";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        vote(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager4 = _newAddress;
            _deleteTopic(_title);
        }
    }

    function changeManager5(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager5, "Can not set own address");

        string memory _title = "changeManager5";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        vote(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager5 = _newAddress;
            _deleteTopic(_title);
        }
    }
}
