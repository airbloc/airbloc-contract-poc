pragma solidity ^0.4.23;

import "./Stake.sol";
import "./PunisherRegistry.sol";
import "openzeppelin-solidity/contracts/AddressUtils.sol";

contract RiskStake is Stake {
    using AddressUtils for address;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public receiver;
    PunisherRegistry punReg;

    // TODO: make punisher registry
    constructor(
        ERC20 token, 
        address _receiver,
        PunisherRegistry _punReg
    )
        Stake(token)
        public
    {
        require(_receiver != address(0x0));
        receiver = _receiver;
        punReg = _punReg;
    }

    /**
     * Punisher slash app's stake.
     */
    function slash(uint256 loseAmount) public {
        require(punReg.isPunisher(msg.sender), "Only punisher can punish.");
        require(stake() >= loseAmount);
        token.safeTransfer(receiver, loseAmount);
    }
}