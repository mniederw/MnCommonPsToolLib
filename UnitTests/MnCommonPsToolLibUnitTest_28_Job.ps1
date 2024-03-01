#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Job(){
  OutProgress (ScriptGetCurrentFuncName);
  #   JobStart                             ( [ScriptBlock] $scr, [Object[]] $scrArgs = $null, [String] $name = "Job" )
  #   JobGet                               ( [String] $id )
  #   JobGetState                          ( [String] $id )
  #   JobWaitForNotRunning                 ( [Int32] $id, [Int32] $timeoutInSec = -1 )
  #   JobWaitForState                      ( [Int32] $id, [String] $state, [Int32] $timeoutInSec = -1 )
  #   JobWaitForEnd                        ( [Int32] $id )
}
Test_Job;
