#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Priv(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  Assert ((PrivGetUserFromName $env:USERNAME).GetType().FullName -eq "System.Security.Principal.NTAccount");
  #   PrivGetUserCurrent                   (){
  #   PrivGetUserSystem                    (){
  #   PrivGetGroupAdministrators           (){
  #   PrivGetGroupAuthenticatedUsers       (){
  #   PrivGetGroupEveryone                 (){
  #   PrivGetUserTrustedInstaller          (){
  #   PrivFsRuleAsString                   ( [System.Security.AccessControl.FileSystemAccessRule] $rule ){
  #   PrivAclAsString                      ( [System.Security.AccessControl.FileSystemSecurity] $acl ){
  #   PrivAclSetProtection                 ( [System.Security.AccessControl.ObjectSecurity] $acl, [Boolean] $isProtectedFromInheritance, [Boolean] $preserveInheritance ){
  #                                          # set preserveInheritance to false to remove inherited access rules, param is ignored if $isProtectedFromInheritance is false.
  #   PrivFsRuleCreateFullControl          ( [System.Security.Principal.IdentityReference] $account, [Boolean] $useInherit ){ # for dirs usually inherit is used
  #   PrivFsRuleCreateByString             ( [System.Security.Principal.IdentityReference] $account, [String] $s ){
  #                                          # format:  access inherit rights ; access = ('+'|'-') ; rights = ('F' | { ('R'|'M'|'W'|'X'|...) [','] } ) ; inherit = ('/'|'') ;
  #                                          # examples: "+F", "+F/", "-M", "+RM", "+RW"
  #   PrivDirSecurityCreateFullControl     ( [System.Security.Principal.IdentityReference] $account ){
  #   PrivFileSecurityCreateOwner          ( [System.Security.Principal.IdentityReference] $account ){
  #   PrivAclHasFullControl                ( [System.Security.AccessControl.FileSystemSecurity] $acl, [System.Security.Principal.IdentityReference] $account, [Boolean] $isDir ){
  #   PrivShowTokenPrivileges              (){
  #   PrivEnableTokenPrivilege             (){
  #                                          # Required for example for Set-ACL if it returns "The security identifier is not allowed to be the owner of this object.";
  #                                          # Then you need for example the Privilege SeRestorePrivilege;
  #                                          # Based on https://gist.github.com/fernandoacorreia/3997188
  #                                          #   or http://www.leeholmes.com/blog/2010/09/24/adjusting-token-privileges-in-powershell/
  #                                          #   or https://social.technet.microsoft.com/forums/windowsserver/en-US/e718a560-2908-4b91-ad42-d392e7f8f1ad/take-ownership-of-a-registry-key-and-change-permissions
  #                                          # Alternative: https://www.powershellgallery.com/packages/PoshPrivilege/0.3.0.0/Content/Scripts%5CEnable-Privilege.ps1
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ PrivEnableTokenAll; }
  #   PrivAclFsRightsToString              ( [System.Security.AccessControl.FileSystemRights] $r ){ # as ICACLS https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls
  #   PrivAclFsRightsFromString            ( [String] $s ){ # inverse of PrivAclFsRightsToString
}
UnitTest_Win_Priv;
