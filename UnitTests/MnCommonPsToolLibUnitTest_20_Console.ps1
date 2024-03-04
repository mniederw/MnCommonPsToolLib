#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Console(){
  OutProgress (ScriptGetCurrentFuncName);
  ConsoleShow;
  ConsoleHide;
  ConsoleShow;
  ConsoleMinimize;
  ConsoleShow;
  ConsoleRestore;
  [RECT] $r = New-Object RECT; [Object] $hd = (Get-Process -ID $PID).MainWindowHandle;
  [Window]::GetWindowRect($hd,[ref]$r) | Out-Null;
  ConsoleSetPos $r.Left $r.Top;
  ConsoleSetGuiProperties;
}
UnitTest_Console;
