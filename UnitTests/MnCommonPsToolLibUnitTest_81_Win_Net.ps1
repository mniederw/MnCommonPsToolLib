#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Net(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  OutProgress "NetGetAdapterSpeed:"; NetAdapterListAll | StreamToTableString | StreamToStringIndented;;
  Assert ((NetGetIpConfig).Count -gt 9);
  Assert ((NetGetNetView).Count -gt 9);
  Assert ((NetGetNetStat).Count -gt 9);
  Assert ((NetGetRoute).Count -gt 9);
  Assert ((NetGetNbtStat).Count -gt 9);
  Assert ((NetGetIpConfig).Count -gt 9);
  Assert ((NetGetIpConfig).Count -gt 9);
  Assert ((NetGetIpConfig).Count -gt 9);
  Assert ((NetGetIpConfig).Count -gt 9);
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ [ServerCertificateValidationCallback]::Ignore(); }
}
UnitTest_Win_Net;
