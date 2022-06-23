#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Service_Task(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   ServiceListRunnings                  (){
  #   ServiceListExistings                 (){ # We could also use Get-Service but members are lightly differnet;
  #                                          # 2017-06 we got (RuntimeException: You cannot call a method on a null-valued expression.) so we added null check.
  #   ServiceListExistingsAsStringArray    (){
  #   ServiceNotExists                     ( [String] $serviceName ){
  #   ServiceExists                        ( [String] $serviceName ){
  #   ServiceAssertExists                  ( [String] $serviceName ){
  #   ServiceGet                           ( [String] $serviceName ){
  #   ServiceGetState                      ( [String] $serviceName ){
  #   ServiceStop                          ( [String] $serviceName, [Boolean] $ignoreIfFailed = $false ){
  #   ServiceStart                         ( [String] $serviceName ){
  #   ServiceSetStartType                  ( [String] $serviceName, [String] $startType, [Boolean] $errorAsWarning = $false ){
  #   ServiceMapHiddenToCurrentName        ( [String] $serviceName ){
  #                                          # Hidden services on Windows 10: Some services do not have a static service name because they do not have any associated DLL or executable.
  #                                          # This method maps a symbolic name as MessagingService_###### by the currently correct service name (ex: "MessagingService_26a344").
  #                                          # The ###### symbolizes a random hex string of 5-6 chars. ex: (ServiceMapHiddenName "MessagingService_######") -eq "MessagingService_26a344";
  #                                          # Currently all these known hidden services are internally started by "C:\WINDOWS\system32\svchost.exe -k UnistackSvcGroup". The following are known:
  #   TaskList                             (){
  #   TaskIsDisabled                       ( [String] $taskPathAndName ){
  #   TaskDisable                          ( [String] $taskPathAndName ){
}
Test_Service_Task;
