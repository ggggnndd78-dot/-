$ErrorActionPreference = "Stop"
Write-Host "Running Ghiyarak final QA..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\backend"
npm install
npx prisma generate
npm run typecheck
npm run test
Write-Host "Start backend in another terminal, then run smoke check:" -ForegroundColor Yellow
Write-Host "npm run start:dev"
Write-Host "npm run test:smoke"
Set-Location "$PSScriptRoot\frontend"
flutter pub get
flutter analyze
flutter test
