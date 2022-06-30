// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes32 _valueInBytes) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes32 _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;
}
