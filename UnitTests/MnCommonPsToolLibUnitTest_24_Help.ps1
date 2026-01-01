#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Help(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert ((HelpHelp                      *>&1).ToString().Length -ge 1);
  Assert ((HelpListOfAllVariables        *>&1).Count -ge 9);
  Assert ((HelpListOfAllAliases          *>&1).ToString().Length -ge 1);
  Assert ((HelpListOfAllCommands         *>&1).ToString().Length -ge 1);
  Assert ((HelpListOfAllModules          *>&1).Count -ge 9);
  Assert ((HelpListOfAllExportedCommands *>&1).Count -ge 99);
  Assert ((HelpGetType "Str") -eq "string");
}
UnitTest_Help;
