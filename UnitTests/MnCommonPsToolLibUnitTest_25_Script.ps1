#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Script(){
  OutProgress (ScriptGetCurrentFuncName);
  ScriptImportModuleIfNotDone "MnCommonPsToolLib"; # MnCommonPsToolLib.psm1
  Assert ((ScriptGetCurrentFunc) -eq "MnCommonPsToolLib.psm1")
  Assert ((ScriptGetCurrentFuncName) -eq "UnitTest_Script")
  Assert ((ScriptGetAndClearLastRc) -eq 0);
  ScriptResetRc;
  Assert ((ScriptNrOfScopes) -ge 2);
  Assert ((ScriptGetProcessCommandLine).Contains("pwsh") -or (ScriptGetProcessCommandLine).Contains("powershell"));
  OutProgress "ScriptGetDirOfLibModule    : $(ScriptGetDirOfLibModule)";
  OutProgress "ScriptGetFileOfLibModule   : $(ScriptGetFileOfLibModule)";
  OutProgress "ScriptGetCallerOfLibModule : $(ScriptGetCallerOfLibModule)";
  OutProgress "ScriptGetTopCaller         : $(ScriptGetTopCaller)";
  OutProgress "ScriptIsProbablyInteractive: $(ScriptIsProbablyInteractive)";
}
UnitTest_Script;
