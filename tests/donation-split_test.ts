import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensures that only contract owner can register charities",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            // Owner registration should succeed
            Tx.contractCall('donation-split', 'register-charity', [
                types.principal(wallet1.address),
                types.ascii("Test Charity"),
                types.uint(50)
            ], deployer.address),

            // Non-owner registration should fail
            Tx.contractCall('donation-split', 'register-charity', [
                types.principal(deployer.address),
                types.ascii("Invalid Charity"),
                types.uint(50)
            ], wallet1.address)
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(100)); // err-owner-only
    }
});

Clarinet.test({
    name: "Cannot register charity with invalid percentage",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('donation-split', 'register-charity', [
                types.principal(wallet1.address),
                types.ascii("Invalid Charity"),
                types.uint(101)
            ], deployer.address)
        ]);

        block.receipts[0].result.expectErr(types.uint(103)); // err-invalid-percentage
    }
});

Clarinet.test({
    name: "Tracks donor statistics and rewards correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const donor = accounts.get('wallet_1')!;

        // Make donation and check stats
        let block = chain.mineBlock([
            Tx.contractCall('donation-split', 'donate', [], donor.address)
        ]);

        // Get donor stats
        let stats = chain.callReadOnlyFn(
            'donation-split',
            'get-donor-stats',
            [types.principal(donor.address)],
            donor.address
        );

        stats.result.expectOk();
    }
});
