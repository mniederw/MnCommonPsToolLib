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

  # TODO on github windows: "wget" was not found in env-path="C:\Program Files\PowerShell\7;C:\Program Files\MongoDB\Server\5.0\bin;C:\aliyun-cli;C:\vcpkg;C:\Program Files (x86)\NSIS\;C:\tools\zstd;
  #   C:\Program Files\Mercurial\;C:\hostedtoolcache\windows\stack\2.15.1\x64;C:\cabal\bin;C:\\ghcup\bin;C:\mingw64\bin;C:\Program Files\dotnet;C:\Program Files\MySQL\MySQL Server 8.0\bin;
  #   C:\Program Files\R\R-4.3.2\bin\x64;C:\SeleniumWebDrivers\GeckoDriver;C:\SeleniumWebDrivers\EdgeDriver\;C:\SeleniumWebDrivers\ChromeDriver;C:\Program Files (x86)\sbt\bin;C:\Program Files (x86)\GitHub CLI;
  #   C:\Program Files\Git\bin;C:\Program Files (x86)\pipx_bin;C:\npm\prefix;C:\hostedtoolcache\windows\go\1.21.7\x64\bin;C:\hostedtoolcache\windows\Python\3.9.13\x64\Scripts;C:\hostedtoolcache\windows\Python\3.9.13\x64;
  #   C:\hostedtoolcache\windows\Ruby\3.0.6\x64\bin;C:\Program Files\OpenSSL\bin;C:\tools\kotlinc\bin;C:\hostedtoolcache\windows\Java_Temurin-Hotspot_jdk\8.0.402-6\x64\bin;C:\Program Files\ImageMagick-7.1.1-Q16-HDRI;
  #   C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;C:\ProgramData\kind;C:\ProgramData\Chocolatey\bin;
  #   C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files\dotnet\;C:\Program Files\PowerShell\7\;
  #   C:\Program Files\Microsoft\Web Platform Installer\;C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\;C:\Program Files\Microsoft SQL Server\150\Tools\Binn\;
  #   C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\;C:\Program Files\Microsoft SQL Server\130\DTS\Binn\;C:\Program Files\Microsoft SQL Server\140\DTS\Binn\;C:\Program Files\Microsoft SQL Server\150\DTS\Binn\;
  #   C:\Program Files\Microsoft SQL Server\160\DTS\Binn\;C:\Strawberry\c\bin;C:\Strawberry\perl\site\bin;C:\Strawberry\perl\bin;C:\ProgramData\chocolatey\lib\pulumi\tools\Pulumi\bin;C:\Program Files\TortoiseSVN\bin;
  #   C:\Program Files\CMake\bin;C:\ProgramData\chocolatey\lib\maven\apache-maven-3.8.7\bin;C:\Program Files\Microsoft Service Fabric\bin\Fabric\Fabric.Code;C:\Program Files\Microsoft SDKs\Service Fabric\Tools\ServiceFabricLocalClusterManager;
  #   C:\Program Files\nodejs\;C:\Program Files\Git\cmd;C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\usr\bin;C:\Program Files\GitHub CLI\;c:\tools\php;C:\Program Files (x86)\sbt\bin;C:\Program Files\Amazon\AWSCLIV2\;
  #   C:\Program Files\Amazon\SessionManagerPlugin\bin\;C:\Program Files\Amazon\AWSSAMCLI\bin\;C:\Program Files\Microsoft SQL Server\130\Tools\Binn\;C:\Program Files\LLVM\bin;
  #   C:\Users\runneradmin\.dotnet\tools;C:\Users\runneradmin\.cargo\bin;C:\Users\runneradmin\AppData\Local\Microsoft\WindowsApps"
  if( -not (OsIsWindows) -or "$env:GITHUB_WORKSPACE" -eq "" ){
    OutProgress "NetDownloadSite"          ; [String] $tmpDir = DirCreateTemp "MNNds"; NetDownloadSite $site $tmpDir -maxBytes 20000;
  }
  
}
Test_Net;
