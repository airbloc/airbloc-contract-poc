pragma solidity ^0.4.23;

import "./AccessControlList.sol";
import "./AppRegistry.sol";

// TODO: build data exchange
contract DataBloc {

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

    AppRegistry appReg;

    mapping (bytes32=>Data) offerings;

    constructor(    
        AppRegistry _appReg
    ) public {
        appReg = _appReg;
    }

    function registerOffering(
        bytes32   dataId,
        bytes32   appId,
        bytes32[] categoryIds,
        uint256   price, 
        uint256   beneficiaryCount
    ) public {
        require(price > 0, "Price can not be zero.");
        require(!hasDataOf(dataId), "Data already registered.");
        require(appReg.hasAppOf(appId), "Invalid app id.");
        require(appReg.isAppOwner(appId, msg.sender), "Sender is not owner of app");
        require(appReg.apps[appId].validateCategories(categoryIds), "Invalid data category.");

        offerings[dataId] = Data(appId, categoryIds, price, beneficiaryCount, 0);
        emit DataRegistered(dataId);
    }

    function unregisterOffering(bytes32 dataId, bytes32 appId) public {
        require(hasDataOf(dataId), "Data is not available.");
        require(appReg.isAppOwner(appId, msg.sender), "Sender is not owner of app");

        delete offerings[dataId];
        emit DataUnregistered(dataId);
    }

    // TODO: change to purchase right of data
    // TODO: get token and send to reward container
    function purchase(bytes32 dataId) public {
        require(hasDataOf(dataId), "Data is not available.");
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