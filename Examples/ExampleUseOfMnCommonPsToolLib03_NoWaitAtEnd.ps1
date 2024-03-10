#!/usr/bin/env pwsh
# Simple example for using MnCommonPsToolLib with standard interactive mode without request or waiting
Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

OutProgressTitle   "$($MyInvocation.MyCommand)";
OutProgress        "Simple example for using MnCommonPsToolLib with standard begin and end interactive mode statements without request or waiting at the end.";
OutProgress        "Working";
OutProgressSuccess "Ok, done. Ending in 1 second(s).";
ProcessSleepSec 2;
