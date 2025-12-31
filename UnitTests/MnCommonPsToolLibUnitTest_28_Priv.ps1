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
  #   PrivDirSecurityCreateOwner           ( [System.Security.Principal.IdentityReference] $account ){
  #   PrivFsRuleCreate                     ( [System.Security.Principal.IdentityReference] $account, [System.Security.AccessControl.FileSystemRights] $rights,
  #                                          [System.Security.AccessControl.InheritanceFlags] $inherit, [System.Security.AccessControl.PropagationFlags] $propagation, [System.Security.AccessControl.AccessControlType] $access ){
  #                                          # usually account is (PrivGetGroupAdministrators)
  #                                          # combinations see: https://msdn.microsoft.com/en-us/library/ms229747(v=vs.100).aspx
  #                                          # https://technet.microsoft.com/en-us/library/ff730951.aspx  Rights=(AppendData,ChangePermissions,CreateDirectories,CreateFiles,Delete,DeleteSubdirectoriesAndFiles,ExecuteFile,FullControl,ListDirectory,Modify,Read,ReadAndExecute,ReadAttributes,ReadData,ReadExtendedAttributes,ReadPermissions,Synchronize,TakeOwnership,Traverse,Write,WriteAttributes,WriteData,WriteExtendedAttributes) Inherit=(ContainerInherit,ObjectInherit,None) Propagation=(InheritOnly,NoPropagateInherit,None) Access=(Allow,Deny)
}
UnitTest_Priv;
