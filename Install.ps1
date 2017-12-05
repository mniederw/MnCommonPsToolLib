
# Do not change the following line, it is a powershell statement and not a comment!
#Requires -Version 3.0
param( [String] $sel )
Set-StrictMode -Version Latest; # Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).
$Global:ErrorActionPreference = "Stop";
$PSModuleAutoLoadingPreference = "none"; # disable autoloading modules
trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; }
[String] $envVar = "PSModulePath";
function OutInfo                              ( [String] $line ){ Write-Host -ForegroundColor White               $line; }
function OutProgress                          ( [String] $line ){ Write-Host -ForegroundColor DarkGray            $line; }
function OutProgressText                      ( [String] $line ){ Write-Host -ForegroundColor DarkGray -NoNewLine $line; }
function OutQuestion                          ( [String] $line ){ Write-Host -ForegroundColor Cyan     -NoNewline $line; }
function FsEntryMakeTrailingBackslash         ( [String] $fsEntry ){ [String] $result = $fsEntry; if( -not $result.EndsWith("\") ){ $result += "\"; } return [String] $result; }
function FsEntryGetAbsolutePath               ( [String] $fsEntry ){ return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
function PsModulePathList                     (){ return [String[]] ([Environment]::GetEnvironmentVariable($envVar, "Machine").Split(";",[System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object{ FsEntryMakeTrailingBackslash $_; }); }
function PsModulePathContains                 ( [String] $d ){ return [Boolean] ((PsModulePathList) -contains (FsEntryMakeTrailingBackslash $d)); }
function PsModulePathAdd                      ( [String] $d ){ PsModulePathSet ((PsModulePathList)+@( (FsEntryMakeTrailingBackslash $d) )); }
function PsModulePathDel                      ( [String] $d ){ PsModulePathSet ((PsModulePathList) | Where-Object{ $_ -ne (FsEntryMakeTrailingBackslash $d) }); }
function PsModulePathSet                      ( [String[]] $a ){ [Environment]::SetEnvironmentVariable($envVar, ($a -join ";"), "Machine"); }
function DirExists                            ( [String] $dir ){ try{ return [Boolean] (Test-Path -PathType Container -LiteralPath $dir ); }catch{ throw [Exception] "DirExists($dir) failed because $($_.Exception.Message)"; } }
function DirListDirs                          ( [String] $d ){ return [String[]] (@()+(Get-ChildItem -Force -Directory -Path $d | ForEach-Object{ $_.FullName })); }
function DirHasFiles                          ( [String] $d, [String] $filePattern ){ return [Boolean] ((Get-ChildItem -Force -Recurse -File -ErrorAction SilentlyContinue -Path "$d\$filePattern") -ne $null); }
function ScriptGetTopCaller                   (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; } if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); } if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); } return [String] $f; } # return empty if called interactive.
function ProcessIsRunningInElevatedAdminMode  (){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
function ProcessRestartInElevatedAdminMode    (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){ [String[]] $cmd = @( (ScriptGetTopCaller) ) + $sel; OutProgress "Not running in elevated administrator mode so elevate current script and exit: `n  $cmd"; Start-Process -Verb "RunAs" -FilePath "powershell.exe" -ArgumentList "& `"$cmd`" "; [Environment]::Exit("0"); throw [Exception] "Exit done, but it did not work, so it throws now an exception."; } }
function UninstallDir                         ( [String] $d ){ OutProgress "RemoveDir '$d'. "; if( DirExists $d ){ ProcessRestartInElevatedAdminMode; Remove-Item -Force -Recurse -LiteralPath $d; } }
function UninstallSrcPath                     ( [String] $d ){ OutProgress "UninstallSrcPath '$d'. "; if( (PsModulePathContains $d) ){ ProcessRestartInElevatedAdminMode; PsModulePathDel $d; } }
function InstallDir                           ( [String] $srcDir, [String] $tarParDir ){ OutProgress "Copy '$srcDir' `n  to '$tarParDir'. "; ProcessRestartInElevatedAdminMode; Copy-Item -Force -Recurse -LiteralPath $srcDir -Destination $tarParDir; }
function InstallSrcPathToPsModulePathIfNotInst( [String] $srcDir ){ OutProgress "Change environment system variable $envVar by appending '$srcDir'. "; 
                                                if( (PsModulePathContains $srcDir) ){ OutProgress "Already installed so environment variable not changed."; }else{ ProcessRestartInElevatedAdminMode; PsModulePathAdd $srcDir; } }
function OutCurrentInstallState               ( [String] $srcRootDir, [String] $moduleTarDir, [String] $color = "White" ){ [Boolean] $srcRootDirIsInPath = PsModulePathContains $srcRootDir; [Boolean] $moduleTarDirExists = DirExists $moduleTarDir; 
                                                [String] $installedText = switch($srcRootDirIsInPath){ $true{"Installed-for-Developers. "} default{switch($moduleTarDirExists){ $true{"Installed-in-Standard-Mode. "} default{"Not-Installed. "}}}}; 
                                                OutProgressText "Current installation state: "; Write-Host -ForegroundColor $color $installedText; }


[String] $tarRootDir = "$Env:ProgramW6432\WindowsPowerShell\Modules"; # more see: https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx
[String] $srcRootDir = $PSScriptRoot; if( $srcRootDir -eq "" ){ $srcRootDir = FsEntryGetAbsolutePath "."; } # ex: "D:\WorkGit\myaccount\MyNameOfPsToolLib_master"
[String[]] $dirsWithPsm1Files = @()+(DirListDirs $srcRootDir | Where-Object{ DirHasFiles $_ "*.psm1" });
if( $dirsWithPsm1Files.Count -ne 1 ){ throw [Exception] "Tool is designed for working below '$srcRootDir' with exactly one directory which contains psm1 files but found $($dirsWithPsm1Files.Count) dirs ($dirsWithPsm1Files)"; }
[String] $moduleSrcDir = $dirsWithPsm1Files[0]; # ex: "D:\WorkGit\myaccount\MyNameOfPsToolLib_master\MyNameOfPsToolLib"
[String] $moduleName = [System.IO.Path]::GetFileName($moduleSrcDir); # ex: "MyNameOfPsToolLib"
[String] $moduleTarDir = "$tarRootDir\$moduleName";
[Boolean] $isDev = DirExists "$srcRootDir\.git";
OutInfo         "Install Menu for Powershell Module - $moduleName";
OutInfo         "-------------------------------------------------------------------------------`n";
OutProgress     "  For installation or uninstallation the elevated administrator mode is ";
OutProgress     "  required and this tool automatically prompts for it when nessessary. ";
OutProgress     "  Powershell requires for any installation of a module that its file must be ";
OutProgress     "  located in a folder with the same name as the module name. ";
OutProgress     "  An installation in standard mode does first an uninstallation and then for ";
OutProgress     "  installation it copies the ps module folder to the common ps module folder ";
OutProgress     "  for all users. An alternative installation for developers does also first an ";
OutProgress     "  uninstallation and then it adds the path of the module folder as entry to the ";
OutProgress     "  ps module path environment variable ($envVar). ";
OutProgress     "  An uninstallation does both, it removes the copied folder from the common ps ";
OutProgress     "  module folder for all users and it removes the path entry from the ps module ";
OutProgress     "  path environment variable. ";
OutProgress     "  (*) Before using these commands after switching install mode you probably ";
OutProgress     "  need to restart your calling shell or program as example a file manager. ";
OutProgress     "  By using this software you agree with the terms of GPL3. ";
OutProgress     "  ";
OutProgress     "  Current environment:";
OutProgress     "    IsInElevatedAdminMode = $(ProcessIsRunningInElevatedAdminMode).";
OutProgress     "    SrcRootDir = '$srcRootDir' ";
OutProgress     "    CommonPsModuleFolderForAllUsers = '$tarRootDir' ";
OutProgressText "    "; OutCurrentInstallState $srcRootDir $moduleTarDir;
OutInfo         "";
OutInfo         "  I = Install or reinstall in standard mode. ";
OutInfo         "  A = Alternative installation for developers to change and test the module. ";
OutInfo         "  N = Uninstall. ";
OutInfo         "  U = When installed (*) in standard mode do update from web. ";
if( $isDev ){ OutInfo "  H = For developer and when installed (*): actualize sha2 hash file of library. "; }
OutInfo         "  Q = Quit. `n";
if( $sel -ne "" ){ OutProgress "Selection: $sel "; }
while( @("I","A","N","U","Q","H") -notcontains $sel ){
  OutQuestion "Enter selection case insensitive and press enter: ";
  $sel = (Read-Host);
}
$Global:ArgsForRestartInElevatedAdminMode = $sel; 
if( $sel -eq "N"             ){ UninstallDir $moduleTarDir; UninstallSrcPath $srcRootDir;                                       OutCurrentInstallState $srcRootDir $moduleTarDir "Green"; }
if( $sel -eq "I"             ){ UninstallDir $moduleTarDir; UninstallSrcPath $srcRootDir; InstallDir $moduleSrcDir $tarRootDir; OutCurrentInstallState $srcRootDir $moduleTarDir "Green"; }
if( $sel -eq "A"             ){ UninstallDir $moduleTarDir; InstallSrcPathToPsModulePathIfNotInst $srcRootDir;                  OutCurrentInstallState $srcRootDir $moduleTarDir "Green"; }
if( $sel -eq "U"             ){ $PSModuleAutoLoadingPreference = "All"; MnCommonPsToolLib\MnCommonPsToolLibSelfUpdate; }
if( $sel -eq "H" -and $isDev ){ $PSModuleAutoLoadingPreference = "All"; MnCommonPsToolLib\FileUpdateItsHashSha2FileIfNessessary "$moduleSrcDir\$moduleName.psm1"; }
if( $sel -eq "Q"             ){ OutProgress "Quit."; }
OutQuestion "Finished. Press enter to exit. "; Read-Host;
