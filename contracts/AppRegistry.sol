pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/examples/SimpleToken.sol";
import "./RiskTokenLockRegistry.sol";
import "./App.sol";

/**
 * AppRegistry stores an app information, and user IDs of the app.
 * A certain amount of token stake — proportional to the number of users — is required for apps.
 *
 * If an app did some bad things that prohibited by Airbloc Protocol's Law,
 * then there's a risk for app can LOSE some amount of it's stake.
 */
contract AppRegistry is RiskTokenLockRegistry {
    using AddressUtils for address;
    using SafeMath for uint256;

    address public receiver;

    mapping(bytes32 => App) public apps;

    event AppRegistered(bytes32 appId, address owner);
    event AppUnregistered(bytes32 appId, address owner);

    /**
     * @param token The address of token for stake.
     * @param penaltyBeneficiary The destination wallet that stake losses are transferred to.
     */
    constructor(
        ERC20 token,
        address penaltyBeneficiary,
        address punisher,
        address defaultReceiver
    )
        RiskTokenLockRegistry(token, penaltyBeneficiary, punisher)
        public
    {
        require(defaultReceiver != address(0));
        receiver = defaultReceiver;
    }

    /**
     * @param appId ID of off-chain app metadata.
     */
    function register(bytes32 appId) public {
        apps[appId] = new App(token);
        emit AppRegistered(appId, msg.sender);
    }

    function unregister(bytes32 appId) public {
        require(hasAppOf(appId), "App not found.");
        App app = apps[appId];
        require(app.owner == msg.sender, "Only app owner can do this.");

        delete apps[appId];
        delete addressOf[appId];
        withdraw(stakeOf(msg.sender));
        emit AppUnregistered(appId, msg.sender);
    }

    /**
     * Add user to app.
     */
    function addUsers(bytes32 appId, bytes32[] ids) public {
        require(hasAppOf(appId), "App not found.");
        App app = apps[appId];
        require(app.owner == msg.sender, "Only app owner can do this.");
        require(
            stakeOf(msg.sender) >= getRequiredStake(app.userCount + ids.length),
            "Insufficient stake amount."
        );

        for (uint256 i = 0; i < ids.length; i++) {
            app.addUser(ids[i], receiver);
        }
    }

    function removeUsers(bytes32 appId, bytes32[] ids)
        public
        onlyAppOwner(appId)
    {
        require(hasAppOf(appId), "App not found.");
        App app = apps[appId];
        require(app.owner == msg.sender, "Only app owner can do this.");

        for (uint256 i = 0; i < ids.length; i++) {
            app.removeUser(ids[i]);
        }
    }

    // @Override TokenLockRegistry
    function withdraw(bytes32 appId, uint256 amount) public {
        require(hasAppOf(appId), "App not found.");
        App app = apps[appId];
        require(app.owner == msg.sender, "Only app owner can do this.");
        require(
            stakeOf(msg.sender) - amount >= getRequiredStake(app.userCount),
            "Insufficient stake amount."
        );
        super.withdraw(amount);
    }

    function hasAppOf(bytes32 appId)
        internal
        view
        returns (bool)
    {
        return apps[appId] != bytes32(0);
    }

    function getRequiredStake(uint256 userCount)
        public
        pure
        returns (uint256)
    {
        return userCount;
    }
}
