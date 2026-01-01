#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Task(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  Assert ((TaskList).Count -gt 9);
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ TaskIsDisabled "\Microsoft\Windows\Task Manager\Interactive"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ TaskDisable    "\Microsoft\Windows\Task Manager\Interactive"; }
}
UnitTest_Win_Task;
