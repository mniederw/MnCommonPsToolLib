#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Tool(){
  OutProgress (ScriptGetCurrentFuncName);
  #   ToolTailFile                         ( [String] $file ){ OutProgress "Show tail of file until ctrl-c is entered"; Get-Content -Wait $file; }
  #   ToolAddLineToConfigFile              ( [String] $file, [String] $line, [String] $existingFileEncodingIfNoBom = "Default" ){ # if file not exists or line not found case sensitive in file then the line is appended
  #   ToolGithubApiListOrgRepos            ( [String] $org, [System.Management.Automation.PSCredential] $cred = $null ){
  #                                          # List all repos (ordered by archived and url) from an org on github.
  #                                          # If user and its Personal-Access-Token PAT instead of password is specified then not only public
  #                                          # but also private repos are listed.
  #   ToolGithubApiAssertValidRepoUrl      ( [String] $repoUrl ){
  #                                          # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
  #   ToolGithubApiDownloadLatestReleaseDir( [String] $repoUrl ){
  #                                          # Creates a unique temp dir, downloads zip, return folder of extracted zip; You should remove dir after usage.
  #                                          # Latest release is the most recent non-prerelease, non-draft release, sorted by its last commit-date.
  #                                          # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
  # ToolEvalVsCodeExec
}
Test_Tool;
