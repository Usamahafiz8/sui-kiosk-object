import { Transaction } from "@mysten/sui/transactions";
import { SuiClient } from "@mysten/sui/client";
import dotenv from "dotenv";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

// Configure dotenv
dotenv.config();

// Configuration
const SUI_NETWORK: string = process.env.SUI_NETWORK || "https://fullnode.mainnet.sui.io";
const client: SuiClient = new SuiClient({ url: SUI_NETWORK });

// Utility function to derive signer from mnemonic
async function getSigner(): Promise<Ed25519Keypair> {
  const mnemonic: string | undefined = process.env.MNEMONIC;
  if (!mnemonic) {
    throw new Error("MNEMONIC not set in .env");
  }
  const keypair: Ed25519Keypair = Ed25519Keypair.deriveKeypair(mnemonic);
  return keypair;
}

async function createCollectionAndMintNFT() {
  const packageID: string | undefined = process.env.PACKAGE_ID;
  if (!packageID) {
    throw new Error("Missing PACKAGE_ID in .env");
  }

  const signer: Ed25519Keypair = await getSigner();
  const signerAddress: string = await signer.toSuiAddress();

  // Step 1: Create Collection
  const tx1: Transaction = new Transaction();
  tx1.setGasBudget(100000000);
  
  // Create collection with mint supply of 1000
  const collectionResult = tx1.moveCall({
    target: `${packageID}::kiosk_nft::create_collection`,
    arguments: [
      tx1.object(packageID), // publisher
      tx1.pure(1000), // mint_supply
    ],
  });

  // Transfer collection to sender
  tx1.transferObjects([collectionResult], signerAddress);

  console.log("Creating collection...");
  const result1 = await client.signAndExecuteTransaction({
    transaction: tx1,
    signer: signer,
    options: {
      showEffects: true,
      showObjectChanges: true,
    },
  });

  if (result1.effects?.status.status !== "success") {
    throw new Error(`Collection creation failed: ${JSON.stringify(result1.effects?.status)}`);
  }

  // Get collection ID from the created objects
  const collectionID = result1.effects.created?.find(
    (obj) => obj.owner?.AddressOwner === signerAddress
  )?.reference.objectId;

  if (!collectionID) {
    throw new Error("Failed to get collection ID");
  }

  console.log("Collection created successfully:", collectionID);

  // Step 2: Mint NFT
  const tx2: Transaction = new Transaction();
  tx2.setGasBudget(100000000);

  // Mint NFT with metadata
  const nftResult = tx2.moveCall({
    target: `${packageID}::kiosk_nft::mint_nft`,
    arguments: [
      tx2.object(collectionID),
      tx2.pure("Tradeport NFT #1"), // name
      tx2.pure("A unique NFT for Tradeport"), // description
      tx2.pure("https://example.com/nft-image.jpg"), // image_url
      tx2.pure("Rare"), // rarity
    ],
  });

  // Transfer NFT to sender
  tx2.transferObjects([nftResult], signerAddress);

  console.log("Minting NFT...");
  const result2 = await client.signAndExecuteTransaction({
    transaction: tx2,
    signer: signer,
    options: {
      showEffects: true,
      showObjectChanges: true,
    },
  });

  if (result2.effects?.status.status !== "success") {
    throw new Error(`NFT minting failed: ${JSON.stringify(result2.effects?.status)}`);
  }

  // Get NFT ID from the created objects
  const nftID = result2.effects.created?.find(
    (obj) => obj.owner?.AddressOwner === signerAddress
  )?.reference.objectId;

  if (!nftID) {
    throw new Error("Failed to get NFT ID");
  }

  console.log("NFT minted successfully:", nftID);
  return { collectionID, nftID };
}

// Execute
createCollectionAndMintNFT().then(console.log).catch(console.error); 