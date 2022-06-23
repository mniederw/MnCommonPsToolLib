#!/usr/bin/env pwsh

# Test Script Analyzer recursively on all repository files

param( [Boolean] $excludeKnown = $false )

trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; }

[String] $dir = "$PSScriptRoot/..";
[String[]] $excl = @();
if( $excludeKnown ){ $excl = @(
   "PSAvoidUsingPositionalParameters"
  ,"PSAvoidGlobalVars"
  ,"PSAvoidUsingConvertToSecureStringWithPlainText"
  ,"PSAvoidUsingUsernameAndPasswordParams"
  ,"PSAvoidUsingPlainTextForPassword"
  ,"PSAvoidUsingEmptyCatchBlock"
  ,"PSAvoidUsingWriteHost"
  ,"PSUseDeclaredVarsMoreThanAssignments"
  );
}

Write-Output "Running Script Analyzer recursively below `"$dir`" ";
$excl | Where-Object{ $null -ne $_ } | ForEach-Object{ Write-Output "    ExcludeRule = $_" }
Write-Output "  Note: If PSScriptAnalyzer is not yet installed then install it with admin rights as followed:";
Write-Output "    Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module -ErrorAction Stop PSScriptAnalyzer;"
Invoke-ScriptAnalyzer -Path $dir -Recurse -Outvariable issues -ReportSummary -ExcludeRule $excl;
Write-Output "Ok, done."; 
Read-Host "Press enter to exit";
