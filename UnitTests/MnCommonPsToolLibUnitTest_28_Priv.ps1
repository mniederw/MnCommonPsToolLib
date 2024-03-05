#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Priv(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO PrivAclRegRightsToString ( [System.Security.AccessControl.RegistryRights] $r )
}
UnitTest_Priv;
