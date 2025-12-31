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
  Assert ((ProcessGetApplInEnvPath "curl").Length -gt 10);
  #
  ProcessStart "tar" @("--version") | Out-Null; # any exe which should exists on all platforms
  [String] $errMsg = "";
  ProcessStart "curl" @("--silent", "--url", "https://unknown-domain.ch/") $false $true 30 ([ref]$errMsg) 6>&1 | Out-Null;
  Assert ($errMsg -eq 'ProcessStart("curl" "--silent" "--url" "https://unknown-domain.ch/") failed with rc=6.');
  #
  Assert ((ProcessEnvVarGet "PATH").Length -gt 80);
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessEnvVarSet; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessEnvVarPathAdd "PATH" "$HOME"; }
  OutProgress "ProcessEnvVarList:"; ProcessEnvVarList;
  Assert ((ProcessPathVarStringToUnifiedArray $env:PATH).Length -gt 10);
  ProcessRefreshEnvVars $true;
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessRemoveAllAlias; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ProcessOpenAssocFile "./myfile.txt"; ProcessOpenAssocFile "https://duckduckgo.com/"; }
}
UnitTest_Process;
