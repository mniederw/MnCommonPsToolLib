#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Svn(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  Assert ((ProcessFindExecutableInPath "svn").Length -ge 0);
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnEnvInfoGet $workDir; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnGetDotSvnDir "$workDir/subdir/"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnAuthorizationSave $workDir "myuser"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnAuthorizationTryLoadFile $workDir "myuser"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnCleanup $workDir; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnStatus $workDir $true; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnRevert $workDir @("./cache/","./a.tmp"); }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnTortoiseCommit $workDir; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnUpdate $workDir "myuser"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnCheckoutAndUpdate $workDir "https://mymach.local/svn" "myuser"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnPreCommitCleanupRevertAndDelFiles $workDir @("./cache/","./a.tmp") @("./config/"); }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ SvnTortoiseCommitAndUpdate $workDir "https://mymach.local/svn" "myuser" $true; }
  # for future use: function SvnList ( [String] $svnUrlAndPath ) # flat list folder; Sometimes: svn: E170013: Unable to connect to a repository at URL '...' svn: E175003: The server at '...' does not support the HTTP/DAV protocol
}
UnitTest_Win_Svn;
