// module nft::personal_kiosk {

//     use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
//     use sui::tx_context::sender;
//     use sui::dynamic_field as df;
//     use sui::event;
//     use sui::object;
//     use sui::transfer;
//     use std::option::{Self, Option};
//     use sui::tx_context::TxContext;

//     const EIncorrectCapObject: u64 = 0;
//     const EIncorrectOwnedObject: u64 = 1;
//     const EKioskNotOwned: u64 = 2;
//     const EWrongKiosk: u64 = 3;

//     /// A personal wrapper around a KioskOwnerCap
//     public struct PersonalKioskCap has key, store {
//         id: UID,
//         cap: Option<KioskOwnerCap>
//     }

//     /// Struct to return IDs instead of actual objects in entry
//     public struct PersonalKioskInfo has copy, drop, store {
//         kiosk_id: ID,
//         cap_id: ID
//     }

//     public struct Borrow { cap_id: ID, owned_id: ID }
//     public struct OwnerMarker has copy, store, drop {}
//     public struct NewPersonalKiosk has copy, drop { kiosk_id: ID }

//     /// Entry for backwards compatibility
//     public entry fun default(kiosk: &mut Kiosk, cap: KioskOwnerCap, ctx: &mut TxContext) {
//         transfer_to_sender(new(kiosk, cap, ctx), ctx);
//     }

//     /// Entry that creates the cap and returns the IDs
//   public entry fun create_and_return_ids(kiosk: &mut Kiosk, cap: KioskOwnerCap, ctx: &mut TxContext): PersonalKioskInfo {
//     let personal_cap = new(kiosk, cap, ctx);
//     let info = PersonalKioskInfo {
//         kiosk_id: object::id(kiosk),
//         cap_id: object::id(&personal_cap),
//     };
//     transfer::transfer(personal_cap, sender(ctx));
//     info
// }


//     public fun new(kiosk: &mut Kiosk, cap: KioskOwnerCap, ctx: &mut TxContext): PersonalKioskCap {
//         create(kiosk, cap, sender(ctx), ctx)
//     }

//     public fun create_for(kiosk: &mut Kiosk, cap: KioskOwnerCap, recipient: address, ctx: &mut TxContext) {
//         let personal_owner_cap = create(kiosk, cap, recipient, ctx);
//         transfer::transfer(personal_owner_cap, recipient)
//     }

//     fun create(kiosk: &mut Kiosk, cap: KioskOwnerCap, owner: address, ctx: &mut TxContext): PersonalKioskCap {
//         assert!(kiosk::has_access(kiosk, &cap), EWrongKiosk);

//         kiosk::set_owner_custom(kiosk, &cap, owner);

//         df::add(kiosk::uid_mut_as_owner(kiosk, &cap), OwnerMarker {}, owner);

//         event::emit(NewPersonalKiosk {
//             kiosk_id: object::id(kiosk)
//         });

//         PersonalKioskCap {
//             id: object::new(ctx),
//             cap: option::some(cap)
//         }
//     }

//     public fun borrow(self: &PersonalKioskCap): &KioskOwnerCap {
//         option::borrow(&self.cap)
//     }

//     public fun borrow_mut(self: &mut PersonalKioskCap): &mut KioskOwnerCap {
//         option::borrow_mut(&mut self.cap)
//     }

//     public fun borrow_val(self: &mut PersonalKioskCap): (KioskOwnerCap, Borrow) {
//         let cap = option::extract(&mut self.cap);
//         let id = object::id(&cap);

//         (cap, Borrow {
//             owned_id: object::id(self),
//             cap_id: id
//         })
//     }

//     public fun return_val(self: &mut PersonalKioskCap, cap: KioskOwnerCap, borrow: Borrow) {
//         let Borrow { owned_id, cap_id } = borrow;
//         assert!(object::id(self) == owned_id, EIncorrectOwnedObject);
//         assert!(object::id(&cap) == cap_id, EIncorrectCapObject);

//         option::fill(&mut self.cap, cap)
//     }

//     public fun is_personal(kiosk: &Kiosk): bool {
//         df::exists_(kiosk::uid(kiosk), OwnerMarker {})
//     }

//     public fun owner(kiosk: &Kiosk): address {
//         assert!(is_personal(kiosk), EKioskNotOwned);
//         *df::borrow(kiosk::uid(kiosk), OwnerMarker {})
//     }

