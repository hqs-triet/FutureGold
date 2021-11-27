pragma solidity ^0.8.2;

import '../libs/SafeMath.sol';

contract FutureGold {
    using SafeMath for uint256;
    address public owner;
    mapping(address => uint) private balances;
    
    mapping(uint => address) public holders;
    mapping(address => uint) public holderIdxs;
    uint public totalSupply = 1000_000_000_000_000 * 10 ** 18;
    string public name = "Future gold meme";
    string public symbol = "XGOLD";
    uint public decimals = 18;
    uint public holderFunds = 0;
    uint public lotteryFunds = 0;
    uint private holderTrxFee = 3;
    uint private lotteryTrxFee = 2;
    uint private totalHolders = 0;
    
    event Transfer(address indexed from, address indexed to, uint value, uint keepForHolderFund, uint keepForLotteryFund);
    event Redistributed();
    
    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {
        revert("No need ETH!");
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "This operation requires owner!");
        _;
    }
    modifier contraintBalance(uint amount) {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance!");
        _;
    }
    modifier contraintAmount(uint amount) {
        require(amount > 0, "Transfer amount must be greater than zero");
        _;
    }
    modifier contraintSendSelfAddress(address target) {
        require(msg.sender != target, "It cannot send to yourself!");
        _;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    function getHolderFee() public view returns(uint) {
        return holderTrxFee;
    }
    function getLotteryFee() public view returns(uint) {
        return lotteryTrxFee;
    }
    function setHolderFee(uint percent) public onlyOwner {
        require(percent > 0 && percent <= 5, "The holder fee is in range (0,5)");
        holderTrxFee = percent;
    }
    function setLotteryTrxFee(uint percent) public onlyOwner {
        require(percent > 0 && percent <= 5, "The lottery fee is in range (0,5)");
        lotteryTrxFee = percent;
    }
    
    function transfer(address to, uint amount) public contraintBalance(amount) 
                                                      contraintAmount(amount) 
                                                      contraintSendSelfAddress(to) returns(bool) {
        (uint realAmount, uint hFee, uint lFee) = calculateFee(amount);
        balances[to] += realAmount;
        balances[msg.sender] -= amount;
        holderFunds += hFee;
        lotteryFunds += lFee;
        
        
        if(holderIdxs[to] == 0) {
            totalHolders++;
            holders[totalHolders] = to;
            holderIdxs[to] = totalHolders;
        }
        
        emit Transfer(msg.sender, to, realAmount, hFee, lFee);
        return true;
    }
    
    function calculateFee(uint amount) private returns (uint realAmount, uint holderFee, uint lotteryFee) {
        uint lotteryFee = amount.mul(lotteryTrxFee).div(10 ** 2);
        uint holderFee = amount.mul(holderTrxFee).div(10 ** 2);
        uint realAmount = amount - lotteryFee - holderFee;
        return (realAmount, holderFee, lotteryFee);
    }
    
    function redistribute() public onlyOwner {
        if(holderFunds == 0 || totalHolders == 0)
            return;
            
        uint256 sum = 0;
        uint oriHolderFunds = holderFunds;
        for(uint idx = 1; idx <= totalHolders; idx++) {
            if(holders[idx] != owner && balances[holders[idx]] > 0) {
                sum = sum.add(balances[holders[idx]]);
            }
        }
        for(uint idx = 1; idx <= totalHolders; idx++) {
            if(holders[idx] != owner && balances[holders[idx]] > 0) {
                // uint256 rate = balances[holders[idx]].div(sum);
                uint receivedAmount = oriHolderFunds.mul(balances[holders[idx]]).div(sum);
                if(receivedAmount > 0) {
                    balances[holders[idx]] += receivedAmount;
                    holderFunds = holderFunds.sub(receivedAmount);    
                }
            }
        }
        emit Redistributed();
    }
    function lottery() public onlyOwner {
        
    } 
}