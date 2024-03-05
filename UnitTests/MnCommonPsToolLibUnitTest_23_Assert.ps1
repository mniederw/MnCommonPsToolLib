#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Assert(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert        $true  "Condition is not ok";
  AssertIsFalse $false "Condition is not ok";
  AssertNotEmpty "abc" "parm1";
  AssertRcIsOk;
}
UnitTest_Assert;
