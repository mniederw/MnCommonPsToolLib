@ECHO off

SET mode=Bypass

ECHO Enable execution mode %mode% for powershell scripts on this machine on 64bit and 32bit environment.
ECHO.
ECHO Current mode on 64bit environment is: & %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe Get-Executionpolicy
ECHO Current mode on 32bit environment is: & %SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe Get-Executionpolicy
ECHO.
ECHO Available modes:
ECHO   Restricted   - No scripts can be run. Windows PowerShell can be used only in interactive mode. Default after os installation.
ECHO   AllSigned    - Only scripts signed by a trusted publisher can be run.
ECHO   RemoteSigned - Downloaded scripts must be signed by a trusted publisher before they can be run.
ECHO   Unrestricted - No restrictions; all Windows PowerShell scripts can be run, but with security warning if running from a share.
ECHO   Bypass       - As Unrestricted but without the warning.
ECHO.
ECHO Note: In any mode a script can always be run with:
ECHO   PowerShell.exe -ExecutionPolicy Unrestricted -NoProfile -File "myfile.ps1"
ECHO Get more info with: powershell.exe Get-Help Set-ExecutionPolicy -full
ECHO   or see: https://technet.microsoft.com/en-us/library/dd347641
ECHO If execution mode has not a required level then you can get the following warning as example:
ECHO   Security Warning: Run only scripts that you trust. While scripts from the Internet can be useful, this script can potentially
ECHO   harm your computer. Do you want to run [D] Do not run  [R] Run once  [S] Suspend [?] Help (default is "D"):
ECHO Usually you set mode to Bypass if you trust yourself, that you won't click by accident on unknown powershell script files.
ECHO.

SET /p answer=Are you sure to enable powershell execution mode %mode% and did you run this batch as administrator [y/n]? 
IF /I "%answer%" NEQ "y" ( ECHO Aborted & PAUSE & EXIT /B 1 )
ECHO.

SET cmd=%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe Set-Executionpolicy %mode%
ECHO Enable for 64bit: %cmd% & %cmd%
IF %ERRORLEVEL% neq 0 ( ECHO Error: rc=%ERRORLEVEL% & PAUSE & EXIT /B 1 )

SET cmd=%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe Set-Executionpolicy %mode%
ECHO Enable for 32bit: %cmd% & %cmd%
IF %ERRORLEVEL% neq 0 ( ECHO Error: rc=%ERRORLEVEL% & PAUSE & EXIT /b 1 )

ECHO. & ECHO OK, done. Press enter to exit. & PAUSE > :NUL
