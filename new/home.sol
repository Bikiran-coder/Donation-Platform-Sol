// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DonationPlatform
 * @dev A transparent donation platform where users can create campaigns and receive donations
 * @author Your Name
 */
contract DonationPlatform {
    
    // Campaign structure
    struct Campaign {
        address payable owner;
        string title;
        string description;
        uint256 targetAmount;
        uint256 raisedAmount;
        uint256 deadline;
        bool isActive;
        uint256 donorCount;
    }
    
    // State variables
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public donations;
    uint256 public campaignCounter;
    
    // Events
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed owner,
        string title,
        uint256 targetAmount,
        uint256 deadline
    );
    
    event DonationMade(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount
    );
    
    event FundsWithdrawn(
        uint256 indexed campaignId,
        address indexed owner,
        uint256 amount
    );
    
    // Modifiers
    modifier campaignExists(uint256 _campaignId) {
        require(_campaignId < campaignCounter, "Campaign does not exist");
        _;
    }
    
    modifier onlyCampaignOwner(uint256 _campaignId) {
        require(campaigns[_campaignId].owner == msg.sender, "Only campaign owner can perform this action");
        _;
    }
    
    modifier campaignActive(uint256 _campaignId) {
        require(campaigns[_campaignId].isActive, "Campaign is not active");
        require(block.timestamp < campaigns[_campaignId].deadline, "Campaign has ended");
        _;
    }
    
    /**
     * @dev Create a new donation campaign
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _targetAmount Target amount to raise (in wei)
     * @param _durationInDays Campaign duration in days
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _targetAmount,
        uint256 _durationInDays
    ) external {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_targetAmount > 0, "Target amount must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");
        
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        
        campaigns[campaignCounter] = Campaign({
            owner: payable(msg.sender),
            title: _title,
            description: _description,
            targetAmount: _targetAmount,
            raisedAmount: 0,
            deadline: deadline,
            isActive: true,
            donorCount: 0
        });
        
        emit CampaignCreated(campaignCounter, msg.sender, _title, _targetAmount, deadline);
        campaignCounter++;
    }
    
    /**
     * @dev Donate to a specific campaign
     * @param _campaignId ID of the campaign to donate to
     */
    function donate(uint256 _campaignId) 
        external 
        payable 
        campaignExists(_campaignId) 
        campaignActive(_campaignId) 
    {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        Campaign storage campaign = campaigns[_campaignId];
        
        // If first time donor, increment donor count
        if (donations[_campaignId][msg.sender] == 0) {
            campaign.donorCount++;
        }
        
        donations[_campaignId][msg.sender] += msg.value;
        campaign.raisedAmount += msg.value;
        
        emit DonationMade(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw funds from a campaign (only campaign owner)
     * @param _campaignId ID of the campaign
     */
    function withdrawFunds(uint256 _campaignId) 
        external 
        campaignExists(_campaignId) 
        onlyCampaignOwner(_campaignId) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.raisedAmount > 0, "No funds to withdraw");
        
        uint256 amount = campaign.raisedAmount;
        campaign.raisedAmount = 0;
        
        campaign.owner.transfer(amount);
        
        emit FundsWithdrawn(_campaignId, msg.sender, amount);
    }
    
    /**
     * @dev Get campaign details
     * @param _campaignId ID of the campaign
     * @return owner Campaign owner address
     * @return title Campaign title
     * @return description Campaign description
     * @return targetAmount Target amount to raise
     * @return raisedAmount Amount raised so far
     * @return deadline Campaign deadline timestamp
     * @return isActive Whether campaign is active and not expired
     * @return donorCount Number of unique donors
     */
    function getCampaign(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (
            address owner,
            string memory title,
            string memory description,
            uint256 targetAmount,
            uint256 raisedAmount,
            uint256 deadline,
            bool isActive,
            uint256 donorCount
        ) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.targetAmount,
            campaign.raisedAmount,
            campaign.deadline,
            campaign.isActive && block.timestamp < campaign.deadline,
            campaign.donorCount
        );
    }
    
    /**
     * @dev Get donation amount by a specific donor to a campaign
     * @param _campaignId ID of the campaign
     * @param _donor Address of the donor
     * @return Donation amount
     */
    function getDonationAmount(uint256 _campaignId, address _donor) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (uint256) 
    {
        return donations[_campaignId][_donor];
    }
    
    /**
     * @dev Get total number of campaigns
     * @return Total campaign count
     */
    function getTotalCampaigns() external view returns (uint256) {
        return campaignCounter;
    }
}
