﻿# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test(){
  OutInfo "MnCommonPsToolLibUnitTestElevated - perform things requiring elevated admid mode";

  OutProgress "ToolWin10PackageGetState of OpenSSH.Client: $(ToolWin10PackageGetState "OpenSSH.Client")"
  # Discard non-readonly test for: ToolWin10PackageInstall "OpenSSH.Client"
  # Discard non-readonly test for: ToolWin10PackageDeinstall "OpenSSH.Client"

  OutSuccess "Ok, done.";
}

Test;
StdInAskForEnter;