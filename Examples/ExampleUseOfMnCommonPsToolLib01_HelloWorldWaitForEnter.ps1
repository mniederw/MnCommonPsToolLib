# simple example for using MnCommonPsToolLib 
Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

OutInfo "Hello world with request for pressing enter key before exit";
OutProgress "Working";
StdInReadLine "Press enter to exit.";
