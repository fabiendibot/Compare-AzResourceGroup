# Compare-AzResourceGroup
A powershell script to compare services created in a subscription weeks over weeks

# How it works
The script will connect to your Azure subscription and list all the ressources in a file. 
Once it's done, the file will be uploaded as blob in a storage account container.

The second time this script is launched, it'll list again all the resources deployed in the subscription and upload the file for hitorization in the container.
After that, it'll downlaod the previous week audit file and compare it to the new one.
The results will be printed on the screen as well as recored in a CSV into /csv/ directory.

# Few things to do before launching the script
1. Create an Azure storage account and a container to store audit files as blobs
2. Fill parameters at the script begining to match storage account, the resrouce group where the storage account is and the container name
3. TenantID parameter is not mandatory
4. SubscriptionID is mandatory

# Launch the script
`.\compare.ps1`

