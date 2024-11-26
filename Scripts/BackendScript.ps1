$PrimaryBackendResourceGroupName = "rgasrwlpri903daa34"
$SecondaryBackendResourceGroupName = "rgasrwlsec903daa34-northeurope"
$BackendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\ToDoApi\.env" # Path to the backend .env file
$newBackendIP = "10.1.2.4"
$LogFilePath = "C:\Temp\BackendScript.log"
$ServiceLogFilePath = "C:\Temp\BackendService.log"
$TaskName = "StartBackendService"

# Create or clear the log file
New-Item -Path $LogFilePath -ItemType File -Force
New-Item -Path $ServiceLogFilePath -ItemType File -Force

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

# Create a scheduled task to start the backend service
Write-Output 'Creating scheduled task to start backend service...' | Out-File $LogFilePath -Append
$Action = New-ScheduledTaskAction -Execute "dotnet" -Argument "run" -WorkingDirectory "C:\Users\TomasTheAdmin\demoapp\ToDoApi"
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings | Out-File $LogFilePath -Append

# Start the scheduled task
Start-ScheduledTask -TaskName $TaskName | Out-File $LogFilePath -Append
Write-Output 'Scheduled task started successfully.' | Out-File $LogFilePath -Append

# Wait for a longer period to allow the service to start
Start-Sleep -Seconds 5

# Check if the backend service is running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:6003" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Output 'Backend service is running.' | Out-File $LogFilePath -Append
    } else {
        Write-Output 'Backend service is not running. Status code: ' + $response.StatusCode | Out-File $LogFilePath -Append
    }
} catch {
    Write-Output 'Failed to access backend service. Error: ' + $_.Exception.Message | Out-File $LogFilePath -Append
}

# Output the contents of the service log file
Write-Output 'Backend service log:' | Out-File $LogFilePath -Append
Get-Content -Path $ServiceLogFilePath | Out-File $LogFilePath -Append

# Clean up the scheduled task
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false | Out-File $LogFilePath -Append