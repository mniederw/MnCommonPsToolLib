
# Do not change the following line, it is a powershell statement and not a comment!
#Requires -Version 3.0
param( [String] $sel )
Set-StrictMode -Version Latest; # Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).
$Global:ErrorActionPreference = "Stop";
$PSModuleAutoLoadingPreference = "none"; # disable autoloading modules
trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; }
function OutInfo                              ( [String] $line ){ Write-Host -ForegroundColor White               $line; }
function OutProgress                          ( [String] $line ){ Write-Host -ForegroundColor DarkGray            $line; }
function OutProgressText                      ( [String] $line ){ Write-Host -ForegroundColor DarkGray -NoNewLine $line; }
function OutQuestion                          ( [String] $line ){ Write-Host -ForegroundColor Cyan     -NoNewline $line; }
function FsEntryMakeTrailingBackslash         ( [String] $fsEntry ){ [String] $result = $fsEntry; 
                                                if( -not $result.EndsWith("\") ){ $result += "\"; } return [String] $result; }
function FsEntryRemoveTrailingBackslash       ( [String] $fsEntry ){ [String] $result = $fsEntry; 
                                                while( $result.Length -gt 1 -and $result.EndsWith("\") ){ $result = $result.Remove($result.Length-1); } 
                                                return [String] $result; }
function FsEntryGetAbsolutePath               ( [String] $fsEntry ){ return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
function OsPsModulePathList                   (){ return [String[]] ([Environment]::GetEnvironmentVariable("PSModulePath", "Machine").
                                                  Split(";",[System.StringSplitOptions]::RemoveEmptyEntries)); }
function OsPsModulePathContains               ( [String] $dir ){ # ex: "D:\WorkGit\myaccount\MyPsLibRepoName"
                                                [String[]] $a = (OsPsModulePathList | ForEach-Object{ FsEntryRemoveTrailingBackslash $_ });
                                                return [Boolean] ($a -contains (FsEntryRemoveTrailingBackslash $dir)); }
function OsPsModulePathAdd                    ( [String] $dir ){ if( OsPsModulePathContains $dir ){ return; }
                                                OsPsModulePathSet ((OsPsModulePathList)+@( (FsEntryRemoveTrailingBackslash $dir) )); }
function OsPsModulePathDel                    ( [String] $dir ){ OsPsModulePathSet (OsPsModulePathList | 
                                                Where-Object{ (FsEntryRemoveTrailingBackslash $_) -ne (FsEntryRemoveTrailingBackslash $dir) }); }
function OsPsModulePathSet                    ( [String[]] $pathList ){ [Environment]::SetEnvironmentVariable("PSModulePath", ($pathList -join ";"), "Machine"); }
function DirExists                            ( [String] $dir ){ try{ return [Boolean] (Test-Path -PathType Container -LiteralPath $dir ); }
                                                catch{ throw [Exception] "DirExists($dir) failed because $($_.Exception.Message)"; } }
function DirListDirs                          ( [String] $d ){ return [String[]] (@()+(Get-ChildItem -Force -Directory -Path $d | ForEach-Object{ $_.FullName })); }
function DirHasFiles                          ( [String] $d, [String] $filePattern ){ 
                                                return [Boolean] ($null -ne (Get-ChildItem -Force -Recurse -File -ErrorAction SilentlyContinue -Path "$d\$filePattern")); }
function ScriptGetTopCaller                   (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); 
                                                if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; } 
                                                if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); } 
                                                if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); } 
                                                return [String] $f; } # return empty if called interactive.
