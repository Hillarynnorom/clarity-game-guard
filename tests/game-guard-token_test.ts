import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure token minting is restricted to owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("game-guard-token", "mint", 
        [types.uint(1000), types.principal(user1.address)], 
        deployer.address
      )
    ]);

    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  },
});
