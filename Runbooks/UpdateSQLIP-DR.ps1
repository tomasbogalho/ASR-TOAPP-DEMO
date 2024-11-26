param (
    [parameter(Mandatory=$false)]
    [Object]$RecoveryPlanContext
)

# Define static variables

$PrimaryBackendIP = "10.0.3.4"
$SecondaryBackendIP = "10.1.2.4"

$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$PrimaryFrontendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$SecondaryFrontendResourceGroupName = "rgasrwlsec903daa34-northeurope"

# Log the contents of the RecoveryPlanContext parameter
Write-Output "RecoveryPlanContext parameter contents:"
Write-Output $RecoveryPlanContext

# Use the RecoveryPlanContext directly as a PowerShell object
$RecoveryPlanContextObj = $RecoveryPlanContext

# Log the contents of the RecoveryPlanContext object
Write-Output "RecoveryPlanContext contents:"
Write-Output $RecoveryPlanContextObj

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
$IsTestFailover = $RecoveryPlanContextObj.FailoverType -eq "Test"
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
$frontendScriptUrl = "https://raw.githubusercontent.com/tomasbogalho/ASR-TOAPP-DEMO/refs/heads/master/Scripts/FrontendScript.ps1"
$backendScriptUrl = "https://raw.githubusercontent.com/tomasbogalho/ASR-TOAPP-DEMO/refs/heads/master/Scripts/BackendScript.ps1"

# Ensure the Temp directory exists on the frontend VM
Write-Output "Ensuring Temp directory exists on the frontend VM..."
Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptString 'New-Item -Path "C:\Temp" -ItemType Directory -Force'
Write-Output "Temp directory ensured on the frontend VM."

# Run the frontend script on the frontend VM
Write-Output "Running frontend script on the frontend VM..."
$startTime = Get-Date
Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptString (Invoke-WebRequest -Uri $frontendScriptUrl).Content
$endTime = Get-Date
Write-Output "Frontend VM updated. Time taken: $($endTime - $startTime)"

# Read and output the frontend script log
$frontendLogPath = "C:\Temp\FrontendScript.log"
$frontendLogContent = Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptString "Get-Content -Path $frontendLogPath -Raw"
if ($frontendLogContent.Value) {
    Write-Output "Frontend Script Log:"
    Write-Output $frontendLogContent.Value
} else {
    Write-Output "Frontend script log not found."
}

# Ensure the Temp directory exists on the backend VM
Write-Output "Ensuring Temp directory exists on the backend VM..."
Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptString 'New-Item -Path "C:\Temp" -ItemType Directory -Force'
Write-Output "Temp directory ensured on the backend VM."

# Run the backend script on the backend VM
Write-Output "Running backend script on the backend VM..."
$startTime = Get-Date
Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptString (Invoke-WebRequest -Uri $backendScriptUrl).Content
$endTime = Get-Date
Write-Output "Backend VM updated. Time taken: $($endTime - $startTime)"

# Read and output the backend script log
$backendLogPath = "C:\Temp\BackendScript.log"
$backendLogContent = Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptString "Get-Content -Path $backendLogPath -Raw"
if ($backendLogContent.Value) {
    Write-Output "Backend Script Log:"
    Write-Output $backendLogContent.Value
} else {
    Write-Output "Backend script log not found."
}