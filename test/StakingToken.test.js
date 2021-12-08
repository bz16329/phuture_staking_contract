const { expect } = require("chai");
const getBigNumber = num => (num + '0'.repeat(18))

describe("StakingToken", function () {
  it("Should return the new greeting once it's changed", async function () {
    let Token;
    let stakingToken;
    let owner;
    let staker0;
    let staker1;
    let mockERC20;
    let dai;

    beforeEach(async function () {
      Token = await ethers.getContractFactory("StakingToken");
      [owner, staker0, staker1] = await ethers.getSigners();
      
      mockERC20 = await ethers.getContractFactory("MockERC20")
      dai = await mockERC20.deploy("DAI", "DAI", getBigNumber(100000))
      await dai.deployed()
      
      await dai.transfer(staker0.address, getBigNumber(2000))
      await dai.transfer(staker1.address, getBigNumber(2000))
      
      stakingToken = await Token.deploy(dai.address);         
      await stakingToken.deployed()
      
      await dai.connect(staker0).approve(stakingToken.address, getBigNumber(2000))
      await dai.connect(staker1).approve(stakingToken.address, getBigNumber(2000))
    });

    describe('Staking token', function () {
      it("Should stake token and get reward successfully", async function () {
        try {
          expect((await stakingToken.connect(staker0).deposit(getBigNumber(1000))));
          expect((await stakingToken.connect(staker1).deposit(getBigNumber(1000))));

          // Check stake balance
          expect((await stakingToken.connect(staker0).getTokenBalance())).to.equal(getBigNumber(1000));
          expect((await stakingToken.connect(staker1).getTokenBalance())).to.equal(getBigNumber(1000));
          
          // The owner distributes reward 
          expect((await stakingToken.connect(owner).distribute(getBigNumber(1000))));
          
          // Deposit again
          expect((await stakingToken.connect(staker0).deposit(getBigNumber(500))));
          expect((await stakingToken.connect(staker0).getTokenBalance())).to.equal(getBigNumber(1500));
          expect((await dai.balanceOf(staker0.address))).to.equal(getBigNumber(1000));
          
          // withdraw
          expect((await stakingToken.connect(staker1).withdraw(getBigNumber(500))));
          expect((await stakingToken.connect(staker1).getTokenBalance())).to.equal(getBigNumber(500));

          // The owner distributes reward again 
          expect((await stakingToken.connect(owner).distribute(getBigNumber(500))));
          
          expect((await dai.balanceOf(staker0.address))).to.equal(getBigNumber(1000));
          expect((await dai.balanceOf(staker1.address))).to.equal(getBigNumber(2000));

          expect((await stakingToken.connect(staker0).getReward()));
          expect((await stakingToken.connect(staker1).withdraw(getBigNumber(500))));

          expect((await dai.balanceOf(staker0.address))).to.equal(getBigNumber(1375));
          expect((await dai.balanceOf(staker1.address))).to.equal(getBigNumber(2625));
        } catch (err) {
          console.log("StakingToken Error: " + err.message);
        }
      })
    })
  });
});
