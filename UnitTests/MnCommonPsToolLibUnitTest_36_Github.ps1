#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Git_Github(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   GitBuildLocalDirFromUrl              ( [String] $tarRootDir, [String] $urlAndOptionalBranch ){
  #                                          # Maps a root dir and a repo url with an optional sharp-char separated branch name
  #                                          # to a target repo dir which contains all url fragments below the hostname.
  #                                          # Example: (GitBuildLocalDirFromUrl "C:\WorkGit\" "https://github.com/mniederw/MnCommonPsToolLib")          == "C:\WorkGit\mniederw\MnCommonPsToolLib";
  #                                          # Example: (GitBuildLocalDirFromUrl "C:\WorkGit\" "https://github.com/mniederw/MnCommonPsToolLib#MyBranch") == "C:\WorkGit\mniederw\MnCommonPsToolLib#MyBranch";
  #   GitCmd                               ( [String] $cmd, [String] $tarRootDir, [String] $urlAndOptionalBranch, [Boolean] $errorAsWarning = $false ){
  #                                          # For commands:
  #                                          #   "Clone"       : Creates a full local copy of specified repo. Target dir must not exist.
  #                                          #                   Branch can be optionally specified, in that case it also will switch to this branch.
  #                                          #                   Default branch name is where the standard remote HEAD is pointing to, usually "master".
  #                                          #   "Fetch"       : Get all changes from specified repo to local repo but without touching current working files.
  #                                          #                   Target dir must exist. Branch in repo url can be optionally specified but no switching will be done.
  #                                          #   "Pull"        : First a Fetch and then it also merges current branch into current working files.
  #                                          #                   Target dir must exist. Branch in repo url can be optionally specified but no switching will be done.
  #                                          #   "CloneOrPull" : if target not exists then Clone otherwise Pull.
  #                                          #   "CloneOrFetch": if target not exists then Clone otherwise Fetch.
  #                                          #   "Reset"       : Reset-hard, loose all local changes. Same as delete folder and clone, but faster.
  #                                          #                   Target dir must exist. If branch is specified then it will switch to it, otherwise will switch to main (or master).
  #                                          # Target-Dir: see GitBuildLocalDirFromUrl.
  #                                          # The urlAndOptionalBranch defines a repo url optionally with a sharp-char separated branch name (allowed chars: A-Z,a-z,0-9,.,_,-).
  #                                          # We assert the no AutoCrLf is used.
  #                                          # Pull-No-Rebase: We generally use no-rebase for pull because commit history should not be modified.
  #                                          # Example: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib"
  #                                          # Example: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib#MyBranch"
  #   GitShowUrl                           ( [String] $repoDir ){
  #   GitShowBranch                        ( [String] $repoDir ){
  #                                          # return current branch (example: "master").
  #   GitShowChanges                       ( [String] $repoDir ){
  #                                          # return changed, deleted and new files or dirs. Per entry one line prefixed with a change code.
  #   windows: ToolGitTortoiseCommit                    ( [String] $workDir, [String] $commitMessage = "" ){
  #   GitListCommitComments                ( [String] $tarDir, [String] $localRepoDir, [String] $fileExtension = ".tmp",
  #                                            [String] $prefix = "Log.", [Int32] $doOnlyIfOlderThanAgeInDays = 14 ){
  #                                          # Reads commit messages and changed files info from localRepoDir
  #                                          # and overwrites it to two target files to target dir.
  #                                          # For building the filenames it takes the two last dir parts and writes the files with the names:
  #                                          # - Log.NameOfRepoParent.NameOfRepo.CommittedComments.tmp
  #                                          # - Log.NameOfRepoParent.NameOfRepo.CommittedChangedFiles.tmp
  #                                          # It is quite slow about 10 sec per repo, so it can be controlled by $doOnlyIfOlderThanAgeInDays.
  #                                          # In case of a git error it outputs it as warning.
  #                                          # Example: GitListCommitComments "C:\WorkGit\_CommitComments" "C:\WorkGit\mniederw\MnCommonPsToolLib"
  #   GitAssertAutoCrLfIsDisabled          (){ # use this before using git
  #   GitDisableAutoCrLf                   (){ # no output if nothing done.
  #   GitCloneOrPullUrls                   ( [String[]] $listOfRepoUrls, [String] $tarRootDirOfAllRepos, [Boolean] $errorAsWarning = $false ){
  #                                          # Works later multithreaded and errors are written out, collected and throwed at the end.
  #                                          # If you want single threaded then call it with only one item in the list.
}
Test_Git_Github;
