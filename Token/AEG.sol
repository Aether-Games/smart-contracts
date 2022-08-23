//SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.0;


interface IAEG20 {
	enum Alloc { PRESALE , SEED , GUILDS , OPEN }
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IAEG20Metadata is IAEG20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}



contract AEG20 is  IAEG20, IAEG20Metadata {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping( Alloc => uint256 ) _allocations;

    uint256 private _totalSupply;
    uint256 private constant _maxSupply = 1000000000 ether; 
    string private constant _name = "AetherGamesToken";
    string private constant _symbol = "AEG";


    constructor() {
    	for( uint8 i=0; i<uint8( Alloc.OPEN ); i++ ) {
    		_allocations[Alloc( i )] = 25;
    	}
    }


    function maxAllocation( uint8 allocationType , uint256 offset ) external view returns( uint256 ) {
    	Alloc _alloc = Alloc( allocationType );
    	uint256 _total = ( ( _allocations[_alloc] - offset ) * _maxSupply );
    	return ( _total / 100 );
    }

  
    function name() external view override returns ( string memory ) {

        return _name;
    }

    function symbol() external view override returns ( string memory ) {

        return _symbol;
    }

    function decimals() external view override returns ( uint8 ) {

        return 18;
    }

    function totalSupply() external view override returns ( uint256 ) {

        return _totalSupply;
    }

    function maxSupply() external view returns( uint256 ) {

    	return _maxSupply;
    }

    function balanceOf( address account ) public view override returns ( uint256 ) {

        return _balances[account];
    }

    function transfer( address recipient , uint256 amount ) public override returns ( bool ) {
        _transfer( msg.sender , recipient , amount );
        return true;
    }

    function allowance( address owner , address spender ) public view override returns ( uint256 ) {
        return _allowances[owner][spender];
    }

    function approve( address spender , uint256 amount ) public override returns ( bool ) {
        _approve( msg.sender , spender , amount );
        return true;
    }

    function transferFrom( address sender , address recipient , uint256 amount ) public override returns ( bool ) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

 
    function _transfer(address sender,address recipient,uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    function mint( address account, uint256 amount , uint8 _alloc ) public {
        uint256 _totalAllocation = maxAllocation( _alloc );
        require( amount <= _allocations[Alloc( _alloc )] , "This Allocation has been minted");
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");


        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

    }

    function _approve(address owner,address spender,uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}





contract AEG {

}