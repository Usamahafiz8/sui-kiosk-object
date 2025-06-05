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

async function listNFTOnTradeport() {
  const packageID: string | undefined = process.env.PACKAGE_ID;
  if (!packageID) {
    throw new Error("Missing PACKAGE_ID in .env");
  }

  const signer: Ed25519Keypair = await getSigner();
  const signerAddress: string = await signer.toSuiAddress();

  // Step 1: Create Kiosk
  const tx1: Transaction = new Transaction();
  tx1.setGasBudget(100000000);

  // Create kiosk
  const kioskResult = tx1.moveCall({
    target: "0x2::kiosk::new",
    arguments: [],
  });

  const kiosk = tx1.object(kioskResult[0]);
  const kioskOwnerCap = tx1.object(kioskResult[1]);

  // Share kiosk
  tx1.moveCall({
    target: "0x2::transfer::public_share_object",
    arguments: [kiosk],
    typeArguments: ["0x2::kiosk::Kiosk"],
  });

  // Transfer kiosk owner cap to sender
  tx1.transferObjects([kioskOwnerCap], signerAddress);

  console.log("Creating kiosk...");
  const result1 = await client.signAndExecuteTransaction({
    transaction: tx1,
    signer: signer,
    options: {
      showEffects: true,
      showObjectChanges: true,
    },
  });

  if (result1.effects?.status.status !== "success") {
    throw new Error(`Kiosk creation failed: ${JSON.stringify(result1.effects?.status)}`);
  }

  // Get kiosk ID and owner cap ID
  const kioskID = result1.effects.created?.find(
    (obj) => "Shared" in (obj.owner || {})
  )?.reference.objectId;

  const kioskOwnerCapID = result1.effects.created?.find(
    (obj) => obj.owner?.AddressOwner === signerAddress
  )?.reference.objectId;

  if (!kioskID || !kioskOwnerCapID) {
    throw new Error("Failed to get kiosk ID or owner cap ID");
  }

  console.log("Kiosk created successfully:", kioskID);
  console.log("Kiosk owner cap created successfully:", kioskOwnerCapID);

  // Step 2: Place NFT in Kiosk
  const tx2: Transaction = new Transaction();
  tx2.setGasBudget(100000000);

  // Place NFT in kiosk
  tx2.moveCall({
    target: "0x2::kiosk::place",
    arguments: [
      tx2.object(kioskID),
      tx2.object(kioskOwnerCapID),
      tx2.object(process.env.NFT_ID || ""), // NFT ID from .env
    ],
    typeArguments: [`${packageID}::kiosk_nft::Nft`],
  });

  console.log("Placing NFT in kiosk...");
  const result2 = await client.signAndExecuteTransaction({
    transaction: tx2,
    signer: signer,
    options: {
      showEffects: true,
      showObjectChanges: true,
    },
  });

  if (result2.effects?.status.status !== "success") {
    throw new Error(`NFT placement failed: ${JSON.stringify(result2.effects?.status)}`);
  }

  console.log("NFT placed in kiosk successfully");

  // Step 3: List NFT for sale
  const tx3: Transaction = new Transaction();
  tx3.setGasBudget(100000000);

  // List NFT for sale with price in SUI
  tx3.moveCall({
    target: "0x2::kiosk::list",
    arguments: [
      tx3.object(kioskID),
      tx3.object(kioskOwnerCapID),
      tx3.object(process.env.NFT_ID || ""), // NFT ID from .env
      tx3.pure(1000000000), // Price in MIST (1 SUI = 1_000_000_000 MIST)
    ],
    typeArguments: [`${packageID}::kiosk_nft::Nft`],
  });

  console.log("Listing NFT for sale...");
  const result3 = await client.signAndExecuteTransaction({
    transaction: tx3,
    signer: signer,
    options: {
      showEffects: true,
      showObjectChanges: true,
    },
  });

  if (result3.effects?.status.status !== "success") {
    throw new Error(`NFT listing failed: ${JSON.stringify(result3.effects?.status)}`);
  }

  console.log("NFT listed for sale successfully");
  return { kioskID, kioskOwnerCapID };
}

// Execute
listNFTOnTradeport().then(console.log).catch(console.error); 