#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Net(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert ((NetConvertMacToIPv6byEUI64 "00:1A:2B:3C:4D:5E") -eq "fe80::021a:2bff:fe3c:4d5e");
  #
  # TODO: NetExtractHostName                   ( [String] $url ){ return [String] ([System.Uri]$url).Host; }
  # TODO: NetUrlUnescape                       ( [String] $url ){ return [String] [uri]::UnescapeDataString($url); } # convert for example %20 to blank.
  # TODO: NetAdapterGetConnectionStatusName    ( [Int32] $netConnectionStatusNr ){
  # TODO: NetPingHostIsConnectable             ( [String] $hostName, [Boolean] $doRetryWithFlushDns = $false ){
  # TODO: NetWebRequestLastModifiedFailSafe    ( [String] $url ){ # Requests metadata from a downloadable file. Return DateTime.MaxValue in case of any problem
  #
  [String] $url = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/main/Readme.txt";
  [String] $site = "https://github.com/mniederw/MnCommonPsToolLib/tree/main/Examples/";
  [String] $tmp = FileGetTempFile;
  OutProgress "NetDownloadFile"          ; NetDownloadFile       $url $tmp; Assert ((FileGetSize $tmp) -gt 0);
  OutProgress "NetDownloadFileByCurl"    ; NetDownloadFileByCurl $url $tmp; Assert ((FileGetSize $tmp) -gt 0);
  OutProgress "NetDownloadToString"      ; Assert ((NetDownloadToString $url) -gt 0);
  OutProgress "NetDownloadToStringByCurl"; Assert ((NetDownloadToStringByCurl $url) -gt 0);
  OutProgress "NetDownloadIsSuccessful"  ; Assert (NetDownloadIsSuccessful $url);
  OutProgress "NetDownloadSite"          ; if( -not (OsIsWindows) -or "$env:GITHUB_WORKSPACE" -eq "" ){ # on linux or non-github-windows
                                             [String] $tmpDir = DirCreateTemp "MNNds";
                                             OutProgress "  We expect warnings as generic: Exceed quota. http://: Invalid host name.";
                                             NetDownloadSite $site $tmpDir -maxBytes 20000 *>&1 | Where-Object{ "$_".Trim() -ne "" } | ForEach-Object{ OutProgress "  $_"; };
                                             # Example: Warning: Ignored one or more occurrences of category=Generic. More see logfile="/tmp/MNNds.123456//.Download.2024-08.detail.log".
                                             DirDelete $tmpDir; }
  # TODO on github action running windows we got:
  #   "wget" was not found in env-path="$env:ProgramFiles\PowerShell\7;$env:ProgramFiles\MongoDB\Server\5.0\bin;C:\aliyun-cli;C:\vcpkg;${env:ProgramFiles(x86)}\NSIS\;C:\tools\zstd;
  #   $env:ProgramFiles\Mercurial\;C:\hostedtoolcache\windows\stack\2.15.1\x64;C:\cabal\bin;C:\\ghcup\bin;C:\mingw64\bin;$env:ProgramFiles\dotnet;$env:ProgramFiles\MySQL\MySQL Server 8.0\bin;
  #   $env:ProgramFiles\R\R-4.3.2\bin\x64;C:\SeleniumWebDrivers\GeckoDriver;C:\SeleniumWebDrivers\EdgeDriver\;C:\SeleniumWebDrivers\ChromeDriver;${env:ProgramFiles(x86)}\sbt\bin;${env:ProgramFiles(x86)}\GitHub CLI;
  #   $env:ProgramFiles\Git\bin;${env:ProgramFiles(x86)}\pipx_bin;C:\npm\prefix;C:\hostedtoolcache\windows\go\1.21.7\x64\bin;C:\hostedtoolcache\windows\Python\3.9.13\x64\Scripts;C:\hostedtoolcache\windows\Python\3.9.13\x64;
  #   C:\hostedtoolcache\windows\Ruby\3.0.6\x64\bin;$env:ProgramFiles\OpenSSL\bin;C:\tools\kotlinc\bin;C:\hostedtoolcache\windows\Java_Temurin-Hotspot_jdk\8.0.402-6\x64\bin;$env:ProgramFiles\ImageMagick-7.1.1-Q16-HDRI;
  #   $env:ProgramFiles\Microsoft SDKs\Azure\CLI2\wbin;$env:ProgramData\kind;$env:ProgramData\Chocolatey\bin;
  #   C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;$env:ProgramFiles\dotnet\;$env:ProgramFiles\PowerShell\7\;
  #   $env:ProgramFiles\Microsoft\Web Platform Installer\;$env:ProgramFiles\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\;$env:ProgramFiles\Microsoft SQL Server\150\Tools\Binn\;
  #   ${env:ProgramFiles(x86)}\Windows Kits\10\Windows Performance Toolkit\;$env:ProgramFiles\Microsoft SQL Server\130\DTS\Binn\;$env:ProgramFiles\Microsoft SQL Server\140\DTS\Binn\;$env:ProgramFiles\Microsoft SQL Server\150\DTS\Binn\;
  #   $env:ProgramFiles\Microsoft SQL Server\160\DTS\Binn\;C:\Strawberry\c\bin;C:\Strawberry\perl\site\bin;C:\Strawberry\perl\bin;$env:ProgramData\chocolatey\lib\pulumi\tools\Pulumi\bin;$env:ProgramFiles\TortoiseSVN\bin;
  #   $env:ProgramFiles\CMake\bin;$env:ProgramData\chocolatey\lib\maven\apache-maven-3.8.7\bin;$env:ProgramFiles\Microsoft Service Fabric\bin\Fabric\Fabric.Code;$env:ProgramFiles\Microsoft SDKs\Service Fabric\Tools\ServiceFabricLocalClusterManager;
  #   $env:ProgramFiles\nodejs\;$env:ProgramFiles\Git\cmd;$env:ProgramFiles\Git\mingw64\bin;$env:ProgramFiles\Git\usr\bin;$env:ProgramFiles\GitHub CLI\;c:\tools\php;${env:ProgramFiles(x86)}\sbt\bin;$env:ProgramFiles\Amazon\AWSCLIV2\;
  #   $env:ProgramFiles\Amazon\SessionManagerPlugin\bin\;$env:ProgramFiles\Amazon\AWSSAMCLI\bin\;$env:ProgramFiles\Microsoft SQL Server\130\Tools\Binn\;$env:ProgramFiles\LLVM\bin;
  #   C:\Users\runneradmin\.dotnet\tools;C:\Users\runneradmin\.cargo\bin;C:\Users\runneradmin\AppData\Local\Microsoft\WindowsApps"
  OutProgress "Call curl native"         ; & (ProcessGetApplInEnvPath "curl") "--show-error" "--fail" "--output" $tmp "--silent" "--create-dirs" "--connect-timeout" "70" "--retry" "2" "--retry-delay" "5" "--tlsv1.2" "--remote-time" "--location" "--max-redirs" "50" "--stderr" "-" "--user-agent" "Test" "--url" $url; AssertRcIsOk;
  FileDelete $tmp;
}
UnitTest_Net;
