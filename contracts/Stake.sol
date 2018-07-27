pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Stake is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // ERC20 token contract being held
    ERC20 public token;

    constructor(ERC20 _token) public {
        token = _token;
    }

    /**
     * Stake and lock your token.
     * @param amount {uint256} you want to stake
     */
    function deposit(uint256 amounut) public {
        require(token.allowance(msg.sender, address(this)) >= amounut);
        require(token.balanceOf(msg.sender) >= amounut);
        token.safeTransferFrom(msg.sender, address(this), amounut);
    }

    /**
     * Withdraw the token you locked up.
     * @param amount {uint256} you want to unstake
     */
    function withdraw(uint256 amount) public {
        require(amount <= stakeOf(msg.sender));
        token.safeTransfer(msg.sender, amount);
    }

    function stakeOf(address addr) public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}