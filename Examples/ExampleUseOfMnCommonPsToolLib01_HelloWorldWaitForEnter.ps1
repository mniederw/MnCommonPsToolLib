# simple example for using MnCommonPsToolLib 
Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

OutInfo "Hello world with request for pressing enter key before exit";
StdInAskAndAssertExpectedAnswer; # Are you sure (y/n)?
OutProgress "Working";
StdInAskForEnter; # Press Enter to Exit
