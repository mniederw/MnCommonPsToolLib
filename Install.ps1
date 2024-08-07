﻿#!/usr/bin/env pwsh

Param( [String] $sel ) # "Install"         : reinstall in standard mode and exit;
                       # "InstallInDevMode": reinstall in developer mode and exit.

Set-StrictMode -Version Latest; trap [Exception] { Write-Error $_; Read-Host "Press Enter to Exit"; break; } $ErrorActionPreference = "Stop";

$PSModuleAutoLoadingPreference = "none"; # disable autoloading modules
Import-Module Microsoft.PowerShell.Management; # load: Get-ChildItem
Import-Module Microsoft.PowerShell.Utility   ; # load: Write-Host,Write-Output
Import-Module Microsoft.PowerShell.Security  ; # load: Get-Executionpolicy
[String] $ps5WinModuleDir = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\";
[String] $ps5ModuleDir    = "$env:ProgramFiles\WindowsPowerShell\Modules\";

function OutProgress                          ( [String] $line, [Int32] $indentLevel = 1, [Boolean] $noNewLine = $false, [String] $color = "Gray" ){ Write-Host -ForegroundColor $color -noNewline:$noNewLine "$("  "*$indentLevel)$line"; }
function OutProgressTitle                     ( [String] $line ){ OutProgress $line -indentLevel:0 -color:White; }
function OutProgressText                      ( [String] $str, [String] $color = "Gray" ){ OutProgress $str -indentLevel:0 -noNewLine:$true -color:$color; }
function OutWarning                           ( [String] $line, [Int32] $indentLevel = 1 ){ OutProgressText "$("  "*$indentLevel)"; Write-Warning $line; }
function OutError                             ( [String] $line, [Int32] $indentLevel = 1 ){ $Host.UI.WriteErrorLine("$("  "*$indentLevel)$line"); }
function OutProgressQuestion                  ( [String] $str  ){ OutProgress $str -indentLevel:0 -noNewLine:$true -color:"Cyan"; }
function DirSep                               (){ return [Char] [IO.Path]::DirectorySeparatorChar; }
function FsEntryHasTrailingDirSep             ( [String] $fsEntry ){ return [Boolean] ($fsEntry.EndsWith("\") -or $fsEntry.EndsWith("/")); }
function FsEntryRemoveTrailingDirSep          ( [String] $fsEntry ){ [String] $r = $fsEntry;
                                                if( $r -ne "" ){ while( FsEntryHasTrailingDirSep $r ){ $r = $r.Remove($r.Length-1); } if( $r -eq "" ){ $r = $fsEntry; } } return [String] $r; }
function FsEntryMakeTrailingDirSep            ( [String] $fsEntry ){
                                                [String] $result = $fsEntry; if( -not (FsEntryHasTrailingDirSep $result) ){ $result += $(DirSep); } return [String] $result; }
function FsEntryGetAbsolutePath               ( [String] $fsEntry ){ return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
function OsIsWindows                          (){ return [Boolean] ([System.Environment]::OSVersion.Platform -eq "Win32NT"); }
function OsPathSeparator                      (){ return [String] $(switch(OsIsWindows){$true{";"}default{":"}}); } # separator for PATH environment variable
function OsPsModulePathList                   (){ return [String[]] ([Environment]::GetEnvironmentVariable("PSModulePath", "Machine").
                                                Split((OsPathSeparator),[System.StringSplitOptions]::RemoveEmptyEntries)); }
function OsPsModulePathContains               ( [String] $dir ){ # Example: "D:\WorkGit\myuser\MyPsLibRepoName"
                                                [String[]] $a = (OsPsModulePathList | ForEach-Object{ FsEntryRemoveTrailingDirSep $_ });
                                                return [Boolean] ($a -contains (FsEntryRemoveTrailingDirSep $dir)); }
function OsPsModulePathAdd                    ( [String] $dir ){ if( (OsPsModulePathContains $dir) ){ return; }
                                                OsPsModulePathSet ((OsPsModulePathList)+@( (FsEntryRemoveTrailingDirSep $dir) )); }
function OsPsModulePathDel                    ( [String] $dir ){ OsPsModulePathSet (OsPsModulePathList |
                                                Where-Object{ (FsEntryRemoveTrailingDirSep $_) -ne (FsEntryRemoveTrailingDirSep $dir) }); }
function OsPsModulePathSet                    ( [String[]] $pathList ){ [Environment]::SetEnvironmentVariable("PSModulePath", ($pathList -join (OsPathSeparator))+(OsPathSeparator), "Machine"); }
function DirExists                            ( [String] $dir ){ try{ return [Boolean] (Test-Path -PathType Container -LiteralPath $dir ); }
                                                catch{ throw [Exception] "DirExists($dir) failed because $($_.Exception.Message)"; } }
function DirListDirs                          ( [String] $dir ){ return [String[]] (@()+(Get-ChildItem -Force -Directory -Path $dir | ForEach-Object{ $_.FullName })); }
function DirHasFiles                          ( [String] $dir, [String] $filePattern ){
                                                return [Boolean] ($null -ne (Get-ChildItem -Force -Recurse -File -ErrorAction SilentlyContinue -Path "$dir\$filePattern")); }
function ScriptGetTopCaller                   (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim();
                                                if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; }
                                                if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
                                                if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
                                                return [String] $f; } # return empty if called interactive.
function ProcessIsLesserEqualPs5              (){ return [Boolean] ($PSVersionTable.PSVersion.Major -le 5); }
function ProcessPsExecutable                  (){ return [String] $(switch((ProcessIsLesserEqualPs5)){ $true{"powershell.exe"} default{"pwsh"}}); } # usually in $PSHOME
function ProcessIsRunningInElevatedAdminMode  (){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
                                                  IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
function ProcessRestartInElevatedAdminMode    (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){
                                                [String] $cmd = @( (ScriptGetTopCaller) ) + $sel;
                                                $cmd = $cmd.Replace("`"","`"`"`""); # see https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.arguments
                                                $cmd = $(switch((ProcessIsLesserEqualPs5)){ $true{"& `"$cmd`""} default{"-Command `"$cmd`""}});
                                                $cmd = "-NoExit -NoLogo " + $cmd;
                                                OutProgress "Not running in elevated administrator mode, so elevate current script and exit: `n  & `"$(ProcessPsExecutable)`" $cmd ";
                                                Start-Process -Verb "RunAs" -FilePath (ProcessPsExecutable) -ArgumentList $cmd;
                                                OutProgress "Exiting in 5 seconds"; Start-Sleep -Seconds 5;
                                                [Environment]::Exit("0"); throw [Exception] "Exit done, but it did not work, so it throws now an exception."; } }
function ShellSessionIs64not32Bit             (){ if( "$env:ProgramFiles" -eq "$env:ProgramW6432" ){ return [Boolean] $true ; }
                                                elseif( "$env:ProgramFiles" -eq "${env:ProgramFiles(x86)}" ){ return [Boolean] $false; }
                                                else{ throw [Exception] "Expected ProgramFiles=`"$env:ProgramFiles`" to be equals to ProgramW6432=`"$env:ProgramW6432`" or ProgramFilesx86=`"${env:ProgramFiles(x86)}`" "; } }
function UninstallDir                         ( [String] $dir ){ OutProgress "RemoveDir '$dir'. ";
                                                if( (DirExists $dir) ){ ProcessRestartInElevatedAdminMode; Remove-Item -Force -Recurse -LiteralPath $dir; } }
function UninstallSrcPath                     ( [String] $dir ){ OutProgress "UninstallSrcPath '$dir'. ";
                                                if( (OsPsModulePathContains $dir) ){ ProcessRestartInElevatedAdminMode; OsPsModulePathDel $dir; } }
function InstallDir                           ( [String] $srcDir, [String] $tarParDir ){ OutProgress "Copy '$srcDir' `n  to '$tarParDir'. ";
                                                ProcessRestartInElevatedAdminMode; Copy-Item -Force -Recurse -LiteralPath $srcDir -Destination $tarParDir; }
function InstallSrcPathToPsModulePathIfNotInst( [String] $srcDir ){ OutProgress "Change environment system variable PSModulePath by appending '$srcDir'. ";
                                                if( (OsPsModulePathContains $srcDir) ){ OutProgress "Already installed so environment variable not changed."; }
                                                else{ ProcessRestartInElevatedAdminMode; OsPsModulePathAdd $srcDir; } }
function SelfUpdate                           (){ $PSModuleAutoLoadingPreference = "All"; # "none" = Disabled. "All" = Auto load when cmd not found.
                                                try{ Import-Module "MnCommonPsToolLib.psm1"; MnCommonPsToolLib\MnCommonPsToolLibSelfUpdate; }
                                                catch{ OutProgress "Please restart shell and maybe calling file manager and retry"; throw; } }
function AddToPsModulePath                    ( [String] $dir ){
                                                if( (OsPsModulePathContains $dir) ){
                                                  OutProgress "Ok, matches expectations for system variable PsModulePath that it contains `"$dir`".";
                                                }else{
                                                  ProcessRestartInElevatedAdminMode;
                                                  OutProgress "To system var PsModulePath appending `"$dir`".";
                                                  OsPsModulePathAdd $dir;
                                                } }

# see https://docs.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module
[String] $linuxTargetDir    = "$HOME/.local/share/powershell/Modules";
[String] $tarRootDir32bit   = "${env:ProgramFiles(x86)}\WindowsPowerShell\Modules";
[String] $tarRootDir64bit   = "$env:ProgramW6432\WindowsPowerShell\Modules";
[String] $srcRootDir        = $PSScriptRoot; if( $srcRootDir -eq "" ){ $srcRootDir = FsEntryGetAbsolutePath "."; } # Example: "D:\WorkGit\myuser\MyNameOfPsToolLib_master"
[String[]] $dirsWithPsm1Files = @()+(DirListDirs $srcRootDir | Where-Object{ DirHasFiles $_ "*.psm1" });
if( $dirsWithPsm1Files.Count -ne 1 ){ throw [Exception] "Tool is designed for working below '$srcRootDir' with exactly one directory which contains psm1 files but found $($dirsWithPsm1Files.Count) dirs ($dirsWithPsm1Files)"; }
[String] $moduleSrcDir      = $dirsWithPsm1Files[0]; # Example: "D:\WorkGit\myuser\MyNameOfPsToolLib_master\MyNameOfPsToolLib" or "/home/myuser/Workspace/mniederw/MnCommonPsToolLib#trunk/MnCommonPsToolLib"
[String] $moduleName        = [System.IO.Path]::GetFileName($moduleSrcDir); # Example: "MyNameOfPsToolLib"
[String] $moduleTarDir32bit = "$tarRootDir32bit\$moduleName";
[String] $moduleTarDir64bit = "$tarRootDir64bit\$moduleName";
[String] $moduleTarDirLinux = "$linuxTargetDir/$moduleName";
[String] $psVersion = "$($PSVersionTable.PSVersion.ToString()) $(switch((ShellSessionIs64not32Bit)){($true){"64bit"}($false){"32bit"}})";
[Boolean] $ps7Exists = DirExists "$env:SystemDrive\Program Files\PowerShell\7\";

function CurrentInstallationModes( [String] $color = "White" ){
  if( (OsIsWindows) ){
    if( (DirExists $moduleTarDir64bit)       ){ OutProgressText -color:$color "Installed-in-Std-Mode-for-64bit "; }else{ OutProgressText "Not-Installed-in-Std-Mode-for-64bit "; }
    if( (DirExists $moduleTarDir32bit)       ){ OutProgressText -color:$color "Installed-in-Std-Mode-for-32bit "; }else{ OutProgressText "Not-Installed-in-Std-Mode-for-32bit "; }
    if( (OsPsModulePathContains $srcRootDir) ){ OutProgressText -color:$color "Installed-for-Developers "       ; }else{ OutProgressText "Not-Installed-for-Developers "       ; }
  }else{
    if( (DirExists $moduleTarDirLinux)       ){ OutProgressText -color:$color "Installed-in-Std-Mode-for-Linux "; }else{ OutProgressText "Not-Installed-in-Std-Mode-for-Linux "; }
  }
  OutProgress "";
}

function InstallStandardMode(){
  OutProgress "Install or reinstall in standard mode. ";
  if( (OsIsWindows) ){
    UninstallDir $moduleTarDir32bit;
    UninstallDir $moduleTarDir64bit;
    UninstallSrcPath $srcRootDir;
    InstallDir $moduleSrcDir $tarRootDir32bit;
    InstallDir $moduleSrcDir $tarRootDir64bit;
  }else{
    OutProgress "Delete-and-Copy `"$moduleSrcDir`" to `"$moduleTarDirLinux`" ";
    if( (DirExists $moduleTarDirLinux) ){ Remove-Item -Force -Recurse -LiteralPath $moduleTarDirLinux; }
    Copy-Item -Force -Recurse -LiteralPath $moduleSrcDir -Destination $linuxTargetDir;
  }
  OutProgressText "Current installation modes: "; CurrentInstallationModes "Green";
}

function InstallInDevMode(){
  OutProgress "Install or reinstall in developer mode, running in dir: $srcRootDir";
  UninstallDir $moduleTarDir32bit;
  UninstallDir $moduleTarDir64bit;
  InstallSrcPathToPsModulePathIfNotInst $srcRootDir;
  OutProgressText "Current installation modes: ";
  CurrentInstallationModes "Green";
}

if( $sel -eq "Install"          ){ InstallStandardMode; [Environment]::Exit("0"); }
if( $sel -eq "InstallInDevMode" ){ InstallInDevMode   ; [Environment]::Exit("0"); }

# for future use: [Boolean] $isDev = DirExists "$srcRootDir\.git";
OutProgressTitle "Install Menu for Powershell Module - $moduleName";
OutProgressTitle "-------------------------------------$("-"*($moduleName.Length))`n";

if( (OsIsWindows) ){
  OutProgress     "For installation or uninstallation the elevated administrator mode is ";
  OutProgress     "required and this tool automatically prompts for it when nessessary. ";
  OutProgress     "Powershell requires for any installation of a module that its file must be ";
  OutProgress     "located in a folder with the same name as the module name, ";
  OutProgress     "otherwise it could not be found by its name or by auto loading modules. ";
  OutProgress     "An installation in standard mode does first an uninstallation and then for ";
  OutProgress     "installation it copies the ps module folder to the common ps module folder ";
  OutProgress     "for all users for 32 and 64 bit. ";
  OutProgress     "An installation in developer mode does also first an uninstallation ";
  OutProgress     "and then it adds the path of the module folder as entry to the ps module ";
  OutProgress     "path environment variable PSModulePath. ";
  OutProgress     "An uninstallation does both, it removes the copied folder from the common ps ";
  OutProgress     "module folder for all users for 32 and 64 bit ";
  OutProgress     "and it removes the path entry from the ps module path environment variable. ";
  OutProgress     "As long as ps7 not contains all of ps5 modules and for having 32bit modules ";
  OutProgress     "usable under 64bit we strongly recommend that PsModulePath also contains ";
  OutProgress     "Ps5WinModDir and Ps5ModuleDir. ";
  OutProgress     "Imporant note: After any installation the current running programs which are ";
  OutProgress     "using the old PsModulePath or which did load previously the old module, they ";
  OutProgress     "need to be restarted or at least refresh all environment variables before ";
  OutProgress     "they can use the new installed module. ";
  OutProgress     "This usually applies for a file manager or ps sessions, but not for win-explorer. ";
  OutProgress     "To work sensibly with powershell you should set the execution mode to Bypass ";
  OutProgress     "(default is RemoteSigned). We recommend this if you trust yourself, that you ";
  OutProgress     "won't click by accident on unknown ps script files.";
  OutProgress     "By using this software you agree with the terms of GPL3. ";
  OutProgress     "";
  OutProgress     "Current environment:";
  OutProgress     "  PsVersion                          = `"$psVersion`". ";
  OutProgress     "  Ps5WinModDir                       = `"$ps5WinModuleDir`". ";
  OutProgress     "  Ps5ModuleDir                       = `"$ps5ModuleDir`". ";
  OutProgress     "  PsModuleFolder(allUsers,64bit)     = `"$tarRootDir64bit`". ";
  OutProgress     "  PsModuleFolder(allUsers,32bit)     = `"$tarRootDir32bit`". ";
  OutProgress     "  SrcRootDir                         = `"$srcRootDir`". ";
  OutProgress     "  IsInElevatedAdminMode              = $(ProcessIsRunningInElevatedAdminMode).";
  OutProgress     "  Executionpolicy-PS7                = $(switch($ps7Exists){($true){& "$env:SystemDrive\Program Files\PowerShell\7\pwsh.EXE" -Command Get-Executionpolicy}($false){"Is-not-installed"}}).";
  OutProgress     "  Executionpolicy-PS5-64bit          = $(& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Command Get-Executionpolicy).";
  OutProgress     "  Executionpolicy-PS5-32bit          = $(& "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -Command Get-Executionpolicy).";
  OutProgress     "  ShellSessionIs64not32Bit           = $(ShellSessionIs64not32Bit). ";
  OutProgress     "  PsModulePath contains Ps5WinModDir = $(OsPsModulePathContains $ps5WinModuleDir). ";
  OutProgress     "  PsModulePath contains Ps5ModuleDir = $(OsPsModulePathContains $ps5ModuleDir). ";
  OutProgress     "  PsModulePath contains SrcRootDir   = $(OsPsModulePathContains $srcRootDir). ";
  OutProgressText "  Current installation modes         = "; CurrentInstallationModes;
  if( ! (ShellSessionIs64not32Bit) ){
    OutWarning "Your current session is 32bit, it is recommended to generally use 64bit! ";
  }
  if( ! (OsPsModulePathContains $ps5WinModuleDir) ){
    OutWarning "PsModulePath not contains Ps5WinModDir, it is strongly recommended to add them (see menu items)! ";
  }
  if( ! (OsPsModulePathContains $ps5ModuleDir) ){
    OutWarning "PsModulePath not contains Ps5ModuleDir, it is strongly recommended to add them (see menu items)! ";
  }
  OutProgress     "";
  OutProgress     "  I = Install or reinstall in standard mode. ";
  OutProgress     "  A = Install in developer mode which uses module at current location to change and test the module. ";
  OutProgress     "  N = Uninstall all modes. ";
  OutProgress     "  U = When installed in standard mode do update from web. "; # in future do download and also switch to standard mode.
  OutProgress     "  W = Add Ps5WinModDir and Ps5ModuleDir to system PsModulePath environment variable. ";
  OutProgress     "  B = Elevate and Configure Execution Policy to Bypass       for environment ps7, ps5-64bit and ps5-32bit. ";
  OutProgress     "  R = Elevate and Configure Execution Policy to RemoteSigned for environment ps7, ps5-64bit and ps5-32bit. ";
  OutProgress     "  Q = Quit. `n";
  if( $sel -ne "" ){ OutProgress "Selection (afterwards exit): $sel "; }
  while( @("I","A","N","U","W","Q","B","R") -notcontains $sel ){
    OutProgressQuestion "Enter selection case insensitive and press enter: ";
    $sel = (Read-Host);
  }
  $Global:ArgsForRestartInElevatedAdminMode = @( $sel );
  if( $sel -eq "N" ){ UninstallDir $moduleTarDir32bit;
                      UninstallDir $moduleTarDir64bit;
                      UninstallSrcPath $srcRootDir;
                      OutProgressText "Current installation modes: "; CurrentInstallationModes "Green"; }
  if( $sel -eq "I" ){ InstallStandardMode; }
  if( $sel -eq "A" ){ InstallInDevMode; }
  if( $sel -eq "U" ){ SelfUpdate; }
  if( $sel -eq "W" ){ AddToPsModulePath $ps5WinModuleDir; AddToPsModulePath $ps5ModuleDir; }
  if( $sel -eq "B" ){ ProcessRestartInElevatedAdminMode;
                      OutProgress "Set-Executionpolicy Bypass";
                      if( $ps7Exists ){ & "$env:SystemDrive\Program Files\PowerShell\7\pwsh.EXE"           -Command { Set-Executionpolicy Bypass; }; }
                                        & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Command { Set-Executionpolicy Bypass; };
                                        & "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -Command { Set-Executionpolicy Bypass; };
  }
  if( $sel -eq "R" ){ ProcessRestartInElevatedAdminMode;
                      OutProgress "Set-Executionpolicy RemoteSigned";
                      if( $ps7Exists ){ & "$env:SystemDrive\Program Files\PowerShell\7\pwsh.EXE"           -Command { Set-Executionpolicy RemoteSigned }; }
                                        & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Command { Set-Executionpolicy RemoteSigned };
                                        & "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -Command { Set-Executionpolicy RemoteSigned }; }
  if( $sel -eq "Q" ){ OutProgress "Quit."; }
}else{ # non-windows
  OutProgress     "Running on Non-Windows OS (Linux, MacOS) ";
  OutProgress     "so currently this installation installs it locally not globally. ";
  OutProgress     "LinuxTargetDir: `"$linuxTargetDir`" ";
  OutProgress     "";
  OutProgress     "  I = Install or reinstall in standard mode. ";
  OutProgress     "  Q = Quit. `n";
  if( $sel -ne "" ){ OutProgress "Selection (afterwards exit): $sel "; }
  while( @("I","Q") -notcontains $sel ){
    OutProgressQuestion "Enter selection case insensitive and press enter: ";
    $sel = (Read-Host);
  }
  if( $sel -eq "I" ){ InstallStandardMode; }
  if( $sel -eq "Q" ){ OutProgress "Quit."; }
}
OutProgressQuestion "Finished. Press Enter to exit. "; Read-Host;
