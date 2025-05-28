# Create a nano contract

{
  "method": "htr_sendNanoContractTx",
  "params": {
    "method": "initialize",
    "address": "WXNSUbP5orwSpUJ2hzHKUs1HmwA8PcDoej",
    "blueprint_id": "0000074c490bb372d4edc0921706b7ac27ca41ba7939562a5e66415b5c57b56d",
    "actions": [{
        "type": "deposit",
        "token": "00",
        "amount": "10",
        "changeAddress": "WXNSUbP5orwSpUJ2hzHKUs1HmwA8PcDoej"
    }],
    "args": [],
    "push_tx": true
  }
}

# 0000013f5e3b152895b87e0c7d185efdd0f283d17a0baf8e4669a9b5b760c1a5
# Create a token (the contract will pay for it):

```json
{
  "method": "htr_createNanoContractCreateTokenTx",
  "params": {
    "method": "create_token",
    "address": "WXNSUbP5orwSpUJ2hzHKUs1HmwA8PcDoej",
    "data": {
      "ncId": "0000013f5e3b152895b87e0c7d185efdd0f283d17a0baf8e4669a9b5b760c1a5",
      "blueprintId": "0000074c490bb372d4edc0921706b7ac27ca41ba7939562a5e66415b5c57b56d",
      "actions": [{
        "type": "withdrawal",
        "token": "00",
        "amount": "10",
        "address": "WXNSUbP5orwSpUJ2hzHKUs1HmwA8PcDoej"
      }],
      "args": []
    },
    "createTokenOptions": {
      "address": null,
      "allowExternalMeltAuthorityAddress": false,
      "allowExternalMintAuthorityAddress": false,
      "amount": "100",
      "changeAddress": null,
      "createMelt": true,
      "createMint": true,
      "name": "Create Token Contract Pays",
      "symbol": "CTCP",
      "contractPaysTokenDeposit": true
    },
    "push_tx": true
  }
}
```

# 0000017594f60ea9e8c2adae76d19cabd4a928fa9dc5179fdb93eac4a46774fe

{
  "method": "htr_sendNanoContractTx",
  "params": {
    "method": "grant_authority",
    "address": "WXNSUbP5orwSpUJ2hzHKUs1HmwA8PcDoej",
    "nc_id": "0000013f5e3b152895b87e0c7d185efdd0f283d17a0baf8e4669a9b5b760c1a5",
    "blueprint_id": "0000074c490bb372d4edc0921706b7ac27ca41ba7939562a5e66415b5c57b56d",
    "actions": [{
        "type": "grant_authority",
        "token": "000001263938b881c8cb79fc3dc56fd416b3f2b83c15cf20ebf462a0783fdff2",
        "authority": "melt",
        "authorityAddress": "WXNSUbP5orwSpUJ2hzHKUs1HmwA8PcDoej"
    }],
    "args": [],
    "push_tx": true
  }
}

{
  "method": "htr_sendNanoContractTx",
  "params": {
    "method": "invoke_authority",
    "address": "WXNSUbP5orwSpUJ2hzHKUs1HmwA8PcDoej",
    "nc_id": "0000012dfb5861f954aa1c731690125c48cf35ad1bfc19677b6e810c1bd6d249",
    "blueprint_id": "00000436b140dd0452e5e6fa790bb40e94d8e89fd849a819cd68454e577dcce7",
    "actions": [{
        "type": "invoke_authority",
        "token": "0000017594f60ea9e8c2adae76d19cabd4a928fa9dc5179fdb93eac4a46774fe",
        "authority": "mint",
        "address": "WXNSUbP5orwSpUJ2hzHKUs1HmwA8PcDoej"
    }],
    "args": [],
    "push_tx": true
  }
}
