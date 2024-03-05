#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Global(){
  OutProgress (ScriptGetCurrentFuncName);

  if( [Console]::OutputEncoding.WebName -ne "utf-8" ){ # we are running in non utf-8 console as example VS-Code.
    $Global:OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [Text.UTF8Encoding]::UTF8;
    GlobalVariablesInit;
  }

  Assert ($global:ErrorActionPreference         -eq "Stop");
  Assert ($global:ReportErrorShowExceptionClass -eq $true );
  Assert ($global:ReportErrorShowInnerException -eq $true );
  Assert ($global:ReportErrorShowStackTrace     -eq $true );
  Assert ($global:FormatEnumerationLimit        -eq 999   );
  Assert ($global:ReportErrorShowExceptionClass -eq $true );
  Assert ($global:ReportErrorShowInnerException -eq $true );
  Assert ($global:ReportErrorShowStackTrace     -eq $true );
  #
  Assert ($global:OutputEncoding.WebName        -eq [Console]::OutputEncoding.WebName);
  if( $global:OutputEncoding.WebName -ne "utf-8" ){ OutWarning "Warning: global:OutputEncoding.WebName=$($global:OutputEncoding.WebName) Expected to use encoding from console $([Console]::OutputEncoding.WebName) (we recommend set both to utf-8), extend your profile to set it"; }
  Assert ([System.Threading.Thread]::CurrentThread.CurrentUICulture.Name -eq 'en-US');
  #
  Assert ($CurrentMonthAndWeekIsoString.Length -ge 10 ); # Example: "2024-03-W9" or "2024-03-W09"
  Assert ($InfoLineColor.Length                -ge  3 ); # Example: "White"
  Assert ($ComputerName.Length                 -ge  3 ); # Example: "mymach"
  #
  GlobalSetModeVerboseEnable         ( $global:VerbosePreference -eq "Continue"        );
  GlobalSetModeEnableAutoLoadingPref ( $global:PSModuleAutoLoadingPreference -eq "All" );
  GlobalSetModeHideOutProgress       ( $global:ModeHideOutProgress                     );
  GlobalSetModeDisallowInteractions  ( $global:ModeDisallowInteractions                );
  GlobalSetModeOutputWithTsPrefix    ( $global:ModeOutputWithTsPrefix                  );
}
UnitTest_Global;
