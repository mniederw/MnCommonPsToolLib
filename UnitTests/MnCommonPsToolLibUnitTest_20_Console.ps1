#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Console(){
  OutProgress (ScriptGetCurrentFuncName);
  try{
    ConsoleShow;
    # ConsoleHide;
    ConsoleShow;
    ConsoleMinimize;
    ConsoleShow;
    ConsoleRestore;
    try{
      [RECT] $r = New-Object RECT; [Object] $hd = (Get-Process -ID $PID).MainWindowHandle;
      [Window]::GetWindowRect($hd,[ref]$r) | Out-Null;
      ConsoleSetPos $r.Left $r.Top;
      if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ ConsoleSetGuiProperties; } # is often tested and would relocate window
    }catch{
      # 2024-03 on github we get: Exception calling "GetWindowRect" with "2" argument(s): "Value cannot be null. (Parameter 'path1')"
      OutProgress "Warning: We ignore exceptions for ConsoleSetPos and ConsoleSetGuiProperties because is probably running on machine without gui or in vs-code-terminal-pwsh: $_";
    }
  }catch{
    # 2024-03 on ps5
    OutWarning "Warning: We ignore exceptions: $_";
  }
}
UnitTest_Console;
