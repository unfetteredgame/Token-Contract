// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Manageable.sol";

contract Managers is Manageable {
    // function changeManager1(address _newAddress) external onlyManagers(msg.sender) {
    //     require(msg.sender != manager1, "Can not set own address");

    //     string memory _title = "changeManager1";
    //     bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
    //     vote(_title, _valueInBytes);

    //     if (isApproved(_title, _valueInBytes)) {
    //         manager1 = _newAddress;
    //         _deleteTopic(_title);
    //     }
    // }

    // function changeManager2(address _newAddress) external onlyManagers(msg.sender) {
    //     require(msg.sender != manager2, "Can not set own address");

    //     string memory _title = "changeManager2";
    //     bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
    //     vote(_title, _valueInBytes);

    //     if (isApproved(_title, _valueInBytes)) {
    //         manager2 = _newAddress;
    //         _deleteTopic(_title);
    //     }
    // }

    // function changeManager3(address _newAddress) external onlyManagers(msg.sender) {
    //     require(msg.sender != manager3, "Can not set own address");

    //     string memory _title = "changeManager3";
    //     bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
    //     vote(_title, _valueInBytes);

    //     if (isApproved(_title, _valueInBytes)) {
    //         manager3 = _newAddress;
    //         _deleteTopic(_title);
    //     }
    // }

    // function changeManager4(address _newAddress) external onlyManagers(msg.sender) {
    //     require(msg.sender != manager4, "Can not set own address");

    //     string memory _title = "changeManager4";
    //     bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
    //     vote(_title, _valueInBytes);

    //     if (isApproved(_title, _valueInBytes)) {
    //         manager4 = _newAddress;
    //         _deleteTopic(_title);
    //     }
    // }

    // function changeManager5(address _newAddress) external onlyManagers(msg.sender) {
    //     require(msg.sender != manager5, "Can not set own address");

    //     string memory _title = "changeManager5";
    //     bytes32 _valueInBytes = keccak256(abi.encodePacked(_newAddress));
    //     vote(_title, _valueInBytes);

    //     if (isApproved(_title, _valueInBytes)) {
    //         manager5 = _newAddress;
    //         _deleteTopic(_title);
    //     }
    // }
}
