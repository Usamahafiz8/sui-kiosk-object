#[allow(lint(share_owned), lint(self_transfer), duplicate_alias)]
module nft::kiosk_nft {
    use std::string::{Self, String};
    use sui::display;
    use sui::package::{Self, Publisher};
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::kiosk::{ Kiosk};
    use sui::transfer_policy::{
        Self as policy,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest
    };
    use sui::coin::{ Coin};
    use sui::sui::SUI;
    use nft::personal_kiosk_rule;
    use nft::kiosk_lock_rule;
    use nft::royalty_rule;
    use nft::witness_rule;

    const EWrongVersion: u64 = 0;
    const EExceedsMintSupply: u64 = 2;
    const ENotAuthorized: u64 = 3;
    const VERSION: u64 = 1;

    // One-time witness for initializing the publisher
    public struct KIOSK_NFT has drop {}

    // Witness for the witness_rule
    public struct Witness has drop {}

    // Represents the NFT
    public struct Nft has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String,
        creator: address,
        mint_number: u64,
        rarity: String,
    }

    // Tracks NFT collection details and mint count
    public struct Collection has key, store {
        id: UID,
        version: u64,
        mint_supply: u64,
        minted: u64,
        creator: address,
    }

    // Initialize the module with Display and TransferPolicy
  fun init(witness: KIOSK_NFT, ctx: &mut TxContext) {
    let publisher = package::claim(witness, ctx);

    // Set up Display for Nft
    let mut display = display::new<Nft>(&publisher, ctx);
    display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name} #{mint_number}"));
    display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
    display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
    display::add(&mut display, string::utf8(b"creator"), string::utf8(b"{creator}"));
    display::add(&mut display, string::utf8(b"rarity"), string::utf8(b"{rarity}"));
    display::update_version(&mut display);
    transfer::public_share_object(display);

    // Create and share TransferPolicy for Nft
    let (mut policy, cap) = policy::new<Nft>(&publisher, ctx); // Declare policy as mutable
    // Add personal_kiosk_rule
    personal_kiosk_rule::add(&mut policy, &cap);
    // Add kiosk_lock_rule
    kiosk_lock_rule::add(&mut policy, &cap);
    // Add royalty_rule with 10% (1000 basis points) and 1000 SUI minimum
    royalty_rule::add(&mut policy, &cap, 1000, 1000);
    // Add witness_rule with Witness type
    witness_rule::add<Nft, Witness>(&mut policy, &cap);
    transfer::public_share_object(policy);
    transfer::public_transfer(cap, tx_context::sender(ctx));

    // Transfer publisher to sender
    transfer::public_transfer(publisher, tx_context::sender(ctx));
}
    public fun create_collection(
        _publisher: &Publisher,
        mint_supply: u64,
        ctx: &mut TxContext
    ): Collection {
        Collection {
            id: object::new(ctx),
            version: VERSION,
            mint_supply,
            minted: 0,
            creator: tx_context::sender(ctx),
        }
    }

    public fun mint_nft(
        collection: &mut Collection,
        name: String,
        description: String,
        image_url: String,
        rarity: String,
        ctx: &mut TxContext
    ): Nft {
        assert!(collection.version == VERSION, EWrongVersion);
        assert!(collection.minted < collection.mint_supply, EExceedsMintSupply);
        assert!(collection.creator == tx_context::sender(ctx), ENotAuthorized);

        collection.minted = collection.minted + 1;
        let nft = Nft {
            id: object::new(ctx),
            name,
            description,
            image_url,
            creator: collection.creator,
            mint_number: collection.minted,
            rarity,
        };
        nft
    }

    // Update the mint supply of a collection
    public fun update_mint_supply(
        collection: &mut Collection,
        new_supply: u64,
        ctx: &mut TxContext
    ) {
        assert!(collection.creator == tx_context::sender(ctx), ENotAuthorized);
        assert!(collection.minted <= new_supply, EExceedsMintSupply);
        collection.mint_supply = new_supply;
    }

    // Get the number of NFTs minted in a collection
    public fun get_minted_count(collection: &Collection): u64 {
        collection.minted
    }

    // Buyer action: Prove personal_kiosk_rule
    public fun prove_personal_kiosk_rule(
        kiosk: &Kiosk,
        _policy: &mut TransferPolicy<Nft>,
        request: &mut TransferRequest<Nft>
    ) {
        personal_kiosk_rule::prove(kiosk, request);
    }

    // Buyer action: Prove kiosk_lock_rule
    public fun prove_kiosk_lock_rule(
        kiosk: &Kiosk,
        _policy: &mut TransferPolicy<Nft>,
        request: &mut TransferRequest<Nft>
    ) {
        kiosk_lock_rule::prove(request, kiosk);
    }

    // Buyer action: Pay royalty fee and prove royalty_rule
    public fun pay_royalty_rule(
        policy: &mut TransferPolicy<Nft>,
        request: &mut TransferRequest<Nft>,
        payment: Coin<SUI>,
    ) {
        royalty_rule::pay(policy, request, payment);
    }

    // Buyer action: Prove witness_rule with Witness
    public fun prove_witness_rule(
        policy: &TransferPolicy<Nft>,
        request: &mut TransferRequest<Nft>
    ) {
        witness_rule::prove<Nft, Witness>(Witness {}, policy, request);
    }

    // Helper function to calculate royalty fee amount
    public fun get_royalty_fee_amount(policy: &TransferPolicy<Nft>, paid: u64): u64 {
        royalty_rule::fee_amount(policy, paid)
    }
}


















































