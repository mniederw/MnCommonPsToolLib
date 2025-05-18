#!/usr/bin/env pwsh

Param( [String] $sel = "" )
  # ""                           : Show interactive menu.
  # "Install"                    : Reinstall in global standard mode and exit.
  # "InstallInLocalDeveloperMode": Reinstall in local developer mode and exit.

Set-StrictMode -Version Latest; $ErrorActionPreference = "Stop"; trap [Exception] { $nl = [Environment]::NewLine; Write-Progress -Activity " " -Status " " -Completed;
  Write-Error -ErrorAction Continue "$($_.Exception.GetType().Name): $($_.Exception.Message)${nl}$($_.InvocationInfo.PositionMessage)$nl$($_.ScriptStackTrace)";
  Read-Host "Press Enter to Exit"; break; }

$Global:OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [Text.UTF8Encoding]::UTF8;
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US');

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
function OsPsModulePathList                   (){ # on non-windows there is no permanent machine env var.
                                                [String] $varScope = $(switch(OsIsWindows){$true{"Machine"}default{"Process"}});
                                                return [String[]] ([Environment]::GetEnvironmentVariable("PSModulePath", $varScope).
                                                Split((OsPathSeparator),[System.StringSplitOptions]::RemoveEmptyEntries)); }
function OsPsModulePathSet                    ( [String[]] $pathList ){ # not on non-windows this is not stored permanently but only in session.
                                                [Environment]::SetEnvironmentVariable("PSModulePath", ($pathList -join (OsPathSeparator))+(OsPathSeparator), "Machine"); }
function OsPsModulePathContains               ( [String] $dir ){ # Example: "D:\WorkGit\myuser\MyPsLibRepoName"
                                                [String[]] $a = (OsPsModulePathList | ForEach-Object{ FsEntryRemoveTrailingDirSep $_ });
                                                return [Boolean] ($a -contains (FsEntryRemoveTrailingDirSep $dir)); }
function OsPsModulePathAdd                    ( [String] $dir ){ if( (OsPsModulePathContains $dir) ){ return; }
                                                OsPsModulePathSet ((OsPsModulePathList)+@( (FsEntryRemoveTrailingDirSep $dir) )); }
function OsPsModulePathDel                    ( [String] $dir ){ OsPsModulePathSet (OsPsModulePathList |
                                                Where-Object{ (FsEntryRemoveTrailingDirSep $_) -ne (FsEntryRemoveTrailingDirSep $dir) }); }
function DirExists                            ( [String] $dir ){ try{ return [Boolean] (Test-Path -PathType Container -LiteralPath $dir ); }
                                                catch{ throw [Exception] "DirExists($dir) failed because $($_.Exception.Message)"; } }
function DirListDirs                          ( [String] $dir ){ return [String[]] (@()+(Get-ChildItem -Force -Directory -LiteralPath $dir | ForEach-Object{ $_.FullName })); }
function DirHasFiles                          ( [String] $dir, [String] $filePattern ){
                                                return [Boolean] ($null -ne (Get-ChildItem -Force -Recurse -File -ErrorAction SilentlyContinue -Path "$dir/$filePattern")); }
function ScriptGetTopCaller                   (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim();
                                                if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; }
                                                if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
                                                if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
                                                return [String] $f; } # return empty if called interactive.
