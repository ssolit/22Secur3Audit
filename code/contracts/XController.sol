// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "./XCVToken.sol";
import "./XNFT.sol";

contract XController {

    error Unauthorized();

    // ====================== STATE VARIABLES ======================

    // XNFT address
    XNFT public immutable xnft;

    // XCVToken address
    XCVToken public immutable xtoken;

    // Only people who know the password can call certain functions
    string private password;

    // Price of minting an NFT
    uint256 public constant NFT_PRICE_ETH = 0.1 ether;

    // Fee ratio charged when selling NFTs
    uint256 public constant SELL_FEE = 10;

    // Percent base
    uint256 public constant BASE = 100;

    // Distribute is a struct holding metadata for when a user sells NFT.
    struct Distribute {
        address to;
        uint256[] ids;
    }

    // NFT selling data
    Distribute[] public toDistribute;

    // Points to the last processed index in the `toDistribute` array
    uint256 public lastDistribute;

    // ====================== CONSTRUCTOR ======================

    /**
     * @dev Initializes the contract by setting the XCVToken address and deploying an XNFT contract
     */
    constructor(XCVToken _xtoken, string memory _password) {
        xtoken = _xtoken;
        xnft = new XNFT();
        password = _password;
    }

    // ====================== MODIFIER ======================

    /**
     * @dev Throws if called without correct password
     */
    modifier requirePassword(string calldata _password) {
        if(!equal(_password, password)) {
            revert Unauthorized();
        }
        _;
    }

    // ====================== CORE ======================

    /// @notice Mint new NFT
    /// The rarity of minted NFTs is determined by the random number generated
    ///
    /// @dev Requirements:
    /// - msg.value should correspond to the number of mint
    /// - The total supply of NFTs must be less than the MAX_SUPPLY
    ///
    /// @param amount Amount to mint
    function mint(uint256 amount) external payable {

        // unchecked to save gas
        unchecked {
            require(amount + xnft.totalSupply() <= xnft.MAX_SUPPLY());
        }

        require(amount > 0, "amount should gt 0");

        for (uint256 i = 0; i < amount; ++i) {
            require(msg.value > NFT_PRICE_ETH, "Insufficient ETH");
            uint256 id = xnft.mint(msg.sender);
            xnft.setRarity(id, getRandomNumber());
        }
    }

    /// @notice Swap NFTs for ETH
    ///
    /// @dev data will be stored in the `toDistribute`
    /// ETH will be distributed through the confirmDistribute function
    /// 
    /// Requirements:
    /// - Check NFT id ownership
    /// - Swapped NFTs will be locked and cannot be transferred
    ///
    /// @param _ids The array of NFT ID the msg.sender would sell
    function swapNFTsforETH(uint256[] calldata _ids) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            require(msg.sender == xnft.ownerOf(id));
            xnft.lock(id);
        }
        toDistribute.push(Distribute(msg.sender, _ids));
    }

    // ====================== ADMIN FUNCTIONS ======================

    /// @notice Admin confirms distribution of ETH
    ///
    /// @dev Only admins who know the password can confirm the swap and distribute ETH
    ///
    /// @param _password Throws if called without correct password
    function confirmDistribute(string calldata _password)
        external
        requirePassword(_password)
    {
        for(uint256 i = lastDistribute; i < toDistribute.length; ++i) {
            Distribute memory dis = toDistribute[i];
            uint256 sell_total = dis.ids.length * NFT_PRICE_ETH * (BASE - SELL_FEE) / BASE;
            (bool success, ) = dis.to.call{value: sell_total}("");
            require(success, "Distribute Failed");
        }

        lastDistribute = toDistribute.length;
    }

    /// @notice Admin withdraw ERC20 tokens
    ///
    /// @dev Only admins who know the password can withdraw tokens
    ///
    /// @param _amount The amount of Tokens you want to withdraw
    /// @param _password Throws if called without correct password

    function withdrawTokens(uint256 _amount, string calldata _password)
        external
        requirePassword(_password)
    {
        uint256 amount = _amount == 0 ? xtoken.balanceOf(address(this)) : _amount;
        if (amount > 0) {
            xtoken.transfer(msg.sender, amount);
        }
    }

    // ====================== VIEWS ======================

    /// @return Boolean : Two strings are equal (true)
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /// @return uint8 : A random number between 0 and 100
    function getRandomNumber() internal view returns(uint8) {
        return uint8(uint256(keccak256(abi.encode(
            msg.sender,
            block.difficulty,
            gasleft()
        )))) % 100;
    }
}