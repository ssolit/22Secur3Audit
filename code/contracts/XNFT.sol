// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./XController.sol";


contract XNFT is ERC721("XNFT", "XNFT") {

    error NotController();

    // ====================== STATE VARIABLES ======================

    // XController contract address. Some functions can only be called by the controller.
    address public immutable controller;

    // Mapping from token ID to rarity
    mapping(uint256 => uint8) public rarity;

    // Mapping from token ID to locked state
    mapping(uint256 => bool) public locked;

    // Token current total supply
    uint256 public totalSupply;

    // Token max supply
    uint256 public constant MAX_SUPPLY = 10000;

    // ====================== CONSTRUCTOR ======================

    /**
     * @dev Initializes the contract by setting the controller contract address.
     * This contract is created when the Xcontroller contract is initialized
     */
    constructor() {
        controller = msg.sender;
    }

    // ====================== MODIFIER ======================

    /**
     * @dev Throws if called by any account other than the controller contract.
     */
    modifier onlyController {
        if(msg.sender != controller) {
            revert NotController();
        }
        _;
    }

    // ====================== OVERRIDE ======================

    /// @notice Locked NFT can no longer be transferred
    /// @dev See {ERC721-transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(!locked[tokenId], "Can't transfer locked NFT");
        super.transferFrom(from, to, tokenId);
    }

    // ====================== ADMIN FUNCTIONS ======================

    /// @notice Controller mint new NFT
    ///
    /// @dev Only controller contract can call this function
    ///
    /// @param to target address that will receive the tokens
    /// @return uint256 new NFT's tokenId
    function mint(address to) external onlyController returns(uint256) {
        _mint(to, totalSupply);
        return totalSupply++;
    }

    /// @notice Controller locks an NFT. Locked NFT can no longer be transferred.
    ///
    /// @dev Only controller contract can call this function
    ///
    /// @param tokenId uint256 ID of the NFT to be locked
    function lock(uint256 tokenId) external {
        locked[tokenId] = true;
    }

    /// @notice Controller sets the rarity of an NFT. The rarity determines the value.
    ///
    /// @dev Only controller contract can call this function
    ///
    /// @param id uint256 ID of the NFT to be set
    /// @param score uint8 A score that defines the rarity of an NFT
    function setRarity(uint256 id, uint8 score) external onlyController {
        rarity[id] = score;
    }
}
