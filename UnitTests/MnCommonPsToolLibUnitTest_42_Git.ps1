#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; }

function UnitTest_Git(){
  OutProgress (ScriptGetCurrentFuncName);
  #
  GitSetGlobalVar "core.pager" "cat"; # use cat for pager because waiting for keyboard is in most cases not neccessary
  #
  if( (OsIsWindows) ){ GitDisableAutoCrLf; } # on github initial settings are systemwide AutoCrLf.
  #
  [String] $d = DirCreateTemp;
  [String] $repoDir = (FsEntryGetAbsolutePath "$d/mniederw/MnCommonPsToolLib#main/");
  Assert ((GitBuildLocalDirFromUrl $d "https://github.com/mniederw/MnCommonPsToolLib") -eq (FsEntryGetAbsolutePath "$d/mniederw/MnCommonPsToolLib/"));
  Assert ((GitBuildLocalDirFromUrl $d "https://github.com/mniederw/MnCommonPsToolLib#main") -eq $repoDir);
  GitCmd "Clone"        $d "https://github.com/mniederw/MnCommonPsToolLib#main";
  GitCmd "Fetch"        $d "https://github.com/mniederw/MnCommonPsToolLib#main";
  GitCmd "Pull"         $d "https://github.com/mniederw/MnCommonPsToolLib#main";
  GitCmd "CloneOrPull"  $d "https://github.com/mniederw/MnCommonPsToolLib#main";
  GitCmd "CloneOrFetch" $d "https://github.com/mniederw/MnCommonPsToolLib#main";
  GitCmd "Revert"       $d "https://github.com/mniederw/MnCommonPsToolLib#main";
  GitCloneOrPullUrls @( "https://github.com/mniederw/MnCommonPsToolLib#main", "https://github.com/mniederw/MnCommonPsToolLib#trunk" ) $d;
  Assert ((GitShowUrl $repoDir) -eq "https://github.com/mniederw/MnCommonPsToolLib");
  Assert ((GitShowRemoteName $repoDir) -eq "origin");
  Assert ((GitShowRepo $repoDir) -eq "mniederw/MnCommonPsToolLib");
  Assert ((GitShowBranch $repoDir) -eq "main");
  Assert ((StringMakeNonNull (GitShowChanges $repoDir)) -eq "");
  Assert (GitBranchList $repoDir).Contains("origin/trunk");
  GitSwitch $repoDir "trunk";
  GitAdd "$repoDir/Releasenotes.txt";
  try{
    GitMerge $repoDir "main";
  }catch{
    # 2024-03 on github we get: failed with rc=128  Committer identity unknown *** Please tell me who you are.
    #   Run   git config --global user.email "you@example.com"   git config --global user.name "Your Name" to set your account's default identity.
    #   Omit --global to set the identity only in this repository. fatal: empty ident name (for <runner@fv-az1538-315.upsp13a5k4ou3ds4kr34xzh2lh.cx.internal.cloudapp.net>) not allowed
    OutWarning "Warning: Ignore exceptions for GitMerge because probably missing committer name: $_ ";
  }
  GitListCommitComments "$repoDir/tmp/" $repoDir;
  GitAssertAutoCrLfIsDisabled;
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ GitSetGlobalVar "mygitglobalvar" "myvalue"; }
  GitDisableAutoCrLf;
  # TODO LATER NOT YET IMPLEMENTED GitBranchRecreate ( [String] $repoUrlWithFromBranch, [String] $toBranch )
  DirDelete $d;
}
UnitTest_Git;
