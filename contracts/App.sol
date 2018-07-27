pragma solidity ^0.4.23;

import "./Stake.sol";
import "./AirContainer.sol";
import "./DataCategoryRegistry.sol";

// Basic App info for minimum proof. Rest of the data is available on off-chain.
contract App is Stake {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    event CategoryAdded(bytes32 id);
    event CategoryRemoved(bytes32 id);

    event DataRegistered(bytes32 dataId);
    event DataUnregistered(bytes32 dataId);

    event UserAdded(address indexed addr);
    event UserRemoved(address indexed addr);
    event UserModified(address indexed pastAddr, address indexed newAddr);

    struct Category {
        bytes32 categoryId;
        uint256 shareUser;
        uint256 shareApp;
        bool isValid;
    }

    struct Data {
        uint256 price; // suggested minimum price (by producer) if its zero, price goes on market
        uint256 beneficiaryCount;
        uint256 purchaseCount;
        bytes32[] categories;
    }

    AirContainer container;
    DataCategoryRegistry category;

    uint256 public userCount;
    mapping (bytes32 => Data) public offerings;
    mapping (bytes32 => Category) public categories;
    mapping (bytes32 => address) private users; // TODO: Privacy consideration


    constructor(
        ERC20 _token, 
        AirContainer _container,
        DataCategoryRegistry _category
    ) 
        Stake(_token)
        public
    {
        userCount = 0;
        container = _container;
        category = _category;
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
        require(!categories[id].isValid, "Category already exists.");
        require(category.validate(categoryId), "Invalid data category.");
        categories[id] = Category(categoryId, shareUser, shareApp, true);
        emit CategoryAdded(id);
    }

    function removeCategory(bytes32 id) public onlyOwner {
        delete categories[id];
        emit CategoryRemoved(id);
    }

    /**
     * Manage data on sale
     */
    function registerOffering(
        bytes32 dataId, 
        uint256 price, 
        uint256 beneficiaryCount,
        bytes32[] _categories
    ) public onlyOwner {
        require(price > 0, "Price can not be zero");
        require(!hasDataOf(dataId), "Data already registered");
        require(category.validateMany(_categories), "Invalid data category.");
        offerings[dataId] = Data(price, beneficiaryCount, 0, _categories);
        emit DataRegistered(dataId);
    }

    function unregisterOffering(bytes32 dataId) public onlyOwner {
        require(!hasDataOf(dataId), "Data is not available");
        delete offerings[dataId];
        emit DataUnregistered(dataId);
    }

    function hasDataOf(bytes32 dataId)
        internal
        view
        returns (bool)
    {
        return offerings[dataId].price != 0;     
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
            stakeOf(msg.sender) >= getRequiredStake(1),
            "Insufficient stake amount."
        );
        users[id] = addr;
        userCount = userCount.add(1);
        emit UserAdded(addr);
    }

    function addUsers(bytes32[] ids, address[] addrs) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            addUser(ids[i], address(container)); // TODO: Need default receiver?
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
            stakeOf(msg.sender) - amount >= getRequiredStake(0),
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
