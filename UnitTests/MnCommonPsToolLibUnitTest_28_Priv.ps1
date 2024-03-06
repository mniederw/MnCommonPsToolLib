#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Priv(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert ((PrivAclRegRightsToString ([System.Security.AccessControl.RegistryRights]::FullControl -as  [System.Security.AccessControl.RegistryRights])) -eq "F,");
  Assert ((PrivAclRegRightsToString ([System.Security.AccessControl.RegistryRights]::ReadKey     -as  [System.Security.AccessControl.RegistryRights])) -eq "R,");
  Assert ((PrivAclRegRightsToString ([System.Security.AccessControl.RegistryRights]::FullControl -bor [System.Security.AccessControl.RegistryRights]::EnumerateSubKeys)) -eq "F,");
  Assert ((PrivAclRegRightsToString ([System.Security.AccessControl.RegistryRights]::ReadKey     -bor [System.Security.AccessControl.RegistryRights]::EnumerateSubKeys)) -eq "R,");
  Assert ((PrivAclRegRightsToString "FullControl") -eq "F,");
  Assert ((PrivAclRegRightsToString "ReadKey")     -eq "R,");
}
UnitTest_Priv;
