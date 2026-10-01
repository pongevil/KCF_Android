@echo off
setlocal EnableExtensions

REM Optional: set a fixed app name for the APK filename (leave empty to read android:label)
set "APP_NAME_OVERRIDE="

cd /d "%~dp0.."
if errorlevel 1 (
  echo ERROR: Cannot change to project root.
  exit /b 1
)

where flutter >nul 2>&1
if errorlevel 1 (
  echo ERROR: flutter not found in PATH.
  exit /b 1
)

set "ENABLE_FCM="
if /I "%~1"=="--fcm" set "ENABLE_FCM=--dart-define=ENABLE_FCM=true"

for /f "usebackq delims=" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0resolve_apk_name.ps1"`) do set "OUTPUT_APK_NAME=%%A"

if errorlevel 1 (
  echo ERROR: Failed to resolve APK output name.
  exit /b 1
)

if not defined OUTPUT_APK_NAME (
  echo ERROR: APK output name is empty.
  exit /b 1
)

set "APK_DIR=build\app\outputs\flutter-apk"
set "SOURCE_APK=%APK_DIR%\app-release.apk"
set "TARGET_APK=%APK_DIR%\%OUTPUT_APK_NAME%"

echo.
echo === BS-Mobile Release APK Build ===
echo Output name : %OUTPUT_APK_NAME%
echo.

if defined ENABLE_FCM (
  echo Building with FCM enabled...
  call flutter build apk --release %ENABLE_FCM%
) else (
  call flutter build apk --release
)

if errorlevel 1 (
  echo.
  echo ERROR: flutter build failed.
  exit /b 1
)

if not exist "%SOURCE_APK%" (
  echo ERROR: Expected build output not found: %SOURCE_APK%
  exit /b 1
)

if exist "%TARGET_APK%" del /f /q "%TARGET_APK%"

for %%F in ("%APK_DIR%\*_V*.apk") do (
  if /I not "%%~nxF"=="%OUTPUT_APK_NAME%" del /f /q "%%F" 2>nul
)

move /Y "%SOURCE_APK%" "%TARGET_APK%" >nul
if errorlevel 1 (
  echo ERROR: Failed to rename APK to %TARGET_APK%
  exit /b 1
)

echo.
echo Build successful.
echo APK: %CD%\%TARGET_APK%
echo.
exit /b 0
