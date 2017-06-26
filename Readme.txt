Common powershell tool library by Marc Niederwieser
---------------------------------------------------

License: GPL3, this is freeware.

Files:

- InstallEnablePowerShellToUnrestrictedRequiresAdminRights.bat
  If you never enabled powershell to run without warning dialogs then run this script 
  which sets execution mode to Bypass to run unrestricted and so without any security warning.
  This is recommended if you can trust your executed powershell scripts that they do not contain malware.
  
- Install.ps1 : Menu script to install or uninstall module.

- MnCommonPsToolLib\MnCommonPsToolLib.psm1
  This is the powershell module, which satisfies the required condition for all modules accessed 
  by PsModulePath that each module must be located in a folder with the same name as the module file.

- LICENSE_GPL3.txt : License file.

  