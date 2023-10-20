// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}
interface IERC721{
    function setApprovalForAll(address operator, bool _approved) external;
}


contract NCTDREAM is ERC721A, Ownable, ReentrancyGuard {
    
    constructor() ERC721A("NCT DREAM", "NCT") {
    }
    uint256 public immutable MAX_SUPPLY = 4900;
    uint256 public immutable TEAM_SUPPLY = 100;
    uint256 public immutable DA_SUPPLY = 1500;
    uint256 public immutable WL_SUPPLY = 3000;

// Modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

// Phase 1
// D.A variables and functions    
    uint256 public startPrice = 0.05 ether;
    uint256 public startAt = 0;
    uint256 public endsAt = 0;
    uint256 public endPrice = 0.01 ether;
    uint256 public discountRate = 0.01 ether;
    uint256 public interval = 1 minutes;
    uint256 public duration = ( ( (startPrice - endPrice) / discountRate ) * interval ) + interval;
    uint256 public mintedInDA = 0;
    function runAuction() public onlyOwner{
        require (startAt==0 && endsAt==0,"The auction is running!");
        startAt = block.timestamp;
        endsAt = block.timestamp + duration;
    }
    function auctionPrice() public view returns (uint256) {
        if (startAt==0) {
            return startPrice;
        }
        if (endsAt < block.timestamp) {
            return endPrice;
        }
        uint256 step = (block.timestamp - startAt) / interval;
        if (startPrice - (step * discountRate) >= endPrice){
            return startPrice - (step * discountRate);
        }
        return endPrice;   
    }
    function safeMintDA(uint256 amount) public payable callerIsUser nonReentrant {
        require(startAt != 0 && endsAt != 0 && block.timestamp < endsAt, "The auction is not running!");
        require(msg.value >= (amount * auctionPrice()), "Not enough ether sent!");
        require(totalSupply() + amount <= MAX_SUPPLY, "Not enough items left!");
        require(mintedInDA + amount <= DA_SUPPLY, "Not enough items left for auction!");
        _safeMint(msg.sender, amount);
        mintedInDA+=amount;
    }


// Phase 2
// WL variables and functions
    bytes32 whitelistRoot;
    uint256 public WLedPrice = 0;
    bool isWLedRunning = false;
    uint256 public mintedInWLed = 0;
    function set_WLedPrice (uint256 _price) public onlyOwner{
        WLedPrice = _price;
    }
    function set_WLRoot (bytes32 _root) public onlyOwner{
        whitelistRoot = _root;
    }
    function runWLed () public onlyOwner{
        require(WLedPrice != 0, "Set the allowlist sale price!");
        isWLedRunning = true;
    }
    function safeMintWL(bytes32[] calldata merkleProof) external payable callerIsUser nonReentrant{
        require(isWLedRunning==true,"Allowlist sale is ended!");
        require(verifyProof(merkleProof,msg.sender), "Not eligible for allowlist mint!");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply!");
        require(mintedInWLed + 1 <= WL_SUPPLY + TEAM_SUPPLY, "Reached max supply!");
        require(msg.value >= WLedPrice, "Not enough ether sent!");
        _safeMint(msg.sender, 1);
        mintedInWLed+=1;
    }
    function endWLed () public onlyOwner{
        isWLedRunning=false;
    }
    function verifyProof(bytes32[] calldata merkleProof, address wallet) internal view returns(bool){
        bytes32 node = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(merkleProof, whitelistRoot, node);
    }

//phase 3
// Public sale variables and functions
    uint256 public publicSalePrice = 0;
    bool isPublicSaleRunning = false;
    function set_publicSalePrice (uint256 _price) public onlyOwner{
        publicSalePrice = _price;
    }
    function runPublicSale() public onlyOwner{
        require(publicSalePrice != 0, "Set the public sale price!");
        isPublicSaleRunning = true;
    }
    function safeMintPS(uint256 amount) external payable nonReentrant callerIsUser{
        require(publicSalePrice != 0, "Public sale has not begun yet!");
        require(isPublicSaleRunning==true,"Public sale is ended!");
        require(totalSupply() + amount <= MAX_SUPPLY, "Not enough items left!");
        require(msg.value >= (amount * publicSalePrice), "Not enough ether sent!");
        _safeMint(msg.sender, amount);
    }
    function endPublicSale () public onlyOwner{
        isPublicSaleRunning=false;
    }
    

// metadata URI
    bool public revealed = false;
    string private _baseTokenURI;
    string private notRevealedUri;
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function revealItems() external onlyOwner{
        revealed = true;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        if(revealed == false) {
            return notRevealedUri;
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

// Withdraw
    function withdraw() public onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

// Withraw other tokens    
    function withdrawERC20(address _tokenContract, uint256 _amount) external onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner(), _amount);  
    }
    
    function approveERC721(address _tokenContract) external onlyOwner{
        IERC721 tokenContract = IERC721(_tokenContract);
        tokenContract.setApprovalForAll(owner(),true);
    }
}

