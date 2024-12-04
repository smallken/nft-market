const { ethers } = require("ethers");
const { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack } = ethers.utils;

async function permitAndTransfer() {
    // 连接到以太坊网络（这里使用Infura作为示例）
    const provider = new ethers.providers.InfuraProvider("ropsten", "YOUR_INFURA_PROJECT_ID");

    // 使用私钥创建钱包（请确保私钥安全）
    const privateKey = "YOUR_PRIVATE_KEY";
    const wallet = new ethers.Wallet(privateKey, provider);

    // ERC20合约地址和ABI
    const tokenAddress = "ERC20_CONTRACT_ADDRESS";
    const tokenAbi = [
        "function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external",
        "function transferFrom(address from, address to, uint256 value) external returns (bool)"
    ];
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, wallet);

    // 设定参数
    const owner = wallet.address;
    const spender = "SPENDER_ADDRESS";
    const value = ethers.utils.parseUnits("10", 18); // 10 tokens
    const nonce = 0; // 获取当前nonce
    const deadline = Math.floor(Date.now() / 1000) + 60 * 60; // 1小时后过期

    // DOMAIN_SEPARATOR和PERMIT_TYPEHASH的计算
    const DOMAIN_SEPARATOR = keccak256(
        defaultAbiCoder.encode(
            ["bytes32", "bytes32", "bytes32", "uint256", "address"],
            [
                keccak256(toUtf8Bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")),
                keccak256(toUtf8Bytes("YourTokenName")),
                keccak256(toUtf8Bytes("1")),
                3, // Ropsten的chainId
                tokenAddress
            ]
        )
    );

    const PERMIT_TYPEHASH = keccak256(
        toUtf8Bytes("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    );

    // 计算签名哈希
    const structHash = keccak256(
        defaultAbiCoder.encode(
            ["bytes32", "address", "address", "uint256", "uint256", "uint256"],
            [PERMIT_TYPEHASH, owner, spender, value, nonce, deadline]
        )
    );

    const digest = keccak256(
        solidityPack(
            ["bytes1", "bytes1", "bytes32", "bytes32"],
            ["\x19", "\x01", DOMAIN_SEPARATOR, structHash]
        )
    );

    // 使用钱包签名
    const signature = await wallet.signMessage(ethers.utils.arrayify(digest));
    const { v, r, s } = ethers.utils.splitSignature(signature);

    // 调用permit
    const tx = await tokenContract.permit(owner, spender, value, deadline, v, r, s);
    await tx.wait();

    console.log("Permit成功，授权转账");

    // 进行转账
    const transferTx = await tokenContract.transferFrom(owner, spender, value);
    await transferTx.wait();

    console.log("转账成功");
}

permitAndTransfer().catch(console.error);