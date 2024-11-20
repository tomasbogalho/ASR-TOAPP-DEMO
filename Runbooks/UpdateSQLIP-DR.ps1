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
Connect-AzAccount -Identity

# Query the frontend VM based on tags
$frontendVM = Get-AzVM -ResourceGroupName $FrontendResourceGroupName | Where-Object { $_.Tags["Role"] -eq "Frontend" }

# Query the backend VM based on tags
$backendVM = Get-AzVM -ResourceGroupName $BackendResourceGroupName | Where-Object { $_.Tags["Role"] -eq "Backend" }

# Script to update environment variable and restart service on the frontend VM
$frontendScript = @"
if (Test-Path '$FrontendEnvFilePath') {
    # Update .env file
    \$envFilePath = '$FrontendEnvFilePath'
    \$newBackendIP = '$newBackendIP'
    \$envFileContent = Get-Content -Path \$envFilePath
    \$updatedEnvFileContent = \$envFileContent -replace 'REACT_APP_API_BASE_URL=.*', 'REACT_APP_API_BASE_URL=http://\$newBackendIP:6003'
    Set-Content -Path \$envFilePath -Value \$updatedEnvFileContent
    Write-Output 'Frontend .env file updated successfully.'
} else {
    Write-Output 'Frontend .env file not found.'
}
cd C:\Users\TomasTheAdmin\todo-frontend
npm start
Write-Output 'Frontend service restarted successfully.'
"@

# Run the script on the frontend VM
Invoke-AzVMRunCommand -ResourceGroupName $FrontendResourceGroupName -VMName $frontendVM.Name -CommandId 'RunPowerShellScript' -ScriptString $frontendScript

# Script to update environment variable and restart service on the backend VM
$backendScript = @"
if (Test-Path '$BackendEnvFilePath') {
    # Update .env file
    \$envFilePath = '$BackendEnvFilePath'
    \$newBackendIP = '$newBackendIP'
    \$envFileContent = Get-Content -Path \$envFilePath
    \$updatedEnvFileContent = \$envFileContent -replace 'BACKEND_IP=.*', 'BACKEND_IP=\$newBackendIP'
    Set-Content -Path \$envFilePath -Value \$updatedEnvFileContent
    Write-Output 'Backend .env file updated successfully.'
} else {
    Write-Output 'Backend .env file not found.'
}
cd C:\Users\TomasTheAdmin\demoapp\ToDoApi
dotnet run
Write-Output 'Backend service restarted successfully.'
"@

# Run the script on the backend VM
Invoke-AzVMRunCommand -ResourceGroupName $BackendResourceGroupName -VMName $backendVM.Name -CommandId 'RunPowerShellScript' -ScriptString $backendScript