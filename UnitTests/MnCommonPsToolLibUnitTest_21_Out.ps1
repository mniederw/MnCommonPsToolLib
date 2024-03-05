#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Out(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert ((OutGetTsPrefix $true).Length -eq 20); # Example: "2024-03-03 00:23:43 "
  OutStringInColor "Gray" "A line";
  OutInfo "Test OutInfo";
  OutSuccess "Test OutSuccess";
  OutWarning "Test OutWarning";
  OutProgress "Test OutProgress";
  OutProgressText "Test OutProgressText "; OutProgress "EndOfLine";
  OutVerbose "Test OutVerbose";
  OutDebug "Test OutDebug";
  OutStartTranscriptInTempDir;
  OutStopTranscript;
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ OutClear; }
}
UnitTest_Out;
