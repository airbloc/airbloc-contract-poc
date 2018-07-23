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
    using SafeMath for uint256;

    // Basic App info for minimum proof. Rest of the data is available on off-chain.
    // TODO: Privacy considerations
    struct App {
        bytes32 id;
        uint256 userCount;
        mapping(address => bool) users;
    }

    mapping(address => App) public apps;
    mapping(bytes32 => address) public addressOf;

    event AppRegister(bytes32 appId, address appAddress);

    /**
     * @param token The address of token for stake.
     * @param penaltyBeneficiary The destination wallet that stake losses are transferred to.
     */
    constructor(ERC20 token, address penaltyBeneficiary, address punisher)
        RiskTokenLockRegistry(token, penaltyBeneficiary, punisher)
        public
    {
    }

    /**
     * @param appId ID of off-chain app metadata.
     */
    function register(bytes32 appId) public {
        apps[msg.sender] = App(appId, 0);
        addressOf[appId] = msg.sender;
        emit AppRegister(appId, msg.sender);
    }

    /**
     * Add user to app.
     */
    function addUser(address[] addedUsers) public {
        require(hasAppOf(msg.sender), "App not found.");
        require(
            stakeOf(msg.sender) >= getRequiredStake(apps[msg.sender].userCount + addedUsers.length),
            "Insufficient stake amount."
        );
        App app = apps[msg.sender];

        for (uint256 i = 0; i < addedUsers.length; i++) {
            app.users[addedUsers[i]] = true;
        }
        app.userCount = app.userCount.add(addedUsers.length);
    }

    function removeUser(address[] removedUsers) public {
        require(hasAppOf(msg.sender), "App not found.");
        App app = apps[msg.sender];

        for (uint256 i = 0; i < removedUsers.length; i++) {
            app.users[removedUsers[i]] = false;
        }
        app.userCount = app.userCount.sub(removedUsers.length);
    }

    function withdraw(uint256 amount) public {
        require(hasAppOf(msg.sender), "App not found.");
        require(stakeOf(msg.sender) - amount >= getRequiredStake(apps[msg.sender].userCount));
        super.withdraw(amount);
    }

    function hasAppOf(address addr) internal view returns (bool) {
        return apps[addr].id != bytes32(0x0);
    }

    function hasUser(bytes32 appId, address user) public view returns (bool) {
        return apps[addressOf[appId]].users[user];
    }

    function getRequiredStake(uint256 userCount) public pure returns (uint256) {
        return userCount;
    }
}
