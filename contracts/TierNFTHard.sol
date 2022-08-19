// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct Tier {
    uint256 value;
    string name;
    string imageURI;
}

contract TierNFT is ERC721, Ownable {
    uint256 public totalSupply;
    uint256 public maxTiers;
    mapping(uint256 => uint256) public tokenTier;
    mapping(uint256 => Tier) public tiers;

    // Events to log Tier data changes
    event TierValuesUpdated(
        uint256 indexed tierId,
        uint256 indexed newValue,
        string newName,
        string newImageURI
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxTiers
    ) ERC721(_name, _symbol) {
        require(_maxTiers > 1, "Should have at least 2 tiers");
        // Set maximum number of tiers
        maxTiers = _maxTiers;
    }

    function setTierData(
        uint256 tierId,
        uint256 value,
        string memory name,
        string memory imageURI
    ) public onlyOwner {
        // Check that data is correct before updating
        require(tierId < maxTiers, "Not a valid tierId");
        if (tierId > 0)
            require(
                value > tiers[tierId - 1].value,
                "Value needs to be > prev tier"
            );
        if (tierId < maxTiers - 1)
            require(
                value < tiers[tierId + 1].value,
                "Value needs to be < next tier"
            );

        // Update the Tier
        tiers[tierId] = Tier(value, name, imageURI);

        // Emit an event to signal a Tier changed
        emit TierValuesUpdated(tierId, value, name, imageURI);
    }

    function mint() public payable {
        require(
            msg.value >= tiers[0].value,
            "Not enough value for the minimum Tier"
        );

        uint256 tierId = 0;

        for (uint256 i = maxTiers - 1; i > 0; i--) {
            if (msg.value >= tiers[i].value) {
                tierId = i;
                break;
            }
        }

        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        tokenTier[totalSupply] = tierId;
    }

    // Create the tokenURI json on the fly without creating files individually
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        string memory tierName = tiers[tokenTier[tokenId]].name;
        string memory imageURI = tiers[tokenTier[tokenId]].imageURI;

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    name(),
                    " #",
                    Strings.toString(tokenId),
                    '", "description": "TierNFTs collection", "image": "',
                    imageURI,
                    '","attributes":[{"trait_type": "Tier", "value": "',
                    tierName,
                    '" }]}'
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }

    // Function to withdraw funds from contract
    function withdraw() public onlyOwner {
        // Check that we have funds to withdraw
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be > 0");

        // Withdraw funds.
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}
