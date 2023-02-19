// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //For preventing reentrancy attacks

contract dMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;    //To keep track of all the nfts
    Counters.Counter private _itemId;
    Counters.Counter private _itemSold;

    address payable contractOwner;          
    uint listingPrice = 10000000000000000;  //listing price to be given by the seller in order to list their nft

    constructor (){
        contractOwner = payable(msg.sender);    //contractOwner will get the listing price
    }

    struct marketItem {     // marketItem components
        uint itemId;
        address nftContract;
        uint  tokenId;
        address payable seller;
        address payable owner;
        uint nftPrice;
        bool soldStatus;
    }
    
    mapping (uint => marketItem) private idMarketItem;

    event itemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint  indexed tokenId,
        address seller,
        address owner,
        uint nftPrice,
        bool soldStatus
    );

     function getListingPrice () public view returns (uint256){
        return listingPrice;
     }


     function createMarketItem (address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {
        require(price > 0, "Price must be greater than zero");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        _itemId.increment();
        uint256 itemId = _itemId.current();

        idMarketItem[itemId] = marketItem(itemId, nftContract, tokenId, payable(msg.sender), payable(address(0)), price, false);

        //Transfer the ownership of the nft to the marketplace contract
        ERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit itemCreated(itemId, nftContract, tokenId, msg.sender, address(0), price, false);
    }

    function marketSale (address nftContract, uint256 itemId ) public payable nonReentrant {
        uint256 price = idMarketItem[itemId].nftPrice;
        uint256 tokenId = idMarketItem[itemId].tokenId;

        require(msg.value >= price, "Amount less than market price");

        //required amount is transfered to the seller
        idMarketItem[itemId].seller.transfer(msg.value);

        //Transfer the ownership from marketplace contract to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        idMarketItem[itemId].owner = payable(msg.sender);
        idMarketItem[itemId].soldStatus = true;

        _itemSold.increment();

        payable(contractOwner).transfer(listingPrice);

    }

    //To track total number of unsold items
    function getMarketItems( ) public view returns (marketItem[] memory){
        uint256 itemCount = _itemId.current();  //total number of items
        uint unsoldItemCount = _itemId.current() - _itemSold.current();
        uint256 currentIndex = 0;
        marketItem[] memory items = new marketItem[](unsoldItemCount);
        for(uint i = 0; i < itemCount; i++){
            if(idMarketItem[i+1].owner == address(0)) {
                uint currentId = idMarketItem[i+1].itemId;
                marketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //list of nft owner by a user

    function fetchmyNFT() public view returns (marketItem[] memory) {
        uint totalItemCount = _itemId.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount; i++) {
            if(idMarketItem[i+1].owner == msg.sender) {
                itemCount += 1;

            }
        }

        marketItem[] memory items = new marketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++) {
            if(idMarketItem[i+1].owner == msg.sender) {
                uint currentId = idMarketItem[i+1].itemId;
                marketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    
}