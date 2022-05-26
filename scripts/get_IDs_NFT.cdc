import MyNFTContract from 0x01

pub fun main(address: Address) : [UInt64] {
let nftOwner = getAccount(address)
// log("NFT Owner")
let capability = nftOwner.getCapability<&{MyNFTContract.NFTReceiver}>(MyNFTContract.CollectionPublicPath)

let receiverRef = capability.borrow()
?? panic("Could not borrow the receiver reference")

return receiverRef.getIDs()
}