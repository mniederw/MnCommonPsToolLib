#!/usr/bin/env pwsh

Set-StrictMode -Version Latest; $ErrorActionPreference = "Stop"; trap [Exception] { $nl = [Environment]::NewLine; Write-Progress -Activity " " -Status " " -Completed;
  Write-Error -ErrorAction Continue "$($_.Exception.GetType().Name): $($_.Exception.Message)${nl}$($_.InvocationInfo.PositionMessage)$nl$($_.ScriptStackTrace)";
  Read-Host "Press Enter to Exit"; break; }

$Global:OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [Text.UTF8Encoding]::UTF8;
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US');

Write-Output "----- TestAllExamplesAndUnitTestsInInteractiveMode.ps1 (running examples and all unitests) ----- ";

Write-Output "----- Load MnCommonPsToolLib.psm1 ----- ";
Write-Output "Assert powershell module library MnCommonPsToolLib.psm1 exists next this running script. ";
Push-Location $PSScriptRoot; Pop-Location;
if( -not (Test-Path -Path "$PSScriptRoot/MnCommonPsToolLib/MnCommonPsToolLib.psm1") ){
  throw [Exception] "Missing file: `"$PSScriptRoot/MnCommonPsToolLib/MnCommonPsToolLib.psm1`" ";
}

Write-Output "Extend PSModulePath by PSScriptRoot";
[Boolean] $is_windows = (-not (Get-Variable -Name "IsWindows" -ErrorAction SilentlyContinue) -or $IsWindows); # portable PS5/PS7
[String]  $pathSep    = $(switch($is_windows){$true{";"}default{":"}});
[Environment]::SetEnvironmentVariable("PSModulePath","${env:PSModulePath}$pathSep$PSScriptRoot","Process"); # add ps module to path

Write-Output "Load our library: MnCommonPsToolLib.psm1";
Import-Module "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

OutProgress "Show MnCommonPsToolLibVersion: $((Get-Module -Name MnCommonPsToolLib -ListAvailable).Version)"; # Example: "7.60"
OutProgress "Show OsPsVersion             : $(OsPsVersion)";              # Example: "7.4"
OutProgress "Show Powershell Version      : $($Host.Version.ToString())"; # Example: "7.4.1"

OutProgress "Remove all aliases except (cd,cat,clear,echo,dir,cp,mv,popd,pushd,rm,rmdir);";
ProcessRemoveAllAlias @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir");

[String[]] $ps1Files = @(
   "$PSScriptRoot/Examples/ExampleUseOfMnCommonPsToolLib01_HelloWorldWaitForEnter.ps1"
  ,"$PSScriptRoot/Examples/ExampleUseOfMnCommonPsToolLib02_StdBegAndEndInteractiveModeStmts.ps1"
  ,"$PSScriptRoot/Examples/ExampleUseOfMnCommonPsToolLib03_NoWaitAtEnd.ps1"
  ,"$PSScriptRoot/Examples/ExampleUseOfMnCommonPsToolLib04_SomeReadOnlyProcessings.ps1"
  ,"$PSScriptRoot/UnitTests/AllUnitTests.ps1"
);

OutProgressTitle "Running all examples and unit tests, input requests are aborted when called non-interactive by github action.";
OutProgress "If it is running elevated then it performs additional tests. ";
AssertRcIsOk;
for( [Int32] $i = 0; $i -lt $ps1Files.Count; $i++ ){

  OutProgressTitle ("----- "+(FsEntryGetFileName $ps1Files[$i])+" -----").PadRight(120,'-');
  & $ps1Files[$i];
  if( "$env:GITHUB_WORKSPACE" -ne "" ){ ScriptResetRc; } # On github input stream was closed
  AssertRcIsOk;

}
OutProgressTitle ("----- TestAllExamplesAndUnitTestsInInteractiveMode.ps1 ended -----").PadRight(120,'-');
OutProgressSuccess "Ok, done. All tests are successful. Exit after 2 seconds. ";
ProcessSleepSec 2;