function ProcessIsLesserEqualPs5              (){ return [Boolean] ($PSVersionTable.PSVersion.Major -le 5); }
function ProcessPsExecutable                  (){ return [String] $(switch((ProcessIsLesserEqualPs5)){ $true{"powershell.exe"} default{"pwsh"}}); } # usually in $PSHOME
function ProcessIsRunningInElevatedAdminMode  (){ if( (OsIsWindows) ){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
                                                  return [Boolean] ("$env:SUDO_USER" -ne "" -or "$env:USERNAME" -eq "root"); }
function ProcessRestartInElevatedAdminMode    (){ if( (ProcessIsRunningInElevatedAdminMode) ){ return; }
                                                if( (OsIsWindows) ){
                                                  [String] $cmd = @( (ScriptGetTopCaller) ) + $sel;
                                                  $cmd = $cmd.Replace("`"","`"`"`""); # see https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.arguments
                                                  $cmd = $(switch((ProcessIsLesserEqualPs5)){ $true{"& `"$cmd`""} default{"-Command `"$cmd`""}});
                                                  $cmd = "-NoExit -NoLogo " + $cmd;
                                                  OutProgress "Not running in elevated administrator mode, so elevate current script and exit: `n  & `"$(ProcessPsExecutable)`" $cmd ";
                                                  OutProgress "  Start-Process -Verb RunAs -FilePath $(ProcessPsExecutable) -ArgumentList $cmd ";
                                                  Start-Process -Verb "RunAs" -FilePath (ProcessPsExecutable) -ArgumentList $cmd;
                                                  OutProgress "Exiting in 10 seconds. "; Start-Sleep -Seconds 10;
                                                }else{
                                                  # works currently only correct if command or argument does not require quotes or double-quotes
                                                  # maybe for pwsh we have to use: -CommandWithArgs cmdString
                                                  OutProgress "Not running in elevated administrator mode, so elevate current script and exit:";
                                                  OutProgress " & sudo $(ProcessPsExecutable) $(ScriptGetTopCaller) $sel ";
                                                  & sudo $(ProcessPsExecutable) $(ScriptGetTopCaller) $sel;
                                                }
                                                [Environment]::Exit("0"); # Note: 'Exit 0;' would only leave the last '. mycommand' statement.
                                                throw [Exception] "Exit done, but it did not work, so it throws now an exception."; }
function ShellSessionIs64not32Bit             (){ if( "$env:ProgramFiles" -eq "$env:ProgramW6432" ){ return [Boolean] $true ; }
                                                elseif( "$env:ProgramFiles" -eq "${env:ProgramFiles(x86)}" ){ return [Boolean] $false; }
                                                else{ throw [Exception] "Expected ProgramFiles=`"$env:ProgramFiles`" to be equals to ProgramW6432=`"$env:ProgramW6432`" or ProgramFilesx86=`"${env:ProgramFiles(x86)}`" "; } }
function DirCopy                              ( [String] $srcDir, [String] $tarParentDir ){
                                                OutProgress "DirCopy `"$srcDir`" to `"$tarParentDir`". ";
                                                Copy-Item -Force -Recurse -LiteralPath $srcDir -Destination $tarParentDir; }
function DirDelete                            ( [String] $dir ){ if( (DirExists $dir) ){ OutProgress "RemoveDir '$dir'. "; Remove-Item -Force -Recurse -LiteralPath $dir; } }
function UninstallGlobalDir                   ( [String] $dir ){ if( (DirExists $dir) ){ ProcessRestartInElevatedAdminMode; DirDelete $dir; } }
function UninstallSrcPath                     ( [String] $dir ){ OutProgress "UninstallSrcPath '$dir'. ";
                                                if( (OsPsModulePathContains $dir) ){ ProcessRestartInElevatedAdminMode; OsPsModulePathDel $dir; } }
function InstallGlobalDir                     ( [String] $srcDir, [String] $tarParDir ){ ProcessRestartInElevatedAdminMode; DirCopy $srcDir $tarParDir; }
function InstallSrcPathToPsModulePathIfNotInst( [String] $srcDir ){ OutProgress "Change environment system variable PSModulePath by appending '$srcDir'. ";
                                                if( (OsPsModulePathContains $srcDir) ){ OutProgress "Already installed so environment variable not changed. "; }
                                                else{ ProcessRestartInElevatedAdminMode; OsPsModulePathAdd $srcDir; } }
function SelfUpdate                           (){ $PSModuleAutoLoadingPreference = "All"; # "none" = Disabled. "All" = Auto load when cmd not found.
                                                try{ Import-Module "MnCommonPsToolLib.psm1"; MnCommonPsToolLib\MnCommonPsToolLibSelfUpdate; }
                                                catch{ OutProgress "Please restart shell and maybe calling file manager and retry. "; throw; } }
function AddToPsModulePath                    ( [String] $dir ){
                                                if( (OsPsModulePathContains $dir) ){
                                                  OutProgress "Ok, matches expectations for system variable PsModulePath that it contains `"$dir`". ";
                                                }else{
                                                  ProcessRestartInElevatedAdminMode;
                                                  OutProgress "To system var PsModulePath appending `"$dir`". ";
                                                  OsPsModulePathAdd $dir;
                                                } }
function SetAllEnvsExecutionPolicy            ( [String] $mode = "Bypass" ){ # For ps5/7-32/64bit set scope LocalMachine to mode and CurrentUser to Undefined; In general use modes: "Bypass", "RemoteSigned".
                                                OutProgress "Set-Executionpolicy for scope LocalMachine to $mode and scope CurrentUser to Undefined if not yet set. ";
                                                function SetExecPolicyToBypassIfNotSet( [String] $ps7Or5Exe ){
                                                  [String] $exe = "`"$ps7Or5Exe`"".PadRight(59);
                                                  [String] $msg = "Set-ExecutionPolicy for $exe";
                                                  if( (FileNotExists $ps7Or5Exe) ){ OutProgress "$($msg): Nothing to set because exe not exists "; return; }
                                                  [String] $modeLocalMachine = & $ps7Or5Exe -ExecutionPolicy $mode -NoProfile -Command Get-Executionpolicy -Scope LocalMachine;
                                                  [String] $modeCurrentUser  = & $ps7Or5Exe -ExecutionPolicy $mode -NoProfile -Command Get-Executionpolicy -Scope CurrentUser;
                                                  if( $modeLocalMachine -eq $mode -and ($modeCurrentUser -eq $mode -or $modeCurrentUser -eq "Undefined") ){
                                                    OutProgress "  $($msg): already up to date."; return;
                                                  }
                                                  ProcessRestartInElevatedAdminMode;
                                                  OutProgress "$msg";
                                                  & $ps7Or5Exe -ExecutionPolicy Bypass -NoProfile -Command { Set-Executionpolicy -Scope LocalMachine -Force $mode; Set-Executionpolicy -Scope CurrentUser -Force Undefined; };
                                                }
                                                SetExecPolicyToBypassIfNotSet "$env:SystemDrive\Program Files\PowerShell\7\pwsh.EXE"          ;
                                                SetExecPolicyToBypassIfNotSet "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe";
                                                SetExecPolicyToBypassIfNotSet "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe";
                                              }
                                                
                                                

# see https://docs.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module
[String]   $moduleRootDirCurrUserLinux = "$HOME/.local/share/powershell/Modules/";
[String]   $moduleRootDirAllUsersLinux = "/usr/local/share/powershell/Modules/";
[String]   $tarRootDir32bit            = "${env:ProgramFiles(x86)}\WindowsPowerShell\Modules";
[String]   $tarRootDir64bit            = "$env:ProgramW6432\WindowsPowerShell\Modules";
[String]   $srcRootDir                 = $PSScriptRoot; if( $srcRootDir -eq "" ){ $srcRootDir = FsEntryGetAbsolutePath "."; } # Example: "D:\WorkGit\myuser\MyNameOfPsToolLib_master"
[String[]] $dirsWithPsm1Files          = @()+(DirListDirs $srcRootDir | Where-Object{ DirHasFiles $_ "*.psm1" });
                                         if( $dirsWithPsm1Files.Count -ne 1 ){ throw [Exception] "Tool is designed for working below '$srcRootDir' with exactly one directory which contains psm1 files but found $($dirsWithPsm1Files.Count) dirs ($dirsWithPsm1Files)"; }
[String]   $moduleSrcDir               = $dirsWithPsm1Files[0]; # Example: "D:\WorkGit\myuser\MyNameOfPsToolLib_master\MyNameOfPsToolLib" or "/home/myuser/Workspace/mniederw/MnCommonPsToolLib#trunk/MnCommonPsToolLib"
[String]   $moduleName                 = [System.IO.Path]::GetFileName($moduleSrcDir); # Example: "MyNameOfPsToolLib"
[String]   $moduleTarDir32bit          = "$tarRootDir32bit\$moduleName";
[String]   $moduleTarDir64bit          = "$tarRootDir64bit\$moduleName";
[String]   $moduleTarDirCurrUserLinux  = "$moduleRootDirCurrUserLinux/$moduleName";
[String]   $moduleTarDirAllUsersLinux  = "$moduleRootDirAllUsersLinux/$moduleName";
[String]   $psVersion                  = "$($PSVersionTable.PSVersion.ToString()) $(switch((ShellSessionIs64not32Bit)){($true){"64bit"}($false){"32bit"}})";
[Boolean]  $ps7Exists                  = DirExists "$env:SystemDrive\Program Files\PowerShell\7\";
[String]   $profilePattern             = "# DO-NOT-MANUALLY-CHANGE-IS-AUTOGENERATED-BY $moduleName/Install.ps1";

function CurrentInstallationModes(){
  [String[]] $modes = @();
  if( (OsIsWindows) ){
    if( (DirExists $moduleTarDir64bit)         ){ $modes += "Installed-in-Global-Std-Mode-AllUsers-64bit"; }
    if( (DirExists $moduleTarDir32bit)         ){ $modes += "Installed-in-Global-Std-Mode-AllUsers-32bit"; }
    # for later add: Local-Std-Mode
  }else{
    if( (DirExists $moduleTarDirAllUsersLinux) ){ $modes += "Installed-in-Global-Std-Mode-AllUsers"; }
    if( (DirExists $moduleTarDirCurrUserLinux) ){ $modes += "Installed-in-Local-Std-Mode-Current-User($env:USERNAME)"; }
  }
  if( (OsPsModulePathContains $srcRootDir)     ){ $modes += "Installed-in-Local-Developer-Mode-Current-User($env:USERNAME)"; }
  if( $modes.Count -eq 0 ){ $modes += "Not-Installed"; }
  return [String] "$modes.";
}

function UninstallGlobalStandardMode(){
  OutProgress "Uninstall global standard mode. ";
  if( (OsIsWindows) ){
    UninstallGlobalDir $moduleTarDir32bit;
    UninstallGlobalDir $moduleTarDir64bit;
  }else{
    UninstallGlobalDir $moduleTarDirAllUsersLinux;
    #Uninstall-Module -Name "MnCommonPsToolLib" -AllVersions -Force -ErrorAction SilentlyContinue; # does nothing because we never installed it this way
  }
}

function UninstallLocalStandardAndDeveloperMode(){
  OutProgress "Uninstall local standard and developer mode. ";
  if( (OsIsWindows) ){
    # here later uninstall: local module dir
    UninstallSrcPath $srcRootDir;
  }else{
    DirDelete $moduleTarDirCurrUserLinux;
    OutProgress "  Remove addition entry of PSModulePath from `"$PROFILE`". ";
    if( Test-Path -Path $PROFILE ){
      [String[]] $lines = @()+(Get-Content -Encoding UTF8 -LiteralPath $PROFILE |
        Where-Object { $_ -notmatch [regex]::Escape($profilePattern) } );
        [String] $encoding = $(switch(ProcessIsLesserEqualPs5){($true){ "UTF8" }($false){ "UTF8BOM" }}); # make UTF8BOM
        $lines | Out-File -Force -NoClobber:$false -Encoding $encoding -LiteralPath $PROFILE; # Appends to each line a nl.
    }
    OutProgress "  Remove entry from PSModulePath. ";
    [String[]] $a = @()+($env:PSModulePath.Split((OsPathSeparator),[System.StringSplitOptions]::RemoveEmptyEntries)) | Where-Object{$null -ne $_} |
      ForEach-Object{ FsEntryMakeTrailingDirSep $_ } |
      Where-Object{ $_ -ne (FsEntryMakeTrailingDirSep $srcRootDir) };
    $env:PSModulePath = ($a -join (OsPathSeparator))+(OsPathSeparator);
  }
}

function UninstallAllModes(){
  UninstallGlobalStandardMode;
  UninstallLocalStandardAndDeveloperMode;
}

function InstallInGlobalStandardMode(){
  OutProgress "Reinstall in global standard mode. ";
  UninstallGlobalStandardMode;
  if( (OsIsWindows) ){
    InstallGlobalDir $moduleSrcDir $tarRootDir32bit;
    InstallGlobalDir $moduleSrcDir $tarRootDir64bit;
  }else{
    InstallGlobalDir $moduleSrcDir $moduleRootDirAllUsersLinux;
  }
}

function InstallInLocalStandardMode(){
  OutProgress "Reinstall in local standard mode. ";
  UninstallLocalStandardAndDeveloperMode;
  if( (OsIsWindows) ){
    # here later add install: local module dir for 32 and 64 bit
  }else{
    DirCopy $moduleSrcDir $moduleRootDirCurrUserLinux;
  }
}

function InstallInLocalDeveloperMode(){
  OutProgress "Reinstall in local developer mode, running in dir: `"$srcRootDir`". ";
  UninstallLocalStandardAndDeveloperMode;
  if( (OsIsWindows) ){
    InstallSrcPathToPsModulePathIfNotInst $srcRootDir;
  }else{
    OutProgress "  Adding PSModulePath extension to `"$PROFILE`". ";
    New-Item -type directory -Force (Split-Path $PROFILE) | Out-Null;
    Add-Content -Path $PROFILE -Value "`$env:PSModulePath += `"$(OsPathSeparator)$srcRootDir`"; $profilePattern";
    . $PROFILE;
  }
}

function ShowHelpInfo(){
    OutProgress  "";
    OutProgress  "Help Info";
    OutProgress  "---------";
    OutProgress  "In case of an error this script waits for ENTER key before exits. ";
    OutProgress  "Common:";
    OutProgress  "  Powershell requires for any installation of a module that its main file must be ";
    OutProgress  "  located in a folder with the same name as the module name, ";
    OutProgress  "  otherwise it could not be found by its name or by auto loading modules. ";
    OutProgress  "  ";
    OutProgress  "  For global installations or uninstallations the elevated administrator mode (sudo on linux) ";
    OutProgress  "  is required and this tool automatically prompts for it when nessessary. ";
    OutProgress  "  ";
    OutProgress  "  An installation in standard mode does first an uninstallation and then for ";
    OutProgress  "  the global or local installation it copies the ps module folder to the common ps module folder ";
    OutProgress  "  for all users (on windows also for ps5 32 and 64 bit) or current user. ";
    OutProgress  "  An uninstallation does remove the copied folder from the common ps module folder. ";
    OutProgress  "  ";
    OutProgress  "  An installation in developer mode does also first a local uninstallation ";
    OutProgress  "  and then it adds the path of the module folder as entry to the ps module ";
    OutProgress  "  path environment variable PSModulePath (in Unix it extends the profile). ";
    OutProgress  "  An uninstallation removes the path entry from the ps module path environment variable (and the profile). ";
    OutProgress  "  ";
    OutProgress  "  Imporant note: After any installation the current running programs which are ";
    OutProgress  "  using the old PsModulePath or which did load previously the old module, they ";
    OutProgress  "  need to be restarted or at least refresh all environment variables before ";
    OutProgress  "  they can use the new installed module. ";
    OutProgress  "  This usually applies for a file manager or ps sessions, but on windows not for win-explorer. ";
    OutProgress  "  To work sensibly with powershell you should set the execution mode to Bypass ";
    OutProgress  "  (default is RemoteSigned). We recommend this if you trust yourself, that you ";
    OutProgress  "  won't click by accident on unknown ps script files.";
    OutProgress  "  ";
    OutProgress  "Windows:";
    OutProgress  "  As long as ps7 not contains all of ps5 modules and for having 32bit modules ";
    OutProgress  "  usable under 64bit we strongly recommend that PsModulePath also contains ";
    OutProgress  "  Ps5WinModDir and Ps5ModuleDir. ";
    OutProgress  "";
    OutProgress  "Unix-Like-OSs:";
    OutProgress  "  System-wide predefined locations for all users are typically in folder for example: ";
    OutProgress  "    /opt/microsoft/powershell/7/Modules/ ";
    OutProgress  "    /snap/powershell/271/opt/powershell/Modules/ ";
    OutProgress  "  Global (=System-wide) locations for all users are typically in folder: ";
    OutProgress  "    /usr/local/share/powershell/Modules/ ";
    OutProgress  "  Local (=User-specific) locations are typically in folder: ";
    OutProgress  "    ~/.local/share/powershell/Modules/ ";
    OutProgress  "  PROFILE user dependent locations: ";
    OutProgress  "        ~/.config/powershell/Microsoft.PowerShell_profile.ps1 ";
    OutProgress  "    /root/.config/powershell/Microsoft.PowerShell_profile.ps1 ";
    OutProgress  "";
    OutProgress  "For future use: ";
    OutProgress  "  For installations from https://www.powershellgallery.com/ the following statements can be used: ";
    OutProgress  "    Install-Module -Name myModuleName -Scope CurrentUser; ";
    OutProgress  "    Install-Module -Name myModuleName -Scope AllUsers   ; ";
    OutProgress  "";
    # OutProgress  "  Own ps-repo can be created by: ";
    # OutProgress  "    mkdir -p /path/to/local/repo; ";
    # OutProgress  "    Save-Module -Name YourModuleName -Path /path/to/local/repo; ";
    # OutProgress  "    Register-PSRepository -Name LocalRepo -SourceLocation /path/to/local/repo; ";
    # OutProgress  "    Install-Module -Name YourModuleName -Repository LocalRepo -Scope CurrentUser; ";
}

function Menu(){
  while($true){
    OutProgressTitle "";
    OutProgressTitle "Install Menu for Powershell Module - $moduleName";
    OutProgressTitle "-------------------------------------$("-"*($moduleName.Length))`n";
    OutProgress     "By using this software you agree with the terms of GPL3. ";
    OutProgress     "";
    OutProgress     "Current environment:";
    OutProgressText "    Current installation modes            = "; OutProgressText -color:Green (CurrentInstallationModes); OutProgress "";
    OutProgress     "  PsVersion                               = `"$psVersion`" on Platform=$([System.Environment]::OSVersion.Platform). ";
    OutProgress     "  Current-User                            = `"$env:USERNAME`". ";
    OutProgress     "  CurrentProcessExecutionPolicy           = $(Get-Executionpolicy -Scope Process). ";
    OutProgress     "  IsInElevatedAdminMode                   = $(ProcessIsRunningInElevatedAdminMode). ";
    OutProgress     "  SrcRootDir                              = `"$srcRootDir`". ";
    OutProgress     "  Powershell User Profile                 = `"$PROFILE`". ";
    if( (OsIsWindows) ){
      OutProgress   "  Ps5WinModDir                            = `"$ps5WinModuleDir`". ";
      OutProgress   "  Ps5ModuleDir                            = `"$ps5ModuleDir`".    ";
      OutProgress   "  PsModuleFolder(allUsers,64bit)          = `"$tarRootDir64bit`". ";
      OutProgress   "  PsModuleFolder(allUsers,32bit)          = `"$tarRootDir32bit`". ";
      OutProgress   "  ExecutionPolicy-PS7-------MachinePolicy = $(switch($ps7Exists){($true){& "$env:SystemDrive\Program Files\PowerShell\7\pwsh.EXE" -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope MachinePolicy}($false){"Is-not-installed"}}).";
      OutProgress   "  ExecutionPolicy-PS5-64bit-MachinePolicy = $(& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"                  -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope MachinePolicy).";
      OutProgress   "  ExecutionPolicy-PS5-32bit-MachinePolicy = $(& "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"                  -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope MachinePolicy).";
      OutProgress   "  ExecutionPolicy-PS7-------UserPolicy    = $(switch($ps7Exists){($true){& "$env:SystemDrive\Program Files\PowerShell\7\pwsh.EXE" -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope UserPolicy   }($false){"Is-not-installed"}}).";
      OutProgress   "  ExecutionPolicy-PS5-64bit-UserPolicy    = $(& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"                  -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope UserPolicy   ).";
      OutProgress   "  ExecutionPolicy-PS5-32bit-UserPolicy    = $(& "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"                  -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope UserPolicy   ).";
      OutProgress   "  ExecutionPolicy-PS7-------CurrentUser   = $(switch($ps7Exists){($true){& "$env:SystemDrive\Program Files\PowerShell\7\pwsh.EXE" -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope CurrentUser  }($false){"Is-not-installed"}}).";
      OutProgress   "  ExecutionPolicy-PS5-64bit-CurrentUser   = $(& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"                  -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope CurrentUser  ).";
      OutProgress   "  ExecutionPolicy-PS5-32bit-CurrentUser   = $(& "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"                  -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope CurrentUser  ).";
      OutProgress   "  ExecutionPolicy-PS7-------LocalMachine  = $(switch($ps7Exists){($true){& "$env:SystemDrive\Program Files\PowerShell\7\pwsh.EXE" -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope LocalMachine }($false){"Is-not-installed"}}).";
      OutProgress   "  ExecutionPolicy-PS5-64bit-LocalMachine  = $(& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"                  -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope LocalMachine ).";
      OutProgress   "  ExecutionPolicy-PS5-32bit-LocalMachine  = $(& "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"                  -ExecutionPolicy Bypass -NoProfile -Command Get-Executionpolicy -Scope LocalMachine ).";
      OutProgress   "  ShellSessionIs64not32Bit                = $(ShellSessionIs64not32Bit). ";
      OutProgress   "  PsModulePath contains Ps5WinModDir      = $(OsPsModulePathContains $ps5WinModuleDir). ";
      OutProgress   "  PsModulePath contains Ps5ModuleDir      = $(OsPsModulePathContains $ps5ModuleDir). ";
      if( ! (ShellSessionIs64not32Bit) ){
        OutWarning "Your current session is 32bit, it is recommended to generally use 64bit! ";
      }
      if( ! (OsPsModulePathContains $ps5WinModuleDir) ){
        OutWarning "PsModulePath not contains Ps5WinModDir, it is strongly recommended to add them (see menu items)! ";
      }
      if( ! (OsPsModulePathContains $ps5ModuleDir) ){
        OutWarning "PsModulePath not contains Ps5ModuleDir, it is strongly recommended to add them (see menu items)! ";
      }
    }else{ # non-windows as linux or macos
      OutProgress   "  ModuleRootDirAllUsers              = `"$moduleRootDirAllUsersLinux`". ";
      OutProgress   "  ModuleRootDirCurrUser              = `"$moduleRootDirCurrUserLinux`". ";
      OutProgress   "  PSModulePath = `"$env:PSModulePath`". ";
    }
    # OutProgress   "  Running OS:                        = Unix-Like. ";
    # OutProgress     "  PsModulePath contains SrcRootDir   = $(OsPsModulePathContains $srcRootDir). ";
    OutProgress     "";
    OutProgress     "I = Reinstall in global standard mode by copying to module path for all users (requires admin permissions). ";
    OutProgress     "C = Reinstall in local  standard mode by copying to module path for current user (also uninstalls local developer mode). ";
    OutProgress     "A = Reinstall in local developer mode by extending module path for current user with current location (also uninstalls local standard mode). ";
    OutProgress     "D = Uninstall from all users (requires admin permissions). ";
    OutProgress     "E = Uninstall from current user (standard and developer mode). ";
    OutProgress     "N = Uninstall all modes. ";
    if( (OsIsWindows) ){
      OutProgress     "U = When installed in standard mode do update from web. "; # in future do download and also switch to standard mode.
      OutProgress     "W = Add Ps5WinModDir and Ps5ModuleDir to system PsModulePath environment variable. ";
      OutProgress     "B = Elevate and Configure Execution Policy to Bypass       for environment ps7, ps5-64bit and ps5-32bit and LocalMach and CurrUser. ";
      OutProgress     "R = Elevate and Configure Execution Policy to RemoteSigned for environment ps7, ps5-64bit and ps5-32bit and LocalMach and CurrUser. ";
    }
    OutProgress     "H = Show help info. ";
    OutProgress     "Q = Quit. ";
    OutProgress     "";
    if( $sel -eq "" ){ OutProgressQuestion "Enter selection case insensitive and press enter: "; $sel = (Read-Host); }
    else{ OutProgress "Selection: `"$sel`" "; }
    if    ( $sel -eq "I" ){ InstallInGlobalStandardMode; }
    elseif( $sel -eq "C" ){ InstallInLocalStandardMode; }
    elseif( $sel -eq "A" ){ InstallInLocalDeveloperMode; }
    elseif( $sel -eq "D" ){ UninstallGlobalStandardMode; }
    elseif( $sel -eq "E" ){ UninstallLocalStandardAndDeveloperMode; }
    elseif( $sel -eq "N" ){ UninstallAllModes; }
    elseif( $sel -eq "U" -and (OsIsWindows) ){ SelfUpdate; }
    elseif( $sel -eq "W" -and (OsIsWindows) ){ AddToPsModulePath $ps5WinModuleDir; AddToPsModulePath $ps5ModuleDir; }
    elseif( $sel -eq "B" -and (OsIsWindows) ){ SetAllEnvsExecutionPolicy "Bypass"; }
    elseif( $sel -eq "R" -and (OsIsWindows) ){ SetAllEnvsExecutionPolicy "RemoteSigned"; }
    elseif( $sel -eq "H" ){ ShowHelpInfo; }
    elseif( $sel -eq "Q" ){ OutProgress "Quit. "; return; }
    else{ OutWarning "Unknown selection: `"$sel`" "; }
    $sel = "";
    OutProgressText "  Current installation modes: "; OutProgressText -color:Green (CurrentInstallationModes); OutProgress "";
  }
}



if( $sel -eq "Install"                     ){ InstallInGlobalStandardMode; return; }
if( $sel -eq "InstallInLocalDeveloperMode" ){ InstallInLocalDeveloperMode; return; }
Menu;
