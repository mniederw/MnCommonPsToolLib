#!/usr/bin/env pwsh

Set-StrictMode -Version Latest;
trap [Exception] { $Host.UI.WriteErrorLine("Trap: $_"); Read-Host; break; }
$ErrorActionPreference = "Stop";

Write-Output "Test all - run all examples, the script analyser and the unit tests with pwsh (powershell)";
Write-Output "  It is compatible for PS5/PS7, elevated, win/linux/macos!";

Write-Output "Show Environment: ";
[Boolean] $is_windows = (-not (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue) -or $IsWindows);
[Boolean] $is_linux   = (-not $is_windows -and $IsLinux);
[Boolean] $is_maxos   = (-not $is_windows -and $IsMacOS);
Write-Output "Show Platform          = $([System.Environment]::OSVersion.Platform)"; # "Win32NT" or "Unix"
Write-Output "Show OS                = $([System.Environment]::OSVersion.VersionString)"; # "Microsoft Windows NT 10.0.19045.0" or "Unix 5.15.0.76"
Write-Output "Show OS (empty on PS5) = $(($PSVersionTable | Select-Object OS).OS)"; # "Microsoft Windows 10.0.19042" or "Linux 5.15.0-76-generic #83~20.04.1-Ubuntu SMP Wed Jun 21 20:23:31 UTC 2023"
Write-Output "Show IsWindows         = $is_windows";
Write-Output "Show IsLinux           = $is_linux";
Write-Output "Show IsMacOS           = $is_maxos";
Write-Output "Show CurrentDir        = `"$PWD`"";
  # Local-Win10   : "D:\mywork\MyOwner\MyRepo"
  # Github-Windows: "D:\a\MyRepo\MyRepo"
  # Github-ubuntu : "/home/runner/work/MnCommonPsToolLib/MnCommonPsToolLib"
Write-Output "GetTempPath: $([System.IO.Path]::GetTempPath())"; # Example: "/tmp/", "C:\Users\myuser\AppData\Local\Temp"
Write-Output "Env-Tmpdir : $($env:TMPDIR)"; # Example: ""
Write-Output "Show GITHUB_WORKSPACE  = `"$($env:GITHUB_WORKSPACE)`"";
  # Local-Win10   : ""
  # Github-Win10  : "D:\a\MyRepo\MyRepo"
  # Github-ubuntu : "/home/runner/work/MnCommonPsToolLib/MnCommonPsToolLib"

Write-Output "Show PSModulePath      = `"`"";
$($env:PSModulePath).Split(";:") | Where-Object{ $null -ne $_ } | ForEach-Object{
  Write-Output "Show PSModulePath      += `";$_`""; }
  # Local-Win10   : ";C:\Users\myuser\Documents\WindowsPowerShell\Modules"
  #                 ";C:\Program Files (x86)\WindowsPowerShell\Modules"
  #                 ";C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
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
  #                 ";C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
  #                 ";C:\Program Files\Microsoft SQL Server\130\Tools\PowerShell\Modules\"
  #                 ";C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\platform\PowerShell"
  # Local-Ubuntu  : ":/home/nn/.local/share/powershell/Modules"
  #                 ":/usr/local/share/powershell/Modules"
  #                 ":/opt/microsoft/powershell/7/Modules"
  # Github-ubuntu : ":/home/runner/.local/share/powershell/Modules"
  #                 ":/usr/local/share/powershell/Modules"
  #                 ":/opt/microsoft/powershell/7/Modules"

# disabled because it would not find for example Write-Output anymore:
#   Write-Output "Set disable autoloading modules."; $PSModuleAutoLoadingPreference = "none";

Write-Output "Install from PSGallery some modules as PSScriptAnalyzer, SqlServer and ThreadJob";
Set-PSRepository PSGallery -InstallationPolicy Trusted; # uses 7 sec
Install-Module -ErrorAction Stop PSScriptAnalyzer, SqlServer, ThreadJob;

Push-Location $PSScriptRoot;

  Write-Output "Assert powershell module library MnCommonPsToolLib.psm1 exists near this running script.";
  Test-Path -Path "MnCommonPsToolLib/MnCommonPsToolLib.psm1" | Should -Be $true;

  Write-Output "Extend PSModulePath by current dir.";
  [String] $pathsep = ":"; if( $is_windows ){ $pathsep = ";"; }
  [Environment]::SetEnvironmentVariable("PSModulePath","${env:PSModulePath}$pathsep$PWD","Process"); # add ps module to path

  Write-Output "Load our library";
  Import-Module "MnCommonPsToolLib.psm1";
  Write-Output "Show MnCommonPsToolLibVersion: $Global:MnCommonPsToolLibVersion"; # Example: "7.01"

  Write-Output "Remove all aliases except (cd,cat,clear,echo,dir,cp,mv,popd,pushd,rm,rmdir);";
  ProcessRemoveAllAlias @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir");

  Write-Output "Show OsPsVersion: $(OsPsVersion)"; # "7.3"

  Write-Output "";
  Write-Output "Running all examples and unit tests, input requests are aborted when called non-interactive by github action.";
  Write-Output "If it is running elevated then it performs additionally tests. ";

  Write-Output ("-"*86); & "Examples/ExampleUseOfMnCommonPsToolLib01_HelloWorldWaitForEnter.ps1"; # waiting is aborted
  Write-Output ("-"*86); & "Examples/ExampleUseOfMnCommonPsToolLib02_StdBegAndEndInteractiveModeStmts.ps1"; # waiting is aborted
  Write-Output ("-"*86); & "Examples/ExampleUseOfMnCommonPsToolLib03_NoWaitAtEnd.ps1";
  Write-Output ("-"*86); & "Examples/ExampleUseOfMnCommonPsToolLib04_SomeReadOnlyProcessings.ps1";
  Write-Output ("-"*86); & "UnitTests/AllUnitTests.ps1";
  Write-Output ("-"*86);

  Write-Output "Ok, UnitTest was successful!";

Pop-Location;

StdInAskForEnter;
