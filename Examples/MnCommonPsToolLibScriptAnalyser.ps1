# Test module MnCommonPsToolLib

trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; }

Write-Output "Note: if PSScriptAnalyzer is not yet installed then install it with admin rights:";
Write-Output "  Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module -ErrorAction Stop PSScriptAnalyzer;"

[String] $dir = "$PSScriptRoot/..";
Write-Output "Running Script Analyzer recursively below `"$dir`"";
# For future use: -ExcludeRule PSAvoidUsingConvertToSecureStringWithPlainText, PSAvoidUsingUsernameAndPasswordParams, PSAvoidUsingPlainTextForPassword, PSAvoidUsingEmptyCatchBlock, PSAvoidUsingWriteHost, PSAvoidGlobalVars, PSUseDeclaredVarsMoreThanAssignments, PSAvoidUsingPositionalParameters
Invoke-ScriptAnalyzer -Path $dir -Recurse -Outvariable issues -ReportSummary;

Read-Host "Press enter to exit";
