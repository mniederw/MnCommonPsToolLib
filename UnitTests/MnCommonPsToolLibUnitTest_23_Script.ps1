#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Script(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   ScriptImportModuleIfNotDone
  #   ScriptGetCurrentFunc
  #   ScriptGetCurrentFuncName
  #   ScriptGetAndClearLastRc
  #   ScriptResetRc
  #   ScriptNrOfScopes
  #   ScriptGetProcessCommandLine
  #   ScriptGetDirOfLibModule
  #   ScriptGetFileOfLibModule
  #   ScriptGetCallerOfLibModule
  #   ScriptGetTopCaller
  #   ScriptIsProbablyInteractive
}
Test_Script;
