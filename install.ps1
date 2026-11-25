$ErrorActionPreference = 'Stop'

foreach ($command in @('uv', 'node', 'npm.cmd')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Missing $command. Install uv and Node.js (including npm), then run this script again."
    }
}

$backend = Join-Path $PSScriptRoot 'backend'
$frontend = Join-Path $PSScriptRoot 'frontend'

Push-Location $backend
try {
    & uv sync --locked
    if ($LASTEXITCODE -ne 0) { throw 'Backend dependency installation failed.' }

    if (-not (Test-Path -LiteralPath '.env')) {
        $createEnv = @'
from pathlib import Path
import secrets

config = Path('.env.example').read_text(encoding='utf-8')
config = config.replace('SECRET_KEY=change-me-to-a-long-random-string', 'SECRET_KEY=' + secrets.token_urlsafe(48))
with open('.env', 'x', encoding='utf-8') as env_file:
    env_file.write(config)
'@
        & uv run --locked python -c $createEnv
        if ($LASTEXITCODE -ne 0) { throw 'Could not create backend/.env.' }
    }
}
finally {
    Pop-Location
}

Push-Location $frontend
try {
    & npm.cmd ci
    if ($LASTEXITCODE -ne 0) { throw 'Frontend dependency installation failed.' }
    if (-not (Test-Path -LiteralPath '.env')) {
        Copy-Item -LiteralPath '.env.example' -Destination '.env'
    }
}
finally {
    Pop-Location
}

Write-Host 'Installation complete. Set GROQ_API_KEY in backend/.env before using chat.'
Write-Host 'Start the backend:  cd backend; uv run --locked uvicorn app.main:app --reload'
Write-Host 'Start the frontend: cd frontend; npm run dev'
