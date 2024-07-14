#!/usr/bin/env pwsh

Set-StrictMode -Version Latest; trap [Exception] { Write-Error $_; Read-Host "Press Enter to Exit"; break; } $ErrorActionPreference = "Stop";

[Boolean] $is_windows = (-not (Get-Variable -Name "IsWindows" -ErrorAction SilentlyContinue) -or $IsWindows); # portable PS5/PS7
[Boolean] $is_linux   = (-not $is_windows -and $IsLinux);
[Boolean] $is_maxos   = (-not $is_windows -and $IsMacOS);
[String]  $pathSep    = $(switch($is_windows){$true{";"}default{":"}});

Write-Output "Test all - run all examples, the script analyser and the unit tests with pwsh (powershell)";
Write-Output "  It is compatible for PS5/PS7, elevated, platforms Windows/Linux/MacOS!";
Write-Output "Show Environment: ";
Write-Output "Show Platform          = $([System.Environment]::OSVersion.Platform     )"; # Example: "Win32NT" or "Unix"
Write-Output "Show OS                = $([System.Environment]::OSVersion.VersionString)"; # Example: "Microsoft Windows NT 10.0.19045.0" or "Unix 5.15.0.76"
Write-Output "Show OS (empty on PS5) = $(($PSVersionTable | Select-Object OS).OS      )"; # Example: "Microsoft Windows 10.0.19042" or "Linux 5.15.0-76-generic #83~20.04.1-Ubuntu SMP Wed Jun 21 20:23:31 UTC 2023"
Write-Output "Show IsWindows         = $is_windows";                                      # Example: "False"
Write-Output "Show IsLinux           = $is_linux";                                        # Example: "True"
Write-Output "Show IsMacOS           = $is_maxos";                                        # Example: "False"
Write-Output "Show GetTempPath()     = $([System.IO.Path]::GetTempPath())";               # Example: "/tmp/", "C:\Users\myuser\AppData\Local\Temp"
Write-Output "Show Env:TmpDir        = $($env:TMPDIR)";                                   # Example: ""
Write-Output "Show CurrentDir        = `"$PWD`"";                                         # Example: Local-Win10   : "D:\mywork\MyOwner\MyRepo"
                                                                                          # Example: Github-Windows: "D:\a\MyRepo\MyRepo"
                                                                                          # Example: Github-ubuntu : "/home/runner/work/MnCommonPsToolLib/MnCommonPsToolLib"
Write-Output "Show GITHUB_WORKSPACE  = `"$($env:GITHUB_WORKSPACE)`"";                     # Example: Local-Win10   : ""
                                                                                          # Example: Github-Windows: "D:\a\MyRepo\MyRepo"
                                                                                          # Example: Github-ubuntu : "/home/runner/work/MnCommonPsToolLib/MnCommonPsToolLib"
Write-Output "Show PSModulePath      = `"`"";
$($env:PSModulePath).Split($pathSep) | Where-Object{ $null -ne $_ } | ForEach-Object{
  Write-Output "Show PSModulePath      += `"$pathSep$_`""; }
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
Write-Output "----- List all environment variables: ----- ";
  Get-Variable | Sort-Object Name | Select-Object Name, Value | Format-Table -AutoSize -Wrap -Property Name, @{Name="Value";Expression={$_.Value};Alignment="Left"};
Write-Output "----- List all aliases: ----- ";
  Get-Alias    | Sort-Object Name | Select-Object CommandType, Name, Definition, Options, Module, Version | Format-Table -AutoSize;
Write-Output "----- List ps gallery repositories: ----- ";
  Get-PSRepository;
Write-Output "----- List installed ps modules ----- ";
  Get-Module -ListAvailable | Sort-Object ModuleType, Name, Version | Select-Object ModuleType, Name, Version, ExportedCommands | Format-Table -Wrap -Force -AutoSize;
Write-Output "----- List commands grouped by modules ----- ";
  Get-Command -Module * | Group Module;