function ProcessIsRunningInElevatedAdminMode  (){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
                                                  IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
function ProcessRestartInElevatedAdminMode    (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){ 
                                                [String[]] $cmd = @( (ScriptGetTopCaller) ) + $sel; 
                                                OutProgress "Not running in elevated administrator mode so elevate current script and exit: `n  $cmd"; 
                                                Start-Process -Verb "RunAs" -FilePath "powershell.exe" -ArgumentList "& `"$cmd`" "; 
                                                [Environment]::Exit("0"); throw [Exception] "Exit done, but it did not work, so it throws now an exception."; } }
function ShellSessionIs64not32Bit             (){ if( "${env:ProgramFiles}" -eq "$env:ProgramW6432"        ){ return [Boolean] $true ; }
                                                elseif( "${env:ProgramFiles}" -eq "${env:ProgramFiles(x86)}" ){ return [Boolean] $false; }
                                                else{ throw [Exception] "Expected ProgramFiles=`"${env:ProgramFiles}`" to be equals to ProgramW6432=`"$env:ProgramW6432`" or ProgramFilesx86=`"${env:ProgramFiles(x86)}`" "; } }
function UninstallDir                         ( [String] $d ){ OutProgress "RemoveDir '$d'. "; 
                                                if( DirExists $d ){ ProcessRestartInElevatedAdminMode; Remove-Item -Force -Recurse -LiteralPath $d; } }
function UninstallSrcPath                     ( [String] $d ){ OutProgress "UninstallSrcPath '$d'. "; 
                                                if( (OsPsModulePathContains $d) ){ ProcessRestartInElevatedAdminMode; OsPsModulePathDel $d; } }
function InstallDir                           ( [String] $srcDir, [String] $tarParDir ){ OutProgress "Copy '$srcDir' `n  to '$tarParDir'. "; 
                                                ProcessRestartInElevatedAdminMode; Copy-Item -Force -Recurse -LiteralPath $srcDir -Destination $tarParDir; }
function InstallSrcPathToPsModulePathIfNotInst( [String] $srcDir ){ OutProgress "Change environment system variable PSModulePath by appending '$srcDir'. "; 
                                                if( (OsPsModulePathContains $srcDir) ){ OutProgress "Already installed so environment variable not changed."; }
                                                else{ ProcessRestartInElevatedAdminMode; OsPsModulePathAdd $srcDir; } }
function SelfUpdate                           (){ $PSModuleAutoLoadingPreference = "All"; # none=Disabled. All=Auto load when cmd not found.
                                                try{ Import-Module "MnCommonPsToolLib.psm1"; MnCommonPsToolLib\MnCommonPsToolLibSelfUpdate; }
                                                catch{ OutProgress "Please restart shell and maybe calling file manager and retry"; throw; } }


# see https://docs.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module?view=powershell-7.1
[String] $tarRootDir32bit = "${env:ProgramFiles(x86)}\WindowsPowerShell\Modules";
[String] $tarRootDir64bit = "$env:ProgramW6432\WindowsPowerShell\Modules";
[String] $srcRootDir = $PSScriptRoot; if( $srcRootDir -eq "" ){ $srcRootDir = FsEntryGetAbsolutePath "."; } # ex: "D:\WorkGit\myaccount\MyNameOfPsToolLib_master"
[String[]] $dirsWithPsm1Files = @()+(DirListDirs $srcRootDir | Where-Object{ DirHasFiles $_ "*.psm1" });
if( $dirsWithPsm1Files.Count -ne 1 ){ throw [Exception] "Tool is designed for working below '$srcRootDir' with exactly one directory which contains psm1 files but found $($dirsWithPsm1Files.Count) dirs ($dirsWithPsm1Files)"; }
[String] $moduleSrcDir = $dirsWithPsm1Files[0]; # ex: "D:\WorkGit\myaccount\MyNameOfPsToolLib_master\MyNameOfPsToolLib"
[String] $moduleName    = [System.IO.Path]::GetFileName($moduleSrcDir); # ex: "MyNameOfPsToolLib"
[String] $moduleTarDir32bit = "$tarRootDir32bit\$moduleName";
[String] $moduleTarDir64bit = "$tarRootDir64bit\$moduleName";

function CurrentInstallationModes( [String] $color = "White" ){
  if( DirExists $moduleTarDir64bit       ){ Write-Host -NoNewline -ForegroundColor $color "Installed-in-Standard-Mode-for-64bit "; }else{ Write-Host -NoNewline -ForegroundColor "DarkGray" "Not-Installed-in-Standard-Mode-for-64bit "; }
  if( DirExists $moduleTarDir32bit       ){ Write-Host -NoNewline -ForegroundColor $color "Installed-in-Standard-Mode-for-32bit "; }else{ Write-Host -NoNewline -ForegroundColor "DarkGray" "Not-Installed-in-Standard-Mode-for-32bit "; }
  if( OsPsModulePathContains $srcRootDir ){ Write-Host -NoNewline -ForegroundColor $color "Installed-for-Developers "            ; }else{ Write-Host -NoNewline -ForegroundColor "DarkGray" "Not-Installed-for-Developers "; }
  Write-Host "";
}

[Boolean] $isDev = DirExists "$srcRootDir\.git";
OutInfo         "Install Menu for Powershell Module - $moduleName";
OutInfo         "-------------------------------------$("-"*($moduleName.Length))`n";
OutProgress     "  For installation or uninstallation the elevated administrator mode is ";
OutProgress     "  required and this tool automatically prompts for it when nessessary. ";
OutProgress     "  Powershell requires for any installation of a module that its file must be ";
OutProgress     "  located in a folder with the same name as the module name, ";
OutProgress     "  otherwise it could not be found by its name or by auto loading modules. ";
OutProgress     "  An installation in standard mode does first an uninstallation and then for ";
OutProgress     "  installation it copies the ps module folder to the common ps module folder ";
OutProgress     "  for all users for 32 and 64 bit. ";
OutProgress     "  An alternative installation for developers does also first an uninstallation ";
OutProgress     "  and then it adds the path of the module folder as entry to the ps module ";
OutProgress     "  path environment variable PSModulePath. ";
OutProgress     "  An uninstallation does both, it removes the copied folder ";
OutProgress     "  from the common ps module folder for all users for 32 and 64 bit ";
OutProgress     "  and it removes the path entry from the ps module path environment variable. ";
OutProgress     "  Imporant note: After any installation the current running programs which are ";
OutProgress     "  using the old PsModulePath or which did load previously the old module, they ";
OutProgress     "  need to be restarted before they can use new installed module. This usually ";
OutProgress     "  applies for a file manager or powershell sessions, but not for win-explorer. ";
OutProgress     "  By using this software you agree with the terms of GPL3. ";
OutProgress     "  ";
OutProgress     "  Current environment:";
OutProgress     "    IsInElevatedAdminMode            = $(ProcessIsRunningInElevatedAdminMode).";
OutProgress     "    ShellSessionIs64not32Bit         = $(ShellSessionIs64not32Bit). ";
OutProgress     "    PsModulePath contains SrcRootDir = $(OsPsModulePathContains $srcRootDir). ";
OutProgress     "    PsModuleFolder(allUsers,64bit)   = '$tarRootDir32bit'. ";
OutProgress     "    PsModuleFolder(allUsers,32bit)   = '$tarRootDir64bit'. ";
OutProgress     "    SrcRootDir                       = '$srcRootDir'. ";
OutProgressText "    Current installation modes       = "; CurrentInstallationModes;
OutInfo         "";
OutInfo         "  I = Install or reinstall in standard mode. ";
OutInfo         "  A = Alternative installation for developers which uses module at current location to change and test the module. ";
OutInfo         "  N = Uninstall all modes. ";
OutInfo         "  U = When installed in standard mode do update from web. "; # in future do download and also switch to standard mode.
OutInfo         "  Q = Quit. `n";
if( $sel -ne "" ){ OutProgress "Selection: $sel "; }
while( @("I","A","N","U","Q") -notcontains $sel ){
  OutQuestion "Enter selection case insensitive and press enter: ";
  $sel = (Read-Host);
}
$Global:ArgsForRestartInElevatedAdminMode = @( $sel );
if( $sel -eq "N" ){ UninstallDir $moduleTarDir32bit;
                    UninstallDir $moduleTarDir64bit;
                    UninstallSrcPath $srcRootDir;
                    OutProgressText "Current installation modes: "; CurrentInstallationModes "Green"; }
if( $sel -eq "I" ){ UninstallDir $moduleTarDir32bit;
                    UninstallDir $moduleTarDir64bit;
                    UninstallSrcPath $srcRootDir;
                    InstallDir $moduleSrcDir $tarRootDir32bit; 
                    InstallDir $moduleSrcDir $tarRootDir64bit; 
                    OutProgressText "Current installation modes: "; CurrentInstallationModes "Green"; }
if( $sel -eq "A" ){ UninstallDir $moduleTarDir32bit;
                    UninstallDir $moduleTarDir64bit;
                    InstallSrcPathToPsModulePathIfNotInst $srcRootDir;
                    OutProgressText "Current installation modes: "; CurrentInstallationModes "Green"; }
if( $sel -eq "U" ){ SelfUpdate; }
if( $sel -eq "Q" ){ OutProgress "Quit."; }
OutQuestion "Finished. Press enter to exit. "; Read-Host;
