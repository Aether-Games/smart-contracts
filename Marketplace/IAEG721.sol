// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;

/**
 * @dev any listed NFT on needs to implement the
 * {ERC-721} standard functions, most secondary functions
 * proposed by OpenZepplin are also included. 
 * only on ERC721 Tokens.
 */
interface IAEG721 {
	function ownerOf(uint256) external view returns(address);
	function balanceOf(address) external view returns(uint256);
    function safeTransferFrom(address,address,uint256,bytes memory) external;
    function transferFrom(address,address,uint256) external;
    function getApproved(uint256) external view returns (address);
    function isApprovedForAll(address,address) external view returns (bool);
 	function tokenURI(uint256) external view returns (string memory);
}
