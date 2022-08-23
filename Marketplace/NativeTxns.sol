// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;


/**
 * This contract mainly intrefaces the marketplace to the native currency handling 
 * instead of dealing with wrapped tokens, this is much easier to integrate.
 */
contract NativeTxns {
	/**
	 * @dev recieves native payment of amount `asked`. where "payed" is `msg.value`
	 */
	function _recieveNative(uint256 asked) internal view returns(bool){
		if(msg.value >= asked){
			return true;
		}
		return false;
	}
	/**
	 * @dev forward any native payments to the `reciever` from the current contract
	 */
	function _sendNative(address reciever, uint256 amount) internal returns(bool) {
		require(address(this).balance >= amount);
		require(payable(reciever).send(amount));
		return true;
	}
}