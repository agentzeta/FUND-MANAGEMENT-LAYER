// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title FundFactory
 * @dev Simplified implementation of fund deployment system
 * @notice This is a demonstration version. Production includes additional features.
 */
contract FundFactory {
    
    struct Fund {
        address manager;
        string name;
        uint256 targetSize;
        uint256 minInvestment;
        uint256 managementFee; // Basis points (1% = 100)
        uint256 performanceFee; // Basis points
        bool isActive;
        uint256 createdAt;
    }
    
    mapping(address => Fund) public funds;
    mapping(address => address[]) public managerFunds;
    address[] public allFunds;
    
    event FundCreated(
        address indexed fundAddress,
        address indexed manager,
        string name,
        uint256 targetSize
    );
    
    event FundStatusChanged(address indexed fundAddress, bool isActive);
    
    /**
     * @dev Creates a new fund with specified parameters
     * @param _name Fund name
     * @param _targetSize Target fund size in base units
     * @param _minInvestment Minimum investment amount
     * @param _managementFee Annual management fee in basis points
     * @param _performanceFee Performance fee in basis points
     * @return fundAddress Address of the newly created fund
     */
    function createFund(
        string memory _name,
        uint256 _targetSize,
        uint256 _minInvestment,
        uint256 _managementFee,
        uint256 _performanceFee
    ) external returns (address fundAddress) {
        require(_targetSize > 0, "Invalid target size");
        require(_managementFee <= 500, "Management fee too high"); // Max 5%
        require(_performanceFee <= 3000, "Performance fee too high"); // Max 30%
        
        // In production, this deploys a separate fund contract
        // For demo, we use a deterministic address
        fundAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            _name,
                            block.timestamp
                        )
                    )
                )
            )
        );
        
        Fund memory newFund = Fund({
            manager: msg.sender,
            name: _name,
            targetSize: _targetSize,
            minInvestment: _minInvestment,
            managementFee: _managementFee,
            performanceFee: _performanceFee,
            isActive: true,
            createdAt: block.timestamp
        });
        
        funds[fundAddress] = newFund;
        managerFunds[msg.sender].push(fundAddress);
        allFunds.push(fundAddress);
        
        emit FundCreated(fundAddress, msg.sender, _name, _targetSize);
        
        return fundAddress;
    }
    
    /**
     * @dev Updates fund status (active/inactive)
     * @param _fundAddress Address of the fund
     * @param _isActive New status
     */
    function updateFundStatus(address _fundAddress, bool _isActive) external {
        require(funds[_fundAddress].manager == msg.sender, "Not fund manager");
        funds[_fundAddress].isActive = _isActive;
        emit FundStatusChanged(_fundAddress, _isActive);
    }
    
    /**
     * @dev Returns all funds managed by an address
     * @param _manager Manager address
     * @return Array of fund addresses
     */
    function getManagerFunds(address _manager) 
        external 
        view 
        returns (address[] memory) 
    {
        return managerFunds[_manager];
    }
    
    /**
     * @dev Returns total number of funds created
     * @return Total fund count
     */
    function getTotalFunds() external view returns (uint256) {
        return allFunds.length;
    }
    
    /**
     * @dev Returns fund details
     * @param _fundAddress Fund address
     * @return Fund struct
     */
    function getFundDetails(address _fundAddress) 
        external 
        view 
        returns (Fund memory) 
    {
        return funds[_fundAddress];
    }
}
