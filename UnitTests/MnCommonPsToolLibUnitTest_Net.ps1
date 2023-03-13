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
  [String] $tar = "$env:TEMP/tmp/MnCommonPsToolLib_UnitTest_Net.tmp";
  OutProgress "NetDownloadIsSuccessful"  ; Assert (NetDownloadIsSuccessful $url);
  OutProgress "NetDownloadFile"          ; NetDownloadFile       $url $tar; Assert ((FileGetSize $tar) -gt 0); FileDelete $tar;
  OutProgress "NetDownloadToString"      ; Assert ((NetDownloadToString $url) -gt 0);
  if( (ProcessFindExecutableInPath "curl") -eq "" ){
    OutProgress "Curl is not in path, so cannot test methods using it.";
  }else{
    OutProgress "NetDownloadFileByCurl"    ; NetDownloadFileByCurl $url $tar; Assert ((FileGetSize $tar) -gt 0); FileDelete $tar;
    OutProgress "NetDownloadToStringByCurl"; Assert ((NetDownloadToStringByCurl $url) -gt 0);
  }
  #
  #   NetDownloadSite                      ( [String] $url, [String] $tarDir, [Int32] $level = 999, [Int32] $maxBytes = ([Int32]::MaxValue), [String] $us = "",
  #                                            [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Int32] $limitRateBytesPerSec = ([Int32]::MaxValue),
  #                                            [Boolean] $alsoRetrieveToParentOfUrl = $false ){
  #                                          # Mirror site to dir; wget: HTTP, HTTPS, FTP. Logfile is written into target dir. Password is not logged.
}
Test_Net;
