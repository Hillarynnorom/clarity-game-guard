import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure users can join community",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("game-guard", "join-community", [], user1.address)
    ]);

    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Test member verification by authorized users",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const moderator = accounts.get("wallet_1")!;
    const user = accounts.get("wallet_2")!;

    let block = chain.mineBlock([
      Tx.contractCall("game-guard", "join-community", [], user.address),
      Tx.contractCall("game-guard", "verify-member", [types.principal(user.address)], deployer.address)
    ]);

    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Test role management functions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("game-guard", "create-role", [
        types.ascii("custom-role"),
        types.tuple({
          'can-invite': types.bool(true),
          'can-verify': types.bool(true),
          'can-moderate': types.bool(false),
          'can-manage-roles': types.bool(false)
        })
      ], deployer.address),
      Tx.contractCall("game-guard", "join-community", [], user.address),
      Tx.contractCall("game-guard", "assign-role", 
        [types.principal(user.address), types.ascii("custom-role")],
        deployer.address
      )
    ]);

    assertEquals(block.receipts.length, 3);
    block.receipts.map(receipt => receipt.result.expectOk());
  },
});
