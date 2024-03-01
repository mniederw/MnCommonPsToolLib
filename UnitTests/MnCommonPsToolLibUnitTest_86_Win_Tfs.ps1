#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Win_Tfs(){
  OutProgress (ScriptGetCurrentFuncName);
  #   TfsExe                               (){ # return tfs executable
  #   TfsHelpWorkspaceInfo                 (){
  #   TfsShowAllWorkspaces                 ( [String] $url, [Boolean] $showPaths = $false, [Boolean] $currentMachineOnly = $false ){
  #                                          # from all users on all machines; normal output is a table but if showPaths is true then it outputs 12 lines per entry
  #                                          # Example: url=https://devops.mydomain.ch/MyTfsRoot
  #   TfsShowLocalCachedWorkspaces         (){ # works without access an url
  #   TfsHasLocalMachWorkspace             ( [String] $url ){ # we support only workspace name identic to computername
  #   TfsInitLocalWorkspaceIfNotDone       ( [String] $url, [String] $rootDir ){
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
Test_Win_Tfs;
