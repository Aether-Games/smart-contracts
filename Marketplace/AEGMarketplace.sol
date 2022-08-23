// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;


import "./IAEG721.sol";
import "./IAEGGenesis721.sol";
import "./IAEG20.sol";
import "./AEGAccess.sol";
import "./AEG721Txns.sol";
import "./AEG20Txns.sol";
import "./NativeTxns.sol";
import "./XComplex.sol";


/**
 * @dev all the payments that are done through the marketplace
 * are facilitated in one contract for ease of read, Mainly the
 * contract deals with native currency and $AEG Tokens
 */
contract Payments is AEG721Txns, AEG20Txns, NativeTxns, AEGAccess {

  
	/**
	 * @dev holds a reference for all the tokens accepted
	 * by AEG marketplace to buy/sell NFTs
	 * address(0) == NATIVE
	 */
	mapping(address => bool) private _acceptedTokens;

	/**
	 * @dev holds a reference to all balances inside the marketplace
	 * from deposits to fees, with respect to tokens.
	 */
	mapping(address => mapping(address => uint256)) private _balances;

	/**
	 * @dev a simple thou percentage deduction
	 * will be able to change to any precision using
	 * `changeMarketFee` function.
	 *
	 * set initially @ 2%
	 */
	uint256 private MARKET_FEE = 20;
	uint256 private FEE_DIVIDER = 1000;

	/**
	 * @dev add support for the native currency 
	 */
	constructor() {

		_acceptedTokens[address(0)] = true;
	}

	/**
	 * @dev changes the market fee. 
	 * applies on all trades that are happening in the marketplace.
	 */
	function changeMarketFee(uint256 _fee, uint256 _divider) external allowAdmins  {
		MARKET_FEE = _fee;
		FEE_DIVIDER = _divider;
		require(_divider != 0, "Payments : Divider cannot be 0");
	}

	/**
	 * @dev add support for any {ERC-20} token, 
	 * must implement the `IAEG20` interface.
	 */
	function addSupportedTokens(address token_addr) external allowAdmins {

		_acceptedTokens[token_addr] = true;
	}

	/**
	 * @dev removes the support of any {ERC-20 token}.
	 */
	function removeSupportedTokens(address token_addr) external allowAdmins {
		require(token_addr != address(0), "Payments : Cannot remove native currency support");
		_acceptedTokens[token_addr] = false;
	}

	/**
	 * @dev check if the token is supported
	 */
	function isTokenSupported(address token_addr) public view returns(bool){

		return _acceptedTokens[token_addr];
	}

	/**
	 * @dev allows people with accessLevel.Keys
	 * to withdraw the fees based on the token
	 */
	function withdraw(address token , uint256 amount) external allowKeys {
		require(_balances[address(this)][token] >= amount , "Payments : can only withdraw fees");
		if(token == address(0)){
			_sendNative(msg.sender , amount);
		}else{
			send20Tokens(msg.sender , token , amount);
		}
	}

	/**
	 * @dev every transaction in the marketplace 
	 * is subject to a `MARKET_FEE/FEE_DIVIDER` as a fee %
	 */
	function _deductFee(address token , uint256 amount) internal returns(uint256){
		uint256 _fee = ((amount*MARKET_FEE)/FEE_DIVIDER);
		_balances[address(this)][token] += _fee;
		return (amount - _fee);
	}
}


/**
 * @dev the interaction and helper
 * function that can be used with the 
 * marketplace XComplex are found in 
 * the `XFlow` contract
 */
