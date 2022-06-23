#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Script(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   ScriptImportModuleIfNotDone          ( [String] $moduleName ){ if( -not (Get-Module $moduleName) ){
  #                                          OutProgress "Import module $moduleName (can take some seconds on first call)";
  #                                          Import-Module -NoClobber $moduleName -DisableNameChecking; } }
  #   ScriptGetCurrentFunc                 (){ return [String] ((Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name); }
  #   ScriptGetCurrentFuncName             (){ return [String] ((Get-PSCallStack)[2].Position); }
  #   ScriptGetAndClearLastRc              (){ [Int32] $rc = 0;
  #                                          if( ((test-path "variable:LASTEXITCODE") -and $null -ne $LASTEXITCODE <# if no windows command was done then $LASTEXITCODE is null #> -and $LASTEXITCODE -ne 0) -or -not $? ){ $rc = $LASTEXITCODE; ScriptResetRc; }
  #                                          return [Int32] $rc; }
  #   ScriptResetRc                        (){ $error.clear(); & "cmd.exe" "/C" "EXIT 0"; $error.clear(); AssertRcIsOk; } # reset ERRORLEVEL to 0
  #   ScriptNrOfScopes                     (){ [Int32] $i = 1; while($true){
  #                                          try{ Get-Variable null -Scope $i -ValueOnly -ErrorAction SilentlyContinue | Out-Null; $i++;
  #                                          }catch{ <# ex: System.Management.Automation.PSArgumentOutOfRangeException #> return [Int32] ($i-1); } } }
  #   ScriptGetProcessCommandLine          (){ return [String] ([environment]::commandline); } # ex: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "& \"C:\myscript.ps1\"";
  #   ScriptGetDirOfLibModule              (){ return [String] $PSScriptRoot ; } # Get dir       of this script file of this function or empty if not from a script; alternative: (Split-Path -Parent -Path ($script:MyInvocation.MyCommand.Path))
  #   ScriptGetFileOfLibModule             (){ return [String] $PSCommandPath; } # Get full path of this script file of this function or empty if not from a script. alternative1: try{ return [String] (Get-Variable MyInvocation -Scope 1 -ValueOnly).MyCommand.Path; }catch{ return [String] ""; }  alternative2: $script:MyInvocation.MyCommand.Path
  #   ScriptGetCallerOfLibModule           (){ return [String] $MyInvocation.PSCommandPath; } # Result can be empty or implicit module if called interactive. alternative for dir: $MyInvocation.PSScriptRoot.
  #   ScriptGetTopCaller                   (){ # return the command line with correct doublequotes.
  #                                          # Result can be empty or implicit module if called interactive.
  #                                          # usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
  #                                          [String] $f = $global:MyInvocation.MyCommand.Definition.Trim();
  #                                          if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return [String] ""; }
  #                                          if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
  #                                          if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
  #                                          return [String] $f; }
  #   ScriptIsProbablyInteractive          (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim();
  #                                          # Result can be empty or implicit module if called interactive.
  #                                          # usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
  #                                          return [Boolean] $f -eq "" -or $f -eq "ScriptGetTopCaller" -or -not $f.StartsWith("&"); }
}
Test_Script;
