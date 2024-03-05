#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Int(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert         ((Int32Clip -5 0 9) -eq 0 -and (Int32Clip 5 0 9) -eq 5 -and (Int32Clip 15 0 9) -eq 9);
}
UnitTest_Int;
