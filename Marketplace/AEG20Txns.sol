// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;

import "./IAEG20.sol";


/**
 * @dev this contract interfaces with all the {ERC-20} tokens' contract.
 * and mainly is responsible for easy transfer of any ERC20 tokens 
 * that is supported by the marketplace.
 */
contract AEG20Txns {
	/**
	 * @dev gets the allowance of the sender to the current address
	 */ 
	function allowance20Tokens(address sender, address token_addr) internal view returns(uint256){
	
		return IAEG20(token_addr).allowance(sender, address(this));
	}

	function distribute20Tokens(address sender, address reciever, address token_addr, uint256 amount1, uint256 amount2) internal returns(bool) {
		require(allowance20Tokens(sender, token_addr) >= (amount1+amount2) , "AEG20Txns : Allowance not enough");
		require(IAEG20(token_addr).transferFrom(sender, address(this), amount2) , "AEG20Txns : Unable to process payment");
		require(IAEG20(token_addr).transferFrom(sender, reciever, amount1), "AEG20Txns : Unable to process payment");
		return true;
	}

	/**
	 * @dev convert any token with address `token_addr` from a human readable amount to it's original
	 * deciamls amount.
	 */
	function _decimalConversion(address token_addr, uint256 amount) internal view returns(uint256){
		return (10**IAEG20(token_addr).decimals())*amount;
	}
	/**
	 * @dev recieves {ERC-20} tokens, by implementing the `allowance` to check if the contract is able
	 * to use the function `transferFrom` from the current contract
	 */
	function recieve20Tokens(address sender, address token_addr, uint256 amount) internal {
		require(IAEG20(token_addr).allowance(sender, address(this)) >= amount, "AEG20Txns : Allowance less than amount");
		require(IAEG20(token_addr).transferFrom(sender, address(this), amount) , "AEG20Txns : Unable to process payment");
	}
	/**
	 * @dev send {ERC-20} tokens to any reciever from the current contract, this is used when the tokens
	 * are transfered to either the DAO or the seller in any other token that native. i.e; `ether`
	 */
	function send20Tokens(address reciever, address token_addr, uint256 amount) internal {
		require(IAEG20(token_addr).balanceOf(address(this)) >= amount, "AEG20Txns : Not enough balance");
		require(IAEG20(token_addr).transfer(reciever , amount) , "AEG20Txns : Unable to process payment");
	}
}
