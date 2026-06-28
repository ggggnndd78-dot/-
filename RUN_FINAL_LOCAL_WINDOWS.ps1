$ErrorActionPreference = "Stop"
Write-Host "Starting Ghiyarak local development setup..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\backend"
if (!(Test-Path ".env")) {
  Copy-Item ".env.example" ".env"
  Write-Host "Created backend\.env from .env.example. Replace SMS/email/payment secrets before real production." -ForegroundColor Yellow
}
npm install
npx prisma generate
npx prisma migrate deploy
npm run prisma:seed
npm run build
npm run start:dev
