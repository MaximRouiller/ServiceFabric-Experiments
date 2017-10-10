$resourceGroupName = "rgServiceFabricCluster"
$location = "eastus"

# Create our resource group
az group create --location $location --name $resourceGroupName

# Create our KeyVault Standard instance
az keyvault create --name my-sfcluster-keyvault --location $location --resource-group $resourceGroupName --enabled-for-deployment

# This command export the policy on file. 
az keyvault certificate get-default-policy > defaultpolicy.json

# !IMPORTANT! 
# By default, PowerShell encode files in UTF-16LE. Azure CLI 2.0 doesn't support it at the time of this writing. So I can't use the file directly. 
# I need to tell PowerShell to convert to a specific encoding (utf8).
$policy = Get-Content .\defaultpolicy.json
$policy | Out-File -Encoding utf8 -FilePath .\defaultpolicy.json

# This command creates a self-signed certificate.
az keyvault certificate create --vault-name my-sfcluster-keyvault -n sfcert -p `@defaultpolicy.json

rm sfcert.pfx
az keyvault secret download --vault-name my-sfcluster-keyvault -n sfcert -e base64 -f sfcert.pfx

Import-PfxCertificate .\sfcert.pfx -CertStoreLocation Cert:\CurrentUser\My\

$resourceId = az keyvault show -n my-sfcluster-keyvault --query id -o tsv
$certificateUrl =az keyvault certificate show --vault-name my-sfcluster-keyvault -n sfcert --query sid -o tsv
$thumbprint=az keyvault certificate show --vault-name my-sfcluster-keyvault -n sfcert --query x509ThumbprintHex -o tsv

@{Thumbprint=$thumbprint; ResourceId=$resourceId; CertificateUrl=$certificateUrl}