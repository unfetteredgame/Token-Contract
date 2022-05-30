// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/// @title Managers Contract for The Unfettered Game
/// @author Yusuf Özcan GÜLER (y.ozcan.guler@gmail.com)
/// @notice Defines 5 manager and allows opening new topics to vote by these managers.
/// If 3 of managers approved a topic approves the topic.
contract Managers is Ownable {
    struct Topic {
        string title;
        uint256 approveCount;
    }
    struct TopicApproval {
        bool approved;
        bytes32 value;
    }

    Topic[] public activeTopics;

    address public manager1;
    address public manager2;
    address public manager3;
    address public manager4;
    address public manager5;

    mapping(string => mapping(address => TopicApproval)) public managerApprovalsForTopic;
    mapping(address => bool) public trustedSources;

    constructor(
        address _manager1,
        address _manager2,
        address _manager3,
        address _manager4,
        address _manager5
    ) {
        require(
            _manager1 != address(0) &&
                _manager2 != address(0) &&
                _manager3 != address(0) &&
                _manager4 != address(0) &&
                _manager5 != address(0),
            "Invalid address in managers"
        );
        manager1 = _manager1;
        manager2 = _manager2;
        manager3 = _manager3;
        manager4 = _manager4;
        manager5 = _manager5;
    }

    // function setManagers(
    //     address _manager1,
    //     address _manager2,
    //     address _manager3,
    //     address _manager4,
    //     address _manager5
    // ) external onlyOwner {
    //     require(manager1 == address(0), "Not allowed after initialization");
    //     require(
    //         _manager1 != address(0) &&
    //             _manager2 != address(0) &&
    //             _manager3 != address(0) &&
    //             _manager4 != address(0) &&
    //             _manager5 != address(0),
    //         "Invalid address in managers"
    //     );
    //     manager1 = _manager1;
    //     manager2 = _manager2;
    //     manager3 = _manager3;
    //     manager4 = _manager4;
    //     manager5 = _manager5;
    // }

    modifier onlyManagers(address _caller) {
        require(isManager(_caller), "Not authorized");
        _;
    }

    modifier onlyTrustedSources(address _sender) {
        require(trustedSources[_sender], "MANAGERS: Untrusted source");
        _;
    }

    /// @notice Adds a smart contract address to trusted sources list.
    /// @dev Because onlyManagers modifier is calling with tx.origin parameter in some functions
    /// adds extra security to block function calls from untrusted senders.
    /// @param _address is the address of the smart contract which can interact with this contract.

    function addAddressToTrustedSources(address _address) external onlyOwner {
        trustedSources[_address] = true;
    }

    function isManager(address _address) public view returns (bool) {
        return (_address == manager1 ||
            _address == manager2 ||
            _address == manager3 ||
            _address == manager4 ||
            _address == manager5);
    }

    /// @notice Approves a topic for manager who started the transaction to caller contract of this function
    /// @dev Must be called from contracts instead of Externally Owned Accounts. And Because this function will be
    /// called by other contracts, `msg.sender` is not the manager address.
    /// For that, uses `onlyManagers` modifier with `tx.origin` global variable as parameter. To block untrusted calls
    /// from chained transactions which starts from manager wallet filters calls with `onlyTrustedSources` modifier.
    /// @param _title to vote by admins
    /// @param _valueInBytes keccak256 hash of the paramaeters of the function which calling this function.

    function approveTopic(string memory _title, bytes32 _valueInBytes)
        public
        onlyManagers(tx.origin)
        onlyTrustedSources(msg.sender)
    {
        require(managerApprovalsForTopic[_title][tx.origin].approved == false, "Already voted");
        managerApprovalsForTopic[_title][tx.origin].approved = true;

        managerApprovalsForTopic[_title][tx.origin].value = _valueInBytes;

        (bool _titleExists, uint256 _topicIndex) = indexOfTopic(_title);

        if (!_titleExists) {
            activeTopics.push(Topic({title: _title, approveCount: 1}));
        } else {
            activeTopics[_topicIndex].approveCount++;
        }
    }

    //internal version of approveTopic function to be called by only manager addres changer functions
    function _approveTopic(string memory _title, bytes32 _valueInBytes) internal {
        require(managerApprovalsForTopic[_title][tx.origin].approved == false, "Already voted");
        managerApprovalsForTopic[_title][tx.origin].approved = true;

        managerApprovalsForTopic[_title][tx.origin].value = _valueInBytes;

        (bool _titleExists, uint256 _topicIndex) = indexOfTopic(_title);

        if (!_titleExists) {
            activeTopics.push(Topic({title: _title, approveCount: 1}));
        } else {
            activeTopics[_topicIndex].approveCount++;
        }
    }

    function cancelTopicApproval(string memory _title) public onlyManagers(msg.sender) {
        (bool _titleExists, uint256 _topicIndex) = indexOfTopic(_title);
        require(_titleExists, "Topic not found");
        require(managerApprovalsForTopic[_title][msg.sender].approved == true, "Not voted");

        activeTopics[_topicIndex].approveCount--;
        if (activeTopics[_topicIndex].approveCount == 0) {
            _deleteTopic(_title);
        } else {
            managerApprovalsForTopic[_title][msg.sender].approved = false;
        }
    }

    function getActiveTopics() public view returns (Topic[] memory) {
        return activeTopics;
    }

    function deleteTopic(string memory _title) external onlyManagers(tx.origin) onlyTrustedSources(msg.sender) {
        _deleteTopic(_title);
    }

    function _deleteTopic(string memory _title) internal {
        (bool _titleExists, uint256 _topicIndex) = indexOfTopic(_title);
        require(_titleExists, "Topic not found");
        managerApprovalsForTopic[_title][manager1].approved = false;
        managerApprovalsForTopic[_title][manager2].approved = false;
        managerApprovalsForTopic[_title][manager3].approved = false;
        managerApprovalsForTopic[_title][manager4].approved = false;
        managerApprovalsForTopic[_title][manager5].approved = false;
        if (_topicIndex < activeTopics.length - 1) {
            activeTopics[_topicIndex] = activeTopics[activeTopics.length - 1];
        }
        activeTopics.pop();
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function indexOfTopic(string memory _element) internal view returns (bool found, uint256 i) {
        for (i = 0; i < activeTopics.length; i++) {
            if (compareStrings(activeTopics[i].title, _element)) {
                return (true, i);
            }
        }
        return (false, 0); //Cannot return -1 with type uint256. For that check the first parameter is true or false always.
    }

    /// @notice Checks if a title approved by 3 of managers with same parameters.
    /// @param _title to check if voted or no
    /// @param _value keccak256 hash of the parameters of caller function
    /// @return  _isApproved true if the title approved by 3 of managers with same parameters

    function isApproved(string memory _title, bytes32 _value) public view returns (bool _isApproved) {
        uint256 _totalValidVotes = 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager1].approved &&
            managerApprovalsForTopic[_title][manager1].value == _value
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager2].approved &&
            managerApprovalsForTopic[_title][manager2].value == _value
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager3].approved &&
            managerApprovalsForTopic[_title][manager3].value == _value
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager4].approved &&
            managerApprovalsForTopic[_title][manager4].value == _value
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager5].approved &&
            managerApprovalsForTopic[_title][manager5].value == _value
            ? 1
            : 0;
        _isApproved = _totalValidVotes >= 3;
    }

    function changeManager1Address(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager1, "Cannot vote to set own address");

        string memory _title = "Change Manager 1 Address";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        _approveTopic(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager1 = _newAddress;
            _deleteTopic(_title);
        }
    }

    function changeManager2Address(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager2, "Cannot vote to set own address");

        string memory _title = "Change Manager 2 Address";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        _approveTopic(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager2 = _newAddress;
            _deleteTopic(_title);
        }
    }

    function changeManager3Address(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager3, "Cannot vote to set own address");

        string memory _title = "Change Manager 3 Address";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        _approveTopic(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager3 = _newAddress;
            _deleteTopic(_title);
        }
    }

    function changeManager4Address(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager4, "Cannot vote to set own address");

        string memory _title = "Change Manager 4 Address";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        _approveTopic(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager4 = _newAddress;
            _deleteTopic(_title);
        }
    }

    function changeManager5Address(address _newAddress) external onlyManagers(msg.sender) {
        require(msg.sender != manager5, "Cannot vote to set own address");

        string memory _title = "Change Manager 5 Address";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
        _approveTopic(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            manager5 = _newAddress;
            _deleteTopic(_title);
        }
    }
}
