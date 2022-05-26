import MyToken from 0x02

/// This transaction is what the minter Account uses to mint new tokens
/// They provide the recipient address and amount to mint, and the tokens
/// are transferred to the address after minting

transaction(recipient: Address, amount: UFix64) {

    /// Reference to the Example Token Admin Resource object
    let tokenAdmin: &MyToken.Administrator

    /// Reference to the Fungible Token Receiver of the recipient
    let tokenReceiver: &{MyToken.Receiver}

    prepare(signer: AuthAccount) {
        // Borrow a reference to the admin object
        self.tokenAdmin = signer.borrow<&MyToken.Administrator>(from: MyToken.TokenAdminStoragePath)
            ?? panic("Signer is not the token admin")

        // Get the account of the recipient and borrow a reference to their receiver
        self.tokenReceiver = getAccount(recipient)
            .getCapability(MyToken.TokenReceiverPublicPath)
            .borrow<&{MyToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")
    }

    execute {

        // Create a minter and mint tokens
        let minter <- self.tokenAdmin.createNewMinter(allowedAmount: amount)
        let mintedVault <- minter.mintTokens(amount: amount)

        // Deposit them to the receiever
        self.tokenReceiver.deposit(from: <-mintedVault)

        destroy minter
    }
}