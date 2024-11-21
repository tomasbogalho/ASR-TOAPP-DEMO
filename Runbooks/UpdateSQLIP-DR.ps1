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
$FrontendEnvFilePath = "C:\Users\TomasTheAdmin\todo-frontend\.env" # Path to the frontend .env file

$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$BackendServiceName = "YourBackendServiceName"
$BackendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\ToDoApi\.env" # Path to the backend .env file

# Extract FailoverType and FailoverDirection from RecoveryPlanContext
if (-not $RecoveryPlanContext) {
    throw "RecoveryPlanContext parameter is required."
}

$FailoverType = $RecoveryPlanContext.FailoverType
$FailoverDirection = $RecoveryPlanContext.FailoverDirection

# Validate FailoverType and FailoverDirection
if (-not $FailoverType) {
    throw "FailoverType is required in RecoveryPlanContext."
}

if (-not $FailoverDirection) {
    throw "FailoverDirection is required in RecoveryPlanContext."
}

# Output the failover type and direction
Write-Output "Failover Type: $FailoverType"
Write-Output "Failover Direction: $FailoverDirection"

# Determine if this is a test failover based on the FailoverType
$IsTestFailover = $FailoverType -match "Test"

# Output whether it is an actual failover or a test failover
if ($IsTestFailover) {
    Write-Output "This is a test failover."
} else {
    Write-Output "This is an actual failover."
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
$startTime = Get-Date
Connect-AzAccount -Identity
$endTime = Get-Date
Write-Output "Connected to Azure. Time taken: $($endTime - $startTime)"

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

# Script to update environment variable and restart service on the frontend VM
$frontendScript = @"
Write-Output 'Starting frontend script...'
if (Test-Path '$FrontendEnvFilePath') {
    Write-Output 'Frontend .env file found.'
    # Update .env file
    \$envFilePath = '$FrontendEnvFilePath'
    \$newBackendIP = '$newBackendIP'
    \$envFileContent = Get-Content -Path \$envFilePath
    Write-Output 'Current .env file content:'
    Write-Output \$envFileContent
    \$updatedEnvFileContent = \$envFileContent -replace 'REACT_APP_API_BASE_URL=.*', 'REACT_APP_API_BASE_URL=http://\$newBackendIP:6003'
    Set-Content -Path \$envFilePath -Value \$updatedEnvFileContent
    Write-Output 'Updated .env file content:'
    Write-Output \$updatedEnvFileContent
    Write-Output 'Frontend .env file updated successfully.'
} else {
    Write-Output 'Frontend .env file not found.'
}
cd C:\Users\TomasTheAdmin\todo-frontend
npm start
Write-Output 'Frontend service restarted successfully.'
"@

# Run the script on the frontend VM
Write-Output "Updating frontend VM..."
$startTime = Get-Date
Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptString $frontendScript
$endTime = Get-Date
Write-Output "Frontend VM updated. Time taken: $($endTime - $startTime)"

# Script to update environment variable and restart service on the backend VM
$backendScript = @"
Write-Output 'Starting backend script...'
if (Test-Path '$BackendEnvFilePath') {
    Write-Output 'Backend .env file found.'
    # Update .env file
    \$envFilePath = '$BackendEnvFilePath'
    \$newBackendIP = '$newBackendIP'
    \$envFileContent = Get-Content -Path \$envFilePath
    Write-Output 'Current .env file content:'
    Write-Output \$envFileContent
    \$updatedEnvFileContent = \$envFileContent -replace 'BACKEND_IP=.*', 'BACKEND_IP=\$newBackendIP'
    Set-Content -Path \$envFilePath -Value \$updatedEnvFileContent
    Write-Output 'Updated .env file content:'
    Write-Output \$updatedEnvFileContent
    Write-Output 'Backend .env file updated successfully.'
} else {
    Write-Output 'Backend .env file not found.'
}
cd C:\Users\TomasTheAdmin\demoapp\ToDoApi
dotnet run
Write-Output 'Backend service restarted successfully.'
"@

# Run the script on the backend VM
Write-Output "Updating backend VM..."
$startTime = Get-Date
Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptString $backendScript
$endTime = Get-Date
Write-Output "Backend VM updated. Time taken: $($endTime - $startTime)"