#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Net(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  OutProgress "NetAdapterListAll: "; NetAdapterListAll | StreamToTableString | StreamToStringIndented;
  OutProgress "NetGetIpConfig:"    ; NetGetIpConfig    | StreamToTableString | StreamToStringIndented;
  OutProgress "NetGetIpAddress:"   ; NetGetIpAddress   | StreamToTableString | StreamToStringIndented;
  Assert ((NetGetNetView).Count -gt 2);
  Assert ((NetGetNetStat).Count -gt 2);
  Assert ((NetGetRoute).Count -gt 2);
  Assert ((NetGetNbtStat).Count -gt 2);
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ [ServerCertificateValidationCallback]::Ignore(); }
}
UnitTest_Win_Net;
