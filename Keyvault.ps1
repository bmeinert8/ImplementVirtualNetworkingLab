# Create the KeyVault in the resource group.
New-AzKeyVault -Name 'VnetLabKeyVaulteus2' -ResourceGroupName 'VnetLabeus' -Location 'East US 2' -EnabledForDeployment -EnabledForTemplateDeployment

# Create the admin username and admin password secrets for the vm
$secret1 = ConvertTo-SecureString 'Username' -AsPlainText -Force
$secret2 = ConvertTo-SecureString 'Password' -AsPlainText -Force

# Add the secrets to key vault
Set-AzKeyVaultSecret -VaultName "VnetLabKeyVaulteus2" -Name "AdminUsername" -SecretValue $secret1
Set-AzKeyVaultSecret -VaultName "VnetLabKeyVaulteus2" -Name "AdminPassword" -SecretValue $secret2
