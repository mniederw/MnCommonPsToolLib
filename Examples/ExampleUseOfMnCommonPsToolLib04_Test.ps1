# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function TestAssertions{
  OutInfo "Test assertions";
  Assert ((2 + 3) -eq 5);
  MnLibCommonSelfTest;
  OutSuccess "Ok, done.";
}

function TestCommon(){
  [DateTime] $oldestDate = Get-Date -Date "0001-01-01 00:00:00.000";
  OutProgress "Today in ISO format: $(DateTimeNowAsStringIsoDate)";
  OutProgress "Oldest date is: $(DateTimeAsStringIso $oldestDate)";
  OutSuccess "Ok, done.";
}

function TestFsEntries(){
  OutInfo "Test file system entry functions";
  OutProgress "Current dir is: $(FsEntryGetAbsolutePath '.')";
  [String] $d = "C:\Users\u4\Documents";
  [String[]] $a = @()+(FsEntryListAsStringArray $d $true $false $true);
  OutProgress "The folder '$d' contains $($a.Count) number of files";
  [String[]] $a2 = $a | Select-Object -First 2;
  [Object[]] $o2 = $a2 | Select-Object @{Name="FileName";Expression={("`"$_`"")}};
  OutProgress "The folder '$d' has the following first two files: $a2";
  OutProgress "View these files in xml  format: $(StringReplaceNewlines ($a2 | StreamToXmlString))";
  OutProgress "View these files in json format: $(StringReplaceNewlines ($a2 | StreamToJsonString))";
  OutProgress "View these files in csv  format: $($o2 | StreamToCsvStrings)";
  OutProgress "View these files in html format: $(StringReplaceNewlines ($o2 | StreamToHtmlTableStrings))";
  OutSuccess "Ok, done.";
}

function TestParallelScripts1 {
  OutInfo "Test 4 parallel scripts which each is waiting 1 second";
  [DateTime] $startedAt = Get-Date;
  (0..4) | ForEachParallel { OutProgress "Running script nr: $_ and wait one second."; Start-Sleep -Seconds 1; }
  OutProgress "Total used time: $((New-Timespan -Start $startedAt -End (Get-Date)).ToString('d\ hh\:mm\:ss\.fff'))";
  OutSuccess "Ok, done.";
}

function TestParallelScripts2 {
  OutInfo "Test 4 parallel scripts which each is waiting some random seconds between 1.1 and 1.9 seconds";
  [DateTime] $startedAt = Get-Date;
  (0..4) | ForEachParallel -MaxThreads 2 { $t = 1.0 + ((Get-Random -Minimum 1 -Maximum 9) / 10); OutProgress "Running script nr: $_ and wait $t seconds."; Start-Sleep -Seconds $t; };
  OutProgress "Total used time: $((New-Timespan -Start $startedAt -End (Get-Date)).ToString('d\ hh\:mm\:ss\.fff'))";
  OutSuccess "Ok, done.";
}

function TestAsynchronousJob {
  OutInfo "Test asynchronous job";
  $job = JobStart { param( $s ); OutProgress "Running job and returning a string."; return [String] $s; } "my argument";
  Start-Sleep -Seconds 1;
  [String] $res = JobWaitForEnd $job.Id;
  OutProgress "Result text of job is: '$res'";
  Assert ($res -eq "my argument");
  OutSuccess "Ok, done.";
}

function TestTools {
  OutInfo "List all public repos of github-org arduino";
  ToolGithubApiListOrgRepos "arduino" | Select-Object Url, archived, language, default_branch, LicName | StreamToTableString;
  OutSuccess "Ok, done.";
}

function TestEnvVar {
  OutInfo "List environment var of different scopes";
  $v1 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::Process);
  $v2 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::User   );
  $v3 = ProcessEnvVarGet "Temp" ([System.EnvironmentVariableTarget]::Machine);
  OutProgress "Environment Variable Temp of scope Process: `"$v1`"";
  OutProgress "Environment Variable Temp of scope User   : `"$v2`"";
  OutProgress "Environment Variable Temp of scope Machine: `"$v3`"";
  Assert ($v1 -eq $env:Temp);
  ProcessEnvVarSet "MnCommonPsToolLibExampleVar" "Testvalue";
  Assert ($env:MnCommonPsToolLibExampleVar -eq "Testvalue");
  ProcessEnvVarSet "MnCommonPsToolLibExampleVar" "";
  OutSuccess "Ok, done.";
}

function TestUrl {
  $url = "https://duckduckgo.com/";
  OutInfo "Check NetDownloadIsSuccessful $url";
  Assert (NetDownloadIsSuccessful $url);
  OutSuccess "Ok, done.";
}

OutInfo "hello world";
TestAssertions;
TestCommon;
TestFsEntries;
TestParallelScripts1;
TestParallelScripts2;
TestAsynchronousJob;
TestTools;
TestEnvVar;
TestUrl;
OutSuccess "Ok, done.";
StdInReadLine "Press enter to exit.";
