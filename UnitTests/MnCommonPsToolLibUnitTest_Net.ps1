#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Net(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   NetExtractHostName                   ( [String] $url ){ return [String] ([System.Uri]$url).Host; }
  #   NetUrlUnescape                       ( [String] $url ){ return [String] [uri]::UnescapeDataString($url); } # convert for example %20 to blank.
  #   NetAdapterGetConnectionStatusName    ( [Int32] $netConnectionStatusNr ){
  #   NetAdapterListAll                    (){
  #   NetPingHostIsConnectable             ( [String] $hostName, [Boolean] $doRetryWithFlushDns = $false ){
  #   NetGetIpConfig                       (){ [String[]] $out = @()+(& "IPCONFIG.EXE" "/ALL"          ); AssertRcIsOk $out; return [String[]] $out; }
  #   NetGetNetView                        (){ [String[]] $out = @()+(& "NET.EXE" "VIEW" $ComputerName ); AssertRcIsOk $out; return [String[]] $out; }
  #   NetGetNetStat                        (){ [String[]] $out = @()+(& "NETSTAT.EXE" "/A"             ); AssertRcIsOk $out; return [String[]] $out; }
  #   NetGetRoute                          (){ [String[]] $out = @()+(& "ROUTE.EXE" "PRINT"            ); AssertRcIsOk $out; return [String[]] $out; }
  #   NetGetNbtStat                        (){ [String[]] $out = @()+(& "NBTSTAT.EXE" "-N"             ); AssertRcIsOk $out; return [String[]] $out; }
  #   ServerCertificateValidationCallback: Add-Type -TypeDefinition "using System;using System.Net;using System.Net.Security;using System.Security.Cryptography.X509Certificates; public class ServerCertificateValidationCallback { public static void Ignore() { ServicePointManager.ServerCertificateValidationCallback += delegate( Object obj, X509Certificate certificate, X509Chain chain, SslPolicyErrors errors ){ return true; }; } } ";
  #   NetWebRequestLastModifiedFailSafe    ( [String] $url ){ # Requests metadata from a downloadable file. Return DateTime.MaxValue in case of any problem
  #
  [String] $url = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/main/Readme.txt";
  [String] $site = "https://github.com/mniederw/MnCommonPsToolLib/tree/main/Examples/";
  OutProgress "NetDownloadIsSuccessful"  ; [String] $tmp = FileGetTempFile; Assert (NetDownloadIsSuccessful $url);
  OutProgress "NetDownloadFile"          ; NetDownloadFile       $url $tmp; Assert ((FileGetSize $tmp) -gt 0); FileDelete $tmp;
  OutProgress "NetDownloadToString"      ; Assert ((NetDownloadToString $url) -gt 0);
  OutProgress "NetDownloadFileByCurl"    ; $tmp = FileGetTempFile; NetDownloadFileByCurl $url $tmp; Assert ((FileGetSize $tmp) -gt 0); FileDelete $tmp;
  OutProgress "NetDownloadToStringByCurl"; Assert ((NetDownloadToStringByCurl $url) -gt 0);
  OutProgress "Call curl native"         ; $tmp = FileGetTempFile; & (ProcessGetCommandInEnvPathOrAltPaths "curl") "--show-error" "--fail" "--output" $tmp "--silent" "--create-dirs" "--connect-timeout" "70" "--retry" "2" "--retry-delay" "5" "--tlsv1.2" "--remote-time" "--location" "--max-redirs" "50" "--stderr" "-" "--user-agent" "Test" "--url" $url; AssertRcIsOk;
  OutProgress "NetDownloadSite"          ; [String] $tmpDir = DirCreateTemp "MNNds"; NetDownloadSite $site $tmpDir -maxBytes 20000;
}
Test_Net;
