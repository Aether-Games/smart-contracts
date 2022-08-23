// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;

/**
 * @dev the interactions in the marketplace might have a utility token 
 * of which it's readily avaliable to trade with, i.e: $AEG.
 * a wallet listing on will have multiple tokens support
 */
interface IAEG20 {
	function allowance(address,address) external view returns(uint256);
	function transferFrom(address,address,uint256) external returns(bool);
    function transfer(address,uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
 	function decimals() external view returns (uint256);
}

