# Simple example for using MnCommonPsToolLib with standard interactive mode
Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

OutInfo "Simple example for using MnCommonPsToolLib with standard begin and end interactive mode statements.";
StdOutBegMsgCareInteractiveMode; # will ask: if you are sure (y/n)
OutProgress "Working";
StdOutEndMsgCareInteractiveMode; # will write: Ok, done. Press Enter to Exit
