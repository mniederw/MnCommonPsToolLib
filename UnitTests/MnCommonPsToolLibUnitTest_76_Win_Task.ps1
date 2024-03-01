#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Win_Task(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  # TODO: TaskList                             (){
  # TODO: TaskIsDisabled                       ( [String] $taskPathAndName ){
  # TODO: TaskDisable                          ( [String] $taskPathAndName ){
}
Test_Win_Task;
