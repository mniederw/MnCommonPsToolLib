# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function TestAssertions{
  OutInfo "$($MyInvocation.MyCommand)";
  Assert ((2 + 3) -eq 5);
  OutSuccess "Ok, done.";
}

function TestCommon(){
  OutInfo "$($MyInvocation.MyCommand)";
  [DateTime] $oldestDate = Get-Date -Date "0001-01-01 00:00:00.000";
  OutProgress "Today in ISO format: $(DateTimeNowAsStringIsoDate)";
  OutProgress "Oldest date is     : $(DateTimeAsStringIso $oldestDate)"; # 0001-01-01 00:00:00
  OutSuccess "Ok, done.";
}

function TestFsEntries(){
  OutInfo "$($MyInvocation.MyCommand)";
  OutProgress "Current dir is: $(FsEntryGetAbsolutePath '.')";
  [String] $d = "$HOME\Documents";
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

function TestParallelStatementsHavingOneSecondWaiting {
  OutInfo "$($MyInvocation.MyCommand)";
  [DateTime] $startedAt = Get-Date;
  (0..4) | ForEachParallel { OutProgress "Running script nr: $_ and wait one second."; Start-Sleep -Seconds 1; }
  OutProgress "Total used time: $((New-Timespan -Start $startedAt -End (Get-Date)).ToString('d\ hh\:mm\:ss\.fff'))";
  OutSuccess "Ok, done.";
}

function TestParallelStatementsHavingRandomWaitBetween1and2Seconds {
  OutInfo "$($MyInvocation.MyCommand)";
  [DateTime] $startedAt = Get-Date;
  (0..4) | ForEachParallel -MaxThreads 2 { $t = 1.0 + ((Get-Random -Minimum 1 -Maximum 9) / 10); OutProgress "Running script nr: $_ and wait $t seconds."; Start-Sleep -Seconds $t; };
  OutProgress "Total used time: $((New-Timespan -Start $startedAt -End (Get-Date)).ToString('d\ hh\:mm\:ss\.fff'))";
  OutSuccess "Ok, done.";
}

function TestAsynchronousJob {
  OutInfo "$($MyInvocation.MyCommand)";
  $job = JobStart { param( $s ); OutProgress "Running job and returning a string."; return [String] $s; } "my argument";
  Start-Sleep -Seconds 1;
  [String] $res = JobWaitForEnd $job.Id;
  OutProgress "Result text of job is: '$res'";
  Assert ($res -eq "my argument");
  OutSuccess "Ok, done.";
}

function TestEnvironmentVarsOfDifferentScopes {
  OutInfo "$($MyInvocation.MyCommand)";
  $v1 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::Process);
  $v2 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::User   );
  $v3 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::Machine);
  OutProgress "Environment Variable Temp of scope Process: `"$v1`""; # GithubWorkflowWindowsLaters: "C:\Users\RUNNER~1\AppData\Local\Temp"
  OutProgress "Environment Variable Temp of scope User   : `"$v2`""; # GithubWorkflowWindowsLaters: "C:\Users\runneradmin\AppData\Local\Temp"
  OutProgress "Environment Variable Temp of scope Machine: `"$v3`""; # GithubWorkflowWindowsLaters: "C:\Windows\TEMP"
  Assert ($v1 -eq $env:Temp);
  ProcessEnvVarSet "MnCommonPsToolLibExampleVar" "Testvalue";
  Assert ($env:MnCommonPsToolLibExampleVar -eq "Testvalue");
  ProcessEnvVarSet "MnCommonPsToolLibExampleVar" "";
  OutSuccess "Ok, done.";
}

function TestNetDownloadToString {
  OutInfo "$($MyInvocation.MyCommand)";
  $url = "https://duckduckgo.com/";
  [String] $content = NetDownloadToString $url;
  Assert ($content.Length -gt 0);
  OutSuccess "Ok, done.";
}

function TestNetDownloadIsSuccessful {
  OutInfo "$($MyInvocation.MyCommand)";
  $url = "https://duckduckgo.com/";
  OutProgress "Check NetDownloadIsSuccessful $url";
  Assert (NetDownloadIsSuccessful $url);
  OutSuccess "Ok, done.";
}

function TestListFirstFivePublicReposOfGithubOrgArduino {
  OutInfo "$($MyInvocation.MyCommand)";
  ToolGithubApiListOrgRepos "arduino" | Select-Object -First 5 Url, archived, language, default_branch, LicName |
    StreamToTableString | Foreach-Object { OutProgressText $_; }; OutProgress "";
  OutSuccess "Ok, done.";
}


OutInfo "$($MyInvocation.MyCommand)";
OutProgress "Perform some tests of the module by using readonly mode (writes only to temp dir) so system is not touched relevantly.";
TestAssertions;
TestCommon;
TestFsEntries;
TestParallelStatementsHavingOneSecondWaiting;
TestParallelStatementsHavingRandomWaitBetween1and2Seconds;
TestAsynchronousJob;
TestEnvironmentVarsOfDifferentScopes;
TestNetDownloadToString;
TestNetDownloadIsSuccessful;
TestListFirstFivePublicReposOfGithubOrgArduino;
StdInReadLine "Press enter to exit.";
