import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new gig",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('flex-hive', 'create-gig',
                [
                    types.ascii("Test Gig"),
                    types.uint(1000000),
                    types.uint(30),
                    types.ascii("Test Description")
                ],
                deployer.address
            )
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectUint(1);
        
        const response = chain.callReadOnlyFn(
            'flex-hive',
            'get-gig',
            [types.uint(1)],
            deployer.address
        );
        
        const gig = response.result.expectOk().expectSome();
        assertEquals(gig.title, "Test Gig");
    }
});

Clarinet.test({
    name: "Can apply for a gig",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const applicant = accounts.get('wallet_1')!;
        
        // First create a gig
        let block = chain.mineBlock([
            Tx.contractCall('flex-hive', 'create-gig',
                [
                    types.ascii("Test Gig"),
                    types.uint(1000000),
                    types.uint(30),
                    types.ascii("Test Description")
                ],
                deployer.address
            )
        ]);
        
        // Then apply for it
        block = chain.mineBlock([
            Tx.contractCall('flex-hive', 'apply-for-gig',
                [
                    types.uint(1),
                    types.ascii("Test Application")
                ],
                applicant.address
            )
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can accept application and complete gig",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const applicant = accounts.get('wallet_1')!;
        
        // Create gig
        chain.mineBlock([
            Tx.contractCall('flex-hive', 'create-gig',
                [
                    types.ascii("Test Gig"),
                    types.uint(1000000),
                    types.uint(30),
                    types.ascii("Test Description")
                ],
                deployer.address
            )
        ]);
        
        // Apply for gig
        chain.mineBlock([
            Tx.contractCall('flex-hive', 'apply-for-gig',
                [
                    types.uint(1),
                    types.ascii("Test Application")
                ],
                applicant.address
            )
        ]);
        
        // Accept application
        let block = chain.mineBlock([
            Tx.contractCall('flex-hive', 'accept-application',
                [
                    types.uint(1),
                    types.principal(applicant.address)
                ],
                deployer.address
            )
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Complete gig
        block = chain.mineBlock([
            Tx.contractCall('flex-hive', 'complete-gig',
                [types.uint(1)],
                deployer.address
            )
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});
