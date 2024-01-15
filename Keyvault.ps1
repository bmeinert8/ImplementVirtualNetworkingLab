# Create the Resource Group for the deployment
$rg = New-AzResourceGroup -Name 'VnetLabeus' -Location 'Eastus2'

# Create the KeyVault in the resource group.
$vault = New-AzKeyVault -Name 'VnetLabKeyVaulteus2' -ResourceGroupName $rg -Location 'Eastus2' -EnabledForDeployment -EnabledForTemplateDeployment

# Create the admin username and admin password secrets for the vm
$secret1 = ConvertTo-SecureString 'Username' -AsPlainText -Force
$secret2 = ConvertTo-SecureString 'Password' -AsPlainText -Force

# Add the secrets to key vault
Set-AzKeyVaultSecret -VaultName $vault -Name "AdminUsername" -SecretValue $secret1
Set-AzKeyVaultSecret -VaultName $vault -Name "AdminPassword" -SecretValue $secret2
