#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

#GlobalSetModeVerboseEnable;
OutInfo "MnCommonPsToolLibUnitTest - running powershell V$($Host.Version.ToString())";
OutInfo "MnCommonPsToolLibUnitTest - perform some tests which do not require elevated admin mode";

Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Array.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Credential.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_FsEntry_Dir_File_Drive_Share_Mount.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Git_Svn_Tfs.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Help_Os.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Info.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Int_DateTime_ByteArray.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Juniper.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Net.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_KnownBugs.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Priv.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Process_Job.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_PsCommon.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_PsCommonWithLintWarnings.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Registry.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Script.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Service_Task.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Sql.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Stream.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_String.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Test_IO_Console_StdIn_StdOut_StdErr.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTest_Tool.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibUnitTestElevated.ps1";
Write-Output ("-"*86); & "$PSScriptRoot/MnCommonPsToolLibScriptAnalyser.ps1";
Write-Output ("-"*86);

OutSuccess "Ok, done. Exit after 5 seconds. ";
ProcessSleepSec 5;
