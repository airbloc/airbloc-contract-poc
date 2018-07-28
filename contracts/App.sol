pragma solidity ^0.4.23;

import "./RiskStake.sol";
import "./DataCategory.sol";

// Basic App info for minimum proof. Rest of the data is available on off-chain.
contract App is RiskStake {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    event CategoryAdded(bytes32 id);
    event CategoryRemoved(bytes32 id);

    event UserAdded(address indexed addr);
    event UserRemoved(address indexed addr);
    event UserModified(address indexed pastAddr, address indexed newAddr);

    struct CategoryOfApp {
        bytes32 categoryId;
        uint256 shareUser;
        uint256 shareApp;
        bool isValid;
    }

    DataCategory dataCtg;

    uint256 public userCount;
    mapping (bytes32 => CategoryOfApp) public ctgOfApps;
    mapping (bytes32 => address) private users; // TODO: Privacy consideration

    constructor(
        ERC20 _token, 
        address _receiver, 
        address _punisher,
        DataCategory _dataCtg
    ) 
        RiskStake(_token, _receiver, _punisher)
        public
    {
        userCount = 0;
        dataCtg = _dataCtg;
    }

    /**
     * Manage data categories (for app)
     */
    function addCategory(
        bytes32 id, 
        bytes32 categoryId, 
        uint256 shareUser, 
        uint256 shareApp
    ) public onlyOwner {
        require(!ctgOfApps[id].isValid, "Category already exists.");
        require(dataCtg.validate(categoryId), "Invalid data category.");
        ctgOfApps[id] = CategoryOfApp(categoryId, shareUser, shareApp, true);
        emit CategoryAdded(id);
    }

    function removeCategory(bytes32 id) public onlyOwner {
        delete ctgOfApps[id];
        emit CategoryRemoved(id);
    }

    function validate(bytes32 id) private view returns (bool) {
        return ctgOfApps[id].isValid;
    }

    // for validate category of apps which data owns it.
    function validateCategories(bytes32[] ids) public view returns (bool) {
        for (uint256 i = 0; i < ids.length; i++) {
            if(!validate(ids[i])) {
                return false;
            }
        }
        return true;
    }

    /**
     * Manage users in contract (Has/Add/Remove/Modify)
     */
    function hasUser(bytes32 id) public view returns(bool) {
        return users[id] != address(0);
    }

    function addUser(bytes32 id, address addr) public onlyOwner {
        require(!hasUser(id), "User already exists.");
        require(
            stake() >= getRequiredStake(1),
            "Insufficient stake amount."
        );
        users[id] = addr;
        userCount = userCount.add(1);
        emit UserAdded(addr);
    }

    function addUsers(bytes32[] ids, address[] addrs) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            addUser(ids[i], addrs[i]); // TODO: Need default receiver?
        }
    }

    function removeUser(bytes32 id) public onlyOwner {
        address addr = users[id];
        delete users[id];
        userCount = userCount.sub(1);
        emit UserRemoved(addr);
    }

    function removeUsers(bytes32[] ids) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            removeUser(ids[i]);
        }
    }

    function modifyUser(bytes32 id, address newAddr) public onlyOwner {
        require(newAddr != address(0), "New address cannot be zero.");
        address addr = users[id];
        users[id] = newAddr;
        emit UserModified(addr, newAddr);
    }

    /**
     * About staking
     */
    // @Override Stake.sol
    function withdraw(uint256 amount) public onlyOwner {
        require(
            stake() - amount >= getRequiredStake(0),
            "Insufficient stake amount."
        );
        super.withdraw(amount);
    }

    function getRequiredStake(uint256 _add)
        public
        pure
        returns (uint256)
    {
        return userCount + _add; // TODO: Add algorithm about staking amount
    }
}
