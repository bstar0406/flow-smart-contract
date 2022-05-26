
pub contract MyToken {

    pub var totalSupply: UFix64

    pub let TokenReceiverPublicPath: PublicPath
    pub let TokenBalancePublicPath: PublicPath
    pub let TokenAdminStoragePath: StoragePath
    pub let TokenValultStoragePath : StoragePath

    pub event TokensInitialized(initialSupply: UFix64)

    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    pub event TokensDeposited(amount: UFix64, to: Address?)

    pub event TokensMinted(amount: UFix64)

    pub event TokensBurned(amount: UFix64)

    pub event MinterCreated(allowedAmount: UFix64)

    pub event BurnerCreated()

   
    pub resource interface Provider {

        pub fun withdraw(amount: UFix64): @Vault {
            post {
                // `result` refers to the return value
                result.balance == amount:
                    "Withdrawal amount must be the same as the balance of the withdrawn Vault"
            }
        }
    }
    pub resource interface Receiver {

        pub fun deposit(from: @Vault)
    }
    pub resource interface Balance {

        pub var balance: UFix64

        init(balance: UFix64) {
            post {
                self.balance == balance:
                    "Balance must be initialized to the initial balance"
            }
        }
    }
    pub resource Vault: Provider, Receiver, Balance {

        pub var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        pub fun withdraw(amount: UFix64): @Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        pub fun deposit(from: @Vault) {
            let vault <- from
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            MyToken.totalSupply = MyToken.totalSupply - self.balance
        }
    }

    pub fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }

    pub resource Administrator {

        pub fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    pub resource Minter {

        /// The amount of tokens that the minter is allowed to mint
        pub var allowedAmount: UFix64

        pub fun mintTokens(amount: UFix64): @MyToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            MyToken.totalSupply = MyToken.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    pub resource Burner {

        pub fun burnTokens(from: @Vault) {
            let vault <- from 
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    init() {
        self.totalSupply = 1000.0

        self.TokenReceiverPublicPath = /public/TokenReceiver
        self.TokenValultStoragePath = /storage/TokenValutPath
        self.TokenBalancePublicPath = /public/TokenBalance
        self.TokenAdminStoragePath = /storage/TokenAdmin
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.TokenValultStoragePath)

        self.account.link<&{Receiver}>(
            self.TokenReceiverPublicPath,
            target: self.TokenValultStoragePath
        )

        self.account.link<&MyToken.Vault{Balance}>(
            self.TokenBalancePublicPath,
            target: self.TokenValultStoragePath
        )

        let admin <- create Administrator()
        self.account.save(<-admin, to: self.TokenAdminStoragePath)

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
