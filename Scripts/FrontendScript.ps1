$SecondaryBackendIP = "10.1.2.4"
#$SecondaryBackendIP = "10.0.3.4"
$FrontendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\todo-frontend\.env" # Path to the frontend .env file
$LogFilePath = "C:\Temp\FrontendScript.log"
$ServiceLogFilePath = "C:\Temp\FrontendService.log"
$TaskName = "StartFrontendService"

# Create or clear the log file
New-Item -Path $LogFilePath -ItemType File -Force
New-Item -Path $ServiceLogFilePath -ItemType File -Force

Write-Output 'Starting frontend script...' | Out-File $LogFilePath -Append
if (Test-Path $FrontendEnvFilePath) {
    Write-Output 'Frontend .env file found.' | Out-File $LogFilePath -Append
    # Update .env file
    $envFilePath = $FrontendEnvFilePath
    $newBackendIP = $SecondaryBackendIP
    $envFileContent = Get-Content -Path $envFilePath
    Write-Output 'Current .env file content:' | Out-File $LogFilePath -Append
    Write-Output $envFileContent | Out-File $LogFilePath -Append
    $updatedEnvFileContent = "REACT_APP_API_BASE_URL=http://"+$newBackendIP+":6003"
    Set-Content -Path $envFilePath -Value $updatedEnvFileContent
    Write-Output 'Updated .env file content:' | Out-File $LogFilePath -Append
    Write-Output $updatedEnvFileContent | Out-File $LogFilePath -Append
    Write-Output 'Frontend .env file updated successfully.' | Out-File $LogFilePath -Append
} else {
    Write-Output 'Frontend .env file not found.' | Out-File $LogFilePath -Append
}

if (Test-Path "C:\Users\TomasTheAdmin\demoapp\todo-frontend") {
    cd C:\Users\TomasTheAdmin\demoapp\todo-frontend
    Write-Output "Changed directory to C:\Users\TomasTheAdmin\demoapp\todo-frontend" | Out-File $LogFilePath -Append
    
    # Ensure dependencies are installed
    if (-not (Test-Path "node_modules")) {
        Write-Output 'Installing dependencies...' | Out-File $LogFilePath -Append
        npm install | Out-File $LogFilePath -Append
    }

    # Ensure kill-port package is installed
    #Write-Output 'Ensuring kill-port package is installed...' | Out-File $LogFilePath -Append
    #npm install kill-port | Out-File $LogFilePath -Append

    # Kill any process using port 3000
    npx kill-port 3000 | Out-File $LogFilePath -Append

    # Create a scheduled task to start the frontend service
    Write-Output 'Creating scheduled task to start frontend service...' | Out-File $LogFilePath -Append
    $Action = New-ScheduledTaskAction -Execute "npm" -Argument "start" -WorkingDirectory "C:\Users\TomasTheAdmin\demoapp\todo-frontend"
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings | Out-File $LogFilePath -Append

    # Start the scheduled task
    Start-ScheduledTask -TaskName $TaskName | Out-File $LogFilePath -Append
    Write-Output 'Scheduled task started successfully.' | Out-File $LogFilePath -Append

    # Wait for a longer period to allow the service to start
    Start-Sleep -Seconds 30

    # Check if the frontend service is running
    #try {
    #    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing
    #    if ($response.StatusCode -eq 200) {
    #        Write-Output 'Frontend service is running.' | Out-File $LogFilePath -Append
    #    } else {
    #        Write-Output 'Frontend service is not running. Status code: ' + $response.StatusCode | Out-File $LogFilePath -Append
    #    }
    #} catch {
    #    Write-Output 'Failed to access frontend service. Error: ' + $_.Exception.Message | Out-File $LogFilePath -Append
    #}

    # Output the contents of the service log file
    #Write-Output 'Frontend service log:' | Out-File $LogFilePath -Append
    #Get-Content -Path $ServiceLogFilePath | Out-File $LogFilePath -Append

    # Clean up the scheduled task
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false | Out-File $LogFilePath -Append
} else {
    Write-Output "Frontend project path not found: C:\Users\TomasTheAdmin\demoapp\todo-frontend" | Out-File $LogFilePath -Append
}