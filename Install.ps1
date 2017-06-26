
# Do not change the following line, it is a powershell statement and not a comment!
#Requires -Version 3.0

param( [String] $sel )
trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; }
$Global:ErrorActionPreference = "Stop";
[String] $tarRootDir = "$Env:ProgramFiles\WindowsPowerShell\Modules"; # more see: https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx
[String] $srcDir = $PSScriptRoot; # ex: "D:\WorkGit\mniederw\MnCommonPsToolLib"
[String] $moduleName = [System.IO.Path]::GetFileName($srcDir); # ex: "MnCommonPsToolLib"
[String] $moduleSrcDir = "$srcDir\$moduleName"; # ex: "D:\WorkGit\mniederw\MnCommonPsToolLib\MnCommonPsToolLib"
[String] $moduleTarDir = "$tarRootDir\$moduleName";
[String] $envvar = "PSModulePath";
[String] $srcPath = $srcDir+"\";

function FsEntryMakeTrailingBackslash( [String] $fsEntry ){ [String] $result = $fsEntry; if( -not $result.EndsWith("\") ){ $result += "\"; } return [String] $result; }
function PsModulePathList(){ return [String[]] ([Environment]::GetEnvironmentVariable($envvar, "Machine").Split(";") | ForEach-Object { FsEntryMakeTrailingBackslash $_; }); }
function PsModulePathContains( [String] $p ){ return [Boolean] ((PsModulePathList) -contains $srcPath); }
function PsModulePathAdd     ( [String] $p ){ PsModulePathSet ((PsModulePathList)+@($srcPath)); }
function PsModulePathDel     ( [String] $p ){ PsModulePathSet ((PsModulePathList) | Where-Object { $_ -ne $p }); }
function PsModulePathSet     ( [String[]] $a ){ [String] $newValue = $a -join ";"; [Environment]::SetEnvironmentVariable($envvar, $newValue, "Machine"); }
function DirExists           ( [String] $d ){ return [Boolean] (Test-Path -PathType Container -LiteralPath $d); }
function ProcessIsRunningInElevatedAdminMode(){ 
  return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator");
}

function ProcessRestartInElevatedAdminMode(){
  if( -not (ProcessIsRunningInElevatedAdminMode) ){
    [String[]] $cmd = @( (ScriptGetTopCaller) ) + $sel;
    Write-Host -ForegroundColor DarkGray "Not running in elevated administrator mode so elevate current script and exit: `n  $cmd"; 
    Start-Process -Verb "RunAs" -FilePath "powershell.exe" -ArgumentList "& `"$cmd`" ";
    [Environment]::Exit("0"); throw [Exception] "Exit done, but it did not work, so it throws now an exception.";
  }
}

function UninstallDir(){
  Write-Host -ForegroundColor DarkGray "RemoveDir '$moduleTarDir'. ";
  if( DirExists $moduleTarDir ){
    ProcessRestartInElevatedAdminMode;
    Remove-Item -Force -Recurse -LiteralPath $moduleTarDir;
  }
}

function UninstallSrcPath(){
  Write-Host -ForegroundColor DarkGray "UninstallSrcPath '$srcPath'. ";
  if( (PsModulePathContains $srcPath) ){
    ProcessRestartInElevatedAdminMode;
    PsModulePathDel $srcPath;
  }
}

function InstallDir(){
  UninstallDir;
  UninstallSrcPath;
  Write-Host -ForegroundColor DarkGray "Copy '$moduleSrcDir' `n  to '$tarRootDir'. ";
  ProcessRestartInElevatedAdminMode;
  Copy-Item -Force -Recurse -LiteralPath $moduleSrcDir -Destination $tarRootDir; 
}

function InstallSrcPath(){
  UninstallDir;
  Write-Host -ForegroundColor DarkGray "Change environment system variable $envvar by appending '$srcPath'. ";
  #Write-Host -ForegroundColor DarkGray "Current value of environment system variable $envvar is: `n  $((PsModulePathList) -join ';') ";
  if( (PsModulePathContains $srcPath) ){
    Write-Host -ForegroundColor DarkGray "Already installed so environment variable not changed.";
  }else{
    ProcessRestartInElevatedAdminMode;
    PsModulePathAdd $srcPath;
  }
}

Write-Host "Install Menu";
Write-Host "------------ `n";
Write-Host "DirInstalled=$(DirExists $moduleTarDir); (TargetDir='$moduleTarDir'). ";
Write-Host "PathInstalled=$(PsModulePathContains $srcPath); (SrcPath='$srcPath') `n";
Write-Host "  I = Install ps module by copying it to the common folder for ps modules for all users: ";
Write-Host "      '$tarRootDir'.";
Write-Host "  A = Alternative installation of ps module by adding the path of this script ";
Write-Host "      to the ps module path ($envvar), used by developers to change module. ";
Write-Host "  U = Uninstall both. ";
Write-Host "  Q = Quit. `n";
if( $sel -ne "" ){ Write-Host "Selection: $sel "; }
while( @("I","A","U","Q") -notcontains $sel ){
  Write-Host -ForegroundColor Cyan -nonewline "Enter selection and press enter (case insensitive: I,A,U,Q): ";
  [String] $sel = (Read-Host);
}
if( $sel -eq "U" ){ UninstallDir; UninstallSrcPath; }
if( $sel -eq "I" ){ InstallDir; }
if( $sel -eq "A" ){ InstallSrcPath; }
if( $sel -eq "Q" ){ Write-Host -ForegroundColor DarkGray "Quit."; }
Write-Host -ForegroundColor Green "Ok, done. Press enter to exit. ";
Read-Host;
