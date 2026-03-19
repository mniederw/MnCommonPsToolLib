#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function TodoUnresolvedProblems(){
  OutProgress (ScriptGetCurrentFuncName);
  #
  # currently no problem to test;
  #
}
TodoUnresolvedProblems;
