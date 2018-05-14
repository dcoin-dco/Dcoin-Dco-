pragma solidity ^0.4.18;

import './SafeMath.sol';
import './ERC20Interface.sol';

contract DCoin is ERC20Interface {
  using SafeMath for uint;

  // State variables
  string public name = "D'Coin";
  string public symbol = 'DCO';
  uint public decimals = 6;
  address public owner;
  uint public maxCoinCap = 200000000 * (10 ** 6);
  uint public totalSupply;
  bool public emergencyFreeze;
  
  // mappings
  mapping (address => uint) balances;
  mapping (address => mapping (address => uint) ) allowed;
  mapping (address => bool) frozen;

  // events
  event Mint(address indexed _to, uint indexed _mintedAmount);
  

  // constructor
  function DCoin () public {
    owner = msg.sender;
  }

  // events
  event OwnershipTransferred(address indexed _from, address indexed _to);
  event Burn(address indexed from, uint256 amount);
  event Freezed(address targetAddress, bool frozen);
  event EmerygencyFreezed(bool emergencyFreezeStatus);
  


  // Modifiers
  modifier onlyOwner {
    require(msg.sender == owner);
     _;
  }

  modifier unfreezed(address _account) { 
    require(!frozen[_account]);
    _;  
  }
  
  modifier noEmergencyFreeze() { 
    require(!emergencyFreeze);
    _; 
  }
  


  // functions

  // ------------------------------------------------------------------------
  // Transfer Token
  // ------------------------------------------------------------------------
  function transfer(address _to, uint _value) unfreezed(_to) unfreezed(msg.sender) noEmergencyFreeze() public returns (bool success) {
    require(_to != 0x0);
    require(balances[msg.sender] >= _value); 
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // ------------------------------------------------------------------------
  // Mint Token (Uncapped Minting)
  // ------------------------------------------------------------------------
  function mintToken (address _targetAddress, uint256 _mintedAmount) unfreezed(_targetAddress) noEmergencyFreeze() public onlyOwner returns(bool res) {
    require(_targetAddress != 0x0); // use burn instead
    require(_mintedAmount != 0);
    require (totalSupply.add(_mintedAmount) <= maxCoinCap);
    balances[_targetAddress] = balances[_targetAddress].add(_mintedAmount);
    totalSupply = totalSupply.add(_mintedAmount);
    emit Mint(_targetAddress, _mintedAmount);
    emit Transfer(address(0), _targetAddress, _mintedAmount) ;
    return true;
  }

  // ------------------------------------------------------------------------
  // Approve others to spend on your behalf
  // ------------------------------------------------------------------------
  /* 
    While changing approval, the allowed must be changed to 0 than then to updated value
    The smart contract doesn't enforces this due to backward competibility but requires frontend to do the validations
   */
  function approve(address _spender, uint _value) unfreezed(_spender) unfreezed(msg.sender) noEmergencyFreeze() public returns (bool success) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // ------------------------------------------------------------------------
  // Approve and call : If approve returns true, it calls receiveApproval method of contract
  // ------------------------------------------------------------------------
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

  // ------------------------------------------------------------------------
  // Transferred approved amount from other's account
  // ------------------------------------------------------------------------
  function transferFrom(address _from, address _to, uint _value) unfreezed(_to) unfreezed(_from) unfreezed(msg.sender) noEmergencyFreeze() public returns (bool success) {
    require(_value <= allowed[_from][msg.sender]);
    require (_value <= balances[_from]);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }


  // ------------------------------------------------------------------------
  // Burn (Destroy tokens)
  // ------------------------------------------------------------------------
  function burn(uint256 _value) unfreezed(msg.sender) public returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

  // ------------------------------------------------------------------------
  //               ONLYOWNER METHODS                             
  // ------------------------------------------------------------------------


  // ------------------------------------------------------------------------
  // Transfer Ownership
  // ------------------------------------------------------------------------
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  // ------------------------------------------------------------------------
  // Freeze account - onlyOwner
  // ------------------------------------------------------------------------
  function freezeAccount (address _target, bool _freeze) public onlyOwner returns(bool res) {
    require(_target != 0x0);
    frozen[_target] = _freeze;
    emit Freezed(_target, _freeze);
    return true;
  }

  // ------------------------------------------------------------------------
  // Emerygency freeze - onlyOwner
  // ------------------------------------------------------------------------
  function emergencyFreezeAllAccounts (bool _freeze) public onlyOwner returns(bool res) {
    emergencyFreeze = _freeze;
    emit EmerygencyFreezed(_freeze);
    return true;
  }
  

  // ------------------------------------------------------------------------
  //               CONSTANT METHODS
  // ------------------------------------------------------------------------


  // ------------------------------------------------------------------------
  // Check Allowance : Constant
  // ------------------------------------------------------------------------
  function allowance(address _tokenOwner, address _spender) public constant returns (uint remaining) {
    return allowed[_tokenOwner][_spender];
  }

  // ------------------------------------------------------------------------
  // Check Balance : Constant
  // ------------------------------------------------------------------------
  function balanceOf(address _tokenOwner) public constant returns (uint balance) {
    return balances[_tokenOwner];
  }

  // ------------------------------------------------------------------------
  // Total supply : Constant
  // ------------------------------------------------------------------------
  function totalSupply() public constant returns (uint) {
    return totalSupply;
  }

  // ------------------------------------------------------------------------
  // Get Freeze Status : Constant
  // ------------------------------------------------------------------------
  function isFreezed(address _targetAddress) public constant returns (bool) {
    return frozen[_targetAddress]; 
  }



  // ------------------------------------------------------------------------
  // Prevents contract from accepting ETH
  // ------------------------------------------------------------------------
  function () public payable {
    revert();
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address _tokenAddress, uint _value) public onlyOwner returns (bool success) {
      return ERC20Interface(_tokenAddress).transfer(owner, _value);
  }
}