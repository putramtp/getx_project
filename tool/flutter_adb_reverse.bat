@echo off
rem VS Code "customTool" for the USB launch configurations (.vscode/launch.json): runs
rem `adb reverse tcp:80 tcp:80` - the phone's 127.0.0.1:80 to this PC's web server (Laragon),
rem lost on every unplug/reboot - then hands every argument to flutter unchanged.
rem adb output is discarded: `flutter run --machine` speaks JSON on stdout, and no phone
rem attached must never block the run. Used instead of a preLaunchTask because VS Code's
rem task system trips an invalid problem matcher from the Gradle for Java extension.
adb reverse tcp:80 tcp:80 >nul 2>&1
call flutter %*
exit /b %ERRORLEVEL%
