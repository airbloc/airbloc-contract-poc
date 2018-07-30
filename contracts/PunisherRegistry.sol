pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/AddressUtils.sol";

contract PunisherRegistry {
    using AddressUtils for address;

    mapping(address => bool) public registry;

    function isPunisher(address _addr) public view returns (bool) {
        return registry[_addr];
    }

    function register(address _new) public {
        require(isPunisher(msg.sender), "Only punisher can register new punisher.");
        require(_new.isContract(), "Only contract can be punisher.");
        registry[_new] = true;
    }
}