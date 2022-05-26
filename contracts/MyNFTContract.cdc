import MyToken from 0x02

pub contract MyNFTContract {

    pub var totalSupply: UInt64

    //pub let tokenVault : &MyToken.Vault

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let MinterPublicPath : PublicPath
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub resource NFT {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let uri: String
        init(
            initID: UInt64,
            name: String,
            description: String,
            uri: String
            ) {
            self.id = initID
            self.name = name
            self.description = description
            self.uri = uri
        }
    }

    pub resource interface NFTReceiver {
        pub fun deposit(token: @NFT)
        pub fun getIDs(): [UInt64]
        pub fun idExists(id: UInt64): Bool
        //pub fun getMetadata(id: UInt64) : {String : String}
    }

    pub resource Collection: NFTReceiver {
        pub var ownedNFTs: @{UInt64: NFT}
        //pub var metadataObjs: {UInt64: { String : String }}

        init () {
            self.ownedNFTs <- {}
            //self.metadataObjs = {}
        }

        pub fun withdraw(withdrawID: UInt64): @NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        pub fun deposit(token: @NFT) {

            let id: UInt64 = token.id

            //self.metadataObjs[token.id] = metadata
            let oldToken <- self.ownedNFTs[token.id] <-! token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun idExists(id: UInt64): Bool {
            return self.ownedNFTs[id] != nil
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        //pub fun updateMetadata(id: UInt64, metadata: {String: String}) {
            //self.metadataObjs[id] = metadata
        //}

        //pub fun getMetadata(id: UInt64): @NFT {
            //return self.ownedNFTs[id]!
        //}

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    pub resource NFTMinter {

        
        pub fun mintNFT(
            recipient: &{MyToken.Receiver},
            name: String,
            description: String,
            thumbnail: String
            ): @NFT {

            MyNFTContract.totalSupply = MyNFTContract.totalSupply + 1 
            var newNFT <- create NFT(
                initID: MyNFTContract.totalSupply,
                name: name,
                description: description,
                uri: thumbnail
            )
            let ref = MyNFTContract.account.borrow<&MyToken.Vault>(from: MyToken.TokenValultStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")

            let vault <- ref.withdraw(amount:1.0)
            recipient.deposit(from: <-vault)
            //var newNFT <- create NFT(initID: MyNFTContract.totalSupply)
            return <-newNFT
        }
    }

    //The init contract is required if the contract contains any fields
    init() {
        // Initialize the total supply
        self.totalSupply = 0
        // Set the named paths
        self.CollectionStoragePath = /storage/NFTCollection
        self.CollectionPublicPath = /public/NFTCollection
        self.MinterStoragePath = /storage/NFTMinter
        self.MinterPublicPath = /public/NFTMinter
        
        if self.account.borrow<&MyToken.Vault>(from: MyToken.TokenValultStoragePath) == nil {
            self.account.save(<-MyToken.createEmptyVault(), to: MyToken.TokenValultStoragePath)
            self.account.link<&MyToken.Vault{MyToken.Receiver}>(
                MyToken.TokenReceiverPublicPath,
                target: MyToken.TokenValultStoragePath
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            self.account.link<&MyToken.Vault{MyToken.Balance}>(
                MyToken.TokenBalancePublicPath,
                target: MyToken.TokenValultStoragePath
            )
        }
        
        //self.tokenVault <- MyToken.createEmptyVault()
        // Get a reference to the signer's stored vault
        //self.tokenVault = self.account.borrow<&MyToken.Vault>(from: MyToken.TokenValultStoragePath)
		//	?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        //self.tokenVault <- vaultRef.withdraw(amount: amount)

        self.account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)
        self.account.link<&{NFTReceiver}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        self.account.save(<-create NFTMinter(), to: self.MinterStoragePath)
        self.account.link<&NFTMinter>(self.MinterPublicPath, target: self.MinterStoragePath)


    }
}