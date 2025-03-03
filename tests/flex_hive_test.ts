[Previous test content plus new tests for dispute resolution]

Clarinet.test({
    name: "Can initiate and resolve disputes",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const worker = accounts.get('wallet_1')!;
        
        // Setup: Create gig and accept application
        // [Previous setup code]
        
        // Test dispute initiation
        let block = chain.mineBlock([
            Tx.contractCall('flex-hive', 'initiate-dispute',
                [
                    types.uint(1),
                    types.ascii("Work not completed as specified")
                ],
                worker.address
            )
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Test dispute resolution
        block = chain.mineBlock([
            Tx.contractCall('flex-hive', 'resolve-dispute',
                [
                    types.uint(1),
                    types.ascii("Split payment 50/50"),
                    types.uint(50)
                ],
                deployer.address
            )
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});
