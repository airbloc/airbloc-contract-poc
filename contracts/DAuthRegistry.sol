pragma solidity ^0.4.23;

contract DAuthRegistry {
    // only store boolean value whether the user authorized Auth rule.
    // @address user's address
    // @bytes32 categoryOfApp Id
    // @bool    authorization
    mapping(address => mapping(bytes32 => bool)) private registry;

    function register(bytes32 categoryOfAppId, bool authorizations) public {
        registry[msg.sender][categoryOfAppId] = authorizations;
    }

    function isUserAllowed(address user, bytes32 categoryOfAppId) public view returns (bool) {
        return registry[user][categoryOfAppId];
    }

    function getAuthorization(bytes32 categoryOfAppId) public view returns (bool) {
        return isUserAllowed(msg.sender, categoryOfAppId);
    }
}