// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function decimals() external returns (uint256);
  
  function transferFrom(
      address sender,
      address recipient,
      uint amount
  ) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Presale {
  //  InputToken public inputToken;
  //  OutputToken public outputToken;

  address payable _owner;
  IERC20 public inputToken; // DAI / USDC / USDT / BUSD
  IERC20 public outputToken; // USDC BUSD ETH
  uint public priceNumerator; // price of 1 inputToken in outputToken;
  uint public priceDenominator; // price of 1 inputToken in outputToken;
  uint public priceNumeratorInNative; // price of 1 native in outputToken;
  uint public priceDenominatorInNative; // price of 1 native in outputToken;
  bool public isPhase1Active;
  bool public isPhase2Active;
  bool public isPhase3Active;

  event Exchange(address from, uint256 input, uint256 output);
  event Bought(address from, uint256 input, uint256 output);
  
  modifier onlyOwner() {
    require(msg.sender == _owner, "Only owner allowed");
    _;
  }

  constructor(address _inputToken, address _outputToken) {
    _owner = payable(msg.sender);
    inputToken = IERC20(_inputToken);
    outputToken = IERC20(_outputToken);
  }


  function setInputToken(address _inputToken) public onlyOwner() {
    inputToken = IERC20(_inputToken);
  }
  function setOutputToken(address _outputToken) public onlyOwner() {
    outputToken = IERC20(_outputToken);
  }

  function setPrice(uint256 _numerator, uint256 _denominator) public onlyOwner() {
    priceNumerator = _numerator;
    priceDenominator = _denominator;
  }

  function getPrice() public view returns (uint256, uint256) {
    return (priceNumerator, priceDenominator);
  }

  function setPriceNative(uint256 _numerator, uint256 _denominator) public onlyOwner() {
    priceNumeratorInNative = _numerator;
    priceDenominatorInNative = _denominator;
  }

  function getPriceInNative() public view returns (uint256, uint256) {
    return (priceNumeratorInNative, priceNumeratorInNative);
  }

  function getAllowance() public view returns (uint256) {
    uint256 allowance = inputToken.allowance(msg.sender, address(this));
    return allowance;
  }

  function getReserves() public view returns (uint256) {
    uint256 reserves = outputToken.balanceOf(address(this));
    return reserves;
  }

  function exchange(uint256 _amount) public {
    require(_amount > 0, "Amount must be greater than 0");
    uint256 allowance = inputToken.allowance(msg.sender, address(this));
    require(allowance >= _amount, "Not enough allowance");
    uint256 amountTobuy = _amount * priceDenominator / priceNumerator;
    uint balanceEtt = getReserves();
    require(balanceEtt >= amountTobuy, "Not enough tokens in the reserve");
    inputToken.transferFrom(msg.sender, address(this), _amount); // paga _amount en BUSD
    outputToken.transfer(msg.sender, amountTobuy); // recibe amountTobuy en ETT
    emit Exchange(msg.sender, _amount, amountTobuy);
  }

  function buy() public payable  {
    require(msg.value > 0, "Value must be greater than 0");
    uint256 amountTobuy = msg.value * priceDenominatorInNative / priceNumeratorInNative;
    uint256 balanceEtt = outputToken.balanceOf(address(this));
    require(balanceEtt >= amountTobuy, "Not enough tokens in the reserve");
    outputToken.transfer(msg.sender, amountTobuy);
    emit Bought(msg.sender, msg.value, amountTobuy);
  }

  function setPhase1Active(bool _phase1Active) public onlyOwner() {
    isPhase1Active = _phase1Active;
  }

  function setPhase2Active(bool _phase2Active) public onlyOwner() {
    isPhase2Active = _phase2Active;
  }

  function setPhase3Active(bool _phase3Active) public onlyOwner() {
    isPhase3Active = _phase3Active;
  }
}