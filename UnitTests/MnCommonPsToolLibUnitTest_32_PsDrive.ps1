#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_PsDrive(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO: PsDriveListAll                       (){
  # TODO: PsDriveCreate                        ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null ){
}
UnitTest_PsDrive;
