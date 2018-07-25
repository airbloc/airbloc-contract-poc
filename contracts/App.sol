pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./AirContainer.sol";

// Basic App info for minimum proof. Rest of the data is available on off-chain.
// TODO: Privacy considerations
contract App is Ownable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    ERC20 public token;
    AirContainer container;

    constructor(ERC20 _token, AirContainer _container) internal {
        userCount = 0;
        token = _token;
        container = _container;
    }

    /**
     * Manage data on sale
     */
    struct Data {
        uint256 price;
        uint256 beneficiaryCount;
        uint256 purchaseCount;
    }

    mapping (bytes32 => Data) public offerings;

    event DataRegistered(bytes32 dataId);
    event DataUnregistered(bytes32 dataId);

    function registerOffering(
        bytes32 dataId, 
        uint256 price, 
        uint256 beneficiaryCount
    ) public onlyOwner {
        require(price > 0, "Price can not be zero");
        require(!hasDataOf(dataId), "Data already registered");
        offerings[dataId] = Data(price, beneficiaryCount, 0);
        emit DataRegistered(dataId);
    }

    function unregisterOffering(bytes32 dataId) public onlyOwner {
        require(!hasDataOf(dataId), "Data is not available");
        delete offerings[dataId];
        emit DataUnregistered(dataId);
    }

    function purchaseData(bytes32 dataId) public {
        require(!hasDataOf(dataId), "Data not available");
        require(token.allowance(msg.sender, address(this)) >= offerings[dataId].price);
        require(token.balanceOf(msg.sender) >= offerings[dataId].price);

        // send to AIR contract
        token.safeTransferFrom(msg.sender, address(this), offerings[dataId].price);
        offerings[dataId].purchaseCount.add(1);
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
    uint256 public userCount;
    mapping (bytes32 => address) private users;

    event UserAdded(address indexed addr);
    event UserRemoved(address indexed addr);
    event UserModified(address indexed pastAddr, address indexed newAddr);

    function hasUser(bytes32 id) public view returns(bool) {
        return users[id] != address(0);
    }

    function addUser(bytes32 id, address addr) public onlyOwner {
        require(!hasUser(id), "User already exists.");
        users[id] = addr;
        userCount = userCount.add(1);
        emit UserAdded(addr);
    }

    function removeUser(bytes32 id) internal {
        address addr = users[id];
        delete users[id];
        userCount = userCount.sub(1);
        emit UserRemoved(addr);
    }

    function modifyUser(bytes32 id, address newAddr) public onlyOwner {
        require(newAddr != address(0), "New address cannot be empty value.");
        address addr = users[id];
        users[id] = newAddr;
        emit UserModified(addr, newAddr);
    }
}