contract XFlow is XComplex, Payments {

	modifier NFTOwner( address nft_contract , uint256 token_id) {
		require(msg.sender == nftOwner(nft_contract, token_id) , "XFlow : Only NFT owners can perform this action");
		_;
	}

	function nftOwner(address nft_contract, uint256 token_id) internal view returns(address){

		return IAEG721(nft_contract).ownerOf(token_id);
	}

	function collectionAllowed(address nft_contract) internal view returns(bool) {
		if(allAllowed){
			return true;
		}
		return _allowedCollections[nft_contract];
	}

	function allowCollection(address nft_contract) external allowAdmins {

		_allowedCollections[nft_contract] = true;
	}

	function denyCollection(address nft_contract) external allowAdmins {

		_allowedCollections[nft_contract] = false;
	}

	function changeAuctionTime(uint256 auction_time) external allowAdmins {
		require(auction_time > 0 , "Auction time must be greater than 0");
		auctionTime = auction_time;	
	}

	function _isListed(address nft_contract, uint256 token_id) internal view returns(bool){

		return _listings[nft_contract][token_id]._listed;
	}

	function isListed(address nft_contract, uint256 token_id) public view returns(bool){

		return _isListed(nft_contract, token_id);
	}

	function listingPrice(address nft_contract, uint256 token_id) public view returns(uint256){
		require(_isListed(nft_contract, token_id), "XFlow : This NFT is not listed");
		return _listings[nft_contract][token_id]._price;
	}

	function _isOpenForBids(address nft_contract , uint256 token_id) internal view returns(bool) {

		return _biddings[nft_contract][token_id]._openForBids;
	}

	function isOpenForBids(address nft_contract, uint256 token_id) public view returns(bool) {

		return _isOpenForBids(nft_contract , token_id);
	}

	function lastBid(address nft_contract, uint256 token_id) public view returns(uint256){
		require(isOpenForBids(nft_contract, token_id), "XFlow : This item is not auctioned");
		return _biddings[nft_contract][token_id]._lastBid;
	}

	function lastBidder(address nft_contract, uint256 token_id) public view returns(address){

		return _biddings[nft_contract][token_id]._biderAddress;
	}

	function changeBid(address nft_contract, uint256 token_id, address nBidder, uint256 nBid) internal{
		_biddings[nft_contract][token_id]._biderAddress = nBidder;
		_biddings[nft_contract][token_id]._lastBid = nBid;
	}

	function _isAuctioned(address nft_contract, uint256 token_id) internal view returns(bool){

		return _auctions[nft_contract][token_id]._auctioned && (_auctions[nft_contract][token_id]._expiry > block.timestamp);
	}

	function isAuctioned(address nft_contract, uint256 token_id) public view returns(bool){

		return _isAuctioned(nft_contract, token_id);
	}

	function auctionPrice(address nft_contract , uint256 token_id) public view returns(uint256){
		require(_isAuctioned(nft_contract , token_id));
		uint256 _s = _auctions[nft_contract][token_id]._start;
		uint256 _e = _auctions[nft_contract][token_id]._expiry;
		uint256 _p = _auctions[nft_contract][token_id]._price;
		return (((_e - _s)*_p)/_e);
	}

	function _removeListing(address nft_contract, uint256 token_id) internal {

		delete _listings[nft_contract][token_id];
	}

	function _removeAuction(address nft_contract, uint256 token_id) internal {

		delete _auctions[nft_contract][token_id];
	}

	function _removeBidding(address nft_contract , uint256 token_id) internal {

		delete _biddings[nft_contract][token_id];
	}
}

/**
 * @dev the Exchange contract is where all the logic
 * of the marketplace is, basically transfering NFTs from
 * sellers to buyers, while ensuring payments are made to
 * sellers. 
 * 
 * The Exchange also allows the NFT owner to manage their NFT
 * anyway they see fit, from listing, starting an auction, stopping
 * an auction, to accepting unlisted bids, etc..
 */
contract Xchange is XFlow {
	/**
	 * @dev in the following logic it's assumed that buyer is `msg.sender`
	 * and reciever is fetched from the appropriate mapping to the struct
	 * i.e: _listings, _auctions, etc..
	 */
	function _xchangePayment(address buyer, address seller, address nft_contract, uint256 token_id, address token, uint256 price) internal returns(bool) {
		uint256 finalAmount = _deductFee(token, price);
		send721Token(seller, buyer, nft_contract, token_id);
		if( token == address(0) ){
			_sendNative(seller, finalAmount);
		}else{
			distribute20Tokens(buyer, seller , token, finalAmount , (price - finalAmount));
		}
		
		return true;
	}
}

/**
 * The marketplace is where all the interactive functions
 * with the public are. basically any marketplace interactin
 * via a *web3* call will essentially be here.
 */