Write-Output "----- List all currently used modules ----- ";
  Get-Module -All; # all currently used
Write-Output "----- end-of-list ----- ";
Write-Output "Set repository PSGallery to trusted: ";
  Set-PSRepository PSGallery -InstallationPolicy Trusted;
  Write-Output "Install and import from PSGallery used modules in user scope: ";
  Write-Output "  Microsoft.PowerShell.Archive, PSReadLine, PowerShellGet, PackageManagement, PSScriptAnalyzer, ThreadJob, SqlServer, Pester.";
  Install-Module Microsoft.PowerShell.Archive, PSReadLine, PowerShellGet, PackageManagement, PSScriptAnalyzer, ThreadJob, SqlServer, Pester;
  Import-Module Microsoft.PowerShell.Archive, PSReadLine, PowerShellGet, PackageManagement, PSScriptAnalyzer, ThreadJob, SqlServer, Pester;

# for future use: Get-Variable -Scope Local; Get-Variable -Scope Script; Get-Variable -Scope Global;
# for future use: Get-PSSnapin -Registered; Get-Command -Noun *; # list pssnapins

# disabled because it would not find for example Write-Output anymore:
#   Write-Output "Set disable autoloading modules."; $PSModuleAutoLoadingPreference = "none"; # disable autoloading modules

Write-Output "Assert powershell module library MnCommonPsToolLib.psm1 exists near this running script.";
Push-Location $PSScriptRoot; Pop-Location;
Test-Path -Path "$PSScriptRoot/MnCommonPsToolLib/MnCommonPsToolLib.psm1" | Should -Be $true;

Write-Output "Extend PSModulePath by PSScriptRoot";
[Environment]::SetEnvironmentVariable("PSModulePath","${env:PSModulePath}$pathSep$PSScriptRoot","Process"); # add ps module to path

Write-Output "Load our library: MnCommonPsToolLib.psm1";
Import-Module "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

OutProgress "Show MnCommonPsToolLibVersion: $((Get-Module -Name MnCommonPsToolLib -ListAvailable).Version)"; # Example: "7.60"
OutProgress "Show OsPsVersion             : $(OsPsVersion)";                   # Example: "7.4"
OutProgress "Show Powershell Version      : $($Host.Version.ToString())";      # Example: "7.4.1"

OutProgress "Remove all aliases except (cd,cat,clear,echo,dir,cp,mv,popd,pushd,rm,rmdir);";
ProcessRemoveAllAlias @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir");

[String[]] $ps1Files = @(
   "$PSScriptRoot/Examples/ExampleUseOfMnCommonPsToolLib01_HelloWorldWaitForEnter.ps1"
  ,"$PSScriptRoot/Examples/ExampleUseOfMnCommonPsToolLib02_StdBegAndEndInteractiveModeStmts.ps1"
  ,"$PSScriptRoot/Examples/ExampleUseOfMnCommonPsToolLib03_NoWaitAtEnd.ps1"
  ,"$PSScriptRoot/Examples/ExampleUseOfMnCommonPsToolLib04_SomeReadOnlyProcessings.ps1"
  ,"$PSScriptRoot/UnitTests/AllUnitTests.ps1"
);

OutProgressTitle "Running all examples and unit tests, input requests are aborted when called non-interactive by github action.";
OutProgress "If it is running elevated then it performs additional tests. ";
AssertRcIsOk;
for( [Int32] $i = 0; $i -lt $ps1Files.Count; $i++ ){

  OutProgressTitle ("----- "+(FsEntryGetFileName $ps1Files[$i])+" -----").PadRight(120,'-');
  & $ps1Files[$i];
  if( "$env:GITHUB_WORKSPACE" -ne "" ){ ScriptResetRc; } # On github input stream was closed
  AssertRcIsOk;

}
OutProgressTitle ("----- TestAll.ps1 ended -----").PadRight(120,'-');
OutProgressSuccess "Ok, done. All tests are successful. Exit after 2 seconds. ";
ProcessSleepSec 2;
