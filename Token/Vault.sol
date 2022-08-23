//SPDX-License-Identifier: GPL v3

pragma solidity^0.8.7;


interface IERC20 {
	function balanceOf(address) external view returns(uint256);
	function allowance(address,address) external view returns(uint256);
	function decimals() external view returns(uint256);
	function safeTransferFrom(address,address,uint256) external returns(bool);
	function transfer(address, uint256) external returns(bool);
	function approve(address, uint256) external;
}

contract IVault20 {
	function send20Token(address token, address to, uint256 amount) internal {
		require(IERC20(token).balanceOf(address(this) >= amount), "GoE20: Not enough balance");
		require(IERC20(token).transfer(to, amount), "GoE20: Unable to transfer");
	}

	function recieve20Token(address token, address from, uint256 amount) internal {
		require(IERC20(token).allowance(from, address(this)) >= amount, "GoE20: Not enough allowance from sender address");
		require(IERC20(token).safeTransferFrom(from, address(this), amount), "GoE20: Not enough balance from sender address");
	}

	function getBalance(address token) internal view returns(uint256){
		return(IERC20(token).balanceOf(address(this)));
	}
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'addition overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'subtraction underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'multiplication overflow');
    }
}

library SWAPLibrary {
    using SafeMath for uint;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SWAPLibrary: same addresses for tokenA and tokenB');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SWAPLibrary: cannot be 0 address');
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = SWAPPair(SWAPFactory(factory).getPair(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SWAPLibrary: input cannot be zero');
        require(reserveA > 0 && reserveB > 0, 'SWAPLibrary: cannot quote based on liquidity');
        amountB = amountA.mul(reserveB) / reserveA;
    }
}

interface SWAPPair {
    function getReserves() external view returns (uint256 _res1, uint256 _res2, uint256 _timestamp);
}

interface SWAPFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract VaultBalance is IVault20 {
	address[] _stableTokens;
	address[] _variousTokens;

	address _GOE;

	enum BalanceType {
		STABLE,
		ONLY_GOE,
		VARIOUS,
		ALL
	}

	function _calculateBalance(BalanceType _balType) internal view returns(uint256 vault_balance){
		if(_balType == BalanceType.STABLE){
			for(uint256 i=0; i<_stableTokens.length; i++){
				vault_balance += getBalance(_stableTokens[i]);
			}
		}else if (_balType == BalanceType.VARIOUS){
			for(uint256 i=0; i<_variousTokens.length; i++){
				vault_balance += getBalance(_variousTokens[i]);
			}
		}else if (_balType == BalanceType.ONLY_GOE){
				vault_balance += getBalance(_GOE);
		}else if (_balType == BalanceType.ALL){
			vault_balance += _calculateBalance(BalanceType.STABLE);
			vault_balance += _calculateBalance(BalanceType.ONLY_GOE);
			vault_balance += _calculateBalance(BalanceType.VARIOUS);
		}
	}

}

contract VaultOracle is VaultBalance {
	 struct RegToken {
        string _tknName;
        address _tknAddr;
        address _tknPair;
    }

  	function registerToken(string memory _tknName, address _tknAddr) public {
        require(msg.sender == owner, "only owner can register new tokens");
        address _pairAddr = SWAPFactory(_factory).getPair(_USDT, _tknAddr);
        require(_pairAddr != address(0), "No pair exists for this token");
        _registeredTokens[_tknName] = RegToken(_tknName, _tknAddr, _pairAddr);
        tokens.push(_tknName);
    }

    function getExchangeRate(string calldata _tknName) public view returns(uint256) {
    	RegToken memory _tkn = _registeredTokens[_tknName];
        uint256 _oneInToken = uint256(uint8(1) * (10**IERC20(_tkn._tknAddr).decimals()));
        (uint _res1, uint _res2,) = SWAPPair(_tkn._tknPair).getReserves();
        return(SWAPLibrary.quote(_oneInToken, _res1, _res2));
    }

    function _getGoEXR() internal view returns(uint256){
    	return getExchangeRate("GoE");
    }
}


contract Vault is VaultBalance {
	event TokensRedeemed(address indexed Redeemer, uint8 TokenSpecs, uint256 TokenAmount, uint256 RedeemTime);
	event TokensAssigned(address indexed Redeemer, uint256 Amount, uint256 FirstRelease, uint256 LastRelease);


	error InsuffcientVaultFunds(uint8 TokenSpecs, uint256 RequestedAmount);
	

	uint256 Threshold;
	uint256 Balancing;
	
	enum ConfigType {
		THRESHOLD,
		BALANCING
	}

	enum TokenType {
		STABLE,
		GoE
	}



	mapping(address => mapping(uint256 => uint256)) _releaseSchedules;



	function changeConfiguration(ConfigType cf, uint256 nVal) public {
		if(cf == ConfigType.THRESHOLD){
			Threshold = nVal;
		}
	}


	function initReleaseSchedule(uint256[] memory _timeOfRelease, uint256 memory _releaseAmount) public {
		require(_timeOfRelease.length == _releaseAmount.length, "Vault: Arrays length mismatch");
		for(uint256 i=0; i<_timeOfRelease.length; i++){
			require(_releaseSchedules[_timeOfRelease[i]] == uint256(0), "Vault: Release Schedule already have been set");
			_releaseSchedules[_timeOfRelease[i]][_releaseAmount[i]];
		}
	}

	function _getRelease(address owner) internal view returns(uint256){

	}

	function _checkToken(TokenType _tt, uint256 _amount) internal view returns(bool){
		uint256 _balance;
		if(_tt == TokenType.STABLE){
			_balance = _calculateBalance(BalanceType.STABLE);
		}else{
			_balance = _calculateBalance(BalanceType.ONLY_GOE);
		}
		return (_balance/_amount) >= Threshold;
	}

	function redeemRelease(TokenType tt, bool override) public bondHolders {
		uint256 _releaseAmount = _getRelease(msg.sender);
		if(override){
			_redeemTokens(TokenType, _releaseAmount, msg.sender, true);
		}else{
			if(_checkToken(tt, _releaseAmount)){
				return _redeemTokens(TokenType, _releaseAmount, msg.sender);
			}
			revert InsuffcientVaultFunds(uint8(tt), _releaseAmount);
		}
	}

	function _redeemTokens(TokenType tt, uint256 releaseAmount, address owner) internal {
		return _redeemTokens(tt, releaseAmount, owner, false);
	}

	function _getCurrentBalancing(uint256 amount) internal view returns(uint256){
		uint256 stableBalance = _calculateBalance(BalanceType.STABLE);
		uint256 goeBalance = _calculateBalance(BalanceType.ONLY_GOE);
		uint256 currentGoePrice = VaultOracle._getGoEXR();

		uint256 vault_ratio = stableBalance/goeBalance;

		if((vault_ratio > currentGoePrice) && (vault_ratio > Balancing)) {
			return amount;
		}else{
			return amount - (currentGoePrice * goeBalance);
		}
	}

	function _redeemTokens(TokenType tt, uint256 releaseAmount, address owner, bool conf) {
		uint256 _stable;
		if(conf){
			_stable = _getCurrentBalancing(releaseAmount);
			send20Token(_stableTokens[0], owner, _stable);
		}
		send20Token(_GOE, owner, releaseAmount - _stable);
	}




}