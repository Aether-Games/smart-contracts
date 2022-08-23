// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;

/**
 * @dev standard imeplemntation for function selector
 * defined in EIP-721 for contracts handling {ERC-721}
 * tokens MUST imeplement `onERC721Received`
 */
interface IAEG721Reciever {

	function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external view returns(bytes4);
}