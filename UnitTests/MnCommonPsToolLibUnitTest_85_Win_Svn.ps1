#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Win_Svn(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   SvnEnvInfo :                         Add-Type -TypeDefinition "public struct SvnEnvInfo {public string Url; public string Path; public string RealmPattern; public string CachedAuthorizationFile; public string CachedAuthorizationUser; public string Revision; }";
  #                                          # Example: Url="https://myhost/svn/Work"; Path="D:\Work"; RealmPattern="https://myhost:443";
  #                                          # CachedAuthorizationFile="$env:APPDATA\Subversion\auth\svn.simple\25ff84926a354d51b4e93754a00064d6"; CachedAuthorizationUser="myuser"; Revision="1234"
  #   SvnExe                               (){ # Note: if certificate is not accepted then a pem file (for example lets-encrypt-r3.pem) can be added to file "$env:APPDATA\Subversion\servers"
  #   SvnEnvInfoGet                        ( [String] $workDir ){
  #                                          # Return SvnEnvInfo; no param is null.
  #   SvnGetDotSvnDir                      ( $workSubDir ){
  #                                          # Return absolute .svn dir up from given dir which must exists.
  #   SvnAuthorizationSave                ( [String] $workDir, [String] $user ){
  #                                          # If this part fails then you should clear authorization account in svn settings.
  #   SvnAuthorizationTryLoadFile          ( [String] $workDir, [String] $user ){
  #                                          # If work auth dir exists then copy content to svn cache dir.
  #   SvnCleanup                           ( [String] $workDir ){
  #                                          # Cleanup a previously failed checkout, update or commit operation.
  #   SvnStatus                            ( [String] $workDir, [Boolean] $showFiles ){
  #                                          # Return true if it has any pending changes, otherwise false.
  #                                          # Example: "M       D:\Work\..."
  #                                          # First char: Says if item was added, deleted, or otherwise changed
  #                                          #   ' ' no modifications
  #                                          #   'A' Added
  #                                          #   'C' Conflicted
  #   SvnRevert                            ( [String] $workDir, [String[]] $relativeRevertFsEntries ){
  #                                          # Undo the specified fs-entries if they have any pending change.
  #   SvnTortoiseCommit                    ( [String] $workDir ){
  #   SvnUpdate                            ( [String] $workDir, [String] $user ){
  #   SvnCheckoutAndUpdate                 ( [String] $workDir, [String] $url, [String] $user, [Boolean] $doUpdateOnly = $false, [String] $pw = "", [Boolean] $ignoreSslCheck = $false ){
  #                                          # Init working copy and get (init and update) last changes. If pw is empty then it uses svn-credential-cache.
  #                                          # If specified update-only then no url is nessessary but if given then it verifies it.
  #                                          # Note: we do not use svn-update because svn-checkout does the same (the difference is only the use of an url).
  #                                          # Note: sometimes often after 5-20 GB received there is a network problem which aborts svn-checkout,
  #                                          #   so if it is recognised as a known exception then it will automatically do a cleanup, wait for 30 sec and retry (max 100 times).
  #   SvnPreCommitCleanupRevertAndDelFiles ( [String] $workDir, [String[]] $relativeDelFsEntryPatterns, [String[]] $relativeRevertFsEntries ){
  #   SvnTortoiseCommitAndUpdate           ( [String] $workDir, [String] $svnUrl, [String] $svnUser, [Boolean] $ignoreIfHostNotReachable, [String] $pw = "" ){
  #                                          # Check svn dir, do svn cleanup, check svn user by asserting it matches previously used svn user, delete temporary files, svn commit (interactive), svn update.
  #                                          # If pw is empty then it takes it from svn-credential-cache.
  #   for future use: function SvnList ( [String] $svnUrlAndPath ) # flat list folder; Sometimes: svn: E170013: Unable to connect to a repository at URL '...' svn: E175003: The server at '...' does not support the HTTP/DAV protocol
}
Test_Win_Svn;
