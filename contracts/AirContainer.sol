pragma solidity ^0.4.23;

import "./AppRegistry.sol";

contract AirContainer {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public token;
    AppRegistry public appReg;

    struct Row {
        bytes32 appId;
        uint256 amount;
        bool isValid;
    }

    mapping (bytes32 => Row) book;

    constructor(ERC20 _token, AppRegistry _appReg) public {
        token = _token;
        appReg = _appReg;
    }

    function deposit(bytes32 appId, bytes32 dataId, uint256 amount) public {
        if(hasRow(dataId)) {
            book[dataId].amount.add(amount);
        } else {
            book[dataId] = Row(appId, amount, true);
        }
    }

    function withdraw(bytes32 dataId) public {
        require(
            appReg.isAppOwner(book[dataId].appId, msg.sender), 
            "Only app owner can withdraw token."
        );

        uint256 amount = book[dataId].amount;
        book[dataId].amount = 0;
        token.safeTransfer(msg.sender, amount);
    }

    function stake(bytes32 dataId) public view returns (uint256) {
        return book[dataId].amount;
    }

    function hasRow(bytes32 dataId) public view returns (bool) {
        return book[dataId].isValid;
    }
}