//just collection and nft minting, no transfer policies
// #[allow(lint(share_owned), lint(self_transfer), duplicate_alias)]
// module nft::kiosk_nft {
//     use std::string::{Self, String};
//     use sui::display;
//     use sui::package::{Self, Publisher};
//     use sui::tx_context::{Self, TxContext};
//     use sui::object::{Self, UID};
//     use sui::transfer;

//     const EWrongVersion: u64 = 0;
//     const EExceedsMintSupply: u64 = 2;
//     const ENotAuthorized: u64 = 3;
//     const VERSION: u64 = 1;

//     // One-time witness for initializing the publisher
//     public struct KIOSK_NFT has drop {}

//     // Represents the NFT
//     public struct Nft has key, store {
//         id: UID,
//         name: String,
//         description: String,
//         image_url: String,
//         creator: address,
//         mint_number: u64,
//         rarity: String,
//     }

//     // Tracks NFT collection details and mint count
//     public struct Collection has key, store {
//         id: UID,
//         version: u64,
//         mint_supply: u64,
//         minted: u64,
//         creator: address,
//     }

//     // Initialize the module with Display
//     fun init(witness: KIOSK_NFT, ctx: &mut TxContext) {
//         let publisher = package::claim(witness, ctx);

//         // Set up Display for Nft
//         let mut display = display::new<Nft>(&publisher, ctx);
//         display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name} #{mint_number}"));
//         display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
//         display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
//         display::add(&mut display, string::utf8(b"creator"), string::utf8(b"{creator}"));
//         display::add(&mut display, string::utf8(b"rarity"), string::utf8(b"{rarity}"));
//         display::update_version(&mut display);
//         transfer::public_share_object(display);

//         // Transfer publisher to sender
//         transfer::public_transfer(publisher, tx_context::sender(ctx));
//     }

//     public fun create_collection(
//         _publisher: &Publisher,
//         mint_supply: u64,
//         ctx: &mut TxContext
//     ): Collection {
//         Collection {
//             id: object::new(ctx),
//             version: VERSION,
//             mint_supply,
//             minted: 0,
//             creator: tx_context::sender(ctx),
//         }
//     }

//     public fun mint_nft(
//         collection: &mut Collection,
//         name: String,
//         description: String,
//         image_url: String,
//         rarity: String,
//         ctx: &mut TxContext
//     ): Nft {
//         assert!(collection.version == VERSION, EWrongVersion);
//         assert!(collection.minted < collection.mint_supply, EExceedsMintSupply);
//         assert!(collection.creator == tx_context::sender(ctx), ENotAuthorized);

//         collection.minted = collection.minted + 1;
//         let nft = Nft {
//             id: object::new(ctx),
//             name,
//             description,
//             image_url,
//             creator: collection.creator,
//             mint_number: collection.minted,
//             rarity,
//         };
//         nft
//     }

//     // Update the mint supply of a collection
//     public fun update_mint_supply(
//         collection: &mut Collection,
//         new_supply: u64,
//         ctx: &mut TxContext
//     ) {
//         assert!(collection.creator == tx_context::sender(ctx), ENotAuthorized);
//         assert!(collection.minted <= new_supply, EExceedsMintSupply);
//         collection.mint_supply = new_supply;
//     }

//     // Get the number of NFTs minted in a collection
//     public fun get_minted_count(collection: &Collection): u64 {
//         collection.minted
//     }
// }