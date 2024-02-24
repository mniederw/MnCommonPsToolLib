#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function TestElevated(){
  OutProgress (ScriptGetCurrentFuncName);
  if( -not (ProcessIsRunningInElevatedAdminMode) ){ OutProgress "Not running in elevated mode, so bypass test."; return; }

  OutInfo "MnCommonPsToolLibUnitTestElevated - perform things requiring elevated admid mode";

  OutProgress "ToolWin10PackageGetState of OpenSSH.Client: $(ToolWin10PackageGetState "OpenSSH.Client")"
  # Discard non-readonly test for: ToolWin10PackageInstall "OpenSSH.Client"
  # Discard non-readonly test for: ToolWin10PackageDeinstall "OpenSSH.Client"

  OutSuccess "Ok, done.";
}

if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
TestElevated;
