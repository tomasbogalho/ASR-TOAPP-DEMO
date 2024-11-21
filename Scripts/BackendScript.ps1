$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$BackendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\ToDoApi\.env" # Path to the backend .env file
$newBackendIP = "10.1.2.4"


Write-Output 'Starting backend script...'
if (Test-Path $BackendEnvFilePath) {
    Write-Output 'Backend .env file found.'
    # Update .env file
    $envFilePath = $BackendEnvFilePath
    $envFileContent = Get-Content -Path $envFilePath
    Write-Output 'Current .env file content:'
    Write-Output $envFileContent
    $updatedEnvFileContent = $envFileContent -replace 'BACKEND_IP=.*', ('BACKEND_IP='+$newBackendIP)
    Set-Content -Path $envFilePath -Value $updatedEnvFileContent
    Write-Output 'Updated .env file content:'
    Write-Output $updatedEnvFileContent
    Write-Output 'Backend .env file updated successfully.'
} else {
    Write-Output 'Backend .env file not found.'
}
cd C:\Users\TomasTheAdmin\demoapp\ToDoApi


# Find all running `dotnet` processes
$dotnetProcesses = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq "dotnet.exe" }

# Check if any `dotnet` processes are running
if ($dotnetProcesses) {
    Write-Host "Found .NET processes running:" -ForegroundColor Green
    $dotnetProcesses | Select-Object ProcessId, CommandLine | Format-Table

    # Stop each process
    foreach ($process in $dotnetProcesses) {
        try {
            Write-Host "Stopping process ID $($process.ProcessId)..." -ForegroundColor Yellow
            Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
            Write-Host "Successfully stopped process ID $($process.ProcessId)." -ForegroundColor Green
        } catch {
            Write-Host "Failed to stop process ID $($process.ProcessId): $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No .NET processes found." -ForegroundColor Cyan
}

dotnet run
Write-Output 'Backend service restarted successfully.'

