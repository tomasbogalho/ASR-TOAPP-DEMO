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

# URLs to the scripts
$frontendScriptUrl = "https://raw.githubusercontent.com/tomasbogalho/ASR-TOAPP-DEMO/refs/heads/master/Scripts/FrontendScript.ps1?token=GHSAT0AAAAAAC2YNZOIGIACPGHPGWDCN6WWZZ76KFA"
$backendScriptUrl = "https://raw.githubusercontent.com/tomasbogalho/ASR-TOAPP-DEMO/refs/heads/master/Scripts/BackendScript.ps1?token=GHSAT0AAAAAAC2YNZOJUYIVKAW5GHT35ZGUZZ76JOQ"

# Download and run the frontend script on the frontend VM
Write-Output "Downloading and running frontend script on the frontend VM..."
Invoke-WebRequest -Uri $frontendScriptUrl -OutFile "FrontendScript.ps1"
Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptPath 'FrontendScript.ps1'
Write-Output "Frontend VM updated."

# Download and run the backend script on the backend VM
Write-Output "Downloading and running backend script on the backend VM..."
Invoke-WebRequest -Uri $backendScriptUrl -OutFile "BackendScript.ps1"
Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptPath 'BackendScript.ps1'
Write-Output "Backend VM updated."