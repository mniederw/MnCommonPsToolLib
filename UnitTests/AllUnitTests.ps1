#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

[String[]] $ps1Files = @(
   "$PSScriptRoot/MnCommonPsToolLibUnitTest_Array.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Credential.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_FsEntry_Dir_File_Drive_Share_Mount.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Git_Svn_Tfs.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Help_Os.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Info.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Int_DateTime_ByteArray.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Juniper.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Net.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_KnownBugs.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Priv.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Process_Job.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_PsCommon.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_PsCommonWithLintWarnings.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Registry.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Script.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Service_Task.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Sql.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Stream.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_String.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Test_IO_Console_StdIn_StdOut_StdErr.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTest_Tool.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibUnitTestElevated.ps1"
  ,"$PSScriptRoot/MnCommonPsToolLibScriptAnalyser.ps1"
);

#GlobalSetModeVerboseEnable;
OutInfo "MnCommonPsToolLibUnitTest - running powershell V$($Host.Version.ToString())";
OutInfo "MnCommonPsToolLibUnitTest - perform some tests which do not require elevated admin mode";
AssertRcIsOk;
[String] $horizontalLine = ("-"*86);
[String[]] $errorPs1Files = @();
for( [Int32] $i = 0; $i -lt $ps1Files.Count; $i++ ){
  Write-Output $horizontalLine;
  try{
    AssertRcIsOk;
    & $ps1Files[$i];
    [Int32] $rc = ScriptGetAndClearLastRc;
    if( $rc -ne 0 ){ throw [ExcMsg] "End of was reached, but the last operation failed [rc=$rc] because it did call a program but it did not handle or reset the rc."; }
  }catch{
    ScriptResetRc; $errorPs1Files += $ps1Files[$i]; StdErrHandleExc $_;
    OutProgress "Continue but will throw at the end of processing all items.";
  }
}
Write-Output $horizontalLine;
if( $errorPs1Files.Count -gt 0 ){ throw [ExcMsg] "Failed for the $($errorPs1Files.Count) files: $errorPs1Files"; }

OutSuccess "Ok, done. Exit after 5 seconds. ";
ProcessSleepSec 5;
