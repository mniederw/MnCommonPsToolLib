#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Service(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  Assert ((ServiceListRunnings).Length -gt 200 );
  Assert ((ServiceListExistings).Count -gt 20);
  Assert ((ServiceListExistingsAsStringArray).Count -gt 20);
  Assert (ServiceNotExists "UnknownUnexistingService")
  Assert (ServiceExists    "RpcSs");
  ServiceAssertExists      "RpcSs";
  Assert ((ServiceGet      "RpcSs").Status -eq "Running");
  Assert ((ServiceGetState "RpcSs") -eq "Running");
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ServiceStop "anyservice"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ServiceStart "anyservice"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ServiceSetStartType "anyservice" "Automatic"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ServiceSetStartType "anyservice" "Automatic"; }
  # TODO 2024-03 fails: Assert ((ServiceMapHiddenToCurrentName "MessagingService_######").StartsWith("MessagingService_"))
}
UnitTest_Win_Service;
