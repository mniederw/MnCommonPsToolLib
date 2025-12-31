#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Job(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){
    [System.Management.Automation.PSRemotingJob] $job = JobStart { Param( $s ); OutProgress "Running as Job param=$s"; } @( "hello" );
    JobGet               $job.id;
    JobGetState          $job.id;
    JobWaitForNotRunning $job.id;
    JobWaitForEnd        $job.id;
    JobWaitForState;
  }
}
UnitTest_Win_Job;
