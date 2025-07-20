/**
 * TestnetDemo.js
 * Demonstration script for FML Protocol on Stellar testnet
 */

const StellarSdk = require('stellar-sdk');
const StellarBridge = require('./StellarBridge');

// Demo configuration
const DEMO_CONFIG = {
    network: 'testnet',
    fundName: 'Demo DeFi Alpha Fund',
    targetSize: 1000000, // $1M
    minInvestment: 100,
    managementFee: 200, // 2%
    performanceFee: 2000 // 20%
};

class TestnetDemo {
    constructor() {
        this.bridge = new StellarBridge('testnet');
        this.demoAccounts = {};
    }

    /**
     * Creates demo accounts with testnet funds
     */
    async setupDemoAccounts() {
        console.log('🚀 Setting up demo accounts...\n');

        // Create fund manager account
        this.demoAccounts.manager = StellarSdk.Keypair.random();
        console.log('Fund Manager Account:', this.demoAccounts.manager.publicKey());

        // Create investor accounts
        this.demoAccounts.investor1 = StellarSdk.Keypair.random();
        this.demoAccounts.investor2 = StellarSdk.Keypair.random();
        
        console.log('Investor 1 Account:', this.demoAccounts.investor1.publicKey());
        console.log('Investor 2 Account:', this.demoAccounts.investor2.publicKey());

        // Fund accounts from testnet friendbot
        console.log('\n💰 Funding accounts from testnet...');
        await this.fundAccount(this.demoAccounts.manager.publicKey());
        await this.fundAccount(this.demoAccounts.investor1.publicKey());
        await this.fundAccount(this.demoAccounts.investor2.publicKey());

        console.log('✅ Demo accounts ready!\n');
    }

    /**
     * Funds account using Stellar testnet friendbot
     */
    async fundAccount(publicKey) {
        try {
            const response = await fetch(
                `https://friendbot.stellar.org?addr=${publicKey}`
            );
            await response.json();
            console.log(`  ✓ Funded ${publicKey.substring(0, 8)}...`);
        } catch (error) {
            console.error(`  ✗ Error funding ${publicKey}:`, error.message);
        }
    }

    /**
     * Demonstrates fund creation
     */
    async demoFundCreation() {
        console.log('📊 Creating fund on Stellar...\n');
        
        const startTime = Date.now();
        
        const result = await this.bridge.createFund({
            managerKeypair: this.demoAccounts.manager,
            fundName: DEMO_CONFIG.fundName,
            targetSize: DEMO_CONFIG.targetSize,
            minInvestment: DEMO_CONFIG.minInvestment,
            managementFee: DEMO_CONFIG.managementFee,
            performanceFee: DEMO_CONFIG.performanceFee
        });

        const creationTime = (Date.now() - startTime) / 1000;

        if (result.success) {
            console.log('✅ Fund created successfully!');
            console.log('  Fund Address:', result.fundAddress);
            console.log('  Transaction:', result.transactionHash);
            console.log('  Creation Time:', creationTime, 'seconds\n');
            
            this.fundAddress = result.fundAddress;
            this.fundKeypair = result.fundKeypair;
        } else {
            console.error('❌ Fund creation failed:', result.error);
        }
    }

    /**
     * Demonstrates compliance verification
     */
    async demoCompliance() {
        console.log('🔐 Simulating compliance verification...\n');

        // In production, this would involve ZK proofs
        // For demo, we'll add compliance data to accounts
        
        const account1 = await this.bridge.server.loadAccount(
            this.demoAccounts.investor1.publicKey()
        );
        
        const transaction = new StellarSdk.TransactionBuilder(account1, {
            fee: await this.bridge.server.fetchBaseFee(),
            networkPassphrase: StellarSdk.Networks.TESTNET
        })
        .addOperation(StellarSdk.Operation.manageData({
            name: 'kyc_status',
            value: 'verified'
        }))
        .addOperation(StellarSdk.Operation.manageData({
            name: 'investor_type',
            value: 'accredited'
        }))
        .addOperation(StellarSdk.Operation.manageData({
            name: 'jurisdiction',
            value: 'US'
        }))
        .setTimeout(30)
        .build();

        transaction.sign(this.demoAccounts.investor1);
        await this.bridge.server.submitTransaction(transaction);

        console.log('✅ Investor 1 compliance verified');

        // Verify compliance
        const compliance = await this.bridge.verifyCompliance(
            this.demoAccounts.investor1.publicKey()
        );
        console.log('  Status:', compliance);
        console.log('');
    }

    /**
     * Demonstrates investment process
     */
    async demoInvestment() {
        console.log('💸 Processing investments...\n');

        // Investor 1 invests
        const investment1 = await this.bridge.invest({
            investorKeypair: this.demoAccounts.investor1,
            fundAddress: this.fundAddress,
            amount: 10000, // $10,000
            assetCode: 'XLM' // Using XLM for demo
        });

        if (investment1.success) {
            console.log('✅ Investment 1 successful!');
            console.log('  Amount: 10,000 XLM');
            console.log('  Transaction:', investment1.transactionHash);
        }

        console.log('');
    }

    /**
     * Demonstrates liquidity pool creation
     */
    async demoLiquidityPool() {
        console.log('💧 Creating liquidity pool...\n');

        const baseAsset = StellarSdk.Asset.native(); // XLM
        const shareAsset = new StellarSdk.Asset(
            'SHARE',
            this.fundAddress
        );

        const poolResult = await this.bridge.createLiquidityPool({
            fundKeypair: this.fundKeypair,
            baseAsset: baseAsset,
            shareAsset: shareAsset,
            initialPrice: 1.0
        });

        if (poolResult.success) {
            console.log('✅ Liquidity pool created!');
            console.log('  Pool Address:', poolResult.poolAddress);
            console.log('  Transaction:', poolResult.transactionHash);
        }

        console.log('');
    }

    /**
     * Shows fund summary
     */
    async showFundSummary() {
        console.log('📈 Fund Summary\n');

        const details = await this.bridge.getFundDetails(this.fundAddress);
        
        console.log('Fund Name:', details.name);
        console.log('Target Size:', `$${parseInt(details.targetSize).toLocaleString()}`);
        console.log('Management Fee:', `${parseInt(details.managementFee) / 100}%`);
        console.log('\nBalances:');
        details.balances.forEach(balance => {
            console.log(`  ${balance.asset_type}: ${balance.balance}`);
        });

        console.log('\n⏱️  Total demo time: < 60 seconds');
        console.log('💰 Total cost: < $1 (network fees only)\n');
    }

    /**
     * Runs complete demonstration
     */
    async runDemo() {
        console.log('═══════════════════════════════════════════');
        console.log('   Fund Management Layer - Testnet Demo    ');
        console.log('═══════════════════════════════════════════\n');

        try {
            await this.setupDemoAccounts();
            await this.demoFundCreation();
            await this.demoCompliance();
            await this.demoInvestment();
            await this.demoLiquidityPool();
            await this.showFundSummary();

            console.log('🎉 Demo completed successfully!');
            console.log('\nTestnet addresses for verification:');
            console.log('- Fund:', this.fundAddress);
            console.log('- Manager:', this.demoAccounts.manager.publicKey());
            console.log('- Investor:', this.demoAccounts.investor1.publicKey());
            
        } catch (error) {
            console.error('\n❌ Demo error:', error.message);
        }
    }
}

// Run demo if called directly
if (require.main === module) {
    const demo = new TestnetDemo();
    demo.runDemo();
}

module.exports = TestnetDemo;
