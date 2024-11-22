param (
    [parameter(Mandatory=$false)]
    [Object]$RecoveryPlanContext
)

# Define static variables
$PrimaryFrontendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryFrontendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$PrimaryBackendIP = "10.0.3.4"
$SecondaryBackendIP = "10.1.2.4"

$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"

# Convert RecoveryPlanContext from JSON
Write-Output "Converting RecoveryPlanContext from JSON..."
$RecoveryPlanContextObj = $RecoveryPlanContext | ConvertFrom-Json
Write-Output "RecoveryPlanContext converted successfully."

# Determine the failover direction from the RecoveryPlanContext
$FailoverDirection = $RecoveryPlanContextObj.FailoverDirection
Write-Output "Failover Direction Identified as: $FailoverDirection"

# Determine the new backend IP address and resource groups based on the failover direction
Write-Output "Setting the variables according to the failover direction..."
if ($FailoverDirection -eq "PrimaryToSecondary") {
    $newBackendIP = $SecondaryBackendIP
    $FrontendResourceGroupName = $SecondaryFrontendResourceGroupName
    $BackendResourceGroupName = $SecondaryBackendResourceGroupName
} elseif ($FailoverDirection -eq "SecondaryToPrimary") {
    $newBackendIP = $PrimaryBackendIP
    $FrontendResourceGroupName = $PrimaryFrontendResourceGroupName
    $BackendResourceGroupName = $PrimaryBackendResourceGroupName
} else {
    throw "Invalid RecoveryPlanContext: Unable to determine failover direction."
}
Write-Output "Variables set successfully. New Backend IP: $newBackendIP"

# Connect to Azure using Managed Identity
Write-Output "Connecting to Azure using Managed Identity..."
$startTime = Get-Date
Connect-AzAccount -Identity
$endTime = Get-Date
Write-Output "Connected to Azure. Time taken: $($endTime - $startTime)"

# Determine if this is a test failover
$IsTestFailover = $RecoveryPlanContextObj.RecoveryPlanName -match "TestFailover"
Write-Output "Is Test Failover: $IsTestFailover"

# Query the frontend VM based on tags or naming convention
Write-Output "Querying frontend VM..."
$startTime = Get-Date
$frontendVM = if ($IsTestFailover) {
    Get-AzVM -ResourceGroupName $FrontendResourceGroupName | Where-Object { $_.Name -match "VM1-FE-test" -and $_.Tags["Role"] -eq "Frontend" }
} else {
    Get-AzVM -ResourceGroupName $FrontendResourceGroupName | Where-Object { $_.Tags["Role"] -eq "Frontend" }
}
$endTime = Get-Date
Write-Output "Frontend VM queried. Time taken: $($endTime - $startTime)"
Write-Output "Frontend VM Name: $($frontendVM.Name)"

# Query the backend VM based on tags or naming convention
Write-Output "Querying backend VM..."
$startTime = Get-Date
$backendVM = if ($IsTestFailover) {
    Get-AzVM -ResourceGroupName $BackendResourceGroupName | Where-Object { $_.Name -match "VM2-BE-test" -and $_.Tags["Role"] -eq "Backend" }
} else {
    Get-AzVM -ResourceGroupName $BackendResourceGroupName | Where-Object { $_.Tags["Role"] -eq "Backend" }
}
$endTime = Get-Date
Write-Output "Backend VM queried. Time taken: $($endTime - $startTime)"
Write-Output "Backend VM Name: $($backendVM.Name)"

# URLs to the scripts
$frontendScriptUrl = "https://raw.githubusercontent.com/tomasbogalho/ASR-TOAPP-DEMO/refs/heads/master/Scripts/FrontendScript.ps1?token=GHSAT0AAAAAAC2YNZOIGIACPGHPGWDCN6WWZZ76KFA"
$backendScriptUrl = "https://raw.githubusercontent.com/tomasbogalho/ASR-TOAPP-DEMO/refs/heads/master/Scripts/BackendScript.ps1?token=GHSAT0AAAAAAC2YNZOJUYIVKAW5GHT35ZGUZZ76JOQ"

# Download and run the frontend script on the frontend VM
Write-Output "Downloading and running frontend script on the frontend VM..."
$startTime = Get-Date
Invoke-WebRequest -Uri $frontendScriptUrl -OutFile "C:\Temp\FrontendScript.ps1"
Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptPath 'C:\Temp\FrontendScript.ps1'
$endTime = Get-Date
Write-Output "Frontend VM updated. Time taken: $($endTime - $startTime)"

# Read and output the frontend script log
$frontendLogPath = "C:\Temp\FrontendScript.log"
if (Test-Path $frontendLogPath) {
    Write-Output "Frontend Script Log:"
    Get-Content -Path $frontendLogPath | Write-Output
} else {
    Write-Output "Frontend script log not found."
}

# Download and run the backend script on the backend VM
Write-Output "Downloading and running backend script on the backend VM..."
$startTime = Get-Date
Invoke-WebRequest -Uri $backendScriptUrl -OutFile "C:\Temp\BackendScript.ps1"
Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptPath 'C:\Temp\BackendScript.ps1'
$endTime = Get-Date
Write-Output "Backend VM updated. Time taken: $($endTime - $startTime)"

# Read and output the backend script log
$backendLogPath = "C:\Temp\BackendScript.log"
if (Test-Path $backendLogPath) {
    Write-Output "Backend Script Log:"
    Get-Content -Path $backendLogPath | Write-Output
} else {
    Write-Output "Backend script log not found."
}