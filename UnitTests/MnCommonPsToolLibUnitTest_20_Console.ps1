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
  try{
    [Window]::GetWindowRect($hd,[ref]$r) | Out-Null;
    ConsoleSetPos $r.Left $r.Top;
    ConsoleSetGuiProperties;
  }catch{
    # 2024-03 on github we get: Exception calling "GetWindowRect" with "2" argument(s): "Value cannot be null. (Parameter 'path1')"
    OutWarning "Warning: We ignore exceptions for ConsoleSetPos and ConsoleSetGuiProperties because is probably running on machine without gui: $_";
  }
}
UnitTest_Console;
