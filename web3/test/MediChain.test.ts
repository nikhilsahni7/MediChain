import { ethers } from "hardhat";
import { expect } from "chai";
import { Signer } from "ethers";

describe("MediChain", function () {
  let contract: any;
  let hospitalA: Signer;
  let hospitalB: Signer;
  let hospitalAAddr: string;
  let hospitalBAddr: string;

  beforeEach(async function () {
    [hospitalA, hospitalB] = await ethers.getSigners();
    hospitalAAddr = await hospitalA.getAddress();
    hospitalBAddr = await hospitalB.getAddress();

    const MediChain = await ethers.getContractFactory("MediChain");
    contract = await MediChain.deploy();
    await contract.waitForDeployment();
  });

  it("should commit inventory", async function () {
    const hash = ethers.keccak256(ethers.toUtf8Bytes("stockA"));

    await contract.connect(hospitalA).commitInventory(hash);

    const result = await contract.getInventoryCommitment(hospitalAAddr);
    expect(result[0]).to.equal(hash);
    expect(result[1]).to.be.a("bigint");
  });

  it("should confirm inventory commitment exists", async function () {
    const hash = ethers.keccak256(ethers.toUtf8Bytes("stockA"));
    await contract.connect(hospitalA).commitInventory(hash);

    const hasCommitted = await contract.hasCommittedInventory(hospitalAAddr);
    expect(hasCommitted).to.be.true;
  });

  it("should allow placing order only if seller has committed inventory", async function () {
    const hash = ethers.keccak256(ethers.toUtf8Bytes("stockA"));
    const orderHash = ethers.keccak256(ethers.toUtf8Bytes("order1"));

    // Hospital A commits inventory
    await contract.connect(hospitalA).commitInventory(hash);

    // Hospital B places order from hospital A
    await contract.connect(hospitalB).placeOrder(orderHash, hospitalAAddr);

    const order = await contract.getOrderByIndex(0);
    expect(order[0]).to.equal(orderHash);
    expect(order[1]).to.equal(hospitalAAddr);
    expect(order[2]).to.equal(hospitalBAddr);
    expect(order[4]).to.equal("Pending");
  });

  it("should reject order if seller has not committed inventory", async function () {
    const orderHash = ethers.keccak256(ethers.toUtf8Bytes("order2"));

    await expect(
      contract.connect(hospitalB).placeOrder(orderHash, hospitalAAddr)
    ).to.be.revertedWith("seller hospital has not committed inventory");
  });

  it("should update order status by involved parties", async function () {
    const invHash = ethers.keccak256(ethers.toUtf8Bytes("stock"));
    const orderHash = ethers.keccak256(ethers.toUtf8Bytes("order3"));

    await contract.connect(hospitalA).commitInventory(invHash);
    await contract.connect(hospitalB).placeOrder(orderHash, hospitalAAddr);

    // hospitalA updates status to Completed
    await contract.connect(hospitalA).updateOrderStatus(0, "Completed");
    const updatedOrder = await contract.getOrderByIndex(0);
    expect(updatedOrder[4]).to.equal("Completed");
  });

  it("should reject update from unrelated address", async function () {
    const invHash = ethers.keccak256(ethers.toUtf8Bytes("stock"));
    const orderHash = ethers.keccak256(ethers.toUtf8Bytes("order4"));

    const [_, __, stranger] = await ethers.getSigners();
    await contract.connect(hospitalA).commitInventory(invHash);
    await contract.connect(hospitalB).placeOrder(orderHash, hospitalAAddr);

    await expect(
      contract.connect(stranger).updateOrderStatus(0, "Cancelled")
    ).to.be.revertedWith("only involved hospitals can update order status");
  });

  it("should return correct order count", async function () {
    const hash = ethers.keccak256(ethers.toUtf8Bytes("stock"));
    const orderHash = ethers.keccak256(ethers.toUtf8Bytes("order5"));

    await contract.connect(hospitalA).commitInventory(hash);
    await contract.connect(hospitalB).placeOrder(orderHash, hospitalAAddr);

    const count = await contract.getOrderCount();
    expect(count).to.equal(1);
  });
});
