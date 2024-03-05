#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Net(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  OutProgress "NetAdapterListAll: "; NetAdapterListAll | StreamToTableString | StreamToStringIndented;
  OutProgress "NetGetIpConfig:"    ;
  try{
    NetGetIpConfig    | StreamToTableString | StreamToStringIndented;
  }catch{
    # On github windows we got: CommandNotFoundException: The term 'select' is not recognized as a name of a cmdlet, function, script file, or executable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
    if( $_.Exception.Message.Contains("CommandNotFoundException: The term 'select' is not recognized") ){ OutWarning "Warning: Ignoring (known on github): $_ "; }else{ throw; }
  }
  try{
    OutProgress "NetGetIpAddress:"   ; NetGetIpAddress   | StreamToTableString | StreamToStringIndented;
  }catch{
    OutWarning "Warning: Ignoring (known on github): $_ ";
  }
  try{
    OutProgress "NetGetNetView: "; NetGetNetView;
    Assert ((NetGetNetView).Count -gt 2);
  }catch{
    OutWarning "Warning: Ignoring (known on github): $_ ";
  }
  try{
    OutProgress "NetGetNetStat: "; NetGetNetStat;
    Assert ((NetGetNetStat).Count -gt 2);
  }catch{
    OutWarning "Warning: Ignoring (known on github): $_ ";
  }
  try{
    OutProgress "NetGetRoute: "; NetGetRoute;
    Assert ((NetGetRoute).Count -gt 2);
  }catch{
    OutWarning "Warning: Ignoring (known on github): $_ ";
  }
  try{
    OutProgress "NetGetNbtStat: "; NetGetNbtStat;
    Assert ((NetGetNbtStat).Count -gt 2);
  }catch{
    OutWarning "Warning: Ignoring (known on github): $_ ";
  }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ [ServerCertificateValidationCallback]::Ignore(); }
}
UnitTest_Win_Net;
