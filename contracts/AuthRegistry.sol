pragma solidity ^0.4.23;

/**
 * AppRegistry stores data authorization settings per person.
 */
contract AuthRegistry {
    // only store boolean value whether the user authorized Auth rule.
    // @address user's address
    // @bytes32 categoryOfApp Id
    // @bool    authorization
    mapping(address => mapping(bytes32 => bool)) private registry;

    // TODO: validate categoryOfAppId and rebuild the category structure (category - app - category of app)
    function register(bytes32 categoryOfAppId, bool authorizations) public {
        registry[msg.sender][categoryOfAppId] = authorizations;
    }

    function getAuthorizations(bytes32 categoryOfAppId) public view returns (bool) {
        return registry[msg.sender][categoryOfAppId];
    }
}