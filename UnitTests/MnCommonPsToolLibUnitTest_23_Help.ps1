#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Help(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   HelpHelp                             (){ Get-Help     | ForEach-Object{ OutInfo $_; } }
  OutProgress "Call HelpListOfAllVariables which writes to console "; HelpListOfAllVariables;
  #   HelpListOfAllAliases                 (){ Get-Alias    | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
  #   HelpListOfAllCommands                (){ Get-Command  | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
  #   HelpListOfAllModules                 (){ Get-Module -ListAvailable | Sort-Object Name | Select-Object Name, ModuleType, Version, ExportedCommands; }
  #   HelpListOfAllExportedCommands        (){ (Get-Module -ListAvailable).ExportedCommands.Values | Sort-Object Name | Select-Object Name, ModuleName; }
  #   HelpGetType                          ( [Object] $obj ){ return [String] $obj.GetType(); }
}
Test_Help;
