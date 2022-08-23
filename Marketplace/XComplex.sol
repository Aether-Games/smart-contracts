// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;


/**
 * @dev the strucutre of listings,auctions,collections
 * are all included in the `XComplex` contract as basic
 * solidity types and structure latest v. 0.8.11;
 */
contract XComplex {

	// Mapping reference to all the collections on the marketplace
	mapping(address => Collection) internal _collections;
	// Mapping reference to each `nft_contract` 
	// Mapping reference to each `token_id` listed on marketplace
	mapping(address => mapping(uint256 => Listing)) internal _listings;
	// Mapping reference to each `nft_contract` 
	// Mapping reference to each `token_id` bids on marketplace
	mapping(address => mapping(uint256 => Biddings)) internal _biddings;
	// Mapping reference to each `nft_contract` 
	// Mapping reference to each `token_id` auction on marketplace
	mapping(address => mapping(uint256 => Auctions)) internal _auctions;

	// Mapping reference for AEG NFTs
	mapping(address => bool) internal _allowedCollections;
	// can accept all NFT contracts
	bool internal allAllowed;
	// time for dutch auction
	uint256 internal auctionTime = 86400;

	// a structure for any Collection 
	// referenced in `_collections`
	struct Collection {
		uint256 tradedVolume;
		uint256[] listedTokens;
	}

	// a structure for any Auction
	// referenced in `_auction`
	struct Auctions {
		address _owner;
		uint256 _price;
		uint256 _start;
		uint256 _expiry;
		bool _auctioned;
	}

	// a stucture for any Auction
	// referenced in `_auction`
	struct Biddings {
		address _owner;
		address _biderAddress;
		uint256 _minBid;
		uint256 _lastBid;
		uint256 _expiry;
		bool _openForBids;
	}

	// a structure for any listing
	// referenced in `_listings`
	struct Listing {
		address _owner;
		uint256 _price;
		address _token;
		address _offerAddress;
		uint256 _offerPrice;
		bool _listed;
	}
}
