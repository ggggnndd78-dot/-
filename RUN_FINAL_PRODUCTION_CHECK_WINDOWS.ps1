Write-Host "=== Ghiyarak Final Production Check ===" -ForegroundColor Cyan

Write-Host "\n[1/2] Backend checks" -ForegroundColor Yellow
Set-Location backend
npm install
npx prisma generate
npm run build
Set-Location ..

Write-Host "\n[2/2] Flutter frontend checks" -ForegroundColor Yellow
Set-Location frontend
flutter clean
flutter pub get
flutter analyze
flutter test
Write-Host "\nIf all checks pass, run: flutter run -d windows" -ForegroundColor Green
