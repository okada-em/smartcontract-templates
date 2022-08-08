import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC20 Contract",  () => {
    it("check total supply when deploy contract", async function () {
        const [owner] = await ethers.getSigners();
        const Marketplace = await ethers.getContractFactory("ERC20Token");
        const hardhatToken = await Marketplace.deploy();
        const ownerBalance = await hardhatToken.balanceOf(owner.address);
        expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
    });
});