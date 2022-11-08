#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Info(){
  OutProgress (ScriptGetCurrentFuncName);
  if( "$($env:WINDIR)" -eq "" ){ OutProgress "Not running on windows, so bypass test."; return; }
  # TODO: InfoAboutComputerOverview            (){
  OutInfo "InfoAboutExistingShares:"; OutProgress (InfoAboutExistingShares);
  # TODO: InfoAboutSystemInfo                  (){
  # TODO: InfoAboutRunningProcessesAndServices (){
  # TODO: InfoHdSpeed                          (){
  # TODO: InfoAboutNetConfig                   (){
  # TODO: InfoGetInstalledDotNetVersion        ( [Boolean] $alsoOutInstalledClrAndRunningProc = $false ){
}
Test_Info;
