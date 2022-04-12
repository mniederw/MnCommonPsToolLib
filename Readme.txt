Common powershell tool library by Marc Niederwieser
---------------------------------------------------

License: GPL3, this is freeware.

Files of this repository:

- InstallEnablePowerShellToUnrestrictedRequiresAdminRights.bat :
  If you never enabled powershell to run without warning dialogs then run this script,
  which sets execution mode to run unrestricted (=Bypass) and so without any security warning.
  This is recommended if you can trust yourself, that you won't click by accident 
  on unknown powershell script files.

- MnCommonPsToolLib\MnCommonPsToolLib.psm1 :
  This is the single powershell module file, which must be located in a folder 
  with the same name under PsModulePath to be auto loadable.

- Install.ps1      : Menu script to easy install or uninstall this powershell module.

- LICENSE_GPL3.txt : Standard License file.

- Releasenotes.txt : Releasenotes for last and previously released versions.

- Examples\*.ps1   : Examples to show some usages of this library. 
                     All these files can simply be executed by doubleclicking them.

- UnitTests\*.ps1  : Tests some main functions of this library.
                     Is also contains the starter for script-analyser to check syntax of all ps1 files.
                     All these files can simply be executed by doubleclicking them.

- .gitignore       : File patterns, which files should be ignored for all git commands.

- .github          : Github workflow configuration which runs on push 
                     all examples and unit tests by pwsh (powershell 7.2).
