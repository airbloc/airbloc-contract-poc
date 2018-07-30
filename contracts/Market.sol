pragma solidity ^0.4.23;

import "./AirContainer.sol";

// TODO: build data exchange
contract Market {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event DataRegistered(bytes32 dataId);
    event DataUnregistered(bytes32 dataId);
    event DataPurchased(bytes32 dataId, address indexed from);

    struct Data {
        bytes32   appId;
        bytes32[] categoryIds;
        uint256   price;          // suggested minimum price (by producer)
        uint256   beneficiaries;  // count
        uint256   purchases;      // count
        bool      isValid;
    }

    ERC20 token;
    AppRegistry appReg;
    AirContainer container;

    mapping (bytes32=>Data) offerings;

    constructor(AirContainer _container) public {
        container = _container;
        token = _container.token();
        appReg = _container.appReg();
    }

    function registerOffering(
        bytes32   dataId,
        bytes32   appId,
        bytes32[] categoryIds,
        uint256   price, 
        uint256   beneficiaries
    ) public {
        require(price > 0, "Price can not be zero.");
        require(!hasDataOf(dataId), "Data already registered.");
        require(appReg.hasAppOf(appId), "Invalid app id.");
        require(appReg.isAppOwner(appId, msg.sender), "Sender is not owner of app");
        require(appReg.validateCategories(appId, categoryIds), "Invalid data category.");

        offerings[dataId] = Data(appId, categoryIds, price, beneficiaries, 0, true);
        emit DataRegistered(dataId);
    }

    function unregisterOffering(bytes32 dataId, bytes32 appId) public {
        require(hasDataOf(dataId), "Data is not available.");
        require(appReg.isAppOwner(appId, msg.sender), "Sender is not owner of app");

        delete offerings[dataId];
        emit DataUnregistered(dataId);
    }

    // TODO: change to purchase right of data (linked to ACL(Access Control List))
    function purchase(bytes32 dataId) public {
        require(hasDataOf(dataId), "Data is not available.");
        Data memory data = offerings[dataId];

        require(token.allowance(msg.sender, address(this)) >= data.price);
        require(token.balanceOf(msg.sender) >= data.price);
        token.safeTransferFrom(msg.sender, address(container), data.price);

        container.deposit(data.appId, dataId, data.price);
        offerings[dataId].purchases.add(1);
        emit DataPurchased(dataId, msg.sender);
    }

    function hasDataOf(bytes32 dataId)
        internal
        view
        returns (bool)
    {
        return offerings[dataId].isValid;
    }
}