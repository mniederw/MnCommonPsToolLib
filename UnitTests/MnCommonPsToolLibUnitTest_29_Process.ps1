#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Process(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert ((ProcessIsLesserEqualPs5) -or $true);
  OutProgress "ProcessPsExecutable : $(ProcessPsExecutable) ";
  [Boolean] $b = ProcessIsRunningInElevatedAdminMode;
  if( $b ){ ProcessAssertInElevatedAdminMode; }
  if( $b ){ ProcessRestartInElevatedAdminMode; }
  OutProgress "ProcessFindExecutableInPath pwsh: $(ProcessFindExecutableInPath "pwsh") ";
  Assert ((ProcessGetCurrentThreadId) -gt 0);
  Assert ((ProcessListRunnings).Count -gt 20);
  Assert ((ProcessListRunningsFormatted).Length -gt 200);
  Assert ((ProcessListRunningsAsStringArray).Count -gt 20);
  Assert ((ProcessIsRunning "pwsh") -or $true);
  ProcessCloseMainWindow "notepad99";
  ProcessKill            "notepad99";
  ProcessSleepSec 1;
  OutProgress "ProcessListInstalledAppx";
  [String[]] $out = ProcessListInstalledAppx; $out|Out-Null; # on linux: empty. On windows example: Microsoft.BingNews_4.34.20074.0_x64__8wekyb3d8bbwe
  Assert ((ProcessGetCommandInEnvPathOrAltPaths "curl").Length -gt 10);
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessStart "notepad"; }
  Assert ((ProcessEnvVarGet "PATH").Length -gt 80);
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessEnvVarSet; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessEnvVarPathAdd "PATH" "$HOME"; }
  OutProgress "ProcessEnvVarList:"; ProcessEnvVarList;
  Assert ((ProcessPathVarStringToUnifiedArray $env:PATH).Length -gt 10);
  ProcessRefreshEnvVars;
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessRemoveAllAlias; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessOpenAssocFile "./myfile.txt"; ProcessOpenAssocFile "https://duckduckgo.com/"; }
}
UnitTest_Process;
