import MyToken from 0x02

transaction {

    prepare(signer: AuthAccount) {

        // Return early if the account already stores a ExampleToken Vault
        if signer.borrow<&MyToken.Vault>(from: MyToken.TokenValultStoragePath) != nil {
            return
        }

        // Create a new ExampleToken Vault and put it in storage
        signer.save(
            <-MyToken.createEmptyVault(),
            to: MyToken.TokenValultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&MyToken.Vault{MyToken.Receiver}>(
            MyToken.TokenReceiverPublicPath,
            target: MyToken.TokenValultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&MyToken.Vault{MyToken.Balance}>(
            MyToken.TokenBalancePublicPath,
            target: MyToken.TokenValultStoragePath
        )
    }
}
