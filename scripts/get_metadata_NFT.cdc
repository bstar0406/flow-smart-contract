import MyNFTContract from 0x01

pub fun main() : {String : String} {
let nftOwner = getAccount(0x02)
// log("NFT Owner")
let capability = nftOwner.getCapability<&{MyNFTContract.NFTReceiver}>(MyNFTContract.CollectionPublicPath)

let receiverRef = capability.borrow()
?? panic("Could not borrow the receiver reference")

return receiverRef.getMetadata(id: 1)
}