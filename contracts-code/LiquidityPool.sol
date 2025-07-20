// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title LiquidityPool
 * @dev Simplified automated market maker for fund shares
 * @notice Production version includes advanced features
 */
contract LiquidityPool {
    
    struct Pool {
        address fundAddress;
        uint256 totalLiquidity;
        uint256 sharePrice; // In base units (e.g., USDC)
        uint256 reserveRatio; // Percentage held in reserve (basis points)
        bool isActive;
    }
    
    mapping(address => Pool) public pools;
    mapping(address => mapping(address => uint256)) public userShares;
    
    event PoolCreated(address indexed fundAddress, uint256 initialPrice);
    event LiquidityAdded(address indexed fundAddress, address indexed provider, uint256 amount);
    event SharesTraded(address indexed fundAddress, address indexed trader, bool isBuy, uint256 shares, uint256 price);
    
    /**
     * @dev Creates a new liquidity pool for a fund
     * @param _fundAddress Address of the fund
     * @param _initialPrice Initial share price
     * @param _reserveRatio Reserve ratio in basis points
     */
    function createPool(
        address _fundAddress,
        uint256 _initialPrice,
        uint256 _reserveRatio
    ) external {
        require(pools[_fundAddress].fundAddress == address(0), "Pool exists");
        require(_initialPrice > 0, "Invalid price");
        require(_reserveRatio <= 5000, "Reserve ratio too high"); // Max 50%
        
        pools[_fundAddress] = Pool({
            fundAddress: _fundAddress,
            totalLiquidity: 0,
            sharePrice: _initialPrice,
            reserveRatio: _reserveRatio,
            isActive: true
        });
        
        emit PoolCreated(_fundAddress, _initialPrice);
    }
    
    /**
     * @dev Adds liquidity to pool
     * @param _fundAddress Fund address
     * @param _amount Amount to add
     */
    function addLiquidity(address _fundAddress, uint256 _amount) external {
        Pool storage pool = pools[_fundAddress];
        require(pool.isActive, "Pool not active");
        require(_amount > 0, "Invalid amount");
        
        pool.totalLiquidity += _amount;
        
        emit LiquidityAdded(_fundAddress, msg.sender, _amount);
    }
    
    /**
     * @dev Calculates share price based on bonding curve
     * @param _fundAddress Fund address
     * @param _shareAmount Number of shares
     * @param _isBuy True for buy, false for sell
     * @return price Total price for transaction
     */
    function calculatePrice(
        address _fundAddress,
        uint256 _shareAmount,
        bool _isBuy
    ) public view returns (uint256 price) {
        Pool memory pool = pools[_fundAddress];
        
        // Simplified linear pricing model
        // Production uses advanced bonding curves
        uint256 priceImpact = (_shareAmount * pool.sharePrice) / 10000;
        
        if (_isBuy) {
            price = pool.sharePrice + priceImpact;
        } else {
            price = pool.sharePrice - priceImpact;
        }
        
        return price * _shareAmount;
    }
    
    /**
     * @dev Executes share purchase
     * @param _fundAddress Fund address
     * @param _shareAmount Number of shares to buy
     */
    function buyShares(address _fundAddress, uint256 _shareAmount) external {
        Pool storage pool = pools[_fundAddress];
        require(pool.isActive, "Pool not active");
        
        uint256 totalPrice = calculatePrice(_fundAddress, _shareAmount, true);
        require(totalPrice <= pool.totalLiquidity, "Insufficient liquidity");
        
        userShares[_fundAddress][msg.sender] += _shareAmount;
        
        // Update price based on volume
        pool.sharePrice = (pool.sharePrice * 10100) / 10000; // 1% increase demo
        
        emit SharesTraded(_fundAddress, msg.sender, true, _shareAmount, totalPrice);
    }
    
    /**
     * @dev Executes share sale
     * @param _fundAddress Fund address
     * @param _shareAmount Number of shares to sell
     */
    function sellShares(address _fundAddress, uint256 _shareAmount) external {
        Pool storage pool = pools[_fundAddress];
        require(pool.isActive, "Pool not active");
        require(userShares[_fundAddress][msg.sender] >= _shareAmount, "Insufficient shares");
        
        uint256 totalPrice = calculatePrice(_fundAddress, _shareAmount, false);
        
        userShares[_fundAddress][msg.sender] -= _shareAmount;
        
        // Update price based on volume
        pool.sharePrice = (pool.sharePrice * 9900) / 10000; // 1% decrease demo
        
        emit SharesTraded(_fundAddress, msg.sender, false, _shareAmount, totalPrice);
    }
    
    /**
     * @dev Returns user's share balance
     * @param _fundAddress Fund address
     * @param _user User address
     * @return balance Share balance
     */
    function getShareBalance(address _fundAddress, address _user) 
        external 
        view 
        returns (uint256 balance) 
    {
        return userShares[_fundAddress][_user];
    }
}
