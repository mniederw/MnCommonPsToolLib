# Test Script Analyzer recursively on all repository files

param( [Boolean] $excludeKnown = $false )

trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; }

Write-Output "Note: if PSScriptAnalyzer is not yet installed then install it with admin rights:";
Write-Output "  Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module -ErrorAction Stop PSScriptAnalyzer;"

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

Write-Output "Running Script Analyzer recursively below `"$dir`" ExcludeRule=($excl)";
Invoke-ScriptAnalyzer -Path $dir -Recurse -Outvariable issues -ReportSummary -ExcludeRule $excl;
Write-Output "Ok, done.";
Read-Host "Press enter to exit";
