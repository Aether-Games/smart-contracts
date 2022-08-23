// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.7;


contract AEGAccess {
	address private _owner;
	mapping( bytes32 => bool ) private _allowed;

	enum AccessLevel {
		NONE,
		CONTRACTS,
		ADMINS,
		KEYS
	}

	constructor() {

		_allowed[getKeccak(msg.sender , AccessLevel.KEYS)] = true;
	}

	function _accessLevel( address addr ) internal view returns(AccessLevel) {
		if( _allowed[getKeccak(addr ,  AccessLevel.KEYS)] ){
			return AccessLevel.KEYS;
		}else if (_allowed[getKeccak(addr ,  AccessLevel.ADMINS)]){
			return AccessLevel.ADMINS;
		}else if (_allowed[getKeccak(addr ,  AccessLevel.CONTRACTS)]){
			return AccessLevel.CONTRACTS;
		}else{
			revert("Address does not have access");
		}
	}

	modifier allowContracts() {
		require(_accessLevel( msg.sender ) >= AccessLevel.CONTRACTS, "AEGAccess : Not allowed");
		_;
	}

	modifier allowAdmins() {
		require(_accessLevel( msg.sender ) >= AccessLevel.ADMINS, "AEGAccess : Not allowed");
		_;
	}

	modifier allowKeys() {
		require(_accessLevel( msg.sender ) >= AccessLevel.KEYS, "AEGAccess : Not allowed");
		_;
	}

	function owner() public view returns(address) {

		return _owner;
	}

	function getKeccak(address addr, AccessLevel al ) internal pure returns(bytes32){

		return keccak256(abi.encode(addr, al));
	}

	function allowAddress(address addr, AccessLevel al) public allowKeys {

		_allowed[getKeccak( addr , al)] = true;
	}

	function denyAddress(address addr) public allowKeys {
		AccessLevel _aAccess = _accessLevel(addr);
		require( _aAccess >= AccessLevel.CONTRACTS , "AEGAccess : Address is not allowed");
		_allowed[ getKeccak( addr , _aAccess )] = false;
	}

}