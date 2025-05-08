import { ethers, Interface, BytesLike, Contract } from "ethers";
import path from "path";
import { readdirSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import * as dotenv from "dotenv";
// import { abi } from "./abi.js";
dotenv.config();

// based on https://github.com/paritytech/contracts-boilerplate/tree/e86ffe91f7117faf21378395686665856c605132/ethers/tools
console.log("ACCOUNT_SEED:", process.env.ACCOUNT_SEED);
console.log("RPC_URL:", process.env.RPC_URL);

const privateKey = process.env.ACCOUNT_SEED;
const rpcUrl = process.env.RPC_URL;

if (!process.env.ACCOUNT_SEED) {
  console.error(
    "ACCOUNT_SEED environment variable is required for deploying smart contract"
  );
  process.exit(1);
}

if (!process.env.RPC_URL) {
  console.error(
    "RPC_URL environment variable is required for deploying smart contract"
  );
  process.exit(1);
}

const provider = new ethers.JsonRpcProvider(rpcUrl);
const wallet = new ethers.Wallet(privateKey as string, provider);

console.log("\n=== DEPLOYMENT INFO ===");
console.log("\nDeploying with address:", wallet.address);
console.log("Connected to RPC:", rpcUrl);

const buildDir = ".build";
const contractsOutDir = path.join(buildDir, "contracts");
const deploysDir = path.join(".deploys", "deployed-contracts");
mkdirSync(deploysDir, { recursive: true });

const contracts = readdirSync(contractsOutDir).filter((f) =>
  f.endsWith(".json")
);

type ContractType = {
  abi: Interface;
  bytecode: BytesLike;
};

(async () => {
  ///////////////////////////////////////
  /// SoftLawDAONFT DEPLOY SCRIPT ////////
  ///////////////////////////////////////
  const contractName = "SoftLawDAO";
  const contract = contracts.find((file) => file.startsWith(contractName));

  if (contract) {
    const name = path.basename(contract, ".json");
    const contractData = JSON.parse(
      readFileSync(path.join(contractsOutDir, contract), "utf8")
    ) as ContractType;
    const factory = new ethers.ContractFactory(
      contractData.abi,
      contractData.bytecode,
      wallet
    );

    console.log(`Deploying contract ${name}...`);
    const SoftLawDAO = await factory.deploy(
      "test", //name
      "test", // description
      1, // voting quorum
      60, // locking period
      "test", // token name
      "test", // token symbol
      10000 // initial token supply
    );
    await SoftLawDAO.waitForDeployment();
    const address = await SoftLawDAO.getAddress();

    console.log(`✅ Deployed ${contractName} at ${address}`);

    const fileContent = JSON.stringify({
      name,
      address,
      abi: contractData.abi,
      deployedAt: Date.now(),
    });
    writeFileSync(path.join(deploysDir, `${address}.json`), fileContent);

    ////// TEST FUNCTIONS ////
    ////// CREATE TREASURY PROPOSAL ///
    console.log("Creating a treasury proposal...");

    const dao = new Contract(address, contractData.abi, wallet);

    // Llamar a la función
    const tx = await dao.createTreasuryProposal(
      "DAO Funding",
      "Proposal to fund devs",
      "0x1234567890abcdef1234567890abcdef12345678",
      ethers.parseUnits("10", 18)
    );
    await tx.wait();
  } else {
    console.log(`Contract ${contractName} not found.`);
  }
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
