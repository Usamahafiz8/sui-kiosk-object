import { Transaction } from "@mysten/sui/transactions";
import { SuiClient } from "@mysten/sui/client";
import dotenv from "dotenv";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

// Configure dotenv
dotenv.config();

const client = new SuiClient({ url: process.env.SUI_NETWORK || "https://fullnode.mainnet.sui.io" });

// Utility function to get signer from mnemonic
function getSigner() {
    const mnemonic = process.env.MNEMONIC;
    if (!mnemonic) throw new Error("MNEMONIC not found in .env");
    return Ed25519Keypair.deriveKeypair(mnemonic);
}

async function createKioskAndListNFT() {
    const signer = getSigner();
    const packageId = process.env.PACKAGE_ID;
    const nftId = process.env.NFT_ID;

    if (!packageId) throw new Error('PACKAGE_ID not found in .env');
    if (!nftId) throw new Error('NFT_ID not found in .env');

    try {
        // Step 1: Create a new kiosk
        console.log('Creating new kiosk...');
        const createKioskTx = new Transaction()
            .moveCall({
                target: '0x2::kiosk::new',
                arguments: []
            });

        const createKioskResult = await client.signAndExecuteTransaction({
            signer,
            transaction: createKioskTx,
            options: {
                showEffects: true,
                showEvents: true
            }
        });

        if (createKioskResult.effects?.status.status !== 'success') {
            throw new Error('Failed to create kiosk');
        }

        // Get kiosk and kiosk owner cap IDs from the transaction
        const kioskId = createKioskResult.effects.created?.[0].reference.objectId;
        const kioskOwnerCapId = createKioskResult.effects.created?.[1].reference.objectId;

        if (!kioskId || !kioskOwnerCapId) {
            throw new Error('Failed to get kiosk IDs');
        }

        console.log('Kiosk created successfully!');
        console.log('Kiosk ID:', kioskId);
        console.log('Kiosk Owner Cap ID:', kioskOwnerCapId);

        // Step 2: Place NFT in kiosk
        console.log('\nPlacing NFT in kiosk...');
        const placeNFTTx = new Transaction()
            .moveCall({
                target: '0x2::kiosk::place',
                typeArguments: [`${packageId}::kiosk_nft::Nft`],
                arguments: [kioskId, kioskOwnerCapId, nftId]
            });

        const placeNFTResult = await client.signAndExecuteTransaction({
            signer,
            transaction: placeNFTTx,
            options: {
                showEffects: true,
                showEvents: true
            }
        });

        if (placeNFTResult.effects?.status.status !== 'success') {
            throw new Error('Failed to place NFT in kiosk');
        }

        console.log('NFT placed in kiosk successfully!');

        // Step 3: List NFT for sale (1 SUI = 1000000000 MIST)
        console.log('\nListing NFT for sale...');
        const listNFTTx = new Transaction()
            .moveCall({
                target: '0x2::kiosk::list',
                typeArguments: [`${packageId}::kiosk_nft::Nft`],
                arguments: [kioskId, kioskOwnerCapId, nftId, '1000000000'] // 1 SUI
            });

        const listNFTResult = await client.signAndExecuteTransaction({
            signer,
            transaction: listNFTTx,
            options: {
                showEffects: true,
                showEvents: true
            }
        });

        if (listNFTResult.effects?.status.status !== 'success') {
            throw new Error('Failed to list NFT');
        }

        console.log('NFT listed for sale successfully!');
        console.log('Price: 1 SUI');

    } catch (error) {
        console.error('Error:', error);
    }
}

createKioskAndListNFT(); 