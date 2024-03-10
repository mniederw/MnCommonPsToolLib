﻿#!/usr/bin/env pwsh

Param( [Boolean] $showAlsoIgnored = $false )

Set-StrictMode -Version Latest; trap [Exception] { Write-Error $_; Read-Host "Press Enter to Exit"; break; } $ErrorActionPreference = "Stop";

function UnitTest_ScriptAnalyser(){
  OutProgress "Test Script Analyzer recursively on all repository files";
  [String] $dir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$PSScriptRoot/../");
  [String[]] $excl = @(
     "PSAvoidGlobalVars"                              # For some values we require global variables
    ,"PSAvoidUsingPositionalParameters"               # Of course we use positional parameters and do not want to use only named parameters
    ,"PSAvoidUsingConvertToSecureStringWithPlainText" # We need it for our own credential storage; File 'MnCommonPsToolLib.psm1' uses ConvertTo-SecureString with plaintext. This will expose secure information. Encrypted standard strings should be used instead. in line 1578 col 88
    ,"PSAvoidUsingUsernameAndPasswordParams"          # We need it for our own credential storage; Function 'CredentialCreate'/'CredentialGetAndStoreIfNotExists' has both Username and Password parameters. Either set the type of the Password parameter to SecureString or replace the Username and Password parameters with a Credential parameter of type PSCredential. If using a Credential parameter in PowerShell 4.0 or earlier, please define a credential transformation attribute after the PSCredential type attribute. in line 1612 col 81
   #,"PSAvoidUsingPlainTextForPassword"               # We need it for our own credential storage
   #,"PSAvoidUsingWriteHost"                          # Otherwise Write-Output is not printed when caller redirects it and for using writes without line feeds
   #,"PSPossibleIncorrectComparisonWithNull"          # We need it for showing this bad feature
   #,"PSUseDeclaredVarsMoreThanAssignments"           # We have a lot of dummy variables
  );
  [String[]] $ignoreKnown = @(
    "Install.ps1 *WARN PSAvoidUsingWriteHost"
    ,"MnCommonPsToolLib.psm1 *WARN PSUseProcessBlockForPipelineCommand" # Command accepts pipeline input but has not defined a process block. in line 155 col 106
    ,"MnCommonPsToolLib.psm1 *WARN PSAvoidUsingWriteHost"
    ,"MnCommonPsToolLib.psm1 *WARN PSAvoidUsingPlainTextForPassword" # Parameter '$repoDirForCred' should not use String type but either SecureString or PSCredential, otherwise it increases the chance to to expose this sensitive information. in line 2429 col 129
    ,"MnCommonPsToolLib_Windows.ps1 *WARN PSAvoidUsingPlainTextForPassword" # Parameter '$secureCredentialFile' should not use String type but either SecureString or PSCredential, otherwise it increases the chance to to expose this sensitive information. in line 720 col 49
    ,"MnCommonPsToolLibUnitTest_PsCommonWithLintWarnings.ps1 *WARN PSPossibleIncorrectComparisonWithNull" # $null should be on the left side of equality comparisons. in line 11 col 48
  );
  #
  Write-Output "Running Powershell Script Analyzer recursively below `"$dir`" showAlsoIgnored=$showAlsoIgnored ";
  Write-Output "  which checks all ps scripts and lists suggestions for improvements. ";
  if( $showAlsoIgnored ){ $excl = @(); $ignoreKnown = @(); }
  $excl        | Where-Object{ $null -ne $_ } | ForEach-Object{ Write-Output "    ExcludeRule     = $_" }
  $ignoreKnown | Where-Object{ $null -ne $_ } | ForEach-Object{ Write-Output "    IgnoreKnownRule = $_" }
  Write-Output "  Note: If PSScriptAnalyzer is not yet installed then install it with admin rights as follow:";
  Write-Output "    Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module -ErrorAction Stop PSScriptAnalyzer;"
  #
  [Object[]] $issues = Invoke-ScriptAnalyzer -Path $dir -Recurse -ExcludeRule $excl;
  # -ReportSummary would produce red line on console, example: 97 rule violations found.    Severity distribution:  Error = 3, Warning = 57, Information = 37
  $nrOfErrors = $issues.Where({$_.Severity -eq 'Error'  }).Count;
  $nrOfWarningsOrInfo = 0;
  [Int32] $rulLen = ($issues | Where-Object{ $null -ne $_ } | ForEach-Object{ $_.RuleName.Length;   } | Measure-Object -Maximum).Maximum;
  [Int32] $scrLen = ($issues | Where-Object{ $null -ne $_ } | ForEach-Object{ $_.ScriptName.Length; } | Measure-Object -Maximum).Maximum;
  [String[]] $lines = $issues | Where-Object{ $null -ne $_ } | ForEach-Object{
    [String] $sev  = $(switch($_.Severity){"Warning"{"WARN"} "Error"{"ERR "} "ParseError"{"ERR "} "Information"{"INFO"} default{"Err$($_.Severity)"} });
    [String] $rul  = $_.RuleName.PadRight($rulLen); # Example: "PSAvoidUsingConvertToSecureStringWithPlainText"
    [String] $scr  = $_.ScriptName.PadRight($scrLen); # Example: "MnCommonPsToolLib.psm1"
    [String] $msgL = $_.Message + " in line " + $_.Line + " col " + $_.Column;
    # $_.IsSuppressed         : False
    # $_.Extent               : $global:MnCommonPsToolLibVersion
    # $_.ScriptPath           : D:\Workspace\SrcGit\mniederw\MnCommonPsToolLib#trunk\MnCommonPsToolLib\MnCommonPsToolLib.psm1
    # $_.RuleSuppressionID    : global:MnCommonPsToolLibVersion
    # $_.SuggestedCorrections :
    "  $scr $sev $rul : $msgL";
   } | Where-Object{
     for( [Int32] $i = 0; $i -lt $ignoreKnown.Length; $i++ ){ if( $_ -like ("  "+$ignoreKnown[$i]+" *: *") ){ return $false; } } return $true;
   } | Sort-Object;
  $lines | Where-Object{ $null -ne $_ } | ForEach-Object{ Write-Output $_; };
  [String] $msg = "ScriptAnalyser found total $nrOfErrors errors and $nrOfWarningsOrInfo warnings-or-infonotes.";
  if( $nrOfErrors -ne 0 ){ throw [Exception] $msg; }
  Write-Output "Ok, done. $msg";
}
UnitTest_ScriptAnalyser;
