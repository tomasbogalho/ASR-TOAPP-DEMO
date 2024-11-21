$PrimaryFrontendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryFrontendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$PrimaryBackendIP = "10.0.3.4"
$SecondaryBackendIP = "10.1.2.4"
$FrontendEnvFilePath = "C:\Users\TomasTheAdmin\todo-frontend\.env" # Path to the frontend .env file

Write-Output 'Starting frontend script...'
if (Test-Path $FrontendEnvFilePath) {
    Write-Output 'Frontend .env file found.'
    # Update .env file
    $envFilePath = $FrontendEnvFilePath
    $newBackendIP = $SecondaryBackendIP
    $envFileContent = Get-Content -Path $envFilePath
    Write-Output 'Current .env file content:'
    Write-Output $envFileContent
    $updatedEnvFileContent = "REACT_APP_API_BASE_URL=http://"+$newBackendIP+":6003"
    Set-Content -Path $envFilePath -Value $updatedEnvFileContent
    Write-Output 'Updated .env file content:'
    Write-Output $updatedEnvFileContent
    Write-Output 'Frontend .env file updated successfully.'
} else {
    Write-Output 'Frontend .env file not found.'
}
cd C:\Users\TomasTheAdmin\todo-frontend
npx kill-port 3000
npm start
Write-Output 'Frontend service restarted successfully.'

powershell.exe -windowstyle hidden -file C:\scripts\script.ps1
