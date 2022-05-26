// This script reads the balance field of an account's FlowToken Balance
import MyToken from 0x02

pub fun main(account: Address): UFix64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(MyToken.TokenBalancePublicPath)
        .borrow<&MyToken.Vault{MyToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
