#!/usr/bin/env pwsh
# Simple example for using MnCommonPsToolLib with standard interactive mode
Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

OutProgressTitle   "$($MyInvocation.MyCommand)";
OutProgress        "Simple example for using MnCommonPsToolLib with standard begin and end interactive mode statements.";
StdInAskForAnswerWhenInInteractMode;
OutProgress        "Working";
OutProgressSuccess "Ok, done."
StdInReadLine      "Press Enter to exit.";

