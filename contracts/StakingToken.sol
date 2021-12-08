//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingToken is Ownable {
    // ERC-20 token to stake
    address stakeTokenAddr;

    //  The sum of all active stake deposits
    uint256 sumDeposit;

    //  The sum of all propotional reward
    //  The propotional reward is (reward / sumDeposit)
    uint256 sumPropotionalReward;

    //  It's used to store the stake balance of all stakers
    mapping(address => uint) public stakeAmount;

    //  It's used to store the last propotional reward of all stakers
    mapping(address => uint) public lastPropotionalReward;

    /**
     * @dev constructor
     * @param _stakeTokenAddr the address of token to stake
     */
    constructor(
        address _stakeTokenAddr
    ) {
        stakeTokenAddr = _stakeTokenAddr;
    }

    /**
     * @dev the function to stake token
     */
    function deposit(uint256 _tokenAmount) external payable {
        // Transfer token from staker to smart contract
        TransferHelper.safeTransferFrom(stakeTokenAddr, msg.sender, address(this), _tokenAmount);

        uint256 rewardAmount = calculateReward(msg.sender, stakeAmount[msg.sender]);

        // Update stake amount, total deposit amount and last proportional reward
        stakeAmount[msg.sender] += _tokenAmount;
        sumDeposit += _tokenAmount;
        lastPropotionalReward[msg.sender] = sumPropotionalReward;

        //  The previous reward will be transfered from smart contract to the staker
        TransferHelper.safeTransfer(stakeTokenAddr, msg.sender, rewardAmount);
    }

    function distribute(uint256 _reward) external payable onlyOwner {
        require(sumDeposit > 0, "No deposit yet");
        sumPropotionalReward += _reward * 1e12 / sumDeposit;
    }

    /**
     * @dev the function to withdraw the staked token in the history
     * @param _tokenAmount the token amount to withdraw
     */
    function withdraw(uint256 _tokenAmount) public {
        uint256 balance = stakeAmount[msg.sender];
        require(balance >= _tokenAmount, "Insufficient token");

        uint256 rewardAmount = calculateReward(msg.sender, balance);
        
        // Update stake amount, total deposit amount and last proportional reward
        sumDeposit -= _tokenAmount;
        stakeAmount[msg.sender] -= _tokenAmount;
        lastPropotionalReward[msg.sender] = sumPropotionalReward;
        
        // Transfer token to the staker
        TransferHelper.safeTransfer(stakeTokenAddr, msg.sender, _tokenAmount + rewardAmount);
    }

    /**
     * @dev the function to get reward for the staker
     */
    function getReward() public {
        uint256 balance = stakeAmount[msg.sender];
        require(balance > 0, "You have never staked any token");

        uint256 rewardAmount = calculateReward(msg.sender, balance);
        require(rewardAmount > 0, "No reward yet");

        // Update only last proportional reward
        lastPropotionalReward[msg.sender] = sumPropotionalReward;
        
        // Transfer token to the staker
        TransferHelper.safeTransfer(stakeTokenAddr, msg.sender, rewardAmount);
    }

    /**
     * @dev the function to calculate the reward of the staker
     * @param _stakerAddr the token owner's address
     */
    function calculateReward(address _stakerAddr, uint _balance) private view returns (uint256)
    {
        uint256 reward = _balance * (sumPropotionalReward - lastPropotionalReward[_stakerAddr]) / 1e12;
        return reward;
    }  

    /**
     * @dev the function to read the balance of the staker
     */
    function getTokenBalance() public view returns (uint256)
    {
        return stakeAmount[msg.sender];
    }  
}
