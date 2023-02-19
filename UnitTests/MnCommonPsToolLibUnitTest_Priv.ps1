#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Priv(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  # TODO:
  #   PrivGetUserFromName                  ( [String] $username ){ # optionally as domain\username
  #   PrivGetUserCurrent                   (){ return [System.Security.Principal.IdentityReference] ([System.Security.Principal.WindowsIdentity]::GetCurrent().User); } # alternative: PrivGetUserFromName "$env:userdomain\$env:username"
  #   PrivGetUserSystem                    (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18"                                                      )).Translate([System.Security.Principal.NTAccount]); } # NT AUTHORITY\SYSTEM = NT-AUTORITÄT\SYSTEM
  #   PrivGetGroupAdministrators           (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544"                                                  )).Translate([System.Security.Principal.NTAccount]); } # BUILTIN\Administrators = VORDEFINIERT\Administratoren  (more https://msdn.microsoft.com/en-us/library/windows/desktop/aa379649(v=vs.85).aspx)
  #   PrivGetGroupAuthenticatedUsers       (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-11"                                                      )).Translate([System.Security.Principal.NTAccount]); } # NT AUTHORITY\Authenticated Users = NT-AUTORITÄT\Authentifizierte Benutzer
  #   PrivGetGroupEveryone                 (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0"                                                       )).Translate([System.Security.Principal.NTAccount]); } # Jeder
  #   PrivGetUserTrustedInstaller          (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464")).Translate([System.Security.Principal.NTAccount]); } # NT SERVICE\TrustedInstaller
  #   PrivFsRuleAsString                   ( [System.Security.AccessControl.FileSystemAccessRule] $rule ){
  #   PrivAclAsString                      ( [System.Security.AccessControl.FileSystemSecurity] $acl ){
  #   PrivAclSetProtection                 ( [System.Security.AccessControl.ObjectSecurity] $acl, [Boolean] $isProtectedFromInheritance, [Boolean] $preserveInheritance ){
  #                                          # set preserveInheritance to false to remove inherited access rules, param is ignored if $isProtectedFromInheritance is false.
  #   PrivFsRuleCreate                     ( [System.Security.Principal.IdentityReference] $account, [System.Security.AccessControl.FileSystemRights] $rights,
  #                                          [System.Security.AccessControl.InheritanceFlags] $inherit, [System.Security.AccessControl.PropagationFlags] $propagation, [System.Security.AccessControl.AccessControlType] $access ){
  #                                          # usually account is (PrivGetGroupAdministrators)
  #                                          # combinations see: https://msdn.microsoft.com/en-us/library/ms229747(v=vs.100).aspx
  #                                          # https://technet.microsoft.com/en-us/library/ff730951.aspx  Rights=(AppendData,ChangePermissions,CreateDirectories,CreateFiles,Delete,DeleteSubdirectoriesAndFiles,ExecuteFile,FullControl,ListDirectory,Modify,Read,ReadAndExecute,ReadAttributes,ReadData,ReadExtendedAttributes,ReadPermissions,Synchronize,TakeOwnership,Traverse,Write,WriteAttributes,WriteData,WriteExtendedAttributes) Inherit=(ContainerInherit,ObjectInherit,None) Propagation=(InheritOnly,NoPropagateInherit,None) Access=(Allow,Deny)
  #   PrivFsRuleCreateFullControl          ( [System.Security.Principal.IdentityReference] $account, [Boolean] $useInherit ){ # for dirs usually inherit is used
  #   PrivFsRuleCreateByString             ( [System.Security.Principal.IdentityReference] $account, [String] $s ){
  #                                          # format:  access inherit rights ; access = ('+'|'-') ; rights = ('F' | { ('R'|'M'|'W'|'X'|...) [','] } ) ; inherit = ('/'|'') ;
  #                                          # examples: "+F", "+F/", "-M", "+RM", "+RW"
  #   PrivDirSecurityCreateFullControl     ( [System.Security.Principal.IdentityReference] $account ){
  #   PrivDirSecurityCreateOwner           ( [System.Security.Principal.IdentityReference] $account ){
  #                                          [System.Security.AccessControl.DirectorySecurity] $result = New-Object System.Security.AccessControl.DirectorySecurity;
  #                                          $result.SetOwner($account);
  #                                          return [System.Security.AccessControl.DirectorySecurity] $result; }
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
  #                                          param(
  #                                            # The privilege to adjust. This set is taken from http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
  #                                            [ValidateSet(
  #                                              "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege", "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege",
  #                                              "SeCreatePagefilePrivilege", "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege", "SeDebugPrivilege",
  #                                              "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege", "SeIncreaseQuotaPrivilege",
  #                                              "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege", "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
  #                                              "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege", "SeRestorePrivilege", "SeSecurityPrivilege",
  #                                              "SeShutdownPrivilege", "SeSyncAgentPrivilege", "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
  #                                              "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege", "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
  #                                              $Privilege,
  #                                            # The process on which to adjust the privilege. Defaults to the current process.
  #                                            $ProcessId = $PID,
  #                                            # Switch to disable the privilege, rather than enable it.
  #                                            [Switch] $Disable
  #                                          )
  #   PrivEnableTokenAll                   (){
  #                                          PrivEnableTokenPrivilege SeLockMemoryPrivilege          ;
  #                                          PrivEnableTokenPrivilege SeIncreaseQuotaPrivilege       ;
  #   PrivAclFsRightsToString              ( [System.Security.AccessControl.FileSystemRights] $r ){ # as ICACLS https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls
  #   PrivAclFsRightsFromString            ( [String] $s ){ # inverse of PrivAclFsRightsToString
  #   PrivAclRegRightsToString              ( [System.Security.AccessControl.RegistryRights] $r ){
}
Test_Priv;
