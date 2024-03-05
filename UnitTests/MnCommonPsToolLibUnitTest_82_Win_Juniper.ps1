#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Juniper(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ JuniperNcEstablishVpnConn "MecureCredentialFile.txt" "https://juniper.vpn/" "realstring"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ JuniperNcEstablishVpnConnAndRdp "file.rdp" "https://juniper.vpn/" "realstring"; }
}
UnitTest_Win_Juniper;
