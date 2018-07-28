pragma solidity ^0.4.23;

import "./Stake.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/AddressUtils.sol";

contract RiskStake is Stake {
    using AddressUtils for address;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public receiver;
    mapping (address=>bool) public punisher;

    // TODO: make punisher registry
    constructor(
        ERC20 token, 
        address _receiver,
        address _punisher
    )
        Stake(token)
        public
    {
        require(_receiver != address(0x0));
        receiver = _receiver;
        punisher[_punisher] = true;
    }

    /**
     * Add punisher contract who can slash someone's stake.
     */
    function addPunisher(address _punisher) external {
        require(punisher[msg.sender], "Only punisher can add punisher.");
        require(_punisher.isContract(), "Only contract can be punisher.");  // ONLY CONTRACT can be punisher.
        punisher[_punisher] = true;
    }

    /**
     * Punish someone by slashing his/her stake.
     */
    function punish(uint256 loseAmount) public {
        require(punisher[msg.sender], "Only punisher can punish.");
        require(stake() >= loseAmount);
        token.safeTransfer(receiver, loseAmount);
    }
}