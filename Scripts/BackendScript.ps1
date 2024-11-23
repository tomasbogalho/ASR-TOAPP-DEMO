$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$BackendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\ToDoApi\.env" # Path to the backend .env file
$newBackendIP = "10.1.2.4"
$LogFilePath = "C:\Temp\BackendScript.log"

# Create or clear the log file
New-Item -Path $LogFilePath -ItemType File -Force

Write-Output 'Starting backend script...' | Out-File $LogFilePath -Append
if (Test-Path $BackendEnvFilePath) {
    Write-Output 'Backend .env file found.' | Out-File $LogFilePath -Append
    # Update .env file
    $envFilePath = $BackendEnvFilePath
    $envFileContent = Get-Content -Path $envFilePath
    Write-Output 'Current .env file content:' | Out-File $LogFilePath -Append
    Write-Output $envFileContent | Out-File $LogFilePath -Append
    $updatedEnvFileContent = $envFileContent -replace 'BACKEND_IP=.*', "BACKEND_IP=$newBackendIP"
    Set-Content -Path $envFilePath -Value $updatedEnvFileContent
    Write-Output 'Updated .env file content:' | Out-File $LogFilePath -Append
    Write-Output $updatedEnvFileContent | Out-File $LogFilePath -Append
    Write-Output 'Backend .env file updated successfully.' | Out-File $LogFilePath -Append
} else {
    Write-Output "Backend .env file not found at path: $BackendEnvFilePath" | Out-File $LogFilePath -Append
}
cd C:\Users\TomasTheAdmin\demoapp\ToDoApi

# Find all running `dotnet` processes
$dotnetProcesses = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq "dotnet.exe" }

# Check if any `dotnet` processes are running
if ($dotnetProcesses) {
    Write-Host "Found .NET processes running:" -ForegroundColor Green | Out-File $LogFilePath -Append
    $dotnetProcesses | Select-Object ProcessId, CommandLine | Format-Table | Out-File $LogFilePath -Append

    # Stop each process
    foreach ($process in $dotnetProcesses) {
        try {
            Write-Host "Stopping process ID $($process.ProcessId)..." -ForegroundColor Yellow | Out-File $LogFilePath -Append
            Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
            Write-Host "Successfully stopped process ID $($process.ProcessId)." -ForegroundColor Green | Out-File $LogFilePath -Append
        } catch {
            Write-Host "Failed to stop process ID $($process.ProcessId): $_" -ForegroundColor Red | Out-File $LogFilePath -Append
        }
    }
} else {
    Write-Host "No .NET processes found." -ForegroundColor Cyan | Out-File $LogFilePath -Append
}

Write-Output 'Running dotnet run...' | Out-File $LogFilePath -Append
Start-Process -FilePath "dotnet" -ArgumentList "run" -NoNewWindow -RedirectStandardOutput $LogFilePath -RedirectStandardError $LogFilePath
Write-Output 'Backend service started successfully in the background.' | Out-File $LogFilePath -Append