# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Registry(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   RegistryMapToShortKey                ( [String] $key ){ # Note: HKCU: will be replaced by HKLM:\SOFTWARE\Classes" otherwise it would not work
  #                                          return [String] $key -replace "HKEY_LOCAL_MACHINE:","HKLM:" -replace "HKEY_CURRENT_USER:","HKCU:" -replace "HKEY_CLASSES_ROOT:","HKCR:" -replace "HKCR:","HKLM:\SOFTWARE\Classes" -replace "HKEY_USERS:","HKU:" -replace "HKEY_CURRENT_CONFIG:","HKCC:"; }
  #   RegistryRequiresElevatedAdminMode    ( [String] $key ){
  #   RegistryAssertIsKey                  ( [String] $key ){
  #                                          throw [Exception] "Missing registry key instead of: `"$key`""; }
  #   RegistryExistsKey                    ( [String] $key ){
  #   RegistryExistsValue                  ( [String] $key, [String] $name = ""){
  #   RegistryCreateKey                    ( [String] $key ){  # creates key if not exists
  #   RegistryGetValueAsObject             ( [String] $key, [String] $name = ""){ # Return null if value not exists.
  #   RegistryGetValueAsString             ( [String] $key, [String] $name = "" ){ # return empty string if value not exists
  #   RegistryListValueNames               ( [String] $key ){
  #   RegistryDelKey                       ( [String] $key ){
  #   RegistryDelValue                     ( [String] $key, [String] $name = "" ){
  #   RegistrySetValue                     ( [String] $key, [String] $name, [String] $type, [Object] $val, [Boolean] $overwriteEvenIfStringValueIsEqual = $false ){
  #                                          # Creates key-value if it not exists; value is changed only if it is not equal than previous value; available types: Binary, DWord, ExpandString, MultiString, None, QWord, String, Unknown.
  #   RegistryImportFile                   ( [String] $regFile ){
  #   RegistryKeyGetAcl                    ( [String] $key ){
  #   RegistryKeyGetHkey                   ( [String] $key ){
  #   RegistryKeyGetSubkey                 ( [String] $key ){
  #   RegistryPrivRuleCreate               ( [System.Security.Principal.IdentityReference] $account, [String] $regRight = "" ){
  #                                          # ex: (PrivGetGroupAdministrators) "FullControl";
  #                                          # regRight ex: "ReadKey", available enums: https://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights(v=vs.110).aspx
  #   RegistryPrivRuleToString             ( [System.Security.AccessControl.RegistryAccessRule] $rule ){
  #                                          # ex: RegistryPrivRuleToString (RegistryPrivRuleCreate (PrivGetGroupAdministrators) "FullControl")
  #   RegistryKeySetOwner                  ( [String] $key, [System.Security.Principal.IdentityReference] $account ){
  #                                          # ex: "HKLM:\Software\MyManufactor" (PrivGetGroupAdministrators);
  #                                          # Changes only if owner is not yet the required one.
  #                                          # Note: Throws PermissionDenied if object is protected by TrustedInstaller.
  #                                          # Use force this if object is protected by TrustedInstaller,
  #                                          # then it asserts elevated mode and enables some token privileges.
  #   RegistryKeySetAclRight               ( [String] $key, [System.Security.Principal.IdentityReference] $account, [String] $regRight = "FullControl" ){
  #                                          # ex: "HKLM:\Software\MyManufactor" (PrivGetGroupAdministrators) "FullControl";
  #   RegistryKeyAddAclRule                ( [String] $key, [System.Security.AccessControl.RegistryAccessRule] $rule ){
  #   RegistryKeySetAclRule                ( [String] $key, [System.Security.AccessControl.RegistryAccessRule] $rule, [Boolean] $useAddNotSet = $false ){
  #                                          # ex: "HKLM:\Software\MyManufactor" (PrivGetGroupAdministrators) "FullControl";
}
Test_Registry;
