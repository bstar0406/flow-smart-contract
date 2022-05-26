// This script reads the total supply field
// of the ExampleToken smart contract

import MyToken from 0x02

pub fun main(): UFix64 {

    let supply = MyToken.totalSupply

    log(supply)

    return supply
}