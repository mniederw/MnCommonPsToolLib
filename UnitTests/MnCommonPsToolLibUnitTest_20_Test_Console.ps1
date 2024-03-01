#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Console(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   ConsoleHide
  #   ConsoleShow
  #   ConsoleRestore
  #   ConsoleMinimize
  #   ConsoleSetPos                        ( [Int32] $x, [Int32] $y ){
  #   ConsoleSetGuiProperties
}
Test_Console;
