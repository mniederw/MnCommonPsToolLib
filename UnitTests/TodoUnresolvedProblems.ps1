#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function TodoUnresolvedProblems(){
  OutProgress (ScriptGetCurrentFuncName);

  OutProgressTitle "2024-03: Problem ProcessStart is hanging but if we replace it by call operator then it works";
  OutProgress "Occurrs with git log command which uses internally a pager which does waiting for keyboard input,";
  OutProgress "even if we made sure that in config we replace pager to use cat. If we use call operator then it does not hang.";
  OutProgress "We set git config to use cat for pager because waiting for keyboard is in most cases not neccessary";
  GitSetGlobalVar "core.pager" "cat";
  [String] $d = DirCreateTemp;
  [String] $repoDir = FsEntryGetAbsolutePath "$d/mniederw/MnCommonPsToolLib/";
  [String] $repoDotGitDir = FsEntryGetAbsolutePath "$repoDir/.git";
  GitCmd "Clone" $d "https://github.com/mniederw/MnCommonPsToolLib";
  OutProgress "Currently GitListCommitComments works because it is implemented by using call operator:";
  GitListCommitComments "$repoDir/tmp/" $repoDir;
  OutProgress "Here the command which works ok with the call operator:";
  [String] $out1 = & git.exe "--git-dir=$repoDotGitDir" "log" "--after=1990-01-01" "--pretty=format:%ci %cn [%ce] %s"; AssertRcIsOk;
  OutProgress "Got output of length: $($out1.length)";
  OutProgress "Here the command using ProcessStart which hangs, go to processlist and kill the git sub-process, then it continues:";
  try{
    [String] $out2 = ProcessStart git.exe @("--git-dir=$repoDotGitDir", "log", "--after=1990-01-01", "--pretty=format:%ci %cn [%ce] %s" ) -careStdErrAsOut:$true -traceCmd:$true;
  }catch{ OutProgress "Error: $_"; }

}
TodoUnresolvedProblems;
