import MyNFTContract from 0x01
import MyToken from 0x02

transaction( _name: String,
    _description: String,
    _uri: String) {

    let receiverRef: &{MyNFTContract.NFTReceiver}
    let minterRef: &MyNFTContract.NFTMinter
    let receiverToken: &{MyToken.Receiver}

    prepare(acct: AuthAccount) {

        let account = getAccount(0x01)

        if acct.borrow<&MyToken.Vault>(from: MyToken.TokenValultStoragePath) == nil {
            // Create a new ExampleToken Vault and put it in storage
            acct.save(
                <-MyToken.createEmptyVault(),
                to: MyToken.TokenValultStoragePath
            )

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            acct.link<&MyToken.Vault{MyToken.Receiver}>(
                MyToken.TokenReceiverPublicPath,
                target: MyToken.TokenValultStoragePath
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            acct.link<&MyToken.Vault{MyToken.Balance}>(
                MyToken.TokenBalancePublicPath,
                target: MyToken.TokenValultStoragePath
            )
        }

        self.receiverRef = acct.getCapability<&{MyNFTContract.NFTReceiver}>(MyNFTContract.CollectionPublicPath)
        .borrow() ?? panic("Could not borrow minter reference")

        self.minterRef = account.getCapability<&MyNFTContract.NFTMinter>(MyNFTContract.MinterPublicPath)
        .borrow()
        ?? panic("Could not borrow minter reference")

        
        self.receiverToken = acct.getCapability<&{MyToken.Receiver}>(MyToken.TokenReceiverPublicPath)
            .borrow()
            ?? panic("Could not get receiver reference to the NFT Collection")

    }

    execute {

        //let _name = "AllCode Logo"
        //let _description = "Fillmore Street"
        //let _uri = "ipfs://QmVH5T7MFVU52hTfQdWvu73iFPEF3jizuGfyVLccTmBCX2"
        let newNFT <- self.minterRef.mintNFT(
                    recipient: self.receiverToken,
                    name: _name,
                    description: _description,
                    thumbnail: _uri)

        self.receiverRef.deposit(token: <-newNFT)

        log("NFT Minted and deposited to Account 2’s Collection")
    }
}