$ErrorActionPreference = "Stop"
Write-Host "Running Ghiyarak production preflight..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\backend"
if (!(Test-Path ".env")) {
  throw "backend\.env is required for production preflight. Create it from .env.example and replace all secrets/origins."
}
$env:GHIYARAK_PREFLIGHT_MODE = "production"
npm install
npx prisma generate
npm run preflight
npm run build:prod
Write-Host "Production preflight passed." -ForegroundColor Green
