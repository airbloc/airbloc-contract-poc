pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

import "./App.sol";

/**
 * AppRegistry stores an app information, and user IDs of the app.
 * A certain amount of token stake — proportional to the number of users — is required for apps.
 *
 * If an app did some bad things that prohibited by Airbloc Protocol's Law,
 * then there's a risk for app can LOSE some amount of it's stake.
 */
contract AppRegistry {
    using AddressUtils for address;
    using SafeMath for uint256;

    ERC20 token;
    address receiver;
    PunisherRegistry punReg;

    DataCategory dataCtg;
    mapping(bytes32 => App) public apps;

    event AppRegistered(bytes32 appId, address owner);
    event AppUnregistered(bytes32 appId, address owner);

    constructor(
        ERC20 _token,
        address _receiver,
        PunisherRegistry _punReg,
        DataCategory _dataCtg
    ) public {
        token = _token;
        receiver = _receiver;
        punReg = _punReg;
        dataCtg = _dataCtg;
    }

    function register(bytes32 appId) public {
        apps[appId] = new App(token, receiver, punReg, dataCtg);
        emit AppRegistered(appId, msg.sender);
    }

    function unregister(bytes32 appId) public {
        require(hasAppOf(appId), "App not found.");
        require(isAppOwner(appId, msg.sender), "Only app owner can do this.");

        delete apps[appId];
        emit AppUnregistered(appId, msg.sender);
    }

    function validateCategories(bytes32 appId, bytes32[] ids) public view returns (bool) {
        return apps[appId].validateCategories(ids);
    }

    function isAppOwner(bytes32 appId, address addr) public view returns (bool) {
        return apps[appId].owner() == addr;
    }

    function hasAppOf(bytes32 appId) public view returns (bool) {
        return apps[appId].token() != address(0);
    }
}