contract AEGMarketplace is Xchange {

	event ListingAdded(address indexed seller, address indexed token_contract, uint256 token_id, address token, uint256 listing_price, uint256 time_stamp);
	event ListingPurchased(address indexed buyer, address indexed seller, address indexed token_contract, uint256 token_id, address token, uint256 token_price, uint256 time_stamp);
	event BidOn(address indexed bidder, address indexed token_contract, uint256 token_id, uint256 token_bid, uint256 time_stamp);
	event BidAccepted(address indexed seller, address indexed bidder,address indexed token_contract, uint256 token_id, uint256 winning_bid, uint256 time_stamp);
	event AuctionStarted(address indexed seller, address indexed token_contract, uint256 token_id, uint256 start_price, uint256 expiry, uint256 time_stamp);
	event AuctionConcluded(address indexed auction_winner, address indexed seller, address indexed token_contract, uint256 token_id, uint256 dutch_price, uint256 time_stamp);


	function addListing(address nft_contract, uint256 token_id, address token, uint256 price) external NFTOwner(nft_contract, token_id) {
		require(isTokenSupported(token), "AEGMarketplace : This token is not suppored");
		_listings[nft_contract][token_id] = Listing(msg.sender, price, token, address(0), 0,  true);
		emit ListingAdded(msg.sender , nft_contract, token_id, token, price, block.timestamp);
	}

	function purchaseListing(address nft_contract, uint256 token_id) external payable {
		require(_isListed(nft_contract, token_id), "AEGMarketplace : This NFT is not listed");
		uint256 listed_price = _listings[nft_contract][token_id]._price;
		address token = _listings[nft_contract][token_id]._token;
		address nft_owner = nftOwner(nft_contract, token_id);
		if( token == address(0) ){
			require(_recieveNative(listed_price) , "AEGMarketplace : Need to pay the price of the NFT");
		}
		_xchangePayment(msg.sender, nft_owner , nft_contract, token_id, token, listed_price);
		_removeListing(nft_contract, token_id);
		emit ListingPurchased(msg.sender, nft_owner, nft_contract, token_id, token, listed_price, block.timestamp);
	}

	function removeListing(address nft_contract, uint256 token_id) external NFTOwner(nft_contract, token_id) {

		_removeListing(nft_contract, token_id);
	}

	function addBidding(address nft_contract, uint256 token_id, address token, uint256 min_bid, uint256 expiry) external NFTOwner(nft_contract, token_id) {
		require(!_isOpenForBids(nft_contract, token_id), "XFlow : This NFT is already open for bids");
		require((block.timestamp+86400) > expiry, "XFlow : Expiry should atleast be 24 hours");
		require(isTokenSupported(token) , "XFlow : Token is not supported");
		_biddings[nft_contract][token_id] = Biddings(msg.sender, address(0), min_bid, 0 , expiry, true);
	}

	function bidOn(address nft_contract, uint256 token_id, uint256 bid) external payable {
		require( _isOpenForBids(nft_contract, token_id) , "AEGMarketplace : Not open for bids");
		uint256 _lastbid = lastBid(nft_contract, token_id);
		require( bid > _lastbid , "AEGMarketplace : Bid must be bigger than last bid");
		address _lastbidder = lastBidder(nft_contract, token_id);
		if((_lastbidder != address(0)) && (_lastbid == 0)){
			require( _sendNative(_lastbidder, _lastbid));
		}
		require( _recieveNative(bid) , "AEGMarketplace : Need to deposit bid");
		changeBid(nft_contract, token_id, msg.sender, bid);
		emit BidOn(msg.sender , nft_contract, token_id, bid, block.timestamp);
	}

	function acceptBid(address nft_contract, uint256 token_id) external NFTOwner(nft_contract, token_id) {
		require( _isOpenForBids(nft_contract, token_id) , "AEGMarketplace : Not open for bids");
		uint256 _lastbid = lastBid(nft_contract, token_id);
		address _lastbidder = lastBidder(nft_contract, token_id);
		_xchangePayment(_lastbidder, msg.sender, nft_contract, token_id, address(0), _lastbid);
		_removeBidding(nft_contract, token_id);
		emit BidAccepted(msg.sender, _lastbidder, nft_contract, token_id, _lastbid, block.timestamp);
	}

	function removeBidding(address nft_contract, uint256 token_id) external NFTOwner(nft_contract, token_id) {

		_removeBidding(nft_contract, token_id);
	}
	


	function addAuction(address nft_contract, uint256 token_id, uint256 price) external NFTOwner(nft_contract, token_id) {
		require(!isAuctioned(nft_contract, token_id),"XFlow : This item is already on auction");
		_auctions[nft_contract][token_id] = Auctions(msg.sender , price , block.timestamp , (block.timestamp + auctionTime) , true);
		emit AuctionStarted(msg.sender, nft_contract, token_id, price, (block.timestamp + auctionTime), block.timestamp);
	}

	function partAuction(address nft_contract, uint256 token_id) external payable{
		uint256 _auctionPrice = auctionPrice(nft_contract, token_id);
		require( _recieveNative(_auctionPrice) , "AEGMarketplace : Need to deposit auction price");
		address nft_owner = nftOwner(nft_contract, token_id);
		_xchangePayment(msg.sender, nft_owner, nft_contract, token_id, address(0), _auctionPrice);
		_removeAuction(nft_contract, token_id);
		emit AuctionConcluded(msg.sender, nft_owner, nft_contract, token_id, _auctionPrice, block.timestamp);
	}

	function removeAuction(address nft_contract, uint256 token_id) external NFTOwner(nft_contract, token_id) {

		_removeAuction(nft_contract, token_id);
	}
}

