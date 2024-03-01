#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Out(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   OutGetTsPrefix                       ( [Boolean] $forceTsPrefix = $false ){
  #   OutStringInColor                     ( [String] $color, [String] $line, [Boolean] $noNewLine = $true ){
  #                                          # NoNewline is used because on multi threading usage, line text and newline can be interrupted between.
  #   OutInfo                              ( [String] $line ){ OutStringInColor $global:InfoLineColor "$(OutGetTsPrefix)$line$([Environment]::NewLine)"; }
  #   OutSuccess                           ( [String] $line ){ OutStringInColor Green "$(OutGetTsPrefix)$line$([Environment]::NewLine)"; }
  #   OutWarning                           ( [String] $line, [Int32] $indentLevel = 1 ){
  #   OutError                             ( [String] $line ){
  #   OutProgress                          ( [String] $line, [Int32] $indentLevel = 1 ){
  #                                          # Used for tracing changing actions, otherwise use OutVerbose.
  #   OutProgressText                      ( [String] $str ){
  #   OutVerbose                           ( [String] $line ){
  #                                          # Output depends on $VerbosePreference, used in general for tracing some important arguments or command results mainly of IO-operations.
  #   OutDebug                             ( [String] $line ){
  #                                          # Output depends on $DebugPreference, used in general for tracing internal states which can produce a lot of lines.
  #   OutClear                             (){ Clear-Host; }
  #   OutStartTranscriptInTempDir          ( [String] $name = "MnCommonPsToolLib" ){ # return logfile
  #   OutStopTranscript                    (){ Stop-Transcript; }
}
Test_Out;