//     public fun try_owner(kiosk: &Kiosk): Option<address> {
//         if (is_personal(kiosk)) {
//             option::some(owner(kiosk))
//         } else {
//             option::none()
//         }
//     }

//     public fun transfer_to_sender(self: PersonalKioskCap, ctx: &mut TxContext) {
//         transfer::transfer(self, sender(ctx));
//     }
// }















// //extension for wrapping the kiosk object with a personal owner cap 
module nft::personal_kiosk {
    
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
   
    use sui::tx_context::{sender};
    use sui::dynamic_field as df;

   
    const EIncorrectCapObject: u64 = 0;
   
    const EIncorrectOwnedObject: u64 = 1;
   
    const EKioskNotOwned: u64 = 2;
   
    const EWrongKiosk: u64 = 3;

    
    public struct PersonalKioskCap has key {
        id: UID,
        cap: Option<KioskOwnerCap>
    }

    
   public struct Borrow { cap_id: ID, owned_id: ID }
    public struct OwnerMarker has copy, store, drop {}
    public struct NewPersonalKiosk has copy, drop { kiosk_id: ID }

    public entry fun default(kiosk: &mut Kiosk, cap: KioskOwnerCap, ctx: &mut TxContext) {
        transfer_to_sender(new(kiosk, cap, ctx), ctx);
    }

    
    public fun new(
        kiosk: &mut Kiosk, cap: KioskOwnerCap, ctx: &mut TxContext
    ): PersonalKioskCap {
        create(kiosk, cap, sender(ctx), ctx)
    }

   
    public fun create_for(
        kiosk: &mut Kiosk, cap: KioskOwnerCap, recipient: address, ctx: &mut TxContext
    ) {
        let personal_owner_cap = create(kiosk, cap, recipient, ctx);
        transfer::transfer(personal_owner_cap, recipient)
    }

    
    fun create(
        kiosk: &mut Kiosk, cap: KioskOwnerCap, owner: address, ctx: &mut TxContext
    ): PersonalKioskCap {
        assert!(kiosk::has_access(kiosk, &cap), EWrongKiosk);

      
        kiosk::set_owner_custom(kiosk, &cap, owner);

        df::add(
            kiosk::uid_mut_as_owner(kiosk, &cap),
            OwnerMarker {},
            owner
        );

        sui::event::emit(NewPersonalKiosk {
            kiosk_id: object::id(kiosk)
        });

        
        PersonalKioskCap {
            id: object::new(ctx),
            cap: option::some(cap)
        }
    }

  
    public fun borrow(self: &PersonalKioskCap): &KioskOwnerCap {
        option::borrow(&self.cap)
    }

  
    public fun borrow_mut(self: &mut PersonalKioskCap): &mut KioskOwnerCap {
        option::borrow_mut(&mut self.cap)
    }


    public fun borrow_val(
        self: &mut PersonalKioskCap
    ): (KioskOwnerCap, Borrow) {
        let cap = option::extract(&mut self.cap);
        let id = object::id(&cap);

        (cap, Borrow {
            owned_id: object::id(self),
            cap_id: id
        })
    }

    public fun return_val(
        self: &mut PersonalKioskCap, cap: KioskOwnerCap, borrow: Borrow
    ) {
        let Borrow { owned_id, cap_id } = borrow;
        assert!(object::id(self) == owned_id, EIncorrectOwnedObject);
        assert!(object::id(&cap) == cap_id, EIncorrectCapObject);

        option::fill(&mut self.cap, cap)
    }

    
    public fun is_personal(kiosk: &Kiosk): bool {
        df::exists_(kiosk::uid(kiosk), OwnerMarker {})
    }

    
    public fun owner(kiosk: &Kiosk): address {
        assert!(is_personal(kiosk), EKioskNotOwned);
        *df::borrow(kiosk::uid(kiosk), OwnerMarker {})
    }

    public fun try_owner(kiosk: &Kiosk): Option<address> {
        if (is_personal(kiosk)) {
            option::some(owner(kiosk))
        } else {
            option::none()
        }
    }

  
    public fun transfer_to_sender(self: PersonalKioskCap, ctx: &mut TxContext) {
        transfer::transfer(self, sender(ctx));
    }
}