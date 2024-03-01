#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Win_Service(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  # TODO: ServiceListRunnings                  (){
  Assert ((ServiceListExistings).Count -gt 20);
  Assert ((ServiceListExistingsAsStringArray).Count -gt 20);
  # TODO: ServiceNotExists                     ( [String] $serviceName ){
  # TODO: ServiceExists                        ( [String] $serviceName ){
  # TODO: ServiceAssertExists                  ( [String] $serviceName ){
  # TODO: ServiceGet                           ( [String] $serviceName ){
  # TODO: ServiceGetState                      ( [String] $serviceName ){
  # TODO: ServiceStop                          ( [String] $serviceName, [Boolean] $ignoreIfFailed = $false ){
  # TODO: ServiceStart                         ( [String] $serviceName ){
  # TODO: ServiceSetStartType                  ( [String] $serviceName, [String] $startType, [Boolean] $errorAsWarning = $false ){
  # TODO: ServiceMapHiddenToCurrentName        ( [String] $serviceName )
}
Test_Win_Service;
