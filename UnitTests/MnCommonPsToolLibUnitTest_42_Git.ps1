#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; }

function UnitTest_Git(){
  OutProgress (ScriptGetCurrentFuncName);
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
  GitMerge $repoDir "main";
  GitListCommitComments "$repoDir/tmp/" $repoDir;
  GitAssertAutoCrLfIsDisabled;
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ GitSetGlobalVar "mygitglobalvar" "myvalue"; }
  GitDisableAutoCrLf;
  # TODO LATER NOT YET IMPLEMENTED GitBranchRecreate ( [String] $repoUrlWithFromBranch, [String] $toBranch )
}
UnitTest_Git;
