
import MyNFTContract from 0x01

// This transaction is what an account would run
// to set itself up to receive NFTs

transaction {

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&MyNFTContract.Collection>(from: MyNFTContract.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- MyNFTContract.createEmptyCollection()

        // save it to the account
        signer.save(<-collection, to: MyNFTContract.CollectionStoragePath) 

        // create a public capability for the collection
        signer.link<&{MyNFTContract.NFTReceiver}>(
            MyNFTContract.CollectionPublicPath,
            target: MyNFTContract.CollectionStoragePath
        ) ?? panic("Could not borrow minter reference")
    }
}
