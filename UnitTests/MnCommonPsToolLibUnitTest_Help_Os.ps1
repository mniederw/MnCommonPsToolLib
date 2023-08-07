#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Help_Os(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  # TODO:
  #   HelpHelp                             (){ Get-Help     | ForEach-Object{ OutInfo $_; } }
  OutProgress "Call HelpListOfAllVariables which writes to console "; HelpListOfAllVariables;
  #   HelpListOfAllAliases                 (){ Get-Alias    | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
  #   HelpListOfAllCommands                (){ Get-Command  | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
  #   HelpListOfAllModules                 (){ Get-Module -ListAvailable | Sort-Object Name | Select-Object Name, ModuleType, Version, ExportedCommands; }
  #   HelpListOfAllExportedCommands        (){ (Get-Module -ListAvailable).ExportedCommands.Values | Sort-Object Name | Select-Object Name, ModuleName; }
  #   HelpGetType                          ( [Object] $obj ){ return [String] $obj.GetType(); }
  #   OsPsVersion                          (){ return [String] (""+$Host.Version.Major+"."+$Host.Version.Minor); } # alternative: $PSVersionTable.PSVersion.Major
  #   OsIsWinVistaOrHigher                 (){ return [Boolean] ([Environment]::OSVersion.Version -ge (new-object "Version" 6,0)); }
  Assert (OsIsWin7OrHigher);
  Assert (OsIs64BitOs);
  #   OsIsHibernateEnabled                 (){
  Assert ((OsInfoMainboardPhysicalMemorySum) -gt 1000000000);
  #   OsWindowsFeatureGetInstalledNames    (){ # Requires windows-server-os or at least Win10Prof with installed RSAT https://www.microsoft.com/en-au/download/details.aspx?id=45520
  #   OsWindowsFeatureDoInstall            ( [String] $name ){ # ex: Web-Server, Web-Mgmt-Console, Web-Scripting-Tools, Web-Basic-Auth, Web-Windows-Auth, NET-FRAMEWORK-45-Core, NET-FRAMEWORK-45-ASPNET, Web-HTTP-Logging, Web-NET-Ext45, Web-ASP-Net45, Telnet-Server, Telnet-Client.
  #   OsWindowsFeatureDoUninstall          ( [String] $name ){ Import-Module ServerManager; OutProgress "Uninstall-WindowsFeature -name $name"; [Object] $res = Uninstall-WindowsFeature -name $name;
  #   OsPsModulePathList                   (){ return [String[]] ([Environment]::GetEnvironmentVariable("PSModulePath", "Machine").
  #   OsPsModulePathContains               ( [String] $dir ){ # ex: "D:\MyGitRoot\MyGitAccount\MyPsLibRepoName"
  #   OsPsModulePathAdd                    ( [String] $dir ){ if( OsPsModulePathContains $dir ){ return; }
  #   OsPsModulePathDel                    ( [String] $dir ){ OsPsModulePathSet (OsPsModulePathList |
  #   OsPsModulePathSet                    ( [String[]] $pathList ){ [Environment]::SetEnvironmentVariable("PSModulePath", ($pathList -join ";"), "Machine"); }
  #   OsGetWindowsProductKey               (){
}
Test_Help_Os;
