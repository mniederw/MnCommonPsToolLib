#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Out(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert ((OutGetTsPrefix $true).Length -eq 20); # Example: "2024-03-03 00:23:43 "
  Assert ([String](OutProgressSuccess       "Test OutProgressSuccess" 6>&1) -eq "  Test OutProgressSuccess");
  Assert ([String](OutWarning               "Test OutWarning"         3>&1) -eq "Test OutWarning");
  Assert ([String](OutWarning               "Test OutWarning"         *>&1) -eq "   Test OutWarning");
  Assert ([String](OutProgress              "Test OutProgress"        6>&1) -eq "  Test OutProgress");
  Assert ([String](OutProgressTitle         "Test OutProgressTitle"   6>&1) -eq "Test OutProgressTitle");
  Assert ([String](OutProgress -color:White "Test OutProgress"        6>&1) -eq "  Test OutProgress");
  function funcOutProgress(){ OutProgress "Test OutProgress" 0 $true; OutProgress "Eol"; }
  Assert ([String](funcOutProgress 6>&1) -eq "Test OutProgress   Eol" );
  OutVerbose "Test OutVerbose";
  OutDebug "Test OutDebug";
  OutStartTranscriptInTempDir;
  OutStopTranscript;
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ OutClear; }
}
UnitTest_Out;
