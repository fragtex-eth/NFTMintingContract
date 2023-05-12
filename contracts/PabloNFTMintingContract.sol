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
    mapping(uint => uint) private _availableTokens;

    IERC20 public immutable paymentToken;
    uint256 public immutable fee;
    uint256 public constant maxNfts = 25;
    uint256 private _numAvailableTokens;

    event AddedToWhitelist(address[] addresses);
    event RemovedFromWhitelist(address[] addresses);
    
    constructor(address _paymentToken, uint256 _fee) ERC721("MyToken", "MTK") {
        paymentToken = IERC20(_paymentToken);
        fee = _fee;
        _numAvailableTokens = maxNfts;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeigwu25an0/";
    }

    function mint() public {
        require(whitelist[msg.sender], "Address not in whitelist");
        require(!minted[msg.sender], "Already minted");
        minted[msg.sender] = true;
        _safeMint(msg.sender);
    }

    function _safeMint(address to) internal {
        require(_numAvailableTokens != 0, "All NFTs already minted");
        uint updatedNumAvailableTokens = _numAvailableTokens;

        paymentToken.safeTransferFrom(msg.sender, address(this), fee);
        uint256 tokenId = getRandomAvailableTokenId(to, updatedNumAvailableTokens);
        _safeMint(to, tokenId);
        --updatedNumAvailableTokens;
        _numAvailableTokens = updatedNumAvailableTokens;
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

    function getRandomAvailableTokenId(address to, uint updatedNumAvailableTokens)
        internal
        returns (uint256)
    {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    updatedNumAvailableTokens
                )
            )
        );
        uint256 randomIndex = randomNum % updatedNumAvailableTokens;
        return getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
    }

    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle. Code taken from CryptoPhunksV2
    function getAvailableTokenAtIndex(uint256 indexToUse, uint updatedNumAvailableTokens)
        internal
        returns (uint256)
    {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = indexToUse;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = updatedNumAvailableTokens - 1;
        uint256 lastValInArray = _availableTokens[lastIndex];
        if (indexToUse != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableTokens[indexToUse] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableTokens[indexToUse] = lastValInArray;
            }
        }
        if (lastValInArray != 0) {
            // Gas refund courtsey of @dievardump
            delete _availableTokens[lastIndex];
        }
        
        return result;
    }
}