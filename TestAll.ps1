#!/usr/bin/env pwsh

Write-Output "Test all - run all examples, the script analyser and the unit tests with pwsh (powershell)";

Write-Output "Show CurrentDir = `"$PWD`""; # "D:\a\MyRepo\MyRepo"

Write-Output "Show GITHUB_WORKSPACE = `"$($env:GITHUB_WORKSPACE)`""; # "D:\a\MyRepo\MyRepo" or empty

Write-Output "Show PSModulePath = `"`""; # "C:\Users\runneradmin\Documents\PowerShell\Modules;C:\Program Files\PowerShell\Modules;c:\program files\powershell\7\Modules;C:\\Modules\azurerm_2.1.0;C:\\Modules\azure_2.1.0;C:\Users\packer\Documents\WindowsPowerShell\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules;C:\Program Files\Microsoft SQL Server\130\Tools\PowerShell\Modules\;C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\platform\PowerShell"
$env:PSModulePath -split ";" | Where-Object{ $null -ne $_ } | ForEach-Object{ Write-Output "Show PSModulePath += `";$_`""; }

Write-Output "Set mode to stop on errors.";
$Global:ErrorActionPreference = "Stop"; trap [Exception] { $Host.UI.WriteErrorLine("Trap: $_"); Read-Host; break; }

Write-Output "Set disable autoloading modules.";
$PSModuleAutoLoadingPreference = "none";

Write-Output "Set extend PSModulePath by current dir.";
[Environment]::SetEnvironmentVariable("PSModulePath","${env:PSModulePath};$PWD","Process"); # add ps module to path

Write-Output "Load library";
Import-Module "MnCommonPsToolLib.psm1";
Write-Output "Show MnCommonPsToolLibVersion: $Global:MnCommonPsToolLibVersion"; # "6.01"

Write-Output "Remove all aliases except (cd,cat,clear,echo,dir,cp,mv,popd,pushd,rm,rmdir);";
ProcessRemoveAllAlias @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir");

Write-Output "Show OsPsVersion: $(OsPsVersion)"; # "7.2"

Write-Output "";
Write-Output "Running all examples and unit tests, input requests are aborted";
Write-Output "--------------------------------------------------------------------------------------";
& "Examples/ExampleUseOfMnCommonPsToolLib01_HelloWorldWaitForEnter.ps1"; # waiting is aborted
Write-Output "--------------------------------------------------------------------------------------";
& "Examples/ExampleUseOfMnCommonPsToolLib02_StdBegAndEndInteractiveModeStmts.ps1"; # waiting is aborted
Write-Output "--------------------------------------------------------------------------------------";
& "Examples/ExampleUseOfMnCommonPsToolLib03_NoWaitAtEnd.ps1";
Write-Output "--------------------------------------------------------------------------------------";
& "Examples/ExampleUseOfMnCommonPsToolLib04_SomeReadOnlyProcessings.ps1";
Write-Output "--------------------------------------------------------------------------------------";
& "UnitTests/AllUnitTests.ps1";
Write-Output "--------------------------------------------------------------------------------------";
Write-Output "Ok, UnitTest was successful!";

StdInAskForEnter;
