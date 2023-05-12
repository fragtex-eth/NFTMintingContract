// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PabloNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIdCounter;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public minted;

    IERC20 public immutable paymentToken;
    uint256 public immutable fee;
    uint256 public constant maxNfts = 25;

    event AddedToWhitelist(address[] addresses);
    event RemovedFromWhitelist(address[] addresses);
    
    constructor(address _paymentToken, uint256 _fee) ERC721("MyToken", "MTK") {
        paymentToken = IERC20(_paymentToken);
        fee = _fee;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeigwu25an0/";
    }

    function safeMint(address to) public {
        require(whitelist[msg.sender], "Address not in whitelist");
        require(!minted[msg.sender], "Already minted");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxNfts, "All NFTs already minted");
        _tokenIdCounter.increment();
        paymentToken.safeTransferFrom(msg.sender, address(this), fee);
        minted[msg.sender] = true;
        

        _safeMint(to, tokenId);
    }

    function addToWhitelist(address[] calldata toAddAddresses) 
    external onlyOwner
    {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
        emit AddedToWhitelist(toAddAddresses);
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromWhitelist(address[] calldata toRemoveAddresses)
    external onlyOwner
    {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
        emit RemovedFromWhitelist(toRemoveAddresses);
    }

    function withdraw() external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        paymentToken.safeTransfer(owner(), balance);
    }
}