#!/usr/bin/env pwsh

# Test Script Analyzer recursively on all repository files

param( [Boolean] $includeKnown = $false )

Set-StrictMode -Version Latest; trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; } $ErrorActionPreference = "Stop";

[String] $dir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$PSScriptRoot/..");
[String[]] $excl = @(
   "PSAvoidGlobalVars"                              # For some values we require global variables
  ,"PSAvoidUsingConvertToSecureStringWithPlainText" # We need it for our own credential storage
  ,"PSAvoidUsingPlainTextForPassword"               # We need it for our own credential storage
  ,"PSAvoidUsingPositionalParameters"               # Of course we use positional parameters and do not want to use only named parameters
  ,"PSAvoidUsingUsernameAndPasswordParams"          # We need it for our own credential storage
  ,"PSAvoidUsingWriteHost"                          # Otherwise Write-Output is not printed when caller redirects it and for using writes without line feeds
  ,"PSPossibleIncorrectComparisonWithNull"          # We need it for showing this bad feature
  ,"PSUseDeclaredVarsMoreThanAssignments"           # We have a lot of dummy variables
);
if( $includeKnown ){ $excl = @(); }

Write-Output "Running Powershell Script Analyzer recursively below `"$dir`" ";
Write-Output "  which checks all ps scripts and lists suggestions for improvements. ";
$excl | Where-Object{ $null -ne $_ } | ForEach-Object{ Write-Output "    ExcludeRule = $_" }
Write-Output "  Note: If PSScriptAnalyzer is not yet installed then install it with admin rights as follow:";
Write-Output "    Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module -ErrorAction Stop PSScriptAnalyzer;"

Invoke-ScriptAnalyzer -Path $dir -Recurse -Outvariable issues -ReportSummary -ExcludeRule $excl;

$nrOfErrors   = $issues.Where({$_.Severity -eq 'Error'  }).Count;
$nrOfWarnings = $issues.Where({$_.Severity -eq 'Warning'}).Count;
[String] $msg = "There were total $nrOfErrors errors and $nrOfWarnings warnings.";
if( $nrOfErrors -eq 0 ){ Write-Output $msg; }else{ Write-Error $msg -ErrorAction Stop; }

Write-Output "Ok, done.";
Read-Host "Press Enter to exit.";
