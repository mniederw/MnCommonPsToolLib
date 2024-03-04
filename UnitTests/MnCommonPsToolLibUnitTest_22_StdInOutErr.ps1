#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_StdInOutErr(){
  OutProgress (ScriptGetCurrentFuncName);
  StdOutLine "Test write a line";
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdInAssertAllowInteractions; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdInReadLine "Press Enter "; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdInReadLinePw "Enter Pw"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdInAskForEnter; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdInAskForBoolean; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdInWaitForAKey; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdOutRedLineAndPerformExit; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ try{ throw [Exception] "Test"; }catch{ StdErrHandleExc $_ 2; } }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdPipelineErrorWriteMsg "Test"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdInAskForAnswerWhenInInteractMode; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ StdInAskAndAssertExpectedAnswer; }
}
UnitTest_StdInOutErr;
