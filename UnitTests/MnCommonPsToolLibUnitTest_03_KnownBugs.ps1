#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_KnowBugs(){
  OutProgress (ScriptGetCurrentFuncName);
  # Known bugs are descripted at the bottom of MnCommonPsToolLib.psm1 file in comments.
  # Some of them are showed here in pure powershell without requiring any library.
  #
  [Boolean] $processIsLesserEqualPs5 = ($PSVersionTable.PSVersion.Major -le 5); Write-Output "Current-PS-Version: $($PSVersionTable.PSVersion.Major)";
  #
  # String.Split(String) works wrongly in PS5 because it internally calls wrongly String.Split(Char[])
  [String] $splitRes = "abc".Split("cx");
  if( (     $processIsLesserEqualPs5 -and $splitRes -eq "ab ") -or
      (-not $processIsLesserEqualPs5 -and $splitRes -eq "abc") ){
    Write-Output "Works as expected (in PS5 wrong, in PS7 correct).";
  }else{ throw [Exception] "Unexpected"; }
}
UnitTest_KnowBugs;
