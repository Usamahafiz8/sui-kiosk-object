module nft::kiosk_nft {
    use std::string::{Self, String};
    use sui::display;
    use sui::package::{Self, Publisher};
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::kiosk::{Kiosk};
    use sui::transfer_policy::{Self as policy, TransferPolicy, TransferPolicyCap, TransferRequest};
    use sui::coin::{Coin};
    use sui::sui::SUI;
    use kiosk::personal_kiosk_rule;
    use kiosk::kiosk_lock_rule;
    use kiosk::royalty_rule;
    const EWrongVersion: u64 = 0;
    const EExceedsMintSupply: u64 = 2;
    const ENotAuthorized: u64 = 3;
    const VERSION: u64 = 1;
    public struct KIOSK_NFT has drop {}
    public struct Nft has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String,
        creator: address,
        mint_number: u64,
        rarity: String,
    }
    public struct Collection has key, store {
        id: UID,
        version: u64,
        mint_supply: u64,
        minted: u64,
        creator: address,
    }
    fun init(witness: KIOSK_NFT, ctx: &mut TxContext) {
        let publisher = package::claim(witness, ctx);
        let mut display = display::new<Nft>(&publisher, ctx);
        display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name} #{mint_number}"));
        display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::add(&mut display, string::utf8(b"creator"), string::utf8(b"{creator}"));
        display::add(&mut display, string::utf8(b"rarity"), string::utf8(b"{rarity}"));
        display::update_version(&mut display);
        transfer::public_share_object(display);
        let (mut policy, cap) = policy::new<Nft>(&publisher, ctx);
        personal_kiosk_rule::add(&mut policy, &cap);
        kiosk_lock_rule::add(&mut policy, &cap);
        royalty_rule::add(&mut policy, &cap, 1000, 1000);
        transfer::public_share_object(policy);
        transfer::public_transfer(cap, tx_context::sender(ctx));
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
    public fun update_mint_supply(
        collection: &mut Collection,
        new_supply: u64,
        ctx: &mut TxContext
    ) {
        assert!(collection.creator == tx_context::sender(ctx), ENotAuthorized);
        assert!(collection.minted <= new_supply, EExceedsMintSupply);
        collection.mint_supply = new_supply;
    }
    public fun get_minted_count(collection: &Collection): u64 {
        collection.minted
    }
    public fun prove_personal_kiosk_rule(
        kiosk: &Kiosk,
        _policy: &mut TransferPolicy<Nft>,
        request: &mut TransferRequest<Nft>
    ) {
        personal_kiosk_rule::prove(kiosk, request);
    }
    public fun prove_kiosk_lock_rule(
        kiosk: &Kiosk,
        _policy: &mut TransferPolicy<Nft>,
        request: &mut TransferRequest<Nft>
    ) {
        kiosk_lock_rule::prove(request, kiosk);
    }
    public fun pay_royalty_rule(
        policy: &mut TransferPolicy<Nft>, 
        request: &mut TransferRequest<Nft>,
        payment: Coin<SUI>,
    ) {
        royalty_rule::pay(policy, request, payment);
    }
    public fun get_royalty_fee_amount(policy: &TransferPolicy<Nft>, paid: u64): u64 {
        royalty_rule::fee_amount(policy, paid)
    }
}