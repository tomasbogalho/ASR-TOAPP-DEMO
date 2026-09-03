# ASR ToDo App Demo

A small full-stack ToDo application used to demonstrate application recovery and backend switching. It consists of a React frontend, an ASP.NET Core API, and a SQL Server database.

## Architecture

| Component | Location | Default address |
| --- | --- | --- |
| React frontend | `todo-frontend/` | `http://localhost:3000` |
| ASP.NET Core API | `ToDoApi/` | `http://127.0.0.1:6003` |
| SQL Server database | External | Configured with an environment variable |

The frontend reads the API address from `REACT_APP_API_BASE_URL`. The API reads its listening address and database connection from environment variables.

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Node.js and npm](https://nodejs.org/)
- SQL Server with permission to create or use a database
- PowerShell for the deployment and runbook scripts

## Database setup

Create a database and the table expected by Entity Framework Core:

```sql
CREATE DATABASE ToDoDB;
GO

USE ToDoDB;
GO

CREATE TABLE ToDoItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Description NVARCHAR(MAX) NULL,
    IsCompleted BIT NOT NULL
);
```

## Run locally

### 1. Start the API

From `ToDoApi/`, create a `.env` file:

```dotenv
BACKEND_IP=127.0.0.1
BACKEND_PORT=6003
DB_CONNECTION_STRING=Server=localhost;Database=ToDoDB;Integrated Security=True;TrustServerCertificate=True;
```

Use a suitable SQL Server connection string for your environment. Do not commit `.env` files or credentials.

Then start the API:

```powershell
Set-Location ToDoApi
dotnet restore
dotnet run
```

The API should report a successful database connection and listen on `http://127.0.0.1:6003`.

### 2. Start the frontend

Open another terminal and create `todo-frontend/.env`:

```dotenv
REACT_APP_API_BASE_URL=http://127.0.0.1:6003
```

Install dependencies and start the development server:

```powershell
Set-Location todo-frontend
npm install
npm start
```

Open [http://localhost:3000](http://localhost:3000).

## API

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/api/todo` | List all ToDo items |
| `POST` | `/api/todo` | Create a ToDo item |
| `GET` | `/api/backend-ip` | Return the configured backend IP |

Example request:

```powershell
$body = @{ description = "Test the demo"; isCompleted = $false } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri http://127.0.0.1:6003/api/todo -ContentType application/json -Body $body
```

## Build and test

```powershell
dotnet build ToDoApi/ToDoApi.csproj
npm --prefix todo-frontend test -- --watchAll=false
npm --prefix todo-frontend run build
```

## Automation

- `Scripts/BackendScript.ps1` updates the backend address and starts the API through a Windows scheduled task.
- `Scripts/FrontendScript.ps1` updates the frontend API address and starts the React application through a Windows scheduled task.
- `Runbooks/UpdateSQLIP-DR.ps1` supports SQL address updates during recovery operations.
- `Runbooks/Delay_*.ps1` provide simple delays for orchestration workflows.

The automation scripts contain environment-specific paths, resource names, and IP addresses. Review and update them before running. Creating scheduled tasks may require administrator permissions.