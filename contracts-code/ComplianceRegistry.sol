// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title IComplianceRegistry
 * @dev Interface for compliance verification system
 * @notice Production implementation uses zero-knowledge proofs
 */
interface IComplianceRegistry {
    
    enum ComplianceStatus {
        Unknown,
        Pending,
        Verified,
        Expired,
        Rejected
    }
    
    enum InvestorType {
        Retail,
        Accredited,
        QualifiedPurchaser,
        Institutional
    }
    
    /**
     * @dev Verifies investor compliance status
     * @param investor Address to verify
     * @param jurisdiction Jurisdiction code (ISO 3166)
     * @return status Compliance status
     * @return investorType Type of investor
     */
    function verifyCompliance(
        address investor,
        string calldata jurisdiction
    ) external view returns (
        ComplianceStatus status,
        InvestorType investorType
    );
    
    /**
     * @dev Submits compliance verification request
     * @param proof Zero-knowledge proof of compliance
     * @notice Actual implementation accepts ZK proof data
     */
    function submitCompliance(bytes calldata proof) external;
    
    /**
     * @dev Checks if investor can participate in specific fund
     * @param investor Investor address
     * @param fundAddress Fund address
     * @return eligible True if investor can participate
     * @return reason Reason if not eligible
     */
    function checkEligibility(
        address investor,
        address fundAddress
    ) external view returns (
        bool eligible,
        string memory reason
    );
    
    /**
     * @dev Returns compliance expiry timestamp
     * @param investor Investor address
     * @return timestamp Unix timestamp of expiry
     */
    function getComplianceExpiry(address investor) 
        external 
        view 
        returns (uint256 timestamp);
    
    /**
     * @dev Emitted when compliance status changes
     */
    event ComplianceUpdated(
        address indexed investor,
        ComplianceStatus status,
        uint256 expiry
    );
    
    /**
     * @dev Emitted when new jurisdiction is supported
     */
    event JurisdictionAdded(
        string jurisdiction,
        uint256 requirements
    );
}

/**
 * @title ComplianceRegistry
 * @dev Placeholder implementation for demonstration
 * @notice Production version implements full ZK-proof based compliance
 */
contract ComplianceRegistry is IComplianceRegistry {
    
    mapping(address => ComplianceStatus) private investorStatus;
    mapping(address => InvestorType) private investorTypes;
    mapping(address => uint256) private complianceExpiry;
    
    constructor() {
        // Demonstration purposes only
    }
    
    function verifyCompliance(
        address investor,
        string calldata jurisdiction
    ) external view override returns (
        ComplianceStatus status,
        InvestorType investorType
    ) {
        // Simplified demo implementation
        status = investorStatus[investor];
        investorType = investorTypes[investor];
        
        if (status == ComplianceStatus.Verified && 
            block.timestamp > complianceExpiry[investor]) {
            status = ComplianceStatus.Expired;
        }
        
        return (status, investorType);
    }
    
    function submitCompliance(bytes calldata proof) external override {
        // Demo: Auto-verify for testing
        // Production: Verify ZK proof
        investorStatus[msg.sender] = ComplianceStatus.Verified;
        investorTypes[msg.sender] = InvestorType.Accredited;
        complianceExpiry[msg.sender] = block.timestamp + 365 days;
        
        emit ComplianceUpdated(
            msg.sender, 
            ComplianceStatus.Verified, 
            complianceExpiry[msg.sender]
        );
    }
    
    function checkEligibility(
        address investor,
        address fundAddress
    ) external view override returns (
        bool eligible,
        string memory reason
    ) {
        if (investorStatus[investor] != ComplianceStatus.Verified) {
            return (false, "Compliance not verified");
        }
        
        if (block.timestamp > complianceExpiry[investor]) {
            return (false, "Compliance expired");
        }
        
        // Additional checks would go here
        return (true, "");
    }
    
    function getComplianceExpiry(address investor) 
        external 
        view 
        override 
        returns (uint256) 
    {
        return complianceExpiry[investor];
    }
}
