#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Git_Github(){
  OutProgress (ScriptGetCurrentFuncName);
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){
    GithubAuthStatus;
    Assert ((GithubGetBranchCommitId "mniederw/MnCommonPsToolLib" "trunk" $PSScriptRoot).Length -gt 40);
    GithubListPullRequests "mniederw/MnCommonPsToolLib";
    GithubCreatePullRequest  "mniederw/MnCommonPsToolLib" "main" "trunk" "" $PSScriptRoot;
    GithubMergeOpenPr "https://github.com/mniederw/MnCommonPsToolLib/pull/123" $PSScriptRoot;
    Assert (GithubBranchExists "mniederw/MnCommonPsToolLib" "main");
    Assert (-not (GithubBranchExists "mniederw/MnCommonPsToolLib" "unexistingBranch"));
    GithubBranchDelete "mniederw/MnCommonPsToolLib" "unittestUnexistingBranch";
  }
}
UnitTest_Git_Github;
