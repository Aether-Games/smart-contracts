// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;


import "./IAEG721Reciever.sol";
/**
 * @dev this contract makes the interactions with the functionality
 * in the marketplace much easier to read/understand. Each function
 * contains a standard way of implementation, to not fall into any diffcuilties
 * while reading the code.
 * 
 * All functions in `NFTokenTxns` throw if the current address of 
 * $AEG marketplace is not approved.
 */ 
contract AEG721Txns is IAEG721Reciever {
	/**
	 * @dev {ERC-721} approval check, to make sure we can transfer any
	 * NFT from the seller to the buyer. Throws if `address(this)` is not `approved`
	 */
	function _approval721Token(address nft_contract, uint256 token_id) internal view returns(bool) {
		return IAEG721(nft_contract).getApproved(token_id) == address(this);
	}
	/**
	 * @dev {ERC-721} sender function, to be able to send after checking `approved` in the contract
	 * this is only called once a trade is verified.
	 */
	function send721Token(address sender, address reciever, address nft_contract, uint256 token_id) internal {
		require(_approval721Token(nft_contract, token_id), "AEG721 : token id is not approved");
		IAEG721(nft_contract).safeTransferFrom(sender, reciever, token_id,"");
	}
	/**
	 * @dev {ERC-721} check that any contract can handle ERC721 Tokens or not
	 */
	function onERC721Received(address,address,uint256,bytes calldata) external pure override returns(bytes4){
		return IAEG721Reciever.onERC721Received.selector;
	}
}