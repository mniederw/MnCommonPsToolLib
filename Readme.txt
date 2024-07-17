MnCommonPsToolLib - Common Powershell Tool Library for PS5 and PS7 and works on multiplatforms (Windows, Linux and OSX)
=======================================================================================================================

Published at: https://github.com/mniederw/MnCommonPsToolLib
Licensed under GPL3. This is freeware.
2013-2024 produced by Marc Niederwieser, Switzerland.

Tribute
-------

> 🇺🇦 UKRAINE [IS BEING ATTACKED](https://war.ukraine.ua/) BY RUSSIAN ARMY. 
> CIVILIANS ARE GETTING KILLED. RESIDENTIAL AREAS ARE GETTING BOMBED.
> - Help Ukraine via:
>   - [Serhiy Prytula Charity Foundation](https://prytulafoundation.org/en/)
>   - [Come Back Alive Charity Foundation](https://savelife.in.ua/en/donate-en/)
>   - [National Bank of Ukraine]
>     (https://bank.gov.ua/en/news/all/natsionalniy-bank-vidkriv-spetsrahunok-dlya-zboru-koshtiv-na-potrebi-armiyi)
> - More info on [war.ukraine.ua](https://war.ukraine.ua/) and [MFA of Ukraine](https://twitter.com/MFA_Ukraine)

Description
-----------

This command line library encapsulates many common powershell functions for the purpose of:
  - supports multi platform compatibility (Windows, Linux and OSX)
    It is splitted into two parts: a mulitplatform compatible part and a Windows-only part
  - simplifys command
  - fixes usual problems
  - supports trace information on functions which make use of source management systems (git,svn,tfs)
  - makes behaviour compatible for usage with pwsh, powershell.exe and powershell_ise.exe
  - acts as documentation
  - encapsulates some external tools as git, svn, etc. which of course will work only 
    if their corresponding executables are installed and are available via path variable.

Installation and Updates:
-------------------------

- Install powershell 7 and on Windows call InstallEnablePowerShellToUnrestrictedRequiresAdminRights.bat (run as admin)
- Clone or download zip file of this repository and extract it
- Run:   pwsh Install.ps1   and select menu item I=Install
- On Windows it installs it system-wide for all users and on linux/osx it installs it for local user.
- Afterwards call pwsh and use any funtion of the library for example: OutProgressTitle "Hello world";
- Later Update: Either repeat installation steps or run:
  Import-Module MnCommonPsToolLib; MnCommonPsToolLibSelfUpdate;

Example usages of this module in a .ps1 script:
-----------------------------------------------
  # Simple example for using MnCommonPsToolLib
  Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
  Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
  OutProgressTitle "Hello world";
  OutProgress "Working";
  StdInReadLine "Press Enter to exit.";
  # More examples see: https://github.com/mniederw/MnCommonPsToolLib/tree/main/Examples

Files of this repository:
-------------------------

- InstallEnablePowerShellToUnrestrictedRequiresAdminRights.bat :
  For windows only. If you never enabled powershell to run without warning dialogs then you can run this script 
  to set execution mode to unrestricted (=Bypass) and so any scripts will run without security warnings.
  This is recommended if you can trust yourself, that you won't click by accident on unknown
  powershell script files. If your powershell is already configured so that you can run scripts,
  then you can perform these actions also with the Install.ps1.

- MnCommonPsToolLib/              : Folder with the files which are installed as powershell module.
  - MnCommonPsToolLib.psm1        : This is the powershell module file (multiplatform compatible part).
                                    To be auto loadable it must be located in a folder referenced in PsModulePath
                                    and its folder name must be the identic to the module file.
                                    If it is running on windows then it also imports the windows part file.
  - MnCommonPsToolLib_Windows.ps1 : The windows parts of the library, imported by the main module file.
  - MnCommonPsToolLib.psd1        : Powershell module manifest file which contains metadata as version and author
                                    and it contains releasenotes for last and previous released versions.

- Install.ps1      : Menu script to easy install or uninstall this powershell module and set ps execution mode.

- LICENSE_GPL3.txt : Standard License file.

- Examples/*.ps1   : Examples to show some usages of this library.
                     All these files can simply be executed by doubleclicking them.

- UnitTests/*.ps1  : Tests some main functions of this library.
                     Is also contains the starter for script-analyser to check syntax of all ps1 files.
                     All these files can simply be executed by doubleclicking them.

- .gitignore       : File patterns, which files should be ignored for all git commands.

- .github          : Github workflow configuration which runs on git actions as push.
                     It runs all examples and unit tests on all three platforms by using powershell 7.

All files except BAT files are stored in UTF8-BOM (byte order mark).


Some notes and common approaches of this library:
-------------------------------------------------
- Unit-Tests: Many functions are covered by unit tests and they are running automatically
  by github workflows internally on platforms windows, linux and osx.
  They can also be run by a manual start.
- Indenting format of library functions: 
  The statements are indented in the way that they are easily readable as documentation.
- Typesafe: Functions and its arguments and return values are always specified with its type
  to assert type reliablility as far as possible.
- Avoid null values: Whenever possible null values are generally avoided. 
  For example arrays are set always empty instead of null.
- Win-1252/UTF8: Text file contents are written per default as UTF8-BOM 
  for improving compatibility between multi platforms.
- Create files: On creating files its path parts are always automatically also created.
- Notes about tracing:
  - Progress : Any change of the system will be notified with color Gray. It is enabled as default.
  - Verbose  : Some io functions will be enriched with Write-Verbose infos, 
               which are written in DarkGray and can be enabled by VerbosePreference.
  - Debug    : Some minor functionalities are enriched with Write-Debug, which can be enabled by DebugPreference.
- Comparison with null: All such comparing statements have the null constant on the left side ($null -eq $a)
  because for arrays this is mandatory.
- Null Arrays: All powershell functions returning an array will always return an empty array instead of null.
- More powershell useful knowledge and additional documentations are added to the bottom of MnCommonPsToolLib.psm1
