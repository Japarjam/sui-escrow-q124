module defi::escrow {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// Object held in Escrow 
struct MakerObj<T:key + store, phantom: TakerObj: key + store> has key, store {
    id: UID,
    maker: address, 
    taker: address,
    taker_obj: ID,
    maker_obj: T,
}

const EMismatchMakerTaker: u64 = 0;
const EMismatchedExchangeObj: u64 = 1; 

pub fun create<T: key + store, TakerObj: key + store>(
    taker: address, 
    vault: address,
    taker_obj: ID, 
    maker_obj: T,
    ctx: &mut TxContext
)

{
    let maker = tx_context::maker(ctx);
    let id = object::new(ctx);
    transfer::public_transfer(
        MakerObj<T, TakerObj>{
            id, maker, taker, taker_obj, maker_obj
        },
        vault
    );
}

public entry fun swap<T1: key + store, T2: key + store>(
    obj1: MakerObj<T1, T2>,
    obj2: MakerObj<T2, T1>, 
){
    let MakerObj {
        id: id1, 
        maker: maker1,
        taker: taker1, 
        taker_obj: taker_obj1,
        maker_obj: maker_obj1, 
    }= obj1;

     let MakerObj {
        id: id2, 
        maker: maker2,
        taker: taker2, 
        taker_obj: taker_obj2,
        maker_obj: maker_obj2, 
    }= obj2;
    object::delete(id1);
    object::delete(id1);

    assert!(&maker1 == &taker2, EMismatchMakerTaker);
    assert!(&maker2 == &taker1, EMismatchMakerTaker);

    assert!(object::id(&maker_obj1)==taker_obj2, EMismatchedExchangeObj);
    assert!(object::id(&maker_obj2)==taker_obj1, EMismatchedExchangeObj);

    transfer::public_transfer(maker_obj1, maker2);
    transfer::public_transfer(maker_obj2, maker1);
}

public entry fun refund<T: key + store, TakerObj: key + store>(
    obj: MakerObj<T,TakerObj>,
) {
    let MakerObj {
        id, maker, taker: _, taker_obj: _, maker_obj
    } = obj;
    object::delete(id);
    transfer::public_transfer(MakerObj, maker);
    }

}