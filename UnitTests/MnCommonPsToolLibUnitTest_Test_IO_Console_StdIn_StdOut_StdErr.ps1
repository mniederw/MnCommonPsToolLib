#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_IO_Console_StdIn_StdOut_StdErr(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   ConsoleHide         
  #   ConsoleShow         
  #   ConsoleRestore      
  #   ConsoleMinimize     
  #   ConsoleSetPos                        ( [Int32] $x, [Int32] $y ){
  #   ConsoleSetGuiProperties
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
  #   StdInAssertAllowInteractions         (){ if( $global:ModeDisallowInteractions ){
  #   StdInReadLine                        ( [String] $line ){ OutStringInColor "Cyan" $line; StdInAssertAllowInteractions; return [String] (Read-Host); }
  #   StdInReadLinePw                      ( [String] $line ){ OutStringInColor "Cyan" $line; StdInAssertAllowInteractions; return [System.Security.SecureString] (Read-Host -AsSecureString); }
  #   StdInAskForEnter                     (){ [String] $dummyLine = StdInReadLine "Press Enter to Exit"; }
  #   StdInAskForBoolean                   ( [String] $msg = "Enter Yes or No (y/n)?", [String] $strForYes = "y", [String] $strForNo = "n" ){
  #   StdInWaitForAKey                     (){
  #   StdOutLine                           ( [String] $line ){ $Host.UI.WriteLine($line); } # Writes an stdout line in default color, normally not used, rather use OutInfo because it classifies kind of output.
  #   StdOutRedLineAndPerformExit          ( [String] $line, [Int32] $delayInSec = 1 ){ #
  #   StdErrHandleExc                      ( [System.Management.Automation.ErrorRecord] $er, [Int32] $delayInSec = 1 ){
  #                                          # Output full error information in red lines and then either wait for pressing enter or otherwise if interactions are globally disallowed then wait specified delay
  #   StdPipelineErrorWriteMsg             ( [String] $msg ){ Write-Error $msg; } # does not work in powershell-ise, so in general do not use it, use throw
  #   StdOutBegMsgCareInteractiveMode      ( [String] $mode = "" ){ # Available mode: ""="DoRequestAtBegin", "NoRequestAtBegin", "NoWaitAtEnd", "MinimizeConsole".
  #                                          # Usually this is the first statement in a script after an info line. So you can give your scripts a standard styling.
  #   StdInAskForAnswerWhenInInteractMode  ( [String] $line = "Are you sure (y/n)? ", [String] $expectedAnswer = "y" ){
  #                                          # works case insensitive; is ignored if interactions are suppressed by global var ModeDisallowInteractions; will abort if not expected answer.
  #   StdInAskAndAssertExpectedAnswer      ( [String] $line = "Are you sure (y/n)? ", [String] $expectedAnswer = "y" ){ # works case insensitive
  #   StdOutEndMsgCareInteractiveMode      ( [Int32] $delayInSec = 1 ){
}
Test_IO_Console_StdIn_StdOut_StdErr;
