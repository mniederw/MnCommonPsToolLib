MnCommonPsToolLib - Common Powershell Tool Library for PS5 and PS7 and multiplatforms (Windows, Linux and OSX)
--------------------------------------------------------------------------------------------------------------

Licensed under GPL3. This is freeware.

This library encapsulates many common commands for the purpose of supporting compatibility between 
multi platforms, simplifying commands, fixing usual problems, supporting tracing information, 
making behaviour compatible for usage with powershell.exe and powershell_ise.exe and acts as documentation.
It is splitted in a mulitplatform compatible part and a part which runs only on Windows.
Some functions depends on that its subtools as git, svn, etc. are available via path variable.

Recommendations and notes about common approaches of this library:
- Unit-Tests: Many functions are included and they are run either automatically by github workflow (on win, linux and osx) or by manual starts.
- Indenting format of library functions: The statements are indented in the way that they are easy readable as documentation.
- Typesafe: Functions and its arguments and return values are always specified with its type to assert type reliablility as far as possible.
- Avoid null values: Whenever possible null values are generally avoided. For example arrays gets empty instead of null.
- Win-1252/UTF8: Text file contents are written per default as UTF8-BOM for improving compatibility between multi platforms.
  They are read in Win-1252(=ANSI) if they have no BOM (byte order mark) or otherwise according to BOM.
- Create files: On writing or appending files they automatically create its path parts.
- Notes about tracing information lines:
  - Progress : Any change of the system will be notified with color Gray. Is enabled as default.
  - Verbose  : Some io functions will be enriched with Write-Verbose infos. which are written in DarkGray and can be enabled by VerbosePreference.
  - Debug    : Some minor additional information are enriched with Write-Debug, which can be enabled by DebugPreference.
- Comparison with null: All such comparing statements have the null constant on the left side ($null -eq $a)
  because for arrays this is mandatory (throws: @() -eq $null)
- Null Arrays: All powershell function returning an array should always return an empty array instead of null 
  for avoiding counting null as one element when added to an empty array.
- More: Powershell useful knowledge and additional documentation see bottom of MnCommonPsToolLib.psm1

Example usages of this module for a .ps1 script:
     # Simple example for using MnCommonPsToolLib
     Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
     OutInfo "Hello world";
     OutProgress "Working";
     StdInReadLine "Press enter to exit.";
More examples see: https://github.com/mniederw/MnCommonPsToolLib/tree/main/Examples

2013-2022 produced by Marc Niederwieser, Switzerland.



Files of this repository:
-------------------------

- InstallEnablePowerShellToUnrestrictedRequiresAdminRights.bat :
  If you never enabled powershell to run without warning dialogs then run this script,
  which sets execution mode to run unrestricted (=Bypass) and so without any security warning.
  This is recommended if you can trust yourself, that you won't click by accident
  on unknown powershell script files.

- MnCommonPsToolLib\MnCommonPsToolLib.psm1 :
  This is the single powershell module file, which must be located in a folder
  with the same name under a folder from PsModulePath to be auto loadable.

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


All files except BAT files are stored in UTF8-BOM.
