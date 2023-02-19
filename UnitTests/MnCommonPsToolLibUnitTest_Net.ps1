#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Net(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
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
  #   NetDownloadFile                      ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [Boolean] $errorAsWarning = $false ){
  #                                          # Download a single file by overwrite it (as NetDownloadFileByCurl),
  #                                          #   powershell internal implementation of curl or wget which works for http, https and ftp only.
  #                                          # Cares http response code 3xx for auto redirections.
  #                                          # If url not exists then it will throw.
  #                                          # If ignoreSslCheck is true then it will currently ignore all following calls,
  #                                          #   so this is no good solution (use NetDownloadFileByCurl).
  #                                          # Maybe later: OAuth. Ex: https://docs.github.com/en/free-pro-team@latest/rest/overview/other-authentication-methods
  #   NetDownloadFileByCurl                ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [Boolean] $errorAsWarning = $false ){
  #                                          # Download a single file by overwrite it (as NetDownloadFile), requires curl.exe in path,
  #                                          # timestamps are also taken, logging info is stored in a global logfile, redirections are followed,
  #                                          # for user agent info a mozilla firefox is set,
  #                                          # if file curl-ca-bundle.crt exists next to curl.exe then this is taken.
  #                                          # Supported protocols: DICT, FILE, FTP, FTPS, Gopher, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMB, SMTP, SMTPS, Telnet and TFTP.
  #                                          # Supported features:  SSL certificates, HTTP POST, HTTP PUT, FTP uploading, HTTP form based upload, proxies, HTTP/2, cookies,
  #                                          #                      user+password authentication (Basic, Plain, Digest, CRAM-MD5, NTLM, Negotiate and Kerberos), file transfer resume, proxy tunneling and more.
  #                                          # ex: curl.exe --show-error --output $tarFile --silent --create-dirs --connect-timeout 70 --retry 2 --retry-delay 5 --remote-time --stderr - --user "$($us):$pw" $url;
  #   NetDownloadToString                  ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [String] $encodingIfNoBom = "UTF8" ){
  #   NetDownloadToStringByCurl            ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [String] $encodingIfNoBom = "UTF8" ){
  #   NetDownloadIsSuccessful              ( [String] $url ){ # test wether an url is downloadable or not
  #   NetDownloadSite                      ( [String] $url, [String] $tarDir, [Int32] $level = 999, [Int32] $maxBytes = ([Int32]::MaxValue), [String] $us = "",
  #                                            [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Int32] $limitRateBytesPerSec = ([Int32]::MaxValue),
  #                                            [Boolean] $alsoRetrieveToParentOfUrl = $false ){
  #                                          # Mirror site to dir; wget: HTTP, HTTPS, FTP. Logfile is written into target dir. Password is not logged.
}
Test_Net;
