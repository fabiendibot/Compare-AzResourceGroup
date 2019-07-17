parameters {
    [String]$StorageAccount,
    [String]$StorageAccountResourceGroup,
    [String]$ContainerName = "comparerg",
    [String]$TenantID,
    [String]$SubscriptionID
 
}

$WeekOfTheYear = get-date -UFormat %V
$PreviousWeek = [int]$WeekOfTheYear - 1
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# Connection to the to be audited subscription
Try {
    if ($TenantID) {
        Login-AzAccount -TenantId $TenantID
    }
    else {
        Login-AzAccount
    }
    Select-AzSubscription -SubscriptionId $SubscriptionID
}
Catch {
    throw "Error connecting to your subscription."
}

# Connect to the storage account
Try {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageAccountResourceGroup -Name $StorageAccount
    $StorageContext = $StorageAccount.context
}
Catch {
    Throw "Error connecting the storage account"
}


Try {
    # Get all Azure resources in the subscription
    Get-AzResource | Out-File $WeekOfTheYear
}
Catch {
    Throw "Error getting informations about the services deployed in the subscription"
}

Try {
    if (Get-AzStorageBlob -Container $ContainerName -Context $StorageContext | ? { $_.Name -eq $WeekOfTheYear }) {
        throw "Already audited this subscription this week."
    }
    # Push the audit file to container
    set-AzStorageblobcontent -File $WeekOfTheYear -Container $containerName -Blob $WeekOfTheYear -Context $StorageContext
}
Catch {
    Throw "Error uploading audit file into container"
}

# test the presence of the previous audit file
if (!(Get-AzStorageBlob -Container $ContainerName -Context $StorageContext | ? { $_.Name -eq $PeviousWeek })) {
    Write-Information "First week launching the audit. No differencies to print."
}
else {
    Try {
        $Array = @()
        Get-AzStorageblobcontent -Blob $PreviousWeek -Container $containerName -Destination "$scriptpath\comparerg\" -Context $StorageContext -Force
        $CompareResult = Compare-Object -ReferenceObject (get-content $scriptPath\comparerg\$PreviousWeek) -DifferenceObject (get-content $scriptPath\comparerg\$WeekOfTheYear)


        Write-Output "Here is the list of the added/removed services"
        $NewObject     = $CompareResult | ? { $_.SideIndicator -eq "=>" }
            $NewObject.inputObject | ? { $_ -like  "ResourceId*" } | % { 
            $Resource = $_.split(":")[1].trim()
            Write-Host "[" -NoNewline
            Write-Host "+" -ForegroundColor Green -NoNewline
            Write-Host "] - $Resource "
            $Array += "$Resource,Created"
        }

        $RemovedObject = $CompareResult | ? { $_.SideIndicator -eq "<=" }
        $RemovedObject.inputObject | ? { $_ -like  "ResourceId*" } | % {
    
            $Resource = $_.split(":")[1].trim()
            Write-Host "[" -NoNewline
            Write-Host "+" -ForegroundColor Red -NoNewline
            Write-Host "] - $Resource"
            $Array += "$Resource,Removed"
        }

        $Array | Out-File "$scriptPath\csv\Compare$PreviousWeekTo$WeekofTheyear.csv" -Force
    }
    Catch {
        Throw "Comparaison from previous week has failed"
    }

}




