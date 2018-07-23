pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/examples/SimpleToken.sol";
import "./RiskTokenLockRegistry.sol";

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

    // Basic App info for minimum proof. Rest of the data is available on off-chain.
    // TODO: Privacy considerations
    struct App {
        address owner;
        uint256 userCount;
        mapping(bytes32 => address) users;
    }

    address public receiver;

    mapping(bytes32 => App) public apps;

    event AppRegistered(bytes32 appId, address appAddress);
    event AppUnregistered(bytes32 appId, address appAddress);

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
        apps[appId] = App(msg.sender, 0);
        emit AppRegistered(appId, msg.sender);
    }

    function unregister(bytes32 appId) public {
        require(hasAppOf(msg.sender), "App not found.");
        require(addressOf[appId] == msg.sender, "Only owner of app can unregister");
        delete apps[msg.sender];
        delete addressOf[appId];
        withdraw(stakeOf(msg.sender));
        emit AppUnregistered(appId, msg.sender);
    }

    /**
     * Add user to app.
     */
    function addUser(bytes32[] ids) public {
        require(hasAppOf(msg.sender), "App not found.");
        require(
            stakeOf(msg.sender) >= getRequiredStake(apps[msg.sender].userCount + ids.length),
            "Insufficient stake amount."
        );
        App app = apps[msg.sender];

        for (uint256 i = 0; i < ids.length; i++) {
            app.users[ids[i]] = receiver;
        }
        app.userCount = app.userCount.add(ids.length);
    }

    function removeUser(bytes32[] ids) public {
        require(hasAppOf(msg.sender), "App not found.");
        App app = apps[msg.sender];

        for (uint256 i = 0; i < ids.length; i++) {
            delete app.users[ids[i]];
        }
        app.userCount = app.userCount.sub(ids.length);
    }

    // @Override TokenLockRegistry
    function withdraw(bytes32 appId, uint256 amount) public {
        require(hasAppOf(appId), "App not found.");
        require(
            stakeOf(msg.sender) - amount >= getRequiredStake(apps[msg.sender].userCount),
            ""
        );
        super.withdraw(amount);
    }

    function isOwner(bytes32 appId) internal view returns (bool) {
        return apps[appId].owner == msg.sender;
    }

    function hasAppOf(bytes32 appId) internal view returns (bool) {
        return apps[appId] != bytes32(0);
    }

    function hasUser(bytes32 appId, bytes32 userId) public view returns (bool) {
        return apps[appId].users[userId];
    }

    function getRequiredStake(uint256 userCount) public pure returns (uint256) {
        return userCount;
    }
}
