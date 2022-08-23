// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;

interface IAEG721 {
	function ownerOf(uint256) external view returns(address);
	function balanceOf(address) external view returns(uint256);
 	function tokenURI(uint256) external view returns (string memory);
}

contract MarketplaceHelper {

	function walletOfOwner(address nft_contract, address nft_owner) external view returns(string[] memory wallet_nfts){
		uint256 owner_balance = IAEG721(nft_contract).balanceOf(nft_owner);
		wallet_nfts = new string[](owner_balance);
		uint256 idx = 0;
		uint256 iter = 0;
		while (idx<owner_balance){
			iter += 1;
			if(IAEG721(nft_contract).ownerOf(iter) == nft_owner){
				wallet_nfts[idx] = getTokenURI(nft_contract, iter);
				idx += 1;
			}
		}
	}

	function getTokenURI(address nft_contract , uint256 token_id) public view returns(string memory){
		return IAEG721(nft_contract).tokenURI(token_id);
	} 
}
