const {ethers} = require("hardhat");
async function main() {
    const [owner] = await ethers.getSigners();
      console.log("Owner Address:" , owner.address);
  const ZenithContract = await ethers.getContractFactory("ZenithX");
const routeraddress="0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3";
  const totalsupply = ethers.utils.parseEther(10000000000);
  const deployContract = await ZenithContract.deploy(totalsupply,routeraddress,{ gasLimit: 6000000 });

  await deployContract.deployed();
  console.log("Contract Address:" , deployContract.address);
}

main() 
  .then(()=>process.exit(0))
  .catch((err)=>{
    console.error(err);
    process.exit(1);
  });
