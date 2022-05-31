const main = async () => {
    const swapBotContractFactory = await hre.ethers.getContractFactory('Autoswapbot');
    const swapBotContract = await swapBotContractFactory.deploy();
    await swapBotContract.deployed();

    console.log("Contract owner:", swapBotContract.address);
}

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();