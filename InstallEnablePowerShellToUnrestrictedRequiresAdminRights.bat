@ECHO off

ECHO Enable execution mode Bypass for powershell scripts on this machine on PS7 or 64bit and 32bit powershell environment.
ECHO.
ECHO Usually you set mode to Bypass if you trust yourself, that you won't click by accident on unknown ps script files.
ECHO.
ECHO Current mode on ps7       environment: 
  IF     EXIST "%ProgramFiles%\PowerShell\7\pwsh.EXE" ( "%ProgramFiles%\PowerShell\7\pwsh.EXE" -Command Get-Executionpolicy ) ELSE ( ECHO pwsh not found )
ECHO Current mode on ps5-64bit environment: 
  %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -Command Get-Executionpolicy
ECHO Current mode on ps5-32bit environment:
  %SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe -Command Get-Executionpolicy
ECHO.
ECHO Available modes:
ECHO   Restricted    - No ps scripts can be run, ps can be used only in interactive mode. Default after OS installation.
ECHO   AllSigned     - Only ps scripts signed by a trusted publisher can be run.
ECHO   RemoteSigned  - Downloaded ps scripts must be signed by a trusted publisher before they can be run.
ECHO   Unrestricted  - No restrictions; all ps scripts can be run, but with security warning if running from a share.
ECHO   Bypass        - As Unrestricted but without the warning.
ECHO.
ECHO Existing scopes in precedence order:
ECHO   MachinePolicy - Group policy in effect at the computer level, generally applied only in a domain, but can be used locally as well.
ECHO   UserPolicy    - Group policy in effect on the user, is also typically only used in enterprise environments.
ECHO   Process       - Value of current ps instance, changes affects no other ps processes, can be set on launch with -ExecutionPolicy param.
ECHO   CurrentUser   - Is configured in the local registry and applies to the user account used to launch ps.
ECHO   LocalMachine  - Is configured in the local registry and applying to all users on the system.
ECHO.
ECHO Note: In any mode a script can always be run with:
ECHO                            powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File "myfile.ps1"
ECHO Get more info with:        powershell.exe Get-Help Set-ExecutionPolicy -full
ECHO Get current config with:   powershell.exe -NoProfile -Command Get-ExecutionPolicy -List
ECHO If mode has not a required level then you will get the following warning as example:
ECHO   Security Warning: Run only scripts that you trust. While scripts from the Internet can be useful, this script can potentially
ECHO   harm your computer. Do you want to run [D] Do not run  [R] Run once  [S] Suspend [?] Help (default is "D"):
ECHO.
ECHO Modes can be reconfigured by continue below or by calling within ps the command (default scope is LocalMachine): Set-ExecutionPolicy
ECHO.

SET /p answer=Are you sure to enable powershell execution mode Bypass and did you run this batch as administrator [y/n]? 
IF /I "%answer%" NEQ "y" ( ECHO Aborted & PAUSE & EXIT /B 1 )
ECHO.

IF EXIST "%ProgramFiles%\PowerShell\7\pwsh.EXE" (
  ECHO Enable Bypass for ps7      : "%ProgramFiles%\PowerShell\7\pwsh.EXE" -Command Set-Executionpolicy Bypass
                                    "%ProgramFiles%\PowerShell\7\pwsh.EXE" -Command Set-Executionpolicy Bypass
                                    IF %ERRORLEVEL% NEQ 0 ( ECHO Error: rc=%ERRORLEVEL% & PAUSE & EXIT /B 1 )
)

  ECHO Enable Bypass for ps5-64bit: "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -Command Set-Executionpolicy Bypass
                                    "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -Command Set-Executionpolicy Bypass
                                    IF %ERRORLEVEL% NEQ 0 ( ECHO Error: rc=%ERRORLEVEL% & PAUSE & EXIT /B 1 )

                                    ECHO Enable Bypass for ps5-32bit: "%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe" -Command Set-Executionpolicy Bypass
                                    "%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe" -Command Set-Executionpolicy Bypass
                                    IF %ERRORLEVEL% NEQ 0 ( ECHO Error: rc=%ERRORLEVEL% & PAUSE & EXIT /b 1 )

ECHO.
ECHO OK, done. Press enter to exit.
PAUSE
