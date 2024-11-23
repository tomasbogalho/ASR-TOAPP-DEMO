$SecondaryBackendIP = "10.1.2.4"
$FrontendEnvFilePath = "C:\Users\TomasTheAdmin\demoapp\todo-frontend\.env" # Path to the frontend .env file
$LogFilePath = "C:\Temp\FrontendScript.log"

# Create or clear the log file
New-Item -Path $LogFilePath -ItemType File -Force

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
    Write-Output 'Ensuring kill-port package is installed...' | Out-File $LogFilePath -Append
    npm install kill-port | Out-File $LogFilePath -Append

    # Kill any process using port 3000
    npx kill-port 3000 | Out-File $LogFilePath -Append

    # Start the frontend service in the background using Start-Process
    Write-Output 'Starting frontend service in the background...' | Out-File $LogFilePath -Append
    Start-Process -FilePath "npm" -ArgumentList "start" -WorkingDirectory "C:\Users\TomasTheAdmin\demoapp\todo-frontend" -NoNewWindow -RedirectStandardOutput "C:\Temp\FrontendService.log" -RedirectStandardError "C:\Temp\FrontendService.log"
    Write-Output 'Frontend service started successfully in the background.' | Out-File $LogFilePath -Append

    # Wait for a longer period to allow the service to start
    Start-Sleep -Seconds 30

    # Check if the frontend service is running
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Output 'Frontend service is running.' | Out-File $LogFilePath -Append
        } else {
            Write-Output 'Frontend service is not running. Status code: ' + $response.StatusCode | Out-File $LogFilePath -Append
        }
    } catch {
        Write-Output 'Failed to access frontend service. Error: ' + $_.Exception.Message | Out-File $LogFilePath -Append
    }
} else {
    Write-Output "Frontend project path not found: C:\Users\TomasTheAdmin\demoapp\todo-frontend" | Out-File $LogFilePath -Append
}