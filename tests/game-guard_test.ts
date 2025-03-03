// [Previous test code remains unchanged]

Clarinet.test({
  name: "Test role revocation functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("game-guard", "join-community", [], user.address),
      Tx.contractCall("game-guard", "assign-role", 
        [types.principal(user.address), types.ascii("moderator")],
        deployer.address
      ),
      Tx.contractCall("game-guard", "revoke-role",
        [types.principal(user.address)],
        deployer.address
      )
    ]);

    assertEquals(block.receipts.length, 3);
    block.receipts.map(receipt => receipt.result.expectOk());
  },
});

// [Add more test cases]
