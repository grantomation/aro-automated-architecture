param keyVaultName string

@secure()
param secretName string

@secure()
param secretValue string



resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: kv
  name: secretName
  properties: {
    value: secretValue
  }
}
