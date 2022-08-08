//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable, Pausable {
    using SafeERC20 for IERC20;

    struct Auction {
        address seller;
        uint256 startedAt;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
    }

    uint32 ownerCut = 3; //0 - 10000 (0.00 - 100.00)
    //----------[Notice] Please set contract address----------
    address erc20ContractAddress = 0xc787Cd6E62b02484F4B7A5e3A14A5b196e9F33b5;
    IERC20 erc20Contract;
    address erc721ContractAddress = 0x844917e1c3b6Fdba8bcEA962426af120110c4a57;
    IERC721 erc721Contract;

    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startedAt, uint256 startingPrice, uint256 endingPrice, uint64 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 price, address winner);
    event AuctionCanceled(uint256 tokenId);

    constructor(){
        erc20Contract = IERC20(erc20ContractAddress);
        erc721Contract = IERC721(erc721ContractAddress);

    }

    modifier isOwn(uint256 _tokenId){
        require(erc721Contract.ownerOf(_tokenId) == msg.sender);
        _;
    }

    function getAuction(
        uint256 _tokenId
    )
        external
        view
        whenNotPaused
        returns (
            address seller,
            uint256 startedAt,
            uint128 startingPrice,
            uint128 endingPrice,
            uint64 duration
        )
    {
        Auction memory _auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(_auction));
        return (
            _auction.seller,
            _auction.startedAt,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration
        );
    }

    function _isOnAuction(Auction memory _auction) internal pure returns (bool) {
        return (_auction.startedAt > 0);
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
        isOwn(_tokenId)
    {
        erc721Contract.safeTransferFrom(msg.sender, address(this), _tokenId);
        Auction memory _auction = Auction(
            msg.sender,
            block.timestamp,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration)
        );
        _addAuction(_tokenId, _auction);
    }

    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        require(_auction.duration >= 1 minutes);
        tokenIdToAuction[_tokenId] = _auction;
        emit AuctionCreated(
            _tokenId,
            _auction.startedAt,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration
        );
    }

    function getCurrentPrice(
        uint256 _tokenId
    )
        external
        view
        whenNotPaused
        returns (uint256)
    {
        Auction memory _auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(_auction));
        return _getCurrentPrice(_auction);
    }

    function _getCurrentPrice(
        Auction memory _auction
    )
        internal
        view
        returns (uint256)
    {
        uint256 _secondsPassed = (_auction.startedAt < block.timestamp) ? block.timestamp - _auction.startedAt : 0;
        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            _secondsPassed
        );
    }

    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 _totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_duration);
            int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;
            return uint256(_currentPrice);
        }
    }

    function cancelAuction(
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        Auction memory auction = tokenIdToAuction[_tokenId];
        require(msg.sender == auction.seller || msg.sender == owner());
        _removeAuction(_tokenId);
        emit AuctionCanceled(_tokenId);
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function bid(
        uint256 _tokenId
    )
        external
        payable
        whenNotPaused
    {
         _bid(_tokenId, msg.value);
         _transfer(msg.sender, _tokenId);
    }

    function _bid(
        uint256 _tokenId,
        uint256 _bidAmount
    )
        internal
    {
        Auction memory _auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(_auction));
        uint256 price = _getCurrentPrice(_auction);
        require(_bidAmount >= price);

        address seller = _auction.seller;
        _removeAuction(_tokenId);

        if(price > 0){
            uint256 _auctioneerCut = _computeCut(price);
            uint256 _sellerProceeds = price - _auctioneerCut;
            erc20Contract.safeTransfer(seller, _sellerProceeds);
        }

        emit AuctionSuccessful(_tokenId, price, msg.sender);
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

    function _transfer(
        address to,
        uint256 _tokenId
    )
        internal
    {
        erc721Contract.safeTransferFrom(address(this), to, _tokenId);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

}


