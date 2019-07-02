Common powershell tool library by Marc Niederwieser
---------------------------------------------------

License: GPL3, this is freeware.

Files:

- InstallEnablePowerShellToUnrestrictedRequiresAdminRights.bat :
  If you never enabled powershell to run without warning dialogs then run this script,
  which sets execution mode to run unrestricted (=Bypass) and so without any security warning.
  This is recommended if you can trust yourself, that you won't click by accident 
  on unknown powershell script files.

- Install.ps1 : Menu script to install or uninstall module.

- MnCommonPsToolLib\MnCommonPsToolLib.psm1 :
  This is the single file powershell module, which satisfies the required condition for all modules 
  accessed by PsModulePath to be located in a folder with the same name as the module file.

- LICENSE_GPL3.txt : Standard License file.

- Releasenotes.txt : Releasenotes for last and previously released versions.

- Examples\*.ps1 : examples to show some usages of this library.
