# simple example for using MnCommonPsToolLib 
Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

OutInfo "Hello world";
OutProgress "Working";
StdInReadLine "Press enter to exit.";
