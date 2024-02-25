#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Process_Job(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  #
  Assert ((ProcessFindExecutableInPath "") -eq "");
  [Boolean] $b = ProcessIsRunningInElevatedAdminMode;
  if( $b ){ ProcessAssertInElevatedAdminMode; }
  if( $b ){ ProcessRestartInElevatedAdminMode; }
  Assert ((ProcessGetCurrentThreadId) -gt 0);
  Assert ((ProcessGetNrOfCores) -gt 1);
  Assert ((ProcessListRunnings).Count -gt 20);
  #   ProcessListRunningsFormatted         ()
  Assert ((ProcessListRunningsAsStringArray).Count -gt 20);
  #   ProcessIsRunning                     ( [String] $processName )
  #   ProcessCloseMainWindow               ( [String] $processName )
  #   ProcessKill                          ( [String] $processName )
  #   ProcessSleepSec                      ( [Int32] $sec )
  OutProgress "ProcessListInstalledAppx";
  [String[]] $out = ProcessListInstalledAppx; $out|Out-Null; # on linux: empty. On windows example: Microsoft.BingNews_4.34.20074.0_x64__8wekyb3d8bbwe
  #   ProcessGetCommandInEnvPathOrAltPaths ( [String] $commandNameOptionalWithExtension, [String[]] $alternativePaths = @(), [String] $downloadHintMsg = "")
  #   ProcessStart                         ( [String] $cmd, [String[]] $cmdArgs = @(), [Boolean] $careStdErrAsOut = $false, [Boolean] $traceCmd = $false )
  #   ProcessEnvVarGet                     ( [String] $name, [System.EnvironmentVariableTarget] $scope = [System.EnvironmentVariableTarget]::Process )
  #   ProcessEnvVarSet                     ( [String] $name, [String] $val, [System.EnvironmentVariableTarget] $scope = [System.EnvironmentVariableTarget]::Process )
  #   ProcessRemoveAllAlias                ( [String[]] $excludeAliasNames = @(), [Boolean] $doTrace = $false )
  #   ProcessOpenAssocFile                 ( [String] $fileOrUrl )
  #   JobStart                             ( [ScriptBlock] $scr, [Object[]] $scrArgs = $null, [String] $name = "Job" )
  #   JobGet                               ( [String] $id )
  #   JobGetState                          ( [String] $id )
  #   JobWaitForNotRunning                 ( [Int32] $id, [Int32] $timeoutInSec = -1 )
  #   JobWaitForState                      ( [Int32] $id, [String] $state, [Int32] $timeoutInSec = -1 )
  #   JobWaitForEnd                        ( [Int32] $id )
}
Test_Process_Job;
