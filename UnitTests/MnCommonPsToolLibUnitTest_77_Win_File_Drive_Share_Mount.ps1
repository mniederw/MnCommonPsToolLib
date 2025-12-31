#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_File_Drive_Share_Mount(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  # TODO:
  #   FileNtfsAlternativeDataStreamAdd     ( [String] $srcFile, [String] $adsName, [String] $val ){
  #   FileNtfsAlternativeDataStreamDel     ( [String] $srcFile, [String] $adsName ){
  #   FileAdsDownloadedFromInternetAdd     ( [String] $srcFile ){
  #   FileAdsDownloadedFromInternetDel     ( [String] $srcFile ){

  #   DriveMapTypeToString                 ( [UInt32] $driveType ){
  #   DriveList                            (){

  #   ShareGetTypeName                     ( [UInt32] $typeNr ){
  #   ShareGetTypeNr                       ( [String] $typeName ){
  #   ShareExists                          ( [String] $shareName ){
  #   ShareListAll                         ( [String] $selectShareName = "" ){
  #   ShareLocksList                       ( [String] $path = "" ){
  #   ShareLocksClose                      ( [String] $path = "" ){
  #   ShareCreate                          ( [String] $shareName, [String] $dir, [String] $descr = "", [Int32] $nrOfAccessUsers = 25, [Boolean] $ignoreIfAlreadyExists = $true ){
  #   ShareRemove                          ( [String] $shareName ){ # no action if it not exists

  #   MountPointLocksListAll               (){
  #   MountPointListAll                    (){ # we define mountpoint as a share mapped to a local path
  #   MountPointGetByDrive                 ( [String] $drive ){ # return null if not found
  #   MountPointRemove                     ( [String] $drive, [String] $mountPoint = "", [Boolean] $suppressProgress = $false ){
  #   MountPointCreate                     ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $errorAsWarning = $false, [Boolean] $noPreLogMsg = $false ){
  # if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){
}
UnitTest_Win_File_Drive_Share_Mount;
