
# Do not change the following line, it is a powershell statement and not a comment!
#Requires -Version 3.0

param( [String] $sel )
Set-StrictMode -Version Latest; # Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).
trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; }
$Global:ErrorActionPreference = "Stop";
[String] $envVar = "PSModulePath";
function FsEntryMakeTrailingBackslash               ( [String] $fsEntry ){ [String] $result = $fsEntry; if( -not $result.EndsWith("\") ){ $result += "\"; } return [String] $result; }
function FsEntryGetAbsolutePath                     ( [String] $fsEntry ){ return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
function PsModulePathList                           (){ return [String[]] ([Environment]::GetEnvironmentVariable($envVar, "Machine").Split(";",[System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object{ FsEntryMakeTrailingBackslash $_; }); }
function PsModulePathContains                       ( [String] $d ){ return [Boolean] ((PsModulePathList) -contains (FsEntryMakeTrailingBackslash $d)); }
function PsModulePathAdd                            ( [String] $d ){ PsModulePathSet ((PsModulePathList)+@( (FsEntryMakeTrailingBackslash $d) )); }
function PsModulePathDel                            ( [String] $d ){ PsModulePathSet ((PsModulePathList) | Where-Object{ $_ -ne (FsEntryMakeTrailingBackslash $d) }); }
function PsModulePathSet                            ( [String[]] $a ){ [Environment]::SetEnvironmentVariable($envVar, ($a -join ";"), "Machine"); }
function DirExists                                  ( [String] $dir ){ try{ return [Boolean] (Test-Path -PathType Container -LiteralPath $dir ); }catch{ throw [Exception] "DirExists($dir) failed because $($_.Exception.Message)"; } }
function DirListDirs                                ( [String] $d ){ return [String[]] (@()+(Get-ChildItem -Force -Directory -Path $d | ForEach-Object{ $_.FullName })); }
function DirHasFiles                                ( [String] $d, [String] $filePattern ){ return [Boolean] ((Get-ChildItem -Force -Recurse -File -ErrorAction SilentlyContinue -Path "$d\$filePattern") -ne $null); }
function ScriptGetTopCaller                         (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; } if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); } if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); } return [String] $f; } # return empty if called interactive.
function ProcessIsRunningInElevatedAdminMode        (){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
function ProcessRestartInElevatedAdminMode          (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){ [String[]] $cmd = @( (ScriptGetTopCaller) ) + $sel; Write-Host -ForegroundColor DarkGray "Not running in elevated administrator mode so elevate current script and exit: `n  $cmd"; Start-Process -Verb "RunAs" -FilePath "powershell.exe" -ArgumentList "& `"$cmd`" "; [Environment]::Exit("0"); throw [Exception] "Exit done, but it did not work, so it throws now an exception."; } }
function UninstallDir                               ( [String] $d ){ Write-Host -ForegroundColor DarkGray "RemoveDir '$d'. "; if( DirExists $d ){ ProcessRestartInElevatedAdminMode; Remove-Item -Force -Recurse -LiteralPath $d; } }
function UninstallSrcPath                           ( [String] $d ){ Write-Host -ForegroundColor DarkGray "UninstallSrcPath '$d'. "; if( (PsModulePathContains $d) ){ ProcessRestartInElevatedAdminMode; PsModulePathDel $d; } }
function InstallDir                                 ( [String] $srcDir, [String] $tarParDir ){ Write-Host -ForegroundColor DarkGray "Copy '$srcDir' `n  to '$tarParDir'. "; ProcessRestartInElevatedAdminMode; Copy-Item -Force -Recurse -LiteralPath $srcDir -Destination $tarParDir; }
function InstallSrcPathToPsModulePathIfNotInstalled ( [String] $srcDir ){ Write-Host -ForegroundColor DarkGray "Change environment system variable $envVar by appending '$srcDir'. "; if( (PsModulePathContains $srcDir) ){ Write-Host -ForegroundColor DarkGray "Already installed so environment variable not changed."; }else{ ProcessRestartInElevatedAdminMode; PsModulePathAdd $srcDir; } }
function OutCurrentInstallState                     ( [String] $srcRootDir, [String] $moduleTarDir, [String] $color = "White" ){ [Boolean] $srcRootDirIsInPath = PsModulePathContains $srcRootDir; [Boolean] $moduleTarDirExists = DirExists $moduleTarDir; [String] $installedText = switch($srcRootDirIsInPath){ $true{"Installed-for-Developers. "} default{switch($moduleTarDirExists){ $true{"Installed-in-Standard-Mode. "} default{"Not-Installed. "}}}}; Write-Host -ForegroundColor White -NoNewLine "Current installation state: "; Write-Host -ForegroundColor $color $installedText; }

[String] $tarRootDir = "$Env:ProgramW6432\WindowsPowerShell\Modules"; # more see: https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx
[String] $srcRootDir = $PSScriptRoot; if( $srcRootDir -eq "" ){ $srcRootDir = FsEntryGetAbsolutePath "."; } # ex: "D:\WorkGit\mniederw\MnCommonPsToolLib_master"
[String[]] $dirsWithPsm1Files = @()+(DirListDirs $srcRootDir | Where-Object{ DirHasFiles $_ "*.psm1" });
if( $dirsWithPsm1Files.Count -ne 1 ){ throw [Exception] "Tool is designed for working below '$srcRootDir' with exactly one directory which contains psm1 files but found $($dirsWithPsm1Files.Count) dirs ($dirsWithPsm1Files)"; }
[String] $moduleSrcDir = $dirsWithPsm1Files[0]; # ex: "D:\WorkGit\mniederw\MnCommonPsToolLib_master\MnCommonPsToolLib"
[String] $moduleName = [System.IO.Path]::GetFileName($moduleSrcDir); # ex: "MnCommonPsToolLib"
[String] $moduleTarDir = "$tarRootDir\$moduleName";
Write-Host -ForegroundColor White    "Install Menu for Powershell Module - $moduleName";
Write-Host -ForegroundColor White    "-------------------------------------------------------------------------------`n";
Write-Host -ForegroundColor DarkGray "  For installation or uninstallation the elevated administrator mode is ";
Write-Host -ForegroundColor DarkGray "  required and this tool automatically prompts for it. ";
Write-Host -ForegroundColor DarkGray "  Powershell requires for any installation of a module that its file must be ";
Write-Host -ForegroundColor DarkGray "  located in a folder with the same name as the module name. ";
Write-Host -ForegroundColor DarkGray "  An installation in standard mode does first an uninstallation and then for ";
Write-Host -ForegroundColor DarkGray "  installation it copies the ps module folder to the common ps module folder ";
Write-Host -ForegroundColor DarkGray "  for all users. An alternative installation for developers does also first an ";
Write-Host -ForegroundColor DarkGray "  uninstallation and then it adds the path of the module folder as entry to the ";
Write-Host -ForegroundColor DarkGray "  ps module path environment variable ($envVar). ";
Write-Host -ForegroundColor DarkGray "  An uninstallation does both, it removes the copied folder from the common ps ";
Write-Host -ForegroundColor DarkGray "  module folder for all users and it removes the path entry from the ps module ";
Write-Host -ForegroundColor DarkGray "  path environment variable. ";
Write-Host -ForegroundColor DarkGray "  ";
Write-Host -ForegroundColor DarkGray "  Current environment:";
Write-Host -ForegroundColor DarkGray "  IsInElevatedAdminMode = $(ProcessIsRunningInElevatedAdminMode).";
Write-Host -ForegroundColor DarkGray "  SrcRootDir = '$srcRootDir' ";
Write-Host -ForegroundColor DarkGray "  CommonPsModuleFolderForAllUsers = '$tarRootDir' ";
Write-Host -ForegroundColor DarkGray "  ";
OutCurrentInstallState $srcRootDir $moduleTarDir;
Write-Host -ForegroundColor White    "";
Write-Host -ForegroundColor White    "  I = Install or reinstall in standard mode. ";
Write-Host -ForegroundColor White    "  A = Alternative installation for developers to change and test the module. ";
Write-Host -ForegroundColor White    "  U = Uninstall. ";
Write-Host -ForegroundColor White    "  W = When in standard mode do update from web - perform MnCommonPsToolLibSelfUpdate ";
Write-Host -ForegroundColor White    "  Q = Quit. `n";
if( $sel -ne "" ){ Write-Host "Selection: $sel "; }
while( @("I","A","U","W","Q") -notcontains $sel ){
  Write-Host -ForegroundColor Cyan -nonewline "Enter selection and press enter (case insensitive: I,A,U,Q): ";
  [String] $sel = (Read-Host);
}
if( $sel -eq "U" ){ UninstallDir $moduleTarDir; UninstallSrcPath $srcRootDir; }
if( $sel -eq "I" ){ UninstallDir $moduleTarDir; UninstallSrcPath $srcRootDir; InstallDir $moduleSrcDir $tarRootDir; }
if( $sel -eq "A" ){ UninstallDir $moduleTarDir; InstallSrcPathToPsModulePathIfNotInstalled $srcRootDir; }
if( $sel -eq "W" ){ MnCommonPsToolLibSelfUpdateNoWait; }
if( $sel -eq "Q" ){ Write-Host -ForegroundColor DarkGray "Quit."; }
if( $sel -eq "U" -or $sel -eq "I" -or $sel -eq "A" ){ OutCurrentInstallState $srcRootDir $moduleTarDir "Green"; }
Write-Host -ForegroundColor Cyan "Ok, finished. Press enter to exit. ";
Read-Host;
