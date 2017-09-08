
# Do not change the following line, it is a powershell statement and not a comment!
#Requires -Version 3.0

param( [String] $sel )
Set-StrictMode -Version Latest; # Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).
trap [Exception] { $Host.UI.WriteErrorLine($_); Read-Host; break; }
$Global:ErrorActionPreference = "Stop";
[String] $envVar = "PSModulePath";

function FsEntryMakeTrailingBackslash( [String] $fsEntry ){ [String] $result = $fsEntry; if( -not $result.EndsWith("\") ){ $result += "\"; } return [String] $result; }
function PsModulePathList            (){ return [String[]] ([Environment]::GetEnvironmentVariable($envVar, "Machine").Split(";",[System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object{ FsEntryMakeTrailingBackslash $_; }); }
function PsModulePathContains        ( [String] $d ){ return [Boolean] ((PsModulePathList) -contains (FsEntryMakeTrailingBackslash $d)); }
function PsModulePathAdd             ( [String] $d ){ PsModulePathSet ((PsModulePathList)+@( (FsEntryMakeTrailingBackslash $d) )); }
function PsModulePathDel             ( [String] $d ){ PsModulePathSet ((PsModulePathList) | Where-Object{ $_ -ne (FsEntryMakeTrailingBackslash $d) }); }
function PsModulePathSet             ( [String[]] $a ){ [Environment]::SetEnvironmentVariable($envVar, ($a -join ";"), "Machine"); }
function DirExists                   ( [String] $d ){ return [Boolean] (Test-Path -PathType Container -LiteralPath $d); }
function DirListDirs                 ( [String] $d ){ return [String[]] (@()+(Get-ChildItem -Force -Directory -Path $d | ForEach-Object{ $_.FullName })); }
function DirHasFiles                 ( [String] $d, [String] $filePattern ){ return [Boolean] ((Get-ChildItem -Force -Recurse -File -ErrorAction SilentlyContinue -Path "$d\$filePattern") -ne $null); }
function ScriptGetTopCaller          (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); # return empty if called interactive.
  if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; }
  if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
  if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
  return [String] $f;
}
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
function UninstallDir( [String] $d ){
  Write-Host -ForegroundColor DarkGray "RemoveDir '$d'. ";
  if( DirExists $d ){
    ProcessRestartInElevatedAdminMode;
    Remove-Item -Force -Recurse -LiteralPath $d;
  }
}
function UninstallSrcPath( [String] $d ){
  Write-Host -ForegroundColor DarkGray "UninstallSrcPath '$d'. ";
  if( (PsModulePathContains $d) ){
    ProcessRestartInElevatedAdminMode;
    PsModulePathDel $d;
  }
}
function InstallDir( [String] $srcDir, [String] $tarParDir ){  
  Write-Host -ForegroundColor DarkGray "Copy '$srcDir' `n  to '$tarParDir'. ";
  ProcessRestartInElevatedAdminMode;
  Copy-Item -Force -Recurse -LiteralPath $srcDir -Destination $tarParDir; 
}
function InstallSrcPathToPsModulePathIfNotInstalled( [String] $srcDir ){
  Write-Host -ForegroundColor DarkGray "Change environment system variable $envVar by appending '$srcDir'. ";
  #Write-Host -ForegroundColor DarkGray "Current value of environment system variable $envVar is: `n  $((PsModulePathList) -join ';') ";
  if( (PsModulePathContains $srcDir) ){
    Write-Host -ForegroundColor DarkGray "Already installed so environment variable not changed.";
  }else{
    ProcessRestartInElevatedAdminMode;
    PsModulePathAdd $srcDir;
  }
}



[String] $tarRootDir = "$Env:ProgramW6432\WindowsPowerShell\Modules"; # more see: https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx
[String] $srcRootDir = $PSScriptRoot; # ex: "D:\WorkGit\mniederw\MnCommonPsToolLib_master"
[String[]] $dirsWithPsm1Files = @()+(DirListDirs $srcRootDir | Where-Object{ DirHasFiles $_ "*.psm1" });
if( $dirsWithPsm1Files.Count -ne 1 ){ throw [Exception] "Tool is designed for working below '$srcRootDir' with exactly one directory which contains psm1 files but found $($dirsWithPsm1Files.Count) dirs ($dirsWithPsm1Files)"; }
[String] $moduleSrcDir = $dirsWithPsm1Files[0]; # ex: "D:\WorkGit\mniederw\MnCommonPsToolLib_master\MnCommonPsToolLib"
[String] $moduleName = [System.IO.Path]::GetFileName($moduleSrcDir); # ex: "MnCommonPsToolLib"
[String] $moduleTarDir = "$tarRootDir\$moduleName";
Write-Host "Install Menu";
Write-Host "------------`n";
Write-Host "ModuleName            = '$moduleName'";
Write-Host "DirInstalled          = $(DirExists $moduleTarDir);  (TargetDir='$moduleTarDir'). ";
Write-Host "PathInstalled         = $(PsModulePathContains $srcRootDir);  (SrcPath='$srcRootDir')";
Write-Host "IsInElevatedAdminMode = $(ProcessIsRunningInElevatedAdminMode); `n";
Write-Host "  I = Standard installation of ps module by uninstalling first and then ";
Write-Host "      by copying it to the common folder for ps modules for all users: ";
Write-Host "      '$tarRootDir'.";
Write-Host "  A = Alternative installation of ps module for developers while changing ";
Write-Host "      and testing the module by uninstalling first and then by adding the path ";
Write-Host "      of this script as entry to the ps module path ($envVar). ";
Write-Host "  U = Uninstall (both: copied folder and path entry). ";
Write-Host "  Q = Quit. `n";
if( $sel -ne "" ){ Write-Host "Selection: $sel "; }
while( @("I","A","U","Q") -notcontains $sel ){
  Write-Host -ForegroundColor Cyan -nonewline "Enter selection and press enter (case insensitive: I,A,U,Q): ";
  [String] $sel = (Read-Host);
}
if( $sel -eq "U" ){ UninstallDir $moduleTarDir; UninstallSrcPath $srcRootDir; }
if( $sel -eq "I" ){ UninstallDir $moduleTarDir; UninstallSrcPath $srcRootDir; InstallDir $moduleSrcDir $tarRootDir; }
if( $sel -eq "A" ){ UninstallDir $moduleTarDir; InstallSrcPathToPsModulePathIfNotInstalled $srcRootDir; }
if( $sel -eq "Q" ){ Write-Host -ForegroundColor DarkGray "Quit."; }
Write-Host -ForegroundColor Green "Ok, done. Press enter to exit. ";
Read-Host;
