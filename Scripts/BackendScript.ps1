$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$BackendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\ToDoApi\.env" # Path to the backend .env file
$newBackendIP = "10.1.2.4"


Write-Output 'Starting backend script...'
if (Test-Path $BackendEnvFilePath) {
    Write-Output 'Backend .env file found.'
    # Update .env file
    $envFilePath = $BackendEnvFilePath
    $newBackendIP = $newBackendIP
    $envFileContent = Get-Content -Path $envFilePath
    Write-Output 'Current .env file content:'
    Write-Output $envFileContent
    $updatedEnvFileContent = $envFileContent -replace 'BACKEND_IP=.*', 'BACKEND_IP=\$newBackendIP'
    Set-Content -Path $envFilePath -Value $updatedEnvFileContent
    Write-Output 'Updated .env file content:'
    Write-Output $updatedEnvFileContent
    Write-Output 'Backend .env file updated successfully.'
} else {
    Write-Output 'Backend .env file not found.'
}
cd C:\Users\TomasTheAdmin\demoapp\ToDoApi
dotnet run
Write-Output 'Backend service restarted successfully.'
