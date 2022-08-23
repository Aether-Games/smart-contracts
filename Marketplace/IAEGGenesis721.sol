// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;

/**
 * @dev AEG contracts do have more functions
 * implemented such as `walletOfOwner` & `totalSupply`
 */
interface IAEGGenesis721 {
	function walletOfOwner(address) external view returns(uint256[] memory);
	function totalSupply() external view returns(uint256);
}