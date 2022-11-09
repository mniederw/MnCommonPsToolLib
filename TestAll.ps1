#!/usr/bin/env pwsh

Write-Output "Test all - run all examples, the script analyser and the unit tests with pwsh (powershell)";

Write-Output "Show Environment: ";
Write-Output "Show Platform         = $([System.Environment]::OSVersion.Platform)"; # "Win32NT" or "Unix"
Write-Output "Show OS               = $($PSVersionTable.OS)"; # "Microsoft Windows 10.0.19042" or ...
Write-Output "Show IsWindows        = $($IsWindows)";
Write-Output "Show IsLinux          = $($IsLinux)";
Write-Output "Show IsMacOS          = $($IsMacOS)";
Write-Output "Show CurrentDir       = `"$PWD`"";
Write-Output "GetTempPath: $([System.IO.Path]::GetTempPath())"; # ex: "/tmp/", "C:\Users\myuser\AppData\Local\Temp"
Write-Output "Env-Tmpdir : $($env:TMPDIR)"; # ex: ""

  # Local-Win10   : "D:\mywork\MyOwner\MyRepo"
  # Github-Windows: "D:\a\MyRepo\MyRepo"
  # Github-ubuntu : "/home/runner/work/MnCommonPsToolLib/MnCommonPsToolLib"

Write-Output "Show GITHUB_WORKSPACE = `"$($env:GITHUB_WORKSPACE)`"";
  # Local-Win10   : ""
  # Github-Win10  : "D:\a\MyRepo\MyRepo"
  # Github-ubuntu : "/home/runner/work/MnCommonPsToolLib/MnCommonPsToolLib"

Write-Output "Show PSModulePath     = `"`"";
$($env:PSModulePath).Split(";:") | Where-Object{ $null -ne $_ } | ForEach-Object{
  Write-Output "Show PSModulePath     += `";$_`""; }
  # Local-Win10   : ";C:\Users\myuser\Documents\WindowsPowerShell\Modules"
  #                 ";C:\Program Files (x86)\WindowsPowerShell\Modules"
  #                 ";C:\Windows\system32\WindowsPowerShell\v1.0\Modules"
  #                 ";C:\Program Files\WindowsPowerShell\Modules"
  #                 ";D:\MyWork\PortableProg\Tool\PowerShellModules"
  #                 ";D:\MyWork\SrcGit\mniederw\MnCommonPsToolLib"
  #                 ";C:\Program Files\VisualSvn VisualSvn Server\PowerShellModules"
  # Github-Win10  : ";C:\Users\runneradmin\Documents\PowerShell\Modules"
  #                 ";C:\Program Files\PowerShell\Modules"
  #                 ";c:\program files\powershell\7\Modules"
  #                 ";C:\\Modules\azurerm_2.1.0"
  #                 ";C:\\Modules\azure_2.1.0"
  #                 ";C:\Users\packer\Documents\WindowsPowerShell\Modules"
  #                 ";C:\Program Files\WindowsPowerShell\Modules"
  #                 ";C:\Windows\system32\WindowsPowerShell\v1.0\Modules"
  #                 ";C:\Program Files\Microsoft SQL Server\130\Tools\PowerShell\Modules\"
  #                 ";C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\platform\PowerShell"
  # Local-Ubuntu  : ":/home/nn/.local/share/powershell/Modules"
  #                 ":/usr/local/share/powershell/Modules"
  #                 ":/opt/microsoft/powershell/7/Modules"
# Github-ubuntu : ":/home/runner/.local/share/powershell/Modules"
  #                 ":/usr/local/share/powershell/Modules"
  #                 ":/opt/microsoft/powershell/7/Modules"

Write-Output "Set mode to stop on errors.";
$Global:ErrorActionPreference = "Stop";
trap [Exception] { $Host.UI.WriteErrorLine("Trap: $_"); Read-Host; break; }

# disabled because it would not find for example Write-Output anymore:
#   Write-Output "Set disable autoloading modules."; $PSModuleAutoLoadingPreference = "none";

Write-Output "Install from PSGallery some modules as PSScriptAnalyzer, SqlServer and ThreadJob";
Set-PSRepository PSGallery -InstallationPolicy Trusted; # uses 7 sec
Install-Module -ErrorAction Stop PSScriptAnalyzer, SqlServer, ThreadJob;

Write-Output "Assert powershell module library exists";
Test-Path "MnCommonPsToolLib/MnCommonPsToolLib.psm1" | Should -Be $true;

Write-Output "Extend PSModulePath by current dir.";
[String] $pathsep = ":"; if( $IsWindows ){ $pathsep = ";"; }
[Environment]::SetEnvironmentVariable("PSModulePath","${env:PSModulePath}$pathsep$PWD","Process"); # add ps module to path

Write-Output "Load our library";
Import-Module "MnCommonPsToolLib.psm1";
Write-Output "Show MnCommonPsToolLibVersion: $Global:MnCommonPsToolLibVersion"; # ex: "7.01"

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
