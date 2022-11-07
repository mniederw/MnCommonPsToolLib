#!/usr/bin/env pwsh
# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function ExampleUseAssertions{
  OutInfo "$($MyInvocation.MyCommand)";
  Assert ((2 + 3) -eq 5);
  OutSuccess "Ok, done.";
}

function ExampleUseCommon(){
  OutInfo "$($MyInvocation.MyCommand)";
  [DateTime] $oldestDate = Get-Date -Date "0001-01-01 00:00:00.000";
  OutProgress "Today in ISO format      : $(DateTimeNowAsStringIsoDate)";
  OutProgress "Current ts in ISO format : $(DateTimeAsStringIso (Get-Date))";
  OutProgress "Oldest date is           : $(DateTimeAsStringIso $oldestDate)"; # 0001-01-01 00:00:00
  OutSuccess "Ok, done.";
}

function ExampleUseFsEntries(){
  OutInfo "$($MyInvocation.MyCommand)";
  OutProgress "Current dir is: $(FsEntryGetAbsolutePath '.')";
  [String] $d = "$HOME/Documents";
  [String[]] $a = @()+(FsEntryListAsStringArray $d $true $false $true | Where-Object{$null -ne $_});
  OutProgress "The folder '$d' contains $($a.Count) number of files";
  [String[]] $a2 = @()+($a | Select-Object -First 2);
  [Object[]] $o2 = @()+($a2 | Select-Object @{Name="FileName";Expression={("`"$_`"")}});
  OutProgress "The folder '$d' has the following first two files: $a2";
  OutProgress "View these files in xml  format: $(StringReplaceNewlines ($a2 | StreamToXmlString))";
  OutProgress "View these files in json format: $(StringReplaceNewlines ($a2 | StreamToJsonString))";
  OutProgress "View these files in csv  format: $($o2 | StreamToCsvStrings)";
  OutProgress "View these files in html format: $(StringReplaceNewlines ($o2 | StreamToHtmlTableStrings))";
  OutSuccess "Ok, done.";
}

function ExampleUseParallelStatementsHavingOneSecondWaiting {
  OutInfo "$($MyInvocation.MyCommand)";
  [DateTime] $startedAt = Get-Date;
  (0..4) | ForEachParallel { OutProgress "Running script nr: $_ and wait one second."; Start-Sleep -Seconds 1; }
  OutProgress "Total used time: $((New-Timespan -Start $startedAt -End (Get-Date)).ToString('d\ hh\:mm\:ss\.fff'))";
  OutSuccess "Ok, done.";
}

function ExampleUseParallelStatementsHavingRandomWaitBetween1and2Seconds {
  OutInfo "$($MyInvocation.MyCommand)";
  [DateTime] $startedAt = Get-Date;
  (0..4) | ForEachParallel -MaxThreads 2 { $t = 1.0 + ((Get-Random -Minimum 1 -Maximum 9) / 10); OutProgress "Running script nr: $_ and wait $t seconds."; Start-Sleep -Seconds $t; };
  OutProgress "Total used time: $((New-Timespan -Start $startedAt -End (Get-Date)).ToString('d\ hh\:mm\:ss\.fff'))";
  OutSuccess "Ok, done.";
}

function ExampleUseAsynchronousJob {
  OutInfo "$($MyInvocation.MyCommand)";
  if( "$($env:WINDIR)" -eq "" ){ OutProgress "Not running on windows, so bypass test."; return; }
  $job = JobStart { param( $s ); Import-Module "MnCommonPsToolLib.psm1"; OutProgress "Running job and returning a string."; return [String] $s; } "my argument";
  Start-Sleep -Seconds 1;
  [String] $res = JobWaitForEnd $job.Id;
  OutProgress "Result text of job is: '$res'";
  Assert ($res -eq "my argument");
  OutSuccess "Ok, done.";
}

function ExampleUseEnvironmentVarsOfDifferentScopes {
  OutInfo "$($MyInvocation.MyCommand)";
  [String] $v = "$($env:Temp)";
  [String] $v1 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::Process);
  [String] $v2 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::User   );
  [String] $v3 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::Machine);
  OutProgress "Environment Variable Temp of scope Process: `"$v1`""; # GithubWorkflowWindowsLaters: "C:\Users\RUNNER~1\AppData\Local\Temp"
  OutProgress "Environment Variable Temp of scope User   : `"$v2`""; # GithubWorkflowWindowsLaters: "C:\Users\runneradmin\AppData\Local\Temp"
  OutProgress "Environment Variable Temp of scope Machine: `"$v3`""; # GithubWorkflowWindowsLaters: "C:\Windows\TEMP"
  OutProgress "`$env:Temp                                 : `"$v`""; # on linux is empty
  Assert ($v1 -eq $v);
  ProcessEnvVarSet "MnCommonPsToolLibExampleVar" "Testvalue";
  Assert ($env:MnCommonPsToolLibExampleVar -eq "Testvalue");
  ProcessEnvVarSet "MnCommonPsToolLibExampleVar" "";
  OutSuccess "Ok, done.";
}

function ExampleUseNetDownloadToString {
  OutInfo "$($MyInvocation.MyCommand)";
  $url = "https://duckduckgo.com/";
  [String] $content = NetDownloadToString $url;
  Assert ($content.Length -gt 0);
  OutSuccess "Ok, done.";
}

function ExampleUseNetDownloadIsSuccessful {
  OutInfo "$($MyInvocation.MyCommand)";
  $url = "https://duckduckgo.com/";
  OutProgress "Check NetDownloadIsSuccessful $url";
  Assert (NetDownloadIsSuccessful $url);
  OutSuccess "Ok, done.";
}

function ExampleUseListFirstFivePublicReposOfGithubOrgArduino {
  OutInfo "$($MyInvocation.MyCommand)";
  ToolGithubApiListOrgRepos "arduino" | Select-Object -First 5 Url, archived, language, default_branch, LicName |
    StreamToTableString | Foreach-Object { OutProgress $_; };
  OutSuccess "Ok, done.";
}


OutInfo "$($MyInvocation.MyCommand)";
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
ExampleUseListFirstFivePublicReposOfGithubOrgArduino;
StdInReadLine "Press enter to exit.";
