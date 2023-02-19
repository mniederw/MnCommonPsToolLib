#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Juniper(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  # TODO:
  #   JuniperNcEstablishVpnConn            ( [String] $secureCredentialFile, [String] $url, [String] $realm ){
  #                                          [String] $serviceName = "DsNcService";
  #                                          [String] $vpnProg = "${env:ProgramFiles(x86)}/Juniper Networks/Network Connect 8.0/nclauncher.exe";
  #                                          # Using: nclauncher [-url Url] [-u username] [-p password] [-r realm] [-help] [-stop] [-signout] [-version] [-d DSID] [-cert client certificate] [-t Time(Seconds min:45, max:600)] [-ir true | false]
  #                                          # Alternatively we could take: "HKLM:\SOFTWARE\Wow6432Node\Juniper Networks\Network Connect 8.0\InstallPath":  C:\Program Files (x86)\Juniper Networks\Network Connect 8.0
  #   JuniperNcEstablishVpnConnAndRdp      ( [String] $rdpfile, [String] $url, [String] $realm ){
}
Test_Juniper;
