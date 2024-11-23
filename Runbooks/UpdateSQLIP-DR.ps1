param (
    [parameter(Mandatory=$false)]
    [Object]$RecoveryPlanContext
)

# Define static variables
$PrimaryFrontendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryFrontendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$PrimaryBackendIP = "10.0.3.4"
$SecondaryBackendIP = "10.1.2.4"
$FrontendServiceName = "YourFrontendServiceName"
$FrontendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\todo-frontend\.env" # Path to the frontend .env file

$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$BackendServiceName = "YourBackendServiceName"
$BackendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\ToDoApi\.env" # Path to the backend .env file

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
    $newBackendIP = $SecondaryBackendIP
    $FrontendResourceGroupName = $SecondaryFrontendResourceGroupName
    $BackendResourceGroupName = $SecondaryBackendResourceGroupName
} else {
    $newBackendIP = $PrimaryBackendIP
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

# Script to update environment variable and restart service on the frontend VM
$frontendScript = @"
param (
    [string]`$newBackendIP
)
`$envFilePath = '$FrontendEnvFilePath'
`$newBackendIP = `$newBackendIP
. `$frontendScriptPath
"@

# Run the script on the frontend VM
Write-Output "Updating frontend VM..."
Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptString $frontendScript -Parameters @{ newBackendIP = $newBackendIP }
Write-Output "Frontend VM updated."

# Script to update environment variable and restart service on the backend VM
$backendScript = @"
param (
    [string]`$newBackendIP
)
`$envFilePath = '$BackendEnvFilePath'
`$newBackendIP = `$newBackendIP
. `$backendScriptPath
"@

# Run the script on the backend VM
Write-Output "Updating backend VM..."
Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptString $backendScript -Parameters @{ newBackendIP = $newBackendIP }
Write-Output "Backend VM updated."

# Read and output the frontend script log
$frontendLogPath = "C:\Temp\FrontendScript.log"
$frontendLogContent = Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptString "Get-Content -Path $frontendLogPath -Raw"
if ($frontendLogContent.Value) {
    Write-Output "Frontend Script Log:"
    Write-Output $frontendLogContent.Value
} else {
    Write-Output "Frontend script log not found."
}

# Read and output the backend script log
$backendLogPath = "C:\Temp\BackendScript.log"
$backendLogContent = Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptString "Get-Content -Path $backendLogPath -Raw"
if ($backendLogContent.Value) {
    Write-Output "Backend Script Log:"
    Write-Output $backendLogContent.Value
} else {
    Write-Output "Backend script log not found."
}