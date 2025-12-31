#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Tfs(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  Assert ((TfsExe).Length -ge 0);
  Assert ((TfsHelpWorkspaceInfo *>&1).Length -ge 3);
  #   TfsShowAllWorkspaces                 ( [String] $url, [Boolean] $showPaths = $false, [Boolean] $currentMachineOnly = $false ){
  #                                          # from all users on all machines; normal output is a table but if showPaths is true then it outputs 12 lines per entry
  #                                          # Example: url=https://devops.mydomain.ch/MyTfsRoot
  #   TfsShowLocalCachedWorkspaces         (){ # works without access an url
  #   TfsHasLocalMachWorkspace             ( [String] $url ){ # we support only workspace name identic to computername
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ TfsInitLocalWorkspaceIfNotDone "https://machine.local/tfs", "$env:TEMP/tmp/Test/tfsrootdir/"; }
  #   TfsDeleteLocalMachWorkspace          ( [String] $url ){ # we support only workspace name identic to computername
  #   TfsGetNewestNoOverwrite              ( [String] $wsdir, [String] $tfsPath, [String] $url ){ # Example: TfsGetNewestNoOverwrite C:\MyWorkspace\Src $/Src https://devops.mydomain.ch/MyTfsRoot
  #   TfsListOwnLocks                      ( [String] $wsdir, [String] $tfsPath ){
  #   TfsAssertNoLocksInDir                ( [String] $wsdir, [String] $tfsPath ){ # Example: "C:\MyWorkspace" "$/Src";
  #   TfsMergeDir                          ( [String] $wsdir, [String] $tfsPath, [String] $tfsTargetBranch ){
  #   TfsResolveMergeConflict              ( [String] $wsdir, [String] $tfsPath, [Boolean] $keepTargetAndNotTakeSource ){
  #   TfsCheckinDirWhenNoConflict          ( [String] $wsdir, [String] $tfsPath, [String] $comment, [Boolean] $handleErrorsAsWarnings ){
  #                                          # Return true if checkin was successful.
  #   TfsUndoAllLocksInDir                 ( [String] $dir ){ # Undo all locks below dir to cleanup a previous failed operation as from merging.
}
UnitTest_Win_Tfs;
