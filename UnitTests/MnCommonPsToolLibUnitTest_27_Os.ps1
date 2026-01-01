#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Os(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  OutProgress "OsPsVersion          : $(OsPsVersion)";
  OutProgress "OsIsWindows          : $(OsIsWindows)";
  OutProgress "OsIsLinux            : $(OsIsLinux)";
  OutProgress "OsIsMacOS            : $(OsIsMacOS)";
  OutProgress "OsIsWinVistaOrHigher : $(OsIsWinVistaOrHigher)";
  OutProgress "OsIsWin7OrHigher     : $(OsIsWin7OrHigher)";
  OutProgress "OsPathSeparator      : $(OsPathSeparator)";
  OutProgress "OsPsModulePathList   : $(OsPsModulePathList)";
  Assert ((OsPsModulePathContains "./mydir/") -eq $false);
  Assert ( ( ([Int32](OsIsWindows)) + ([Int32](OsIsLinux)) + ([Int32](OsIsMacOS)) ) -eq 1 );
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ OsPsModulePathAdd "./mydir/"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ OsPsModulePathDel "./mydir/"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ OsPsModulePathSet "./mydir1/$(OsPathSeparator)./mydir2/"; }
}
UnitTest_Os;
