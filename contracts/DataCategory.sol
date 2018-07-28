pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract DataCategory is Ownable{
    struct Category {
        string name;
        string icon;
        uint256 reputation;
        bool isValid;
    }

    mapping (bytes32 => Category) categories;

    event CategoryRegistered(bytes32 id, string name);
    event CategoryUnregistered(bytes32 id, string name);

    function register(bytes32 id, string name, string icon, uint256 reputation) public onlyOwner {
        require(!categories[id].isValid, "Category already exists.");
        categories[id] = Category(name, icon, reputation, true);
        emit CategoryRegistered(id, name);
    }

    function unregister(bytes32 id) public onlyOwner {
        Category memory category = categories[id];
        delete categories[id];
        emit CategoryUnregistered(id, category.name);
    }

    function validate(bytes32 id) public view returns (bool) {
        return categories[id].isValid;
    }
}