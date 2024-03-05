#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Credential(){
  OutProgress (ScriptGetCurrentFuncName);
  #
  # TODO:  CredentialStandardizeUserWithDomain  ( [String] $username ){
  #                                          # Allowed username as input: "", "u0", "u0@domain", "@domain\u0", "domain\u0"   used because for unknown reasons sometimes a username like user@domain does not work, it requires domain\user.
  # TODO:  CredentialGetSecureStrFromHexString  ( [String] $text ){
  # TODO:  CredentialGetSecureStrFromText       ( [String] $text ){ AssertNotEmpty $text "$(ScriptGetCurrentFunc).callingText";
  # TODO:  CredentialGetHexStrFromSecureString  ( [System.Security.SecureString] $code ){
  # TODO:  CredentialGetTextFromSecureString    ( [System.Security.SecureString] $code ){
  # TODO:  CredentialGetUsername                ( [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $onNullCredGetCurrentUserInsteadOfEmpty = $false ){
  #                                          # if cred is null then take current user.
  # TODO:  CredentialGetPassword                ( [System.Management.Automation.PSCredential] $cred = $null ){
  #                                          # if cred is null then return empty string.
  #                                          # $cred.GetNetworkCredential().Password is the same as (CredentialGetTextFromSecureString $cred.Password)
  # TODO:  CredentialWriteToFile                ( [System.Management.Automation.PSCredential] $cred, [String] $secureCredentialFile ){
  # TODO:  CredentialRemoveFile                 ( [String] $secureCredentialFile ){
  # TODO:  CredentialReadFromFile               ( [String] $secureCredentialFile ){
  # TODO:  CredentialCreate                     ( [String] $username = "", [String] $password = "", [String] $accessShortDescription = "" ){
  # TODO:  CredentialGetAndStoreIfNotExists     ( [String] $secureCredentialFile, [String] $username = "", [String] $password = "", [String] $accessShortDescription = ""){
  #                                          # If username or password is empty then they are asked from std input.
  #                                          # If file exists and non-empty-user matches then it takes credentials from it.
  #                                          # If file not exists or non-empty-user not matches then it is written by given credentials.
  #                                          # For access description enter a message hint which is added to request for user as "login host xy", "mountpoint xy", etc.
  #                                          # For secureCredentialFile usually use: "$env:LOCALAPPDATA\MyNameOrCompany\MyOperation.secureCredentials.txt";
}
UnitTest_Credential;
