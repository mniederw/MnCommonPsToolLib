#!/usr/bin/env pwsh
# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function IsProbablyRunningOnGitHubActions { return [Boolean] ("$env:GITHUB_ACTIONS" -eq "true"); }

function ExampleUseAssertions{
  OutProgressTitle "$($MyInvocation.MyCommand)";
  Assert ((2 + 3) -eq 5);
  OutProgressSuccess "Ok, done.";
}

function ExampleUseCommon(){
  OutProgressTitle "$($MyInvocation.MyCommand)";
  [DateTime] $minimumDate = Get-Date -Date "0001-01-01 00:00:00.000";
  OutProgress "Today in ISO format      : $(DateTimeNowAsStringIsoDate)";
  OutProgress "Current ts in ISO format : $(DateTimeAsStringIso (Get-Date))";
  OutProgress "Minimum date is          : $(DateTimeAsStringIso $minimumDate)"; # 0001-01-01 00:00:00
  OutProgressSuccess "Ok, done.";
}

function ExampleUseFsEntries(){
  OutProgressTitle "$($MyInvocation.MyCommand)";
  OutProgress "Current dir is: $(FsEntryGetAbsolutePath '.')";
  [String] $d = "$HOME/Documents";
  if( (OsIsMacOS) -and (IsProbablyRunningOnGithubActions) ){
    OutWarning "Since V7.107 it seams FsEntryListAsStringArray is looping endless on MacOS on GithubActions, so we discard it. "; return;
  }
  [String[]] $a = @()+(FsEntryListAsStringArray $d $true $false $true | Where-Object{$null -ne $_});
  OutProgress "The folder '$d' contains $($a.Count) number of files";
  [String[]] $a2 = @()+($a | Select-Object -First 2);
  [Object[]] $o2 = @()+($a2 | Select-Object @{Name="FileName";Expression={("`"$_`"")}});
  OutProgress "The folder '$d' has the following first two files: $a2";
  OutProgress "View these files in xml  format: $(StringReplaceNewlines ($a2 | StreamToXmlString))";
  OutProgress "View these files in json format: $(StringReplaceNewlines ($a2 | StreamToJsonString))";
  OutProgress "View these files in csv  format: $($o2 | StreamToCsvStrings)";
  OutProgress "View these files in html format: $(StringReplaceNewlines ($o2 | StreamToHtmlTableStrings))";
  OutProgressSuccess "Ok, done.";
}

function ExampleUseParallelStatementsHavingOneSecondWaiting {
  OutProgressTitle "$($MyInvocation.MyCommand)";
  [DateTime] $startedAt = Get-Date;
  # Note about statement blocks: No functions or variables of the script where it is embedded can be used.
  (0..4) | ForEachParallel { Write-Output "Running script nr: $_ and wait one second."; Start-Sleep -Seconds 1; }
  OutProgress "Total used time: $((New-Timespan -Start $startedAt -End (Get-Date)).ToString('d\ hh\:mm\:ss\.fff'))";
  OutProgressSuccess "Ok, done.";
}

function ExampleUseParallelStatementsHavingRandomWaitBetween1and2Seconds {
  OutProgressTitle "$($MyInvocation.MyCommand)";
  [DateTime] $startedAt = Get-Date;
  # Note about statement blocks: No functions or variables of the script where it is embedded can be used.
  (0..4) | ForEachParallel -MaxThreads 2 { $t = 1.0 + ((Get-Random -Minimum 1 -Maximum 9) / 10);
    Write-Output "Running script nr: $_ and wait $t seconds."; Start-Sleep -Seconds $t; };
  OutProgress "Total used time: $((New-Timespan -Start $startedAt -End (Get-Date)).ToString('d\ hh\:mm\:ss\.fff'))";
  OutProgressSuccess "Ok, done.";
}

function ExampleUseAsynchronousJob {
  OutProgressTitle "$($MyInvocation.MyCommand)";
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  $job = JobStart { Param( $s ); Import-Module "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; } OutProgress "Running job and returning a string."; return [String] $s; } "my argument";
  Start-Sleep -Seconds 1;
  [String] $res = JobWaitForEnd $job.Id;
  OutProgress "Result text of job is: '$res'";
  Assert ($res -eq "my argument");
  OutProgressSuccess "Ok, done.";
}

function ExampleUseEnvironmentVarsOfDifferentScopes {
  OutProgressTitle "$($MyInvocation.MyCommand)";
  [String] $v = "$env:TEMP";
  [String] $v1 = ProcessEnvVarGet "TEMP" ([System.EnvironmentVariableTarget]::Process);
  [String] $v2 = ProcessEnvVarGet "TEMP" ([System.EnvironmentVariableTarget]::User   );
  [String] $v3 = ProcessEnvVarGet "TEMP" ([System.EnvironmentVariableTarget]::Machine);
  [String] $v4 = [System.IO.Path]::GetTempPath();
  [String] $v5 = (DirGetTemp);
  OutProgress  "Note: Environment Variable TEMP of any scope are usually empty on Linux and MacOS ";
  OutProgress "`$env:TEMP                                 : `"$v`"" ; # on linux is empty
  OutProgress  "Environment Variable TEMP of scope Process: `"$v1`""; # "C:\Users\RUNNER~1\AppData\Local\Temp"
  OutProgress  "Environment Variable TEMP of scope User   : `"$v2`""; # "C:\Users\runneradmin\AppData\Local\Temp"
  OutProgress  "Environment Variable TEMP of scope Machine: `"$v3`""; # "C:\Windows\TEMP"
  OutProgress "`[System.IO.Path]::GetTempPath()           : `"$v4`""; # "C:\Temp\User_u1", "/tmp/", "/var/folders/xy/a_b_cd_efghijklmnopqrstuvwxyz2/T/"
  OutProgress "`DirGetTemp                                : `"$v5`""; # "C:\Temp\User_u1\", "/tmp/", "/var/folders/xy/a_b_cd_efghijklmnopqrstuvwxyz2/T/"
  Assert ($v1 -eq $v);
  ProcessEnvVarSet "MnCommonPsToolLibExampleVar" "Testvalue";
  Assert ($env:MnCommonPsToolLibExampleVar -eq "Testvalue");
  ProcessEnvVarSet "MnCommonPsToolLibExampleVar" "";
  OutProgressSuccess "Ok, done.";
}

function ExampleUseNetDownloadToString {
  OutProgressTitle "$($MyInvocation.MyCommand)";
  $url = "https://duckduckgo.com/";
  [String] $content = NetDownloadToString $url;
  Assert ($content.Length -gt 0);
  OutProgressSuccess "Ok, done.";
}

function ExampleUseNetDownloadIsSuccessful {
  OutProgressTitle "$($MyInvocation.MyCommand)";
  $url = "https://duckduckgo.com/";
  OutProgress "Check NetDownloadIsSuccessful $url";
  Assert (NetDownloadIsSuccessful $url);
  OutProgressSuccess "Ok, done.";
}

function ExampleUseListFirstFivePublicReposOfGithubOrg {
  OutProgressTitle "$($MyInvocation.MyCommand)";
  # find by: https://api.github.com/search/users?q=type:org
  [String[]] $orgs = @( "arduino", "google", "microsoft", "github", "EpicGames", "facebook", "openai", "alibaba", "apple", "dotnet" );
  # note: using this can lead to error: "Response status code does not indicate success: 403 (rate limit exceeded)."
  # so we choose randomly one and hope this works.
  [String] $randomOrg = $orgs[(Get-Random -Minimum 0 -Maximum ($orgs.Count))];
  OutProgress "List first 5 public repos of github org $randomOrg ";
  try{
  ToolGithubApiListOrgRepos $randomOrg | Select-Object -First 5 Url, archived, language, default_branch, LicName |
    StreamToTableString | Foreach-Object { OutProgress $_; };
    OutProgressSuccess "Ok, done.";
  }catch{
    if( -not $_.Exception.Message.Contains("403 (rate limit exceeded)") ){ throw; }
    OutProgressSuccess "Ok, done. We got 403(rate-limit-exceeded) which we must ignore because it occurrs sometimes.";
  }
}


OutProgressTitle "$($MyInvocation.MyCommand)";
OutProgress "As example perform some readonly things (writes only to temp dir) so system is not touched relevantly.";
ExampleUseAssertions;
ExampleUseCommon;
ExampleUseFsEntries;
ExampleUseParallelStatementsHavingOneSecondWaiting;
ExampleUseParallelStatementsHavingRandomWaitBetween1and2Seconds;
ExampleUseAsynchronousJob;
ExampleUseEnvironmentVarsOfDifferentScopes;
ExampleUseNetDownloadToString;
ExampleUseNetDownloadIsSuccessful;
ExampleUseListFirstFivePublicReposOfGithubOrg;
AssertRcIsOk;
StdInReadLine "Press Enter to exit.";
