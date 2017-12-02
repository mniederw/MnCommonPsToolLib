# Simple example for using MnCommonPsToolLib with standard interactive mode without request or waiting
Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
OutInfo "Simple example for using MnCommonPsToolLib with standard interactive mode without request or waiting";
StdOutBegMsgCareInteractiveMode "NoRequestAtBegin, NoWaitAtEnd"; # will nothing write
OutProgress "Working";
StdOutEndMsgCareInteractiveMode; # will write: "Ok, done. Ending in 1 second(s)."
