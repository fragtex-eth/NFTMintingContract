// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PabloNFT
 */
contract PabloNFT is ERC721, Ownable {
    using SafeERC20 for IERC20;

    // Declare state variables for whitelist, minted status, and available tokens
    mapping(address => bool) public whitelist;
    mapping(address => bool) public minted;
    mapping(uint => uint) private _availableTokens;

    // Declare state variables for the payment token and related constants
    IERC20 public immutable paymentToken;
    uint256 public immutable fee;
    uint256 public constant maxNfts = 25;
    uint256 private _numAvailableTokens;

    // Declare events for whitelist changes
    event AddedToWhitelist(address[] addresses);
    event RemovedFromWhitelist(address[] addresses);

    /**
     * @notice The constructor initializes the contract with the specified payment token and fee.
     * @param _paymentToken The address of the ERC20 token to use for payments.
     * @param _fee The fee required for minting a token.
     */
    constructor(address _paymentToken, uint256 _fee) ERC721("MyToken", "MTK") {
        paymentToken = IERC20(_paymentToken);
        fee = _fee;
        _numAvailableTokens = maxNfts;
    }

    /// @dev Returns the base URI for token metadata.
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeigwu25an0/";
    }

    /**
     * @notice Mints a new token for the sender if they are on the whitelist and haven't minted one already.
     */
    function mint() public {
        require(whitelist[msg.sender], "Address not in whitelist");
        require(!minted[msg.sender], "Already minted");
        minted[msg.sender] = true;
        _safeMint(msg.sender);
    }

    /**
     * @notice Adds addresses to the whitelist, only callable by the contract owner.
     * @param toAddAddresses An array of addresses to add to the whitelist.
     */
    function addToWhitelist(address[] calldata toAddAddresses)
        external
        onlyOwner
    {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
        emit AddedToWhitelist(toAddAddresses);
    }

    /**
     * @notice Removes addresses from the whitelist, only callable by the contract owner.
     * @param toRemoveAddresses An array of addresses to remove from the whitelist.
     */
    function removeFromWhitelist(address[] calldata toRemoveAddresses)
        external
        onlyOwner
    {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
        emit RemovedFromWhitelist(toRemoveAddresses);
    }

    /**
     * @notice Withdraws the payment tokens from the contract, only callable by the contract owner.
     */
    function withdraw() external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this
        ));
        paymentToken.safeTransfer(owner(), balance);
    }

    /**
     * @dev Safely mints a new token for a specified address.
     * @param to The address to receive the minted token.
     */
    function _safeMint(address to) internal {
        require(_numAvailableTokens != 0, "All NFTs already minted");
        uint updatedNumAvailableTokens = _numAvailableTokens;

        paymentToken.safeTransferFrom(msg.sender, address(this), fee);
        uint256 tokenId = getRandomAvailableTokenId(to, updatedNumAvailableTokens);
        _safeMint(to, tokenId);
        --updatedNumAvailableTokens;
        _numAvailableTokens = updatedNumAvailableTokens;
    }

    /**
     * @dev Returns a random available token ID.
     * @param to The address requesting the mint.
     * @param updatedNumAvailableTokens The current number of available tokens.
     * @return tokenId The random available token ID.
     */
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
                    block.prevrandao,
                    blockhash(block.number - 1),
                    address(this),
                    updatedNumAvailableTokens
                )
            )
        );
        uint256 randomIndex = randomNum % updatedNumAvailableTokens;
        return getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
    }

    /**
     * @dev Returns the available token at the specified index.
     * @param indexToUse The index to check for available token.
     * @param updatedNumAvailableTokens The current number of available tokens.
     * @return result The available token ID at the specified index.
     */
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
