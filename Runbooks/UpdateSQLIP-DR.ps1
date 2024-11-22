param (
    [parameter(Mandatory=$false)]
    [Object]$RecoveryPlanContext
)

# Define static variables
$PrimaryFrontendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryFrontendResourceGroupName = "rgasrwlsec903daa34-northeurope"

$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"

# Determine the failover direction from the RecoveryPlanContext
$FailoverDirection = if ($RecoveryPlanContext.RecoveryPlanName -match "PrimaryToSecondary") {
    "PrimaryToSecondary"
} elseif ($RecoveryPlanContext.RecoveryPlanName -match "SecondaryToPrimary") {
    "SecondaryToPrimary"
} else {
    throw "Invalid RecoveryPlanContext: Unable to determine failover direction."
}

# Determine the new backend IP address and resource groups based on the failover direction
if ($FailoverDirection -eq "PrimaryToSecondary") {
    
    $FrontendResourceGroupName = $SecondaryFrontendResourceGroupName
    $BackendResourceGroupName = $SecondaryBackendResourceGroupName
} else {
    
    $FrontendResourceGroupName = $PrimaryFrontendResourceGroupName
    $BackendResourceGroupName = $PrimaryBackendResourceGroupName
}

# Connect to Azure using Managed Identity
Write-Output "Connecting to Azure..."
Connect-AzAccount -Identity
Write-Output "Connected to Azure."

# Determine if this is a test failover
$IsTestFailover = $RecoveryPlanContext.RecoveryPlanName -match "TestFailover"

# Query the frontend VM based on tags or naming convention
$frontendVM = if ($IsTestFailover) {
    Get-AzVM -ResourceGroupName $FrontendResourceGroupName | Where-Object { $_.Name -match "VM1-FE-test" -and $_.Tags["Role"] -eq "Frontend" }
} else {
    Get-AzVM -ResourceGroupName $FrontendResourceGroupName | Where-Object { $_.Tags["Role"] -eq "Frontend" }
}

# Query the backend VM based on tags or naming convention
$backendVM = if ($IsTestFailover) {
    Get-AzVM -ResourceGroupName $BackendResourceGroupName | Where-Object { $_.Name -match "VM2-BE-test" -and $_.Tags["Role"] -eq "Backend" }
} else {
    Get-AzVM -ResourceGroupName $BackendResourceGroupName | Where-Object { $_.Tags["Role"] -eq "Backend" }
}

# Path to the scripts
$frontendScriptPath = "C:\Users\TomasTheAdmin\demoapp\Scripts\FrontendScript.ps1"
$backendScriptPath = "C:\Users\TomasTheAdmin\demoapp\Scripts\BackendScript.ps1"

# Run the script on the frontend VM
Write-Output "Updating frontend VM..."
Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptPath $frontendScriptPath
Write-Output "Frontend VM updated."

# Run the script on the backend VM
Write-Output "Updating backend VM..."
Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptPath $backendScriptPath
Write-Output "Backend VM updated."