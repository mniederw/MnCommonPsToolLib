# Common powershell tool library
# 2013-2018 produced by Marc Niederwieser, Switzerland. Licensed under GPL3. This is freeware.
# Published at: https://github.com/mniederw/MnCommonPsToolLib
#
# This library encapsulates many common commands for the purpose of:
#   Making behaviour compatible for usage with powershell.exe and powershell_ise.exe,
#   fixing problems, supporting tracing information and simplifying commands for documentation.
#
# Notes about common approaches:
# - Typesafe: Functions and its arguments and return values are always specified with its type to assert type reliablility.
# - ANSI/UTF8: Text file contents are written as default as UTF8-BOM for improving compatibility to other platforms besides Windows.
#   They are read in ANSI if they have no BOM (byte order mark) or otherwise according to BOM.
# - Indenting format of this file: The statements of the functions below are indented in the given way because function names should be easy readable as documentation.
# - On writing or appending files they automatically create its path parts.
# - Notes about tracing information lines:
#   - Progress : Any change of the system will be notified with (Write-Host -ForegroundColor DarkGray). Is enabled as default.
#   - Verbose  : Some read io will be notified with (Write-Verbose) which can be enabled by VerbosePreference.
#   - Debug    : Some minor additional information are notified with (Write-Debug) which can be enabled by DebugPreference.
#
#
# Example usages of this module for a .ps1 script:
#      # Simple example for using MnCommonPsToolLib 
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
#      Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "Hello world";
#      OutProgress "Working";
#      StdInReadLine "Press enter to exit.";
# or
#      # Simple example for using MnCommonPsToolLib with standard interactive mode
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
#      Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "Simple example for using MnCommonPsToolLib with standard interactive mode";
#      StdOutBegMsgCareInteractiveMode; # will ask: if you are sure (y/n)
#      OutProgress "Working";
#      StdOutEndMsgCareInteractiveMode; # will write: Ok, done. Press Enter to Exit
# or
#      # Simple example for using MnCommonPsToolLib with standard interactive mode without request or waiting
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
#      Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "Simple example for using MnCommonPsToolLib with standard interactive mode without request or waiting";
#      StdOutBegMsgCareInteractiveMode "NoRequestAtBegin, NoWaitAtEnd"; # will nothing write
#      OutProgress "Working";
#      StdOutEndMsgCareInteractiveMode; # will write: "Ok, done. Ending in 1 second(s)."
# or
#      [CmdletBinding()] Param( [parameter(Mandatory=$true)] [String] $p1, [parameter(Mandatory=$true)] [String] $p2 )
#      OutInfo "Parameters: p1=$p1 p2=$p2";
#

# Do not change the following line, it is a powershell statement and not a comment! Note: if it would be run interactively then it would throw: RuntimeException: Error on creating the pipeline.
#Requires -Version 3.0

# Version: Own version variable because manifest can not be embedded into the module itself only by a separate file which is a lack.
#   Major version changes will reflect breaking changes and minor identifies extensions and third number are for bugfixes.
[String] $MnCommonPsToolLibVersion = "1.27";
  # 2018-12-16  V1.27  suppress import-module warnings, improve ToolCreateLnkIfNotExists, rename FsEntryPrivAclAsString to PrivAclAsString, rename PrivFsSecurityHasFullControl to PrivAclHasFullControl, new: FsEntryCreateSymLink, FsEntryCreateHardLink, CredentialReadUserFromFile; 
  # 2018-12-16  V1.26  doc
  # 2018-10-08  V1.25  improve git logging, add ProcessStart
  # 2018-09-27  V1.24  fix FsEntryMakeRelative for equal dirs
  # 2018-09-26  V1.23  fix logfile of SqlPerformFile
  # 2018-09-26  V1.22  improved logging of SqlPerformFile
  # 2018-09-26  V1.21  improved FsEntryMakeRelative
  # 2018-09-26  V1.20  add: ScriptImportModuleIfNotDone, SqlPerformFile;
  # 2018-09-07  V1.19  remove deprecated: DirExistsAssert (use DirAssertExists instead), DateTimeFromStringAsFormat (use DateTimeFromStringIso instead), DateTimeAsStringForFileName (use DateTimeNowAsStringIso instead), fix DateTimeFromStringIso formats. Added FsEntryFsInfoFullNameDirWithBackSlash, FsEntryResetTs. Ignore Import err. Use ps module sqlserver instead sqlps and now with connectstring.
  # 2018-09-06  V1.18  add ConsoleSetGuiProperties, GetExtension.
  # 2018-08-14  V1.17  fix git err msg.
  # 2018-08-07  V1.16  add tool for sign assemblies, DirCreateTemp.
  # 2018-07-26  V1.15  improve handling of git, improve createLnk, ads functions, add doc.
  # 2018-03-26  V1.14  add ToolTailFile, FsEntryDeleteToRecycleBin.
  # 2018-02-23  V1.13  renamed deprecated DateTime* functions, new FsEntryGetLastModified, improve PsDownload, fixed DateTimeAsStringIso.
  # 2018-02-14  V1.12  add StdInAskForBoolean. DirExistsAssert is deprecated, use DirAssertExists instead.
  # 2018-02-06  V1.11  extend functions, fix FsEntryGetFileName.
  # 2018-01-18  V1.10  add HelpListOfAllModules, version var, improve ForEachParallel, improve log file names. 
  # 2018-01-09  V1.09  unify error messages, improved elevation, PsDownloadFile.
  # 2017-12-30  V1.08  improve RemoveSmb, renamed SvnCheckout to SvnCheckoutAndUpdate and implement retry.
  # 2017-12-16  V1.07  fix WgetDownloadSite.
  # 2017-12-02  V1.06  improved self-update hash handling, improve touch.
  # 2017-11-22  V1.05  extend functions, improved self-update by hash.
  # 2017-10-22  V1.04  extend functions, improve FileContentsAreEqual, self-update.
  # 2017-10-10  V1.03  extend functions.
  # 2017-09-08  V1.02  extend by jobs, parallel.
  # 2017-08-11  V1.01  update.
  # 2017-06-25  V1.00  published as open source to github.

Set-StrictMode -Version Latest; # Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).
trap [Exception] { $Host.UI.WriteErrorLine($_); break; } # ensure really no exc can continue! Is not called if a catch block is used! It is recommended for client code to use catch blocks for handling exceptions.

# define global variables if they are not yet defined; caller of this script can anytime set or change these variables to control the specified behaviour.
if( -not [Boolean](Get-Variable ModeHideOutProgress               -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeHideOutProgress               -value $false; }
if( -not [Boolean](Get-Variable ModeDisallowInteractions          -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeDisallowInteractions          -value $false; }
if( -not [Boolean](Get-Variable ModeDisallowElevation             -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeDisallowElevation             -value $false; }
if( -not [String] (Get-Variable ModeNoWaitForEnterAtEnd           -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeNoWaitForEnterAtEnd           -value $false; }
if( -not [String] (Get-Variable ArgsForRestartInElevatedAdminMode -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ArgsForRestartInElevatedAdminMode -value @()   ; }

# set some powershell predefined global variables:
$Global:ErrorActionPreference         = "Stop"                    ; # abort if a called exe will write to stderr, default is 'Continue'. Can be overridden in each command by [-ErrorAction actionPreference]
$Global:ReportErrorShowExceptionClass = $true                     ; # on trap more detail exception info
$Global:ReportErrorShowInnerException = $true                     ; # on trap more detail exception info
$Global:ReportErrorShowStackTrace     = $true                     ; # on trap more detail exception info
$Global:FormatEnumerationLimit        = 999                       ; # used for Format-Table, but seams not to work, default is 4
$Global:OutputEncoding                = [Console]::OutputEncoding ; # for pipe to native applications use the same as current console, default is 'System.Text.ASCIIEncoding'

# leave the following global variables on their default values, is here written just for documentation:
#   $Global:InformationPreference   SilentlyContinue   # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $Global:VerbosePreference       SilentlyContinue   # Available: Stop, Inquire, Continue(=show verbose and continue), SilentlyContinue(=default=no verbose).
#   $Global:DebugPreference         SilentlyContinue   # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $Global:ProgressPreference      Continue           # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $Global:WarningPreference       Continue           # Available: Stop, Inquire, Continue, SilentlyContinue. Can be overridden in each command by [-WarningAction actionPreference]
#   $Global:ConfirmPreference       High               # Available: None, Low, Medium, High.
#   $Global:WhatIfPreference        False              # Available: False, True.

# we like english error messages
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US');
  # alternatives: [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US'); Set-Culture en-US;

# import some modules (because it is more performant to do it once than doing this in each function using methods of this module)
# note: for example on "Windows Server 2008 R2" we currently are missing these modules but we ignore the errors because it its enough if the functions which uses these modules will fail.
#   The specified module 'ScheduledTasks'/'SmbShare' was not loaded because no valid module file was found in any module directory.
if( (Import-Module -NoClobber -Name "ScheduledTasks" -ErrorAction Continue 2>&1) -ne $null ){ $error.clear(); Write-Host -ForegroundColor Yellow "Ignored failing of Import-Module ScheduledTasks because it will fail later if a function is used from it."; }
if( (Import-Module -NoClobber -Name "SmbShare"       -ErrorAction Continue 2>&1) -ne $null ){ $error.clear(); Write-Host -ForegroundColor Yellow "Ignored failing of Import-Module SmbShare       because it will fail later if a function is used from it."; }

# for later usage: Import-Module -NoClobber -Name "SmbWitness";
Add-Type -Name Window -Namespace Console -MemberDefinition '[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);';

# statement extensions
function ForEachParallel {
  # based on https://powertoe.wordpress.com/2012/05/03/foreach-parallel/  
  # ex: (0..20) | ForEachParallel { echo "Nr: $_"; Start-Sleep 1; }; (0..5) | ForEachParallel -MaxThreads 2 { echo "Nr: $_"; Start-Sleep 1; }
  param( [Parameter(Mandatory=$true,position=0)]              [System.Management.Automation.ScriptBlock] $ScriptBlock,
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [PSObject]                                 $InputObject,
         [Parameter(Mandatory=$false)]                        [Int32]                                    $MaxThreads=8 )
  # note: for some unknown reason we sometimes get a red line "One or more errors occurred." but it continuous successfully.
  BEGIN{
    try{
      $iss = [System.Management.Automation.Runspaces.Initialsessionstate]::CreateDefault();
      $pool = [Runspacefactory]::CreateRunspacePool(1,$maxthreads,$iss,$host); $pool.open();
      $threads = @();
      $ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("param(`$_)`r`n"+$Scriptblock.ToString());
    }catch{ $Host.UI.WriteErrorLine("ForEachParallel-BEGIN: $($_)"); }
  }PROCESS{
    try{
      $powershell = [powershell]::Create().addscript($scriptblock).addargument($InputObject); 
      $powershell.runspacepool = $pool;
      $threads += @{ instance = $powershell; handle = $powershell.begininvoke(); };
    }catch{ $Host.UI.WriteErrorLine("ForEachParallel-PROCESS: $($_)"); }
  }END{
    try{
      [Boolean] $notdone = $true; while( $notdone ){ $notdone = $false;
        [System.Threading.Thread]::Sleep(250); # polling interval in msec
        for( [Int32] $i = 0; $i -lt $threads.count; $i++ ){
          if( $threads[$i].handle ){
            if( $threads[$i].handle.iscompleted ){
              try{
                $threads[$i].instance.endinvoke($threads[$i].handle);
              }catch{ Write-Host -ForegroundColor DarkGray "ForEachParallel-endinvoke: Ignoring $($_)"; $error.clear(); }
              $threads[$i].instance.dispose(); 
              $threads[$i].handle = $null; 
              [gc]::Collect();
            }else{ $notdone = $true; }
          }
        }
      }
    }catch{ $Host.UI.WriteErrorLine("ForEachParallel-END: $($_)"); } # ex: 2018-07: Exception calling "EndInvoke" with "1" argument(s)
  }
}

# set some self defined constant global variables
if( (Get-Variable -Scope global -ErrorAction SilentlyContinue -Name ComputerName) -eq $null ){ # check wether last variable already exists because reload safe
  New-Variable -option Constant -scope global -name CurrentMonthIsoString        -value ([String](Get-Date -format yyyy-MM)); # alternative: yyyy-MM-dd_HH_mm
  New-Variable -option Constant -scope global -name CurrentMonthAndWeekIsoString -value ([String]((Get-Date -format "yyyy-MM-")+(Get-Date -uformat "W%V")));
  New-Variable -option Constant -scope global -name UserQuickLaunchDir           -value ([String]"$env:APPDATA\Microsoft\Internet Explorer\Quick Launch");
  New-Variable -option Constant -scope global -name UserSendToDir                -value ([String]"$env:APPDATA\Microsoft\Windows\SendTo");
  New-Variable -option Constant -scope global -name UserMenuDir                  -value ([String]"$env:APPDATA\Microsoft\Windows\Start Menu");
  New-Variable -option Constant -scope global -name UserMenuStartupDir           -value ([String]"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup");
  New-Variable -option Constant -scope global -name AllUsersMenuDir              -value ([String]"$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu");
  New-Variable -option Constant -scope global -name InfoLineColor                -Value $(switch($Host.Name -eq "Windows PowerShell ISE Host"){($true){"Gray"}default{"White"}}); # ise is white so we need a contrast color
  New-Variable -option Constant -scope global -name ComputerName                 -value ([String]"$env:computername".ToLower());
}

# Script local variables
[String] $script:LogDir = "$env:TEMP\MnCommonPsToolLibLog";

# ----- exported tools and types -----

function GlobalSetModeVerboseEnable           ( [Boolean] $val = $true ){ $Global:VerbosePreference = $(switch($val){($true){"Continue"}default{"SilentlyContinue"}}); }
function GlobalSetModeHideOutProgress         ( [Boolean] $val = $true ){ $Global:ModeHideOutProgress      = $val; } # if true then OutProgress does nothing
function GlobalSetModeDisallowInteractions    ( [Boolean] $val = $true ){ $Global:ModeDisallowInteractions = $val; } # if true then any call to read from input will throw, it will not restart script for entering elevated admin mode and after any unhandled exception it does not wait for a key
function GlobalSetModeDisallowElevation       ( [Boolean] $val = $true ){ $Global:ModeDisallowElevation    = $val; } # if true then it will not restart script for entering elevated admin mode
function GlobalSetModeNoWaitForEnterAtEnd     ( [Boolean] $val = $true ){ $Global:ModeNoWaitForEnterAtEnd  = $val; } # if true then it will not wait for enter in StdOutBegMsgCareInteractiveMode
function GlobalSetModeEnableAutoLoadingPref   ( [Boolean] $val = $true ){ $Global:PSModuleAutoLoadingPreference = $(switch($val){($true){$null}default{"none"}}); } # enable or disable autoloading modules, available internal values: All (=default), ModuleQualified, None.

function StringIsNullOrEmpty                  ( [String] $s ){ return [Boolean] [String]::IsNullOrEmpty($s); }
function StringIsNotEmpty                     ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrEmpty($s)); }
function StringIsNullOrWhiteSpace             ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrWhiteSpace($s)); }
function StringLeft                           ( [String] $s, [Int32] $len ){ return [String] $s.Substring(0,(Int32Clip $len 0 $s.Length)); }
function StringRight                          ( [String] $s, [Int32] $len ){ return [String] $s.Substring($s.Length-(Int32Clip $len 0 $s.Length)); }
function StringRemoveRightNr                  ( [String] $s, [Int32] $len ){ return StringLeft $s ($s.Length-$len); }
function StringSplitIntoLines                 ( [String] $s ){ return [String[]] (($s -replace "`r`n", "`n") -split "`n"); } # for empty string it returns an array with one item.
function StringReplaceNewlinesBySpaces        ( [String] $s ){ return [String] ($s -replace "`r`n", "`n" -replace "`r", "" -replace "`n", " "); }
function StringArrayInsertIndent              ( [String[]] $lines, [Int32] $nrOfBlanks ){ if( $lines -eq $null ){ return [String[]] $null; } return [String[]] ($lines | %{ ((" "*$nrOfBlanks)+$_); }); }
function StringArrayDistinct                  ( [String[]] $lines ){ return [String[]] ($lines | Select-Object -Unique); }
function StringPadRight                       ( [String] $s, [Int32] $len, [Boolean] $doQuote = $false  ){ [String] $r = $s; if( $doQuote ){ $r = '"'+$r+'"'; } return [String] $r.PadRight($len); }
function StringSplitToArray                   ( [String] $sepChars, [String] $s, [Boolean] $removeEmptyEntries = $true ){ return [String[]] (@()+$s.Split($sepChars,$(switch($removeEmptyEntries){($true){[System.StringSplitOptions]::RemoveEmptyEntries}default{[System.StringSplitOptions]::None}}))); }
function StringReplaceEmptyByTwoQuotes        ( [String] $str ){ return [String] $(switch((StringIsNullOrEmpty $str)){($true){"`"`""}default{$str}}); }
function StringRemoveRight                    ( [String] $str, [String] $strRight, [Boolean] $ignoreCase = $true ){ [String] $r = StringRight $str $strRight.Length; return [String] $(switch(($ignoreCase -and $r -eq $strRight) -or $r -ceq $strRight){($true){StringRemoveRightNr $str $strRight.Length}default{$str}}); }
function StringFromException                  ( [Exception] $ex ){ return [String] "$($ex.GetType().Name): $($ex.Message -replace `"`r`n`",`" `") $($ex.Data|ForEach-Object{`"`r`n Data: [$($_.Values)]`"})`r`n StackTrace:`r`n$($ex.StackTrace)"; } # use this if $_.Exception.Message is not enough. note: .Data is never null.
function DateTimeAsStringIso                  ( [DateTime] $ts, [String] $fmt = "yyyy-MM-dd HH:mm:ss" ){ return [String] $ts.ToString($fmt); }
function DateTimeNowAsStringIso               ( [String] $fmt = "yyyy-MM-dd HH:mm:ss" ){ return [String] (Get-Date -format $fmt); }
function DateTimeNowAsStringIsoDate           (){ return [String] (DateTimeNowAsStringIso "yyyy-MM-dd"); }
function DateTimeFromStringIso                ( [String] $s ){ # "yyyy-MM-dd HH:mm:ss.fff" or "yyyy-MM-ddTHH:mm:ss.fff".
                                                [String] $fmt = "yyyy-MM-dd HH:mm:ss.fff"; if( $s.Length -le 10 ){ $fmt = "yyyy-MM-dd"; }elseif( $s.Length -le 16 ){ $fmt = "yyyy-MM-dd HH:mm"; }elseif( $s.Length -le 19 ){ $fmt = "yyyy-MM-dd HH:mm:ss"; }
                                                elseif( $s.Length -le 20 ){ $fmt = "yyyy-MM-dd HH:mm:ss."; }elseif( $s.Length -le 21 ){ $fmt = "yyyy-MM-dd HH:mm:ss.f"; }elseif( $s.Length -le 22 ){ $fmt = "yyyy-MM-dd HH:mm:ss.ff"; }
                                                if( $s.Length -gt 10 -and $s[10] -ceq 'T' ){ $fmt = $fmt.remove(10,1).insert(10,'T'); }
                                                try{ return [DateTime] [datetime]::ParseExact($s,$fmt,$null); }catch{ <# ex: Ausnahme beim Aufrufen von "ParseExact" mit 3 Argument(en): Die Zeichenfolge wurde nicht als gültiges DateTime erkannt. #> throw [Exception] "DateTimeFromStringIso(`"$s`") is not a valid datetime in format `"$fmt`""; } }
function ByteArraysAreEqual                   ( [Byte[]] $a1, [Byte[]] $a2 ){ if( $a1.LongLength -ne $a2.LongLength ){ return $false; } for( [Int64] $i = 0; $i -lt $a1.LongLength; $i++ ){ if( $a1[$i] -ne $a2[$i] ){ return $false; } } return $true; }
function Int32Clip                            ( [Int32] $i, [Int32] $lo, [Int32] $hi ){ if( $i -lt $lo ){ return $lo; } elseif( $i -gt $hi ){ return $hi; }else{ return $i; } } 
function ConsoleHide                          (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,0); } #0 hide (also by PowerShell.exe -WindowStyle Hidden)
function ConsoleShow                          (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,5); } #5 nohide
function ConsoleRestore                       (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,1); } #1 show
function ConsoleMinimize                      (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,6); } #6 minimize
function ConsoleSetGuiProperties              (){ [Object] $pshost = get-host; 
                                                  [Object] $w = $pshost.ui.rawui; $w.windowtitle = "$PSCommandPath"; $w.foregroundcolor = "Gray"; $w.backgroundcolor ="DarkBlue"; 
                                                  [Object] $n = $w.buffersize; $n.height = 9999; $n.width = 260; $w.buffersize = $n; 
                                                  $n = $w.windowsize; $n.height = 50; $n.width = 150; $w.windowsize = $n; }
function StdInAssertAllowInteractions         (){ if( $global:ModeDisallowInteractions ){ throw [Exception] "Cannot read for input because all interactions are disallowed, either caller should make sure variable ModeDisallowInteractions is false or he should not call an input method."; } }
function StdInReadLine                        ( [String] $line ){ Write-Host -ForegroundColor Cyan -nonewline $line; StdInAssertAllowInteractions; return [String] (Read-Host); }
function StdInReadLinePw                      ( [String] $line ){ Write-Host -ForegroundColor Cyan -nonewline $line; StdInAssertAllowInteractions; return [System.Security.SecureString] (Read-Host -AsSecureString); }
function StdInAskForEnter                     (){ [String] $line = StdInReadLine "Press Enter to Exit"; }
function StdInAskForBoolean                   ( [String] $msg =  "Enter Yes or No (y/n)?", [String] $strForYes = "y", [String] $strForNo = "n" ){ while($true){ Write-Host -ForegroundColor Magenta -NoNewline $msg; [String] $answer = StdInReadLine ""; if( $answer -eq $strForYes ){ return [Boolean] $true ; } if( $answer -eq $strForNo  ){ return [Boolean] $false; } } }
function StdInWaitForAKey                     (){ StdInAssertAllowInteractions; $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null; } # does not work in powershell-ise, so in general do not use it, use StdInReadLine()
function StdOutLine                           ( [String] $line ){ $Host.UI.WriteLine($line); } # writes an stdout line in default color, normally not used, rather use OutInfo because it gives more information what to output
function StdOutRedLine                        ( [String] $line ){ $Host.UI.WriteErrorLine($line); } # writes an stderr line in red
function StdOutRedLineAndPerformExit          ( [String] $line, [Int32] $delayInSec = 1 ){ StdOutRedLine $line; if( $global:ModeDisallowInteractions ){ ProcessSleepSec $delayInSec; }else{ StdInReadLine "Press Enter to Exit"; }; Exit 1; }
function StdErrHandleExc                      ( [System.Management.Automation.ErrorRecord] $er, [Int32] $delayInSec = 1 ){
                                                # Output full error information in red lines and then either wait for pressing enter or otherwise if interactions are globally disallowed then wait specified delay
                                                [String] $msg = "$(StringFromException $er.Exception)"; # ex: "ArgumentOutOfRangeException: Specified argument was out of the range of valid values. Parameter name: times  at ..."
                                                $msg += "`r`n ScriptStackTrace: `r`n   $($er.ScriptStackTrace -replace `"`r`n`",`"`r`n`   `")"; # ex: at <ScriptBlock>, C:\myfile.psm1: line 800 at MyFunc
                                                $msg += "`r`n InvocationInfo:`r`n   $($er.InvocationInfo.PositionMessage-replace `"`r`n`",`"`r`n`   `" )"; # At D:\myfile.psm1:800 char:83 \n   + ...         } | ForEach-Object{ "    ,`@(0,`"-`",`"T`",`"$($_.Name        ... \n   +                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~; 
                                                $msg += "`r`n InvocationInfoLine: $($er.InvocationInfo.Line -replace `"`r`n`",`" `" -replace `"\s+`",`" `" )";
                                                $msg += "`r`n InvocationInfoMyCommand: $($er.InvocationInfo.MyCommand)"; # ex: ForEach-Object
                                                $msg += "`r`n InvocationInfoInvocationName: $($er.InvocationInfo.InvocationName)"; # ex: ForEach-Object
                                                $msg += "`r`n InvocationInfoPSScriptRoot: $($er.InvocationInfo.PSScriptRoot)"; # ex: D:\MyModuleDir
                                                $msg += "`r`n InvocationInfoPSCommandPath: $($er.InvocationInfo.PSCommandPath)"; # ex: D:\MyToolModule.psm1
                                                $msg += "`r`n FullyQualifiedErrorId: $($er.FullyQualifiedErrorId)"; # ex: "System.ArgumentOutOfRangeException,Microsoft.PowerShell.Commands.ForEachObjectCommand"
                                                $msg += "`r`n ErrorRecord: $($er.ToString() -replace `"`r`n`",`" `")"; # ex: "Specified argument was out of the range of valid values. Parametername: times"
                                                $msg += "`r`n CategoryInfo: $(switch($er.CategoryInfo -ne $null){($true){$er.CategoryInfo.ToString()}default{''}})"; # https://msdn.microsoft.com/en-us/library/system.management.automation.errorcategory(v=vs.85).aspx
                                                $msg += "`r`n PipelineIterationInfo: $($er.PipelineIterationInfo|ForEach-Object{'$_, '})";
                                                $msg += "`r`n TargetObject: $($er.TargetObject)"; # can be null
                                                $msg += "`r`n ErrorDetails: $(switch($er.ErrorDetails -ne $null){($true){$er.ErrorDetails.ToString()}default{''}})";
                                                $msg += "`r`n PSMessageDetails: $($er.PSMessageDetails)";
                                                StdOutRedLine $msg;
                                                if( -not $global:ModeDisallowInteractions ){ 
                                                StdOutRedLine "Press enter to exit"; 
                                                  try{
                                                    Read-Host; return;
                                                  }catch{ # ex: PSInvalidOperationException:  Read-Host : Windows PowerShell is in NonInteractive mode. Read and Prompt functionality is not available.
                                                    StdOutRedLine "Note: Cannot Read-Host because $($_.Exception.Message)"; 
                                                  }
                                                }
                                                if( $delayInSec -gt 0 ){ StdOutLine "Waiting for $delayInSec seconds."; }
                                                ProcessSleepSec $delayInSec; 
                                                }
function StdPipelineErrorWriteMsg             ( [String] $msg ){ Write-Error $msg; } # does not work in powershell-ise, so in general do not use it, use throw
function StdOutBegMsgCareInteractiveMode      ( [String] $mode = "DoRequestAtBegin" ){ # available mode: "DoRequestAtBegin", "NoRequestAtBegin", "NoWaitAtEnd", "MinimizeConsole". Usually this is the first statement in a script after an info line. So you can give your scripts a standard styling.
                                                ScriptResetRc; [String[]] $modes = @()+($mode -split "," | ForEach-Object{ $_.Trim() });
                                                Assert ((@()+($modes | Where-Object{ $_ -ne "DoRequestAtBegin" -and $_ -ne "NoRequestAtBegin" -and $_ -ne "NoWaitAtEnd" -and $_ -ne "MinimizeConsole"})).Count -eq 0 ) "StdOutBegMsgCareInteractiveMode was called with unknown mode='$mode'";
                                                GlobalSetModeNoWaitForEnterAtEnd ($modes -contains "NoWaitAtEnd");
                                                if( -not $global:ModeDisallowInteractions -and $modes -notcontains "NoRequestAtBegin" ){ StdInAskForAnswerWhenInInteractMode "Are you sure (y/n)? "; }
                                                if( $modes -contains "MinimizeConsole" ){ OutProgress "Minimize console"; ProcessSleepSec 0; ConsoleMinimize; } }
function StdInAskForAnswerWhenInInteractMode  ( [String] $line, [String] $expectedAnswer = "y" ){
                                                if( -not $global:ModeDisallowInteractions ){ [String] $answer = StdInReadLine $line; if( $answer.ToLower() -ne $expectedAnswer ){ StdOutRedLineAndPerformExit "Aborted"; } } }
function StdOutEndMsgCareInteractiveMode      ( [Int32] $delayInSec = 1 ){ if( $global:ModeDisallowInteractions -or $global:ModeNoWaitForEnterAtEnd ){ 
                                                OutSuccess "Ok, done. Ending in $delayInSec second(s)."; ProcessSleepSec $delayInSec; }else{ OutSuccess "Ok, done. Press Enter to Exit;"; StdInReadLine; } }
function Assert                               ( [Boolean] $cond, [String] $msg = "" ){ if( -not $cond ){ throw [Exception] "Assertion failed $msg"; } }
function AssertRcIsOk                         ( [String[]] $linesToOutProgress = $null, [Boolean] $useLinesAsExcMessage = $false, [String] $logFileToOutProgressIfFailed = "" ){
                                                # can also be called with a single string; only nonempty progress lines are given out
                                                [Int32] $rc = ScriptGetAndClearLastRc; 
                                                if( $rc -ne 0 ){
                                                  if( -not $useLinesAsExcMessage ){ $linesToOutProgress | Where-Object{ -not [String]::IsNullOrWhiteSpace($_) } | ForEach-Object{ OutProgress $_ }; }
                                                  [String] $msg = "Last operation failed [rc=$rc]. "; 
                                                  if( $useLinesAsExcMessage ){ $msg = $(switch($rc -eq 1 -and $out -ne ""){($true){""}default{$msg}}) + ([String]$linesToOutProgress).Trim(); }
                                                  try{ OutProgress "Dump of $($logFileToOutProgressIfFailed):"; FileReadContentAsLines $logFileToOutProgressIfFailed | ForEach-Object { OutProgress "  $_"; } }catch{}                                               
                                                  throw [Exception] $msg; } }
function ScriptImportModuleIfNotDone          ( [String] $moduleName ){ if( -not (Get-Module $moduleName) ){ OutProgress "Import module $moduleName (can take some seconds on first call)"; Import-Module -NoClobber $moduleName -DisableNameChecking; } }
function ScriptGetCurrentFunc                 (){ return [String] ((Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name); }
function ScriptGetAndClearLastRc              (){ [Int32] $rc = 0; if( ((test-path "variable:LASTEXITCODE") -and $LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) -or -not $? ){ $rc = $LASTEXITCODE; ScriptResetRc; } return [Int32] $rc; } # if no windows command was done then $LASTEXITCODE is null
function ScriptResetRc                        (){ $error.clear(); & "cmd.exe" "/C" "EXIT 0"; $error.clear(); AssertRcIsOk; } # reset ERRORLEVEL to 0
function ScriptNrOfScopes                     (){ [Int32] $i = 1; while($true){ 
                                                try{ Get-Variable null -Scope $i -ValueOnly -ErrorAction SilentlyContinue | Out-Null; $i++; 
                                                }catch{ <# ex: System.Management.Automation.PSArgumentOutOfRangeException #> return [Int32] ($i-1); } } }
function ScriptGetProcessCommandLine          (){ return [String] ([environment]::commandline); } # ex: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "& \"C:\myscript.ps1\"";
function ScriptGetDirOfLibModule              (){ return [String] $PSScriptRoot ; } # get dir       of this script file of this function or empty if not from a script; alternative: (Split-Path -Parent -Path ($script:MyInvocation.MyCommand.Path))
function ScriptGetFileOfLibModule             (){ return [String] $PSCommandPath; } # get full path of this script file of this function or empty if not from a script. alternative1: try{ return [String] (Get-Variable MyInvocation -Scope 1 -ValueOnly).MyCommand.Path; }catch{ return [String] ""; }  alternative2: $script:MyInvocation.MyCommand.Path
function ScriptGetCallerOfLibModule           (){ return [String] $MyInvocation.PSCommandPath; } # return can be empty or implicit module if called interactive. alternative for dir: $MyInvocation.PSScriptRoot
function ScriptGetTopCaller                   (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); # return can be empty or implicit module if called interactive. usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
                                                if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; }
                                                if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
                                                if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
                                                return [String] $f; }
function ScriptIsProbablyInteractive          (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); # return can be empty or implicit module if called interactive. usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
                                                return [Boolean] $f -eq "" -or $f -eq "ScriptGetTopCaller" -or -not $f.StartsWith("&"); }
function StreamAllProperties                  (){ $input | Select-Object *; }
function StreamAllPropertyTypes               (){ $input | Get-Member -Type Property; }
function StreamFilterWhitespaceLines          (){ $input | Where-Object{ -not [String]::IsNullOrWhiteSpace($_) }; }
function StreamToNull                         (){ $input | Out-Null; }
function StreamToString                       (){ $input | Out-String -Width 999999999; }
function StreamToStringDelEmptyLeadAndTrLines (){ $input | Out-String -Width 999999999 | ForEach-Object{ $_ -replace "[ \f\t\v]]+\r\n","\r\n" -replace "^(\r\n)+","" -replace "(\r\n)+$","" }; }
function StreamToGridView                     (){ $input | Out-GridView -Title "TableData"; }
function StreamToCsvStrings                   (){ $input | ConvertTo-Csv -NoTypeInformation; } # does not work for a simple string array as expected
function StreamToJsonString                   (){ $input | ConvertTo-Json -Depth 100; }
function StreamToJsonCompressedString         (){ $input | ConvertTo-Json -Depth 100 -Compress; }
function StreamToXmlString                    (){ $input | ConvertTo-Xml -Depth 999999999 -As String -NoTypeInformation; }
function StreamToHtmlTableStrings             (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As Table; }
function StreamToHtmlListStrings              (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As List; }
function StreamToListString                   (){ $input | Format-List -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToFirstPropMultiColumnString   (){ $input | Format-Wide -AutoSize -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToCsvFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){
                                                $input | Export-Csv -Force:$overwrite -NoClobber:$(-not $overwrite) -NoTypeInformation -Encoding $encoding -Path (FsEntryEsc $file); } # nothing done if target already exists
function StreamToXmlFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){
                                                $input | Export-Clixml -Force:$overwrite -NoClobber:$(-not $overwrite) -Depth 999999999 -Encoding $encoding -Path (FsEntryEsc $file);} # nothing done if target already exists
function StreamToDataRowsString               ( [String[]] $propertyNames ){ if( $propertyNames -eq $null -or $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); } 
                                                $input | Format-Table -Wrap -Force -autosize -HideTableHeaders $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToTableString                  ( [String[]] $propertyNames ){ if( $propertyNames -eq $null -or $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); } 
                                                $input | Format-Table -Wrap -Force -autosize $propertyNames | StreamToStringDelEmptyLeadAndTrLines; } # does not work for a simple string array as expected
function OutInfo                              ( [String] $line ){ Write-Host -ForegroundColor $InfoLineColor -NoNewline "$line`r`n"; } # NoNewline is used because on multi threading usage line text and newline can be interrupted between
function OutWarning                           ( [String] $line, [Int32] $indentLevel = 1 ){ Write-Host -ForegroundColor Yellow -NoNewline (("  "*$indentLevel)+$line+"`r`n"); }
function OutSuccess                           ( [String] $line ){ Write-Host -ForegroundColor Green -NoNewline "$line`r`n"; }
function OutProgress                          ( [String] $line, [Int32] $indentLevel = 1 ){ if( $Global:ModeHideOutProgress ){ return; } Write-Host -ForegroundColor DarkGray -NoNewline (("  "*$indentLevel) +$line+"`r`n"); } # used for tracing changing actions, otherwise use OutVerbose
function OutProgressText                      ( [String] $str  ){ if( $Global:ModeHideOutProgress ){ return; } Write-Host -ForegroundColor DarkGray -NoNewline $str; }
function OutVerbose                           ( [String] $line ){ Write-Verbose -Message $line; } # output depends on $VerbosePreference, used tracing read or network operations
function OutDebug                             ( [String] $line ){ Write-Debug -Message $line; } # output depends on $DebugPreference, used tracing read or network operations
function OutClear                             (){ Clear-Host; }
function ProcessFindExecutableInPath          ( [String] $exec ){ [Object] $p = (Get-Command $exec -ErrorAction SilentlyContinue); if( $p -eq $null ){ return [String] ""; } return [String] $p.Source; } # return full path or empty if not found
function ProcessIsRunningInElevatedAdminMode  (){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
function ProcessAssertInElevatedAdminMode     (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){ throw [Exception] "Assertion failed because requires to be in elevated admin mode"; } }
function ProcessRestartInElevatedAdminMode    (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){
                                                [String[]] $topCallerArguments = @(); # currently it supports no arguments because we do not know how to access them (something like $global:args would be nice)
                                                # ex: "C:\myscr.ps1" or if interactive then statement name ex: "ProcessRestartInElevatedAdminMode"
                                                [String[]] $cmd = @( (ScriptGetTopCaller) ) + $topCallerArguments + $Global:ArgsForRestartInElevatedAdminMode;
                                                if( $Global:ModeDisallowInteractions -or $Global:ModeDisallowElevation ){ 
                                                  [String] $msg = "Script is currently not in elevated admin mode but the proceeding statements would require it. "
                                                  $msg += "The calling script=`"$cmd`" has the modes ModeDisallowInteractions=$Global:ModeDisallowInteractions and ModeDisallowElevation=$Global:ModeDisallowElevation, ";
                                                  $msg += "if both of them would be reset then it would try to restart script here to enter the elevated admin mode. ";
                                                  $msg += "Now it will continue but it will probably fail."; 
                                                  OutWarning $msg;
                                                }else{
                                                  $cmd = @("&", "`"$cmd`"" );
                                                  if( ScriptIsProbablyInteractive ){ $cmd = @("-NoExit") + $cmd; }
                                                  OutProgress "Not running in elevated administrator mode so elevate current script and exit: powershell.exe $cmd";
                                                  Start-Process -Verb "RunAs" -FilePath "powershell.exe" -ArgumentList $cmd; # ex: InvalidOperationException: This command cannot be run due to the error: Der Vorgang wurde durch den Benutzer abgebrochen.
                                                  # AssertRcIsOk; seams not to be nessessary
                                                  [Environment]::Exit("0"); # note: 'Exit 0;' would only leave the last '. mycommand' statement.
                                                  throw [Exception] "Exit done, but it did not work, so it throws now an exception.";
                                                } } }
function ProcessGetCurrentThreadId            (){ return [Int32] [Threading.Thread]::CurrentThread.ManagedThreadId; }
function ProcessListRunnings                  (){ return (Get-Process * | Where-Object{ $_.Id -ne 0 } | Sort-Object ProcessName); }
function ProcessListRunningsAsStringArray     (){ return (ProcessListRunnings | Format-Table -auto -HideTableHeaders " ",ProcessName,ProductVersion,Company | StreamToStringDelEmptyLeadAndTrLines); }
function ProcessIsRunning                     ( [String] $processName ){ return [Boolean] ((Get-Process -ErrorAction SilentlyContinue ($processName -replace ".exe","")) -ne $null); }
function ProcessKill                          ( [String] $processName ){ [Object] $p = Get-Process ($processName -replace ".exe","") -ErrorAction SilentlyContinue; 
                                                if( $p -ne $null ){ OutProgress "ProcessKill $processName"; ProcessRestartInElevatedAdminMode; $p.Kill(); } }
function ProcessSleepSec                      ( [Int32] $sec ){ Start-Sleep -s $sec; }
function ProcessListInstalledAppx             (){ return [String[]] (Get-AppxPackage | Select-Object PackageFullName | Sort PackageFullName); }
function ProcessGetCommandInEnvPathOrAltPaths ( [String] $commandNameOptionalWithExtension, [String[]] $alternativePaths = @(), [String] $downloadHintMsg ){
                                                [System.Management.Automation.CommandInfo] $cmd = Get-Command -CommandType Application -Name $commandNameOptionalWithExtension -ErrorAction SilentlyContinue;
                                                if( $cmd -ne $null ){ return [String] $cmd.Path; }
                                                foreach( $d in $alternativePaths ){ [String] $f = (Join-Path $d $commandNameOptionalWithExtension); if( (FileExists $f) ){ return $f; } }
                                                throw [Exception] "$(ScriptGetCurrentFunc): commandName='$commandNameOptionalWithExtension' was wether found in env-path='$env:PATH' nor in alternativePaths='$alternativePaths'. $downloadHintMsg"; }
function ProcessStart                         ( [String] $cmd, [String[]] $cmdArgs = @(), [Boolean] $outToProgress = $true, [Boolean] $careStdErrAsOut = $false ){ 
                                                # return output as string array. if stderr is not empty then it throws its text. But if ErrorActionPreference is Continue then stderr is simply appended to output. 
                                                # stores internally stdout and stderr to variables an not files.
                                                # available opt: "", ""
                                                AssertRcIsOk;
                                                [String] $traceInfo = "`"$cmd`""; $cmdArgs | Where-Object { $_ -ne $null } | ForEach-Object{ $traceInfo += " `"$_`""; };
                                                OutProgress $traceInfo; 
                                                $prInfo = New-Object System.Diagnostics.ProcessStartInfo; 
                                                $prInfo.FileName = (Get-Command $cmd).Path; $prInfo.Arguments = $cmdArgs; $prInfo.CreateNoWindow = $true; $prInfo.WindowStyle = "Normal";
                                                $prInfo.UseShellExecute = $false; <# nessessary for redirect io #> $prInfo.RedirectStandardError = $true; $prInfo.RedirectStandardOutput = $true;
                                                $pr = New-Object System.Diagnostics.Process; $pr.StartInfo = $prInfo; 
                                                [void]$pr.Start(); $pr.WaitForExit();
                                                [String[]] $out = (StringSplitIntoLines $pr.StandardOutput.ReadToEnd()) | Where-Object{ -not [String]::IsNullOrWhiteSpace($_) };
                                                [String] $err = $pr.StandardError.ReadToEnd().Trim();
                                                if( $careStdErrAsOut -or $Global:ErrorActionPreference -eq "Continue" ){ $out += $err; $err = ""; }
                                                if( $Global:ErrorActionPreference -ne "Continue" ){
                                                  if( $pr.ExitCode -ne 0 -or $err -ne "" ){
                                                    if( $out -ne "" ){ OutProgress $out; }
                                                    throw [Exception] "ProcessStart($traceInfo) failed with rc=$($pr.ExitCode) $err.";
                                                  }
                                                }
                                                if( $outToProgress ){ $out | Where-Object{ $_ -ne $null } | ForEach-Object{ OutProgress $_; }; }
                                                return [String[]] $out; }
function JobStart                             ( [ScriptBlock] $scr, [Object[]] $scrArgs = $null, [String] $name = "Job" ){ # return job object of type PSRemotingJob, the returned object of the script block can later be requested
                                                return [System.Management.Automation.Job] (Start-Job -name $name -ScriptBlock $scr -ArgumentList $scrArgs); }
function JobGet                               ( [String] $id ){ return [System.Management.Automation.Job] (Get-Job -Id $id); } # return job object
function JobGetState                          ( [String] $id ){ return [String] (JobGet $id).State; } # NotStarted, Running, Completed, Stopped, Failed, and Blocked.
function JobWaitForNotRunning                 ( [Int32] $id, [Int32] $timeoutInSec = -1 ){ $job = Wait-Job -Id $id -Timeout $timeoutInSec; }
function JobWaitForState                      ( [Int32] $id, [String] $state, [Int32] $timeoutInSec = -1 ){ $job = Wait-Job -Id $id -State $state -Force -Timeout $timeoutInSec; }
function JobWaitForEnd                        ( [Int32] $id ){ JobWaitForNotRunning $id; return [Object] (Receive-Job -Id $id); } # return result object of script block, job is afterwards deleted
function HelpHelp                             (){ Get-Help     | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllVariables               (){ Get-Variable | Sort-Object Name | ForEach-Object{ OutInfo "$($_.Name.PadRight(32)) $($_.Value)"; } } # Select-Object Name, Value | StreamToListString
function HelpListOfAllAliases                 (){ Get-Alias    | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllCommands                (){ Get-Command  | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllModules                 (){ Get-Module -ListAvailable | Sort-Object Name | Select-Object Name, ModuleType, Version, ExportedCommands; }
function HelpGetType                          ( [Object] $obj ){ return [String] $obj.GetType(); }
function OsPsVersion                          (){ return [String] (""+$Host.Version.Major+"."+$Host.Version.Minor); } # alternative: $PSVersionTable.PSVersion.Major
function OsIsWinVistaOrHigher                 (){ return [Boolean] ([Environment]::OSVersion.Version -ge (new-object "Version" 6,0)); }
function OsIsWin7OrHigher                     (){ return [Boolean] ([Environment]::OSVersion.Version -ge (new-object "Version" 6,1)); }
function OsIs64BitOs                          (){ return [Boolean] (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ea 0).OSArchitecture -eq "64-Bit"; }
function OsInfoMainboardPhysicalMemorySum     (){ return [Int64] (Get-WMIObject -class Win32_PhysicalMemory |Measure-Object -Property capacity -Sum).Sum; }
function PrivGetUserFromName                  ( [String] $username ){ # optionally as domain\username
                                                return [System.Security.Principal.NTAccount] $username; }
function PrivGetUserCurrent                   (){ return [System.Security.Principal.IdentityReference] ([System.Security.Principal.WindowsIdentity]::GetCurrent().User); } # alternative: PrivGetUserFromName "$env:userdomain\$env:username"
function PrivGetUserSystem                    (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18"                                                      )).Translate([System.Security.Principal.NTAccount]); } # NT AUTHORITY\SYSTEM = NT-AUTORITÄT\SYSTEM 
function PrivGetGroupAdministrators           (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544"                                                  )).Translate([System.Security.Principal.NTAccount]); } # BUILTIN\Administrators = VORDEFINIERT\Administratoren  (more https://msdn.microsoft.com/en-us/library/windows/desktop/aa379649(v=vs.85).aspx)
function PrivGetGroupAuthenticatedUsers       (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-11"                                                      )).Translate([System.Security.Principal.NTAccount]); } # NT AUTHORITY\Authenticated Users = NT-AUTORITÄT\Authentifizierte Benutzer
function PrivGetUserTrustedInstaller          (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464")).Translate([System.Security.Principal.NTAccount]); } # NT SERVICE\TrustedInstaller
function PrivFsRuleAsString                   ( [System.Security.AccessControl.FileSystemAccessRule] $rule ){
                                                return [String] "($($rule.IdentityReference);$(($rule.FileSystemRights) -replace ' ','');$($rule.InheritanceFlags -replace ' ','');$($rule.PropagationFlags -replace ' ','');$($rule.AccessControlType);IsInherited=$($rule.IsInherited))";
                                                } # for later: CentralAccessPolicyId, CentralAccessPolicyName, Sddl="O:BAG:SYD:PAI(A;OICI;FA;;;SY)(A;;FA;;;BA)"
function PrivAclAsString                      ( [System.Security.AccessControl.FileSystemSecurity] $acl ){
                                                [String] $s = "Owner=$($acl.Owner);Group=$($acl.Group);Acls="; foreach( $a in $acl.Access){ $s += PrivFsRuleAsString $a; } return [String] $s; }
function PrivAclSetProtection                 ( [Object] $acl, [Boolean] $accessRuleProtection, [Boolean] $auditRuleProtection ){ $acl.SetAccessRuleProtection($accessRuleProtection, $auditRuleProtection); }
function PrivFsRuleCreate                     ( [System.Security.Principal.IdentityReference] $account, [System.Security.AccessControl.FileSystemRights] $rights,
                                                [System.Security.AccessControl.InheritanceFlags] $inherit, [System.Security.AccessControl.PropagationFlags] $propagation, [System.Security.AccessControl.AccessControlType] $access ){ 
                                                # combinations see: https://msdn.microsoft.com/en-us/library/ms229747(v=vs.100).aspx
                                                # https://technet.microsoft.com/en-us/library/ff730951.aspx  Rights=(AppendData,ChangePermissions,CreateDirectories,CreateFiles,Delete,DeleteSubdirectoriesAndFiles,ExecuteFile,FullControl,ListDirectory,Modify,Read,ReadAndExecute,ReadAttributes,ReadData,ReadExtendedAttributes,ReadPermissions,Synchronize,TakeOwnership,Traverse,Write,WriteAttributes,WriteData,WriteExtendedAttributes) Inherit=(ContainerInherit,ObjectInherit,None) Propagation=(InheritOnly,NoPropagateInherit,None) Access=(Allow,Deny)
                                                return [System.Security.AccessControl.FileSystemAccessRule] (New-Object System.Security.AccessControl.FileSystemAccessRule($account, $rights, $inherit, $propagation, $access)); }
function PrivFsRuleCreateFullControl          ( [System.Security.Principal.IdentityReference] $account, [Boolean] $useInherit ){ # for dirs usually inherit is used
                                                [System.Security.AccessControl.InheritanceFlags] $inh = switch($useInherit){ ($false){[System.Security.AccessControl.InheritanceFlags]::None} ($true){[System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"} };
                                                [System.Security.AccessControl.PropagationFlags] $prf = switch($useInherit){ ($false){[System.Security.AccessControl.PropagationFlags]::None} ($true){[System.Security.AccessControl.PropagationFlags]::None                          } }; # alternative [System.Security.AccessControl.PropagationFlags]::InheritOnly
                                                return (PrivFsRuleCreate $account ([System.Security.AccessControl.FileSystemRights]::FullControl) $inh $prf ([System.Security.AccessControl.AccessControlType]::Allow)); }
function PrivDirSecurityCreateFullControl     ( [System.Security.Principal.IdentityReference] $account ){
                                                [System.Security.AccessControl.DirectorySecurity] $result = New-Object System.Security.AccessControl.DirectorySecurity;
                                                $result.AddAccessRule((PrivFsRuleCreateFullControl $account $true));
                                                return [System.Security.AccessControl.DirectorySecurity] $result; }
function PrivDirSecurityCreateOwner           ( [System.Security.Principal.IdentityReference] $account ){
                                                [System.Security.AccessControl.DirectorySecurity] $result = New-Object System.Security.AccessControl.DirectorySecurity;
                                                $result.SetOwner($account);
                                                return [System.Security.AccessControl.DirectorySecurity] $result; }
function PrivFileSecurityCreateOwner          ( [System.Security.Principal.IdentityReference] $account ){
                                                [System.Security.AccessControl.FileSecurity] $result = New-Object System.Security.AccessControl.FileSecurity;
                                                $result.SetOwner($account);
                                                return [System.Security.AccessControl.FileSecurity] $result; }
function PrivAclHasFullControl                ( [System.Security.AccessControl.FileSystemSecurity] $acl, [System.Security.Principal.IdentityReference] $account, [Boolean] $isDir ){
                                                $a = $acl.Access | Where-Object{ $_.IdentityReference -eq $account } |
                                                   Where-Object{ $_.FileSystemRights -eq "FullControl" -and $_.AccessControlType -eq "Allow" } |
                                                   Where-Object{ -not $isDir -or ($_.InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ContainerInherit) -and $_.InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ObjectInherit)) };
                                                   Where-Object{ -not $isDir -or $_.PropagationFlags -eq [System.Security.AccessControl.PropagationFlags]::None }
                                                 return [Boolean] ($a -ne $null); }
function RegistryMapToShortKey                ( [String] $key ){ 
                                                if( -not $key.StartsWith("HKEY_","CurrentCultureIgnoreCase") ){ return [String] $key; }
                                                return [String] $key -replace "HKEY_LOCAL_MACHINE:","HKLM:" -replace "HKEY_CURRENT_USER:","HKCU:" -replace "HKEY_CLASSES_ROOT:","HKCR:" -replace "HKEY_USERS:","HKU:" -replace "HKEY_CURRENT_CONFIG:","HKCC:"; }
function RegistryRequiresElevatedAdminMode    ( [String] $key ){ 
                                                if( $key.StartsWith("HKLM:","CurrentCultureIgnoreCase") -or $key.StartsWith("HKEY_LOCAL_MACHINE:","CurrentCultureIgnoreCase") ){ ProcessRestartInElevatedAdminMode; } }
function RegistryAssertIsKey                  ( [String] $key ){ 
                                                if( $key.StartsWith("HK","CurrentCultureIgnoreCase") -or $key.StartsWith("HKEY_","CurrentCultureIgnoreCase") ){ return; } throw [Exception] "Missing registry key instead of: '$key'"; }
function RegistryExistsKey                    ( [String] $key ){ 
                                                RegistryAssertIsKey $key; return [Boolean] (Test-Path $key); }
function RegistryExistsValue                  ( [String] $key, [String] $name = ""){ 
                                                RegistryAssertIsKey $key; if( $name -eq "" ){ $name = "(default)"; } 
                                                [Object] $k = Get-Item -Path $key -ErrorAction SilentlyContinue; 
                                                return [Boolean] $k -and $k.GetValue($name, $null) -ne $null; }
function RegistryCreateKey                    ( [String] $key ){  # creates key if not exists
                                                RegistryAssertIsKey $key; if( ! (RegistryExistsKey $key) ){ RegistryRequiresElevatedAdminMode $key; New-Item -Force -Path $key | Out-Null; } }
function RegistryGetValueAsObject             ( [String] $key, [String] $name = ""){ 
                                                RegistryAssertIsKey $key; if( $name -eq "" ){ $name = "(default)"; } # return null if value not exists
                                                [Object] $v = Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue;
                                                if( $v -eq $null ){ return [Object] $null; }else{ return [Object] $v.$name; } }
function RegistryGetValueAsString             ( [String] $key, [String] $name = "" ){ # return empty string if value not exists
                                                RegistryAssertIsKey $key; [Object] $obj = RegistryGetValueAsObject $key $name; if( $obj -eq $null ){ return ""; } return [String] $obj.ToString(); }
function RegistryListValueNames               ( [String] $key ){ 
                                                RegistryAssertIsKey $key; return [String[]] (Get-Item -Path $key).GetValueNames(); } # throws if key not found, if (default) value is assigned then empty string is returned for it.
function RegistryDelKey                       ( [String] $key ){ 
                                                RegistryAssertIsKey $key; if( !(RegistryExistsKey $key) ){ return; } RegistryRequiresElevatedAdminMode; Remove-Item -Path "$key"; }
function RegistryDelValue                     ( [String] $key, [String] $name = "" ){ 
                                                RegistryAssertIsKey $key; if( $name -eq "" ){ $name = "(default)"; } 
                                                if( !(RegistryExistsValue $key $name) ){ return; } 
                                                RegistryRequiresElevatedAdminMode; Remove-ItemProperty -Path $key -Name $name; }
function RegistrySetValue                     ( [String] $key, [String] $name, [String] $type, [Object] $val, [Boolean] $overwriteEvenIfStringValueIsEqual = $false ){
                                                # creates key-value if it not exists; value is changed only if it is not equal than previous value; available types: Binary, DWord, ExpandString, MultiString, None, QWord, String, Unknown.
                                                RegistryAssertIsKey $key; if( $name -eq "" ){ $name = "(default)"; } RegistryCreateKey $key; if( !$overwriteEvenIfStringValueIsEqual ){ 
                                                  [Object] $obj = RegistryGetValueAsObject $key $name; if( $obj -ne $null -and $val -ne $null -and $obj.GetType() -eq $val.GetType() -and $obj.ToString() -eq $obj.ToString() ){ return; }
                                                } 
                                                try{ Set-ItemProperty -Path $key -Name $name -Type $type -Value $val; 
                                                }catch{ # ex: SecurityException: Requested registry access is not allowed.
                                                  throw [Exception] "$(ScriptGetCurrentFunc)($key,$name) failed because $($_.Exception.Message) (often it requires elevated mode)"; } }                                                
function RegistryImportFile                   ( [String] $regFile ){
                                                OutProgress "RegistryImportFile '$regFile'"; FileAssertExists $regFile; 
                                                try{ <# stupid, it writes success to stderr #> & "$env:SystemRoot\system32\reg.exe" "IMPORT" $regFile 2>&1 | Out-Null; AssertRcIsOk; 
                                                }catch{ <# ignore always: System.Management.Automation.RemoteException Der Vorgang wurde erfolgreich beendet. #> [String] $expectedMsg = "Der Vorgang wurde erfolgreich beendet."; 
                                                  if( $_.Exception.Message -ne $expectedMsg ){ throw [Exception] "$(ScriptGetCurrentFunc)('$regFile') failed. We expected an exc but this must match '$expectedMsg' but we got: '$($_.Exception.Message)'"; } ScriptResetRc; } }
function RegistryKeyGetAcl                    ( [String] $key ){
                                                return [System.Security.AccessControl.RegistrySecurity] (Get-Acl -Path $key); } # must be called with shortkey form
function RegistryKeyGetHkey                   ( [String] $key ){
                                                if    ( $key.StartsWith("HKLM:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.Registry]::LocalMachine; }  # Note: we must return result immediatly because we had problems if it would be stored in a variable
                                                elseif( $key.StartsWith("HKCU:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.Registry]::CurrentUser; }
                                                elseif( $key.StartsWith("HKCR:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.Registry]::ClassesRoot; }
                                                elseif( $key.StartsWith("HKCC:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.Registry]::CurrentConfig; }
                                                elseif( $key.StartsWith("HKPD:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.Registry]::PerformanceData; }
                                                elseif( $key.StartsWith("HKU:","CurrentCultureIgnoreCase")  ){ return [Microsoft.Win32.Registry]::Users; }
                                                else{ throw [Exception] "$(ScriptGetCurrentFunc): Unknown HKey in: '$key'"; } }
function RegistryKeyGetSubkey                 ( [String] $key ){ 
                                                return [String] ($key -split ":",2)[1]; }
function RegistryPrivRuleCreate               ( [System.Security.Principal.IdentityReference] $account, [String] $regRight = "" ){
                                                # ex: "FullControl", "ReadKey". available enums: https://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights(v=vs.110).aspx 
                                                if( $regRight -eq "" ){ return [System.Security.AccessControl.AccessControlSections]::None; }
                                                $inh = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit";
                                                $pro = [System.Security.AccessControl.PropagationFlags]::None;
                                                return New-Object System.Security.AccessControl.RegistryAccessRule($account,[System.Security.AccessControl.RegistryRights]$regRight,$inh,$pro,[System.Security.AccessControl.AccessControlType]::Allow); }
                                                # alternative: "ObjectInherit,ContainerInherit"
function RegistryKeySetOwner                  ( [String] $key, [System.Security.Principal.IdentityReference] $account ){ # Note: throws PermissionDenied if object is protected by TrustedInstaller, then use RegistryKeySetOwnerForced
                                                [System.Security.AccessControl.RegistrySecurity] $acl = RegistryKeyGetAcl $key; 
                                                if( $acl.Owner -ne $account.Value ){ OutProgress "RegistryKeySetOwner `"$key`" `"$($account.ToString())`""; $acl.SetOwner($account); Set-Acl -Path $key -AclObject $acl; } }
function RegistryKeySetOwnerForced            ( [String] $key, [System.Security.Principal.IdentityReference] $account ){ # use this if object is protected by TrustedInstaller
                                                ProcessRestartInElevatedAdminMode; PrivEnableTokenPrivilege SeTakeOwnershipPrivilege; PrivEnableTokenPrivilege SeRestorePrivilege;
                                                try{ [Object] $k = (RegistryKeyGetHkey $key).OpenSubKey((RegistryKeyGetSubkey $key),[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership);
                                                [Object] $acl = $k.GetAccessControl();
                                                $acl.SetOwner($account); $k.SetAccessControl($acl); $k.Close();
                                                }catch{ throw [Exception] "$(ScriptGetCurrentFunc)($key,$account) failed because $($_.Exception.Message)"; } }
function RegistryKeySetAccessRuleForced       ( [String] $key, [System.Security.AccessControl.RegistryAccessRule] $rule ){ # use this if object is protected by TrustedInstaller
                                                ProcessRestartInElevatedAdminMode; PrivEnableTokenPrivilege SeTakeOwnershipPrivilege; PrivEnableTokenPrivilege SeRestorePrivilege;
                                                try{ [Object] $k = (RegistryKeyGetHkey $key).OpenSubKey((RegistryKeyGetSubkey $key),[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership);
                                                  [Object] $acl = $k.GetAccessControl();
                                                  $acl.SetAccessRule($rule); <# alternative: AddAccessRule #> $k.SetAccessControl($acl); $k.Close(); 
                                                }catch{ throw [Exception] "$(ScriptGetCurrentFunc)($key,$rule) failed because $($_.Exception.Message)"; } }
function OsGetWindowsProductKey               (){
                                                [String] $map = "BCDFGHJKMPQRTVWXY2346789"; 
                                                [Object] $value = (Get-ItemProperty "HKLM:\\SOFTWARE\Microsoft\Windows NT\CurrentVersion").digitalproductid[0x34..0x42]; [String] $p = ""; 
                                                for( $i = 24; $i -ge 0; $i-- ){ 
                                                  $r = 0; for( $j = 14; $j -ge 0; $j-- ){ $r = ($r * 256) -bxor $value[$j]; $value[$j] = [math]::Floor([double]($r/24)); $r = $r % 24; } 
                                                  $p = $map[$r] + $p; if( ($i % 5) -eq 0 -and $i -ne 0 ){ $p = "-" + $p; } 
                                                } 
                                                return [String] $p; }
function OsIsHibernateEnabled                 (){
                                                if( (FileNotExists "$env:SystemDrive\hiberfil.sys") ){ return $false; } 
                                                if( OsIsWin7OrHigher ){ return [Boolean] (RegistryGetValueAsString "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "HibernateEnabled") -eq "1"; }
                                                # win7     ex: Die folgenden Standbymodusfunktionen sind auf diesem System verfügbar: Standby ( S1 S3 ) Ruhezustand Hybrider Standbymodus
                                                # winVista ex: Die folgenden Ruhezustandfunktionen sind auf diesem System verfügbar: Standby ( S3 ) Ruhezustand Hybrider Standbymodus
                                                [String] $out = & "$env:SystemRoot\system32\POWERCFG.EXE" "-AVAILABLESLEEPSTATES" | Where-Object{
                                                  $_ -like "Die folgenden Standbymodusfunktionen sind auf diesem System verf*" -or $_ -like "Die folgenden Ruhezustandfunktionen sind auf diesem System verf*" }; 
                                                AssertRcIsOk; return [Boolean] ((($out.Contains("Ruhezustand") -or $out.Contains("Hibernate"))) -and (FileExists "$env:SystemDrive\hiberfil.sys")); }
function ServiceListRunnings                  (){ 
                                                return (Get-Service * | Where-Object{ $_.Status -eq "Running" } | Sort-Object Name | Format-Table -auto -HideTableHeaders " ",Name,DisplayName | StreamToStringDelEmptyLeadAndTrLines); }
function ServiceListExistings                 (){ 
                                                return [System.Management.ManagementObject[]] (Get-WmiObject win32_service | Sort-Object ProcessId,Name); } # we could also use Get-Service but members are lightly differnet; 2017-06 we got (RuntimeException: You cannot call a method on a null-valued expression.) so we added null check
function ServiceListExistingsAsStringArray    (){ 
                                                return (ServiceListExistings | Format-Table -auto -HideTableHeaders " ",ProcessId,Name,StartMode,State | StreamToStringDelEmptyLeadAndTrLines); }
function ServiceNotExists                     ( [String] $serviceName ){ 
                                                return [Boolean] -not (ServiceExists $serviceName); }
function ServiceExists                        ( [String] $serviceName ){ 
                                                return [Boolean] ((Get-Service $serviceName -ErrorAction SilentlyContinue) -ne $null); }
function ServiceAssertExists                  ( [String] $serviceName ){ 
                                                OutVerbose "Assert service exists: $serviceName"; if( ServiceNotExists $serviceName ){ throw [Exception] "Assertion failed because service not exists: $serviceName"; } }
function ServiceGet                           ( [String] $serviceName ){ 
                                                return [Object] (Get-Service -Name $serviceName -ErrorAction SilentlyContinue); } # name,displayname,status
function ServiceGetState                      ( [String] $serviceName ){ 
                                                [Object] $s = ServiceGet $serviceName; if( $s -eq $null ){ return [String] ""; } return [String] $s.Status; }
                                                # ServiceControllerStatus: "","ContinuePending","Paused","PausePending","Running","StartPending","Stopped","StopPending".
function ServiceStop                          ( [String] $serviceName ){
                                                [String] $s = ServiceGetState $serviceName; if( $s -eq "" -or $s -eq "stopped" ){ return; }
                                                OutProgress "ServiceStop $serviceName"; ProcessRestartInElevatedAdminMode;
                                                Stop-Service -Name $serviceName; } # instead of check for stopped we could also use -PassThru
function ServiceStart                         ( [String] $serviceName ){ 
                                                OutVerbose "Check if either service $ServiceName is running or otherwise go in elevate mode and start service"; 
                                                [String] $s = ServiceGetState $serviceName; if( $s -eq "" ){ throw [Exception] "Service not exists: '$serviceName'"; } if( $s -eq "Running" ){ return; } 
                                                OutProgress "ServiceStart $serviceName"; ProcessRestartInElevatedAdminMode; Start-Service -Name $serviceName; } #alternative: -displayname or Restart-Service
function ServiceSetStartType                  ( [String] $serviceName, [String] $startType, [Boolean] $errorAsWarning = $false ){
                                                [String] $startTypeExt = switch($startType){ "Disabled" {$startType} "Manual" {$startType} "Automatic" {$startType} "Automatic_Delayed" {"Automatic"} default { throw [Exception] "Unknown startType=$startType expected Disabled,Manual,Automatic,Automatic_Delayed."; } };
                                                [Nullable[UInt32]] $targetDelayedAutostart = switch($startType){ "Automatic" {0} "Automatic_Delayed" {1} default {$null} };
                                                [String] $key = "HKLM\System\CurrentControlSet\Services\$serviceName";
                                                [String] $regName = "DelayedAutoStart";
                                                [UInt32] $delayedAutostart = RegistryGetValueAsObject $key $regName; # null converted to 0
                                                [Object] $s = ServiceGet $serviceName; if( $s -eq $null ){ throw [Exception] "Service $serviceName not exists"; }
                                                if( $s.StartType -ne $startTypeExt -or ($targetDelayedAutostart -ne $null -and $targetDelayedAutostart -ne $delayedAutostart) ){
                                                  OutProgress "$(ScriptGetCurrentFunc) '$serviceName' $startType"; 
                                                  if( $s.StartType -ne $startTypeExt ){ 
                                                    ProcessRestartInElevatedAdminMode;
                                                    try{ Set-Service -Name $serviceName -StartupType $startTypeExt;
                                                    }catch{ #ex: for aswbIDSAgent which is antivir protection we got: ServiceCommandException: Service ... cannot be configured due to the following error: Zugriff verweigert
                                                      [String] $msg = "$(ScriptGetCurrentFunc)($serviceName,$startType) because $($_.Exception.Message)";
                                                      if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                      OutWarning "ignore failing of $msg";
                                                    }
                                                  }
                                                  if( $targetDelayedAutostart -ne $null -and $targetDelayedAutostart -ne $delayedAutostart ){
                                                     RegistrySetValue $key $regName "DWORD" $targetDelayedAutostart;
                                                     # default autostart delay of 120 sec is stored at: HKLM\SYSTEM\CurrentControlSet\services\$serviceName\AutoStartDelay = DWORD n
                                                  } } }
function ServiceMapHiddenToCurrentName        ( [String] $serviceName ){
                                                # Hidden services on Windows 10: Some services do not have a static service name because they do not have any associated DLL or executable.
                                                # This method maps a symbolic name as MessagingService_###### by the currently correct service name (ex: "MessagingService_26a344").
                                                # The ###### symbolizes a random hex string of 5-6 chars. ex: (ServiceMapHiddenName "MessagingService_######") -eq "MessagingService_26a344";
                                                # Currently all these known hidden services are internally started by "C:\WINDOWS\system32\svchost.exe -k UnistackSvcGroup". The following are known:
                                                [String[]] $a = @( "MessagingService_######", "PimIndexMaintenanceSvc_######", "UnistoreSvc_######", "UserDataSvc_######", "WpnUserService_######", "CDPUserSvc_######", "OneSyncSvc_######" );
                                                if( $a -notcontains $serviceName ){ return $serviceName; }
                                                [String] $mask = $serviceName -replace "_######","_*";
                                                [String] $result = (Get-Service * | ForEach-Object Name | Where-Object{ $_ -like $mask } | Sort | Select -First 1);
                                                if( $result -eq "" ){ $result = $serviceName;}
                                                return [String] $result; }
function TaskList                             (){ 
                                                Get-ScheduledTask | Select-Object @{Name="Name";Expression={($_.TaskPath+$_.TaskName)}}, State, Author, Description | Sort-Object Name; }
                                                # alternative: schtasks.exe /query /NH /FO CSV
function TaskIsDisabled                       ( [String] $taskPathAndName ){ 
                                                [String] $taskPath = (Split-Path -Parent $taskPathAndName).Trimend("\") + "\"; 
                                                [String] $taskName = Split-Path -Leaf $taskPathAndName; 
                                                return [Boolean] ((Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName).State -eq "Disabled"); }
function TaskDisable                          ( [String] $taskPathAndName ){ 
                                                [String] $taskPath = (Split-Path -Parent $taskPathAndName).Trimend("\") + "\"; [String] $taskName = Split-Path -Leaf $taskPathAndName; 
                                                if( !(TaskIsDisabled $taskPathAndName) ){ OutProgress "TaskDisable $taskPathAndName"; ProcessRestartInElevatedAdminMode; 
                                                try{ Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName | Out-Null; }
                                                catch{ OutWarning "Ignore failing of disabling task '$taskPathAndName' because $($_.Exception.Message)"; } } }
function FsEntryEsc                           ( [String] $fsentry ){ 
                                                if( $fsentry -eq "" ){ throw [Exception] "Empty file name not allowed"; } # escaping is not nessessary if a command supports -LiteralPath.
                                                return [String] [Management.Automation.WildcardPattern]::Escape($fsentry); } # important for chars as [,], etc.
function FsEntryMakeValidFileName             ( [string] $str ){ [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object{ $str = $str.Replace($_,'_') }; return [String] $str; }
function FsEntryMakeRelative                  ( [String] $fsEntry, [String] $belowDir, [Boolean] $prefixWithDotDir = $false ){
                                                # works without IO to file system; if $fsEntry is not equal or below dir then it throws;
                                                # if fs-entry is equal the below-dir then it returns a dot;
                                                # a trailing backslash of the fs entry is not changed;
                                                # trailing backslashes for belowDir are not nessessary. ex: "Dir1\Dir2" -eq (FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir");
                                                Assert ($belowDir -ne "") "belowDir is empty.";
                                                $belowDir = FsEntryMakeTrailingBackslash (FsEntryGetAbsolutePath $belowDir);
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                if( (FsEntryMakeTrailingBackslash $fsEntry) -eq $belowDir ){ $fsEntry += "\."; }
                                                Assert ($fsEntry.StartsWith($belowDir,"CurrentCultureIgnoreCase")) "Expected '$fsEntry' is below '$belowDir'";
                                                return [String] ($(switch($prefixWithDotDir){($true){".\"}default{""}})+$fsEntry.Substring($belowDir.Length)); }
function FsEntryGetAbsolutePath               ( [String] $fsEntry ){ # works without IO, so no check to file system; does not change a trailing backslash
                                                return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
                                                # note: we cannot use (Resolve-Path -LiteralPath $fsEntry) because it will throw if path not exists, see http://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist
function FsEntryHasTrailingBackslash          ( [String] $fsEntry ){ return [Boolean] $fsEntry.EndsWith("\"); }
function FsEntryRemoveTrailingBackslash       ( [String] $fsEntry ){ 
                                                [String] $result = $fsEntry; if( $result -ne "" ){ while( $result.EndsWith("\") ){ $result = $result.Remove($result.Length-1); }
                                                if( $result -eq "" ){ $result = $fsEntry; } } return [String] $result; } # leading backslashes are not removed.
function FsEntryMakeTrailingBackslash         ( [String] $fsEntry ){ 
                                                [String] $result = $fsEntry; if( -not $result.EndsWith("\") ){ $result += "\"; } return [String] $result; }
function FsEntryJoinRelativePatterns          ( [String] $rootDir, [String[]] $relativeFsEntriesPatternsSemicolonSeparated ){
                                                # create an array ex: @( "c:\myroot\bin\", "c:\myroot\obj\", "c:\myroot\*.tmp", ... ) from input as @( "bin\;obj\;", ";*.tmp;*.suo", ".\dir\d1?\", ".\dir\file*.txt");
                                                # if an fs entry specifies a dir patterns then it must be specified by a trailing backslash. 
                                                [String[]] $a = @(); $relativeFsEntriesPatternsSemicolonSeparated | ForEach-Object{ $a += StringSplitToArray ";" $_; };
                                                return  ($a | ForEach-Object{ "$rootDir\$_" }); }
function FsEntryGetFileNameWithoutExt         ( [String] $fsEntry ){ 
                                                return [String] [System.IO.Path]::GetFileNameWithoutExtension((FsEntryRemoveTrailingBackslash $fsEntry)); }
function FsEntryGetFileName                   ( [String] $fsEntry ){ 
                                                return [String] [System.IO.Path]::GetFileName((FsEntryRemoveTrailingBackslash $fsEntry)); }
function FsEntryGetFileExtension              ( [String] $fsEntry ){ 
                                                return [String] [System.IO.Path]::GetExtension((FsEntryRemoveTrailingBackslash $fsEntry)); }
function FsEntryMakeAbsolutePath              ( [String] $dirWhenFsEntryIsRelative, [String] $fsEntryRelativeOrAbsolute ){ 
                                                return [String] (FsEntryGetAbsolutePath ([System.IO.Path]::Combine($dirWhenFsEntryIsRelative,$fsEntryRelativeOrAbsolute))); }
function FsEntryGetDrive                      ( [String] $fsEntry ){ # ex: "C:"
                                                return [String] (Split-Path -Qualifier (FsEntryGetAbsolutePath $fsEntry)); }
function FsEntryIsDir                         ( [String] $fsEntry ){ return [Boolean] (Get-Item -Force -LiteralPath $fsEntry).PSIsContainer; } # empty string not allowed
function FsEntryGetParentDir                  ( [String] $fsEntry ){ # returned path does not contain trailing backslash; for c:\ or \\mach\share it return "";
                                                return [String] (Split-Path -LiteralPath (FsEntryGetAbsolutePath $fsEntry)); }
function FsEntryExists                        ( [String] $fsEntry ){ 
                                                return [Boolean] (DirExists $fsEntry) -or (FileExists $fsEntry); }
function FsEntryNotExists                     ( [String] $fsEntry ){ 
                                                return [Boolean] -not (FsEntryExists $fsEntry); }
function FsEntryAssertExists                  ( [String] $fsEntry, [String] $text = "Assertion failed" ){ 
                                                if( !(FsEntryExists $fsEntry) ){ throw [Exception] "$text because fs entry not exists: '$fsEntry'"; } }
function FsEntryAssertNotExists               ( [String] $fsEntry, [String] $text = "Assertion failed" ){ 
                                                if(  (FsEntryExists $fsEntry) ){ throw [Exception] "$text because fs entry already exists: '$fsEntry'"; } }
function FsEntryGetLastModified               ( [String] $fsEntry ){ 
                                                return [DateTime] (Get-Item -Force -LiteralPath $fsEntry).LastWriteTime; }
function FsEntryNotExistsOrIsOlderThanNrDays  ( [String] $fsEntry, [Int32] $maxAgeInDays ){ 
                                                return [Boolean] ((FsEntryNotExists $fsEntry) -or ((FsEntryGetLastModified $fsEntry).AddDays($maxAgeInDays) -lt (Get-Date))); }
function FsEntrySetAttributeReadOnly          ( [String] $fsEntry, [Boolean] $val ){ 
                                                OutProgress "FsFileSetAttributeReadOnly $fsEntry $val"; Set-ItemProperty (FsEntryEsc $fsEntry) -name IsReadOnly -value $val; }
function FsEntryFindFlatSingleByPattern       ( [String] $fsEntryPattern ){ 
                                                [System.IO.FileSystemInfo[]] $r = @()+(Get-ChildItem -Force -ErrorAction SilentlyContinue -Path $fsEntryPattern);
                                                if( $r.Count -eq 0 ){ throw [Exception] "No file exists: '$fsEntryPattern'"; }
                                                if( $r.Count -gt 1 ){ throw [Exception] "More than one file exists: '$fsEntryPattern'"; }
                                                return [String] $r[0].FullName; }
function FsEntryFsInfoFullNameDirWithBackSlash( [System.IO.FileSystemInfo] $fsInfo ){ return [String] ($fsInfo.FullName+$(switch($fsInfo.PSIsContainer){($true){"\"}default{""}})); }
function FsEntryListAsFileSystemInfo          ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
                                                # List entries specified by a pattern, which applies to files and directories and which can contain wildards (*,?). 
                                                # If inclTopDir is true (and includeDirs is true and no wildcards are used and so a single dir is specified) then the dir itself is included. 
                                                # Examples for fsEntryPattern: "C:\*.tmp", ".\dir\*.tmp", "dir\te?*.tmp", "*\dir\*.tmp", "dir\*", "bin\".
                                                # Output is unsorted. Ignores case and access denied conditions. If not found an entry then an empty array is returned.
                                                # It works with absolute or relative paths. A leading ".\" for relative paths is optional.
                                                # If recursive is specified then it applies pattern matching of last specified part (.\*.tmp;.\Bin\) in each sub dir.
                                                # Wildcards on parent dir parts are also allowed ("dir*\*.tmp","*\*.tmp").
                                                # It work as intuitive as possible, but here are more detail specifications:
                                                #   If no wildcards are used then behaviour is the following: 
                                                #     In non-recursive mode and if pattern matches a file (".\f.txt") then it is listed, 
                                                #     and if pattern matches a dir (".\dir") its content is listed flat.
                                                #     In recursive mode the last backslash separated part of the pattern ("f.txt" or "dir") is searched in two steps,
                                                #     first if it matches a file (".\f.txt") then it is listed, and if matches a dir (".\dir") then its content is listed deeply,
                                                #     second if pattern was not yet found then searches it recursively but if it is a dir then its content is not listed.
                                                # Trailing backslashes:  Are handled in powershell quite curious: 
                                                #   In non-recursive mode they are handled as they are not present, so files are also matched ("*\myfile\").
                                                #   In recursive mode they wrongly match only files and not directories ("*\myfile\") and
                                                #   so parent dir parts (".\*\dir\" or "d1\dir\") would not be found for unknown reasons.
                                                #   So we interpret a trailing backslash as it would not be present with the exception that
                                                #   if pattern contains a trailing backslash then pattern "\*\" will be replaced by ("\.\").
                                                Assert ($fsEntryPattern -ne "") "pattern is empty";
                                                [String] $pa = $fsEntryPattern;
                                                [Boolean] $trailingBackslashMode = (FsEntryHasTrailingBackslash $pa);
                                                if( $trailingBackslashMode ){
                                                  $pa = FsEntryRemoveTrailingBackslash $pa;
                                                }
                                                OutVerbose "FsEntryListAsFileSystemInfo '$pa' recursive=$recursive includeDirs=$includeDirs includeFiles=$includeFiles";
                                                [System.IO.FileSystemInfo[]] $result = @();
                                                if( $trailingBackslashMode -and $pa.Contains("\*\") ){
                                                  # enable that ".\*\dir\" can also find dir as top dir
                                                  $pa = $pa.Replace("\*\","\.\"); # otherwise Get-ChildItem would find dirs.
                                                }
                                                if( $inclTopDir -and $includeDirs -and -not ($pa -eq "*" -or $pa.EndsWith("\*")) ){
                                                  $result += (Get-Item -Force -ErrorAction SilentlyContinue -Path $pa) | Where-Object{ $_.PSIsContainer } | Where-Object{ $_ -ne $null };
                                                }
                                                $result += (Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse:$recursive -Path $pa | 
                                                  Where-Object{ ($includeDirs -and $includeFiles) -or ($includeDirs -and $_.PSIsContainer) -or ($includeFiles -and -not $_.PSIsContainer) });
                                                return $result; }
function FsEntryListAsStringArray             ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
                                                # Output of directories will have a trailing backslash. more see FsEntryListAsFileSystemInfo.
                                                return [String[]] (@() + (FsEntryListAsFileSystemInfo $fsEntryPattern $recursive $includeDirs $includeFiles $inclTopDir |
                                                  ForEach-Object{ FsEntryFsInfoFullNameDirWithBackSlash $_} )); }
function FsEntryDelete                        ( [String] $fsEntry ){ 
                                                if( $fsEntry.EndsWith("\") ){ DirDelete $fsEntry; }else{ FileDelete $fsEntry; } }
function FsEntryDeleteToRecycleBin            ( [String] $fsEntry ){
                                                Add-Type -AssemblyName Microsoft.VisualBasic;
                                                [String] $e = FsEntryGetAbsolutePath $fsEntry;
                                                OutProgress "FsEntryDeleteToRecycleBin '$e'";
                                                FsEntryAssertExists $e "Not exists: '$e'";
                                                if( FsEntryIsDir $e ){ [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($e,'OnlyErrorDialogs','SendToRecycleBin');
                                                }else{                 [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($e,'OnlyErrorDialogs','SendToRecycleBin'); } }
function FsEntryRename                        ( [String] $fsEntryFrom, [String] $fsEntryTo ){ 
                                                OutProgress "FsEntryRename '$fsEntryFrom' '$fsEntryTo'"; 
                                                FsEntryAssertExists $fsEntryFrom; FsEntryAssertNotExists $fsEntryTo; 
                                                Rename-Item -Path (FsEntryGetAbsolutePath (FsEntryRemoveTrailingBackslash $fsEntryFrom)) -newName (FsEntryGetAbsolutePath (FsEntryRemoveTrailingBackslash $fsEntryTo)) -force; }
function FsEntryCreateSymLink                 ( [String] $newSymLink, [String] $fsEntryOrigin ){ # for files or dirs, relative or absolute origin must exists, its stupid but it requires elevated rights (junctions (=~symlinksToDirs) do not) (https://superuser.com/questions/104845/permission-to-make-symbolic-links-in-windows-7/105381).
                                                New-Item -ItemType SymbolicLink -Name (FsEntryEsc $newSymLink) -Value (FsEntryEsc $fsEntryOrigin); }
function FsEntryCreateHardLink                ( [String] $newHardLink, [String] $fsEntryOrigin ){ # for files or dirs, origin must exists, it requires elevated rights.
                                                New-Item -ItemType HardLink -Name (FsEntryEsc $newHardLink) -Value (FsEntryEsc $fsEntryOrigin); }
function FsEntryCreateDirSymLink              ( [String] $symLinkDir, [String] $symLinkOriginDir ){ # creates junctions which are symlinks to dirs with some slightly other behaviour around privileges and local/remote usage
                                                if( !(DirExists $symLinkOriginDir)  ){ throw [Exception] "Cannot create dir sym link because original directory not exists: '$symLinkOriginDir'"; }
                                                FsEntryAssertNotExists $symLinkDir "Cannot create dir sym link";
                                                [String] $cd = Get-Location;
                                                Set-Location (FsEntryGetParentDir $symLinkDir);
                                                [String] $symLinkName = FsEntryGetFileName $symLinkDir;
                                                & "cmd.exe" "/c" ('mklink /J "'+$symLinkName+'" "'+$symLinkOriginDir+'"'); AssertRcIsOk;
                                                Set-Location $cd; }
function FsEntryReportMeasureInfo             ( [String] $fsEntry ){ # must exists, works recursive
                                                if( FsEntryNotExists $fsEntry ){ throw [Exception] "File system entry not exists: '$fsEntry'"; }
                                                [Microsoft.PowerShell.Commands.GenericMeasureInfo] $size = Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse -LiteralPath $fsEntry |
                                                  Measure-Object -Property length -sum;
                                                if( $size -eq $null ){ return [String] "SizeInBytes=0; NrOfFsEntries=0;"; }
                                                return [String] "SizeInBytes=$($size.sum); NrOfFsEntries=$($size.count);"; }
function FsEntryCreateParentDir               ( [String] $fsEntry ){ [String] $dir = FsEntryGetParentDir $fsEntry; DirCreate $dir; }
function FsEntryMoveByPatternToDir            ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $showProgressFiles = $false ){ # target dir must exists
                                                OutProgress "FsEntryMoveByPatternToDir '$fsEntryPattern' to '$targetDir'"; DirAssertExists $targetDir;
                                                FsEntryListAsStringArray $fsEntryPattern | Sort-Object | 
                                                  ForEach-Object{ if( $showProgressFiles ){ OutProgress "Source: $_"; }; Move-Item -Force -Path $_ -Destination (FsEntryEsc $targetDir); }; }
function FsEntryCopyByPatternByOverwrite      ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $continueOnErr = $false ){
                                                OutProgress "FsEntryCopyByPatternByOverwrite '$fsEntryPattern' to '$targetDir' continueOnErr=$continueOnErr";
                                                DirCreate $targetDir; Copy-Item -ErrorAction SilentlyContinue -Recurse -Force -Path $fsEntryPattern -Destination (FsEntryEsc $targetDir);
                                                if( -not $? ){ if( ! $continueOnErr ){ AssertRcIsOk; }else{ OutWarning "CopyFiles '$fsEntryPattern' to '$targetDir' failed, will continue"; } } }
function FsEntryFindNotExistingVersionedName  ( [String] $fsEntry, [String] $ext = ".bck", [Int32] $maxNr = 9999 ){ # return ex: "C:\Dir\MyName.001.bck"
                                                $fsEntry = (FsEntryGetAbsolutePath $fsEntry);
                                                while( $fsEntry.EndsWith('\') ){ $fsEntry = $fsEntry.Remove($fsEntry.Length-1); }
                                                if( $fsEntry.EndsWith('\') ){ throw [Exception] "$(ScriptGetCurrentFunc)($fsEntry) not available because has trailing backslash"; }
                                                if( $fsEntry.Length -gt (260-4-$ext.Length) ){ throw [Exception] "$(ScriptGetCurrentFunc)($fsEntry,$ext) not available because fullpath longer than 260-4-extLength"; }
                                                [Int32] $n = 1; do{ [String] $newFs = $fsEntry + "." + $n.ToString("D3")+$ext; if( (FsEntryNotExists $newFs) ){ return [String] $newFs; } $n += 1; }until( $n -gt $maxNr );
                                                throw [Exception] "$(ScriptGetCurrentFunc)($fsEntry,$ext,$maxNr) not available because reached maxNr"; }
function FsEntryAclGet                        ( [String] $fsEntry ){
                                                ProcessRestartInElevatedAdminMode;
                                                return [System.Security.AccessControl.FileSystemSecurity] (Get-Acl -Path (FsEntryEsc $fsEntry)); }
function FsEntryAclSetInheritance             ( [String] $fsEntry ){
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry; 
                                                if( $acl.AreAccessRulesProtected ){
                                                  [Boolean] $isProtected = $false; [Boolean] $preserveInheritance = $true;
                                                  $acl.SetAccessRuleProtection($isProtected,$preserveInheritance);
                                                  Set-Acl -AclObject $acl -Path (FsEntryEsc $fsEntry);
                                                } }
function FsEntryAclRuleWrite                  ( [String] $modeSetAddOrDel, [String] $fsEntry, [System.Security.AccessControl.FileSystemAccessRule] $rule, [Boolean] $recursive = $false ){ # $modeSetAddOrDel = "Set", "Add", "Del".
                                                OutProgress "FsEntryAclRuleWrite $modeSetAddOrDel '$fsEntry' '$(PrivFsRuleAsString $rule)'"; 
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry; 
                                                if    ( $modeSetAddOrDel -eq "Set" ){ $acl.SetAccessRule($rule); } 
                                                elseif( $modeSetAddOrDel -eq "Add" ){ $acl.AddAccessRule($rule); }
                                                elseif( $modeSetAddOrDel -eq "Del" ){ $acl.RemoveAccessRule($rule); } 
                                                else{ throw [Exception] "For modeSetAddOrDel expected 'Set', 'Add' or 'Del' but got '$modeSetAddOrDel'"; } 
                                                Set-Acl -Path (FsEntryEsc $fsEntry) -AclObject $acl; <# Set-Acl does set or add #>
                                                if( $recursive -and (FsEntryIsDir $fsEntry) ){
                                                  FsEntryListAsStringArray "$fsEntry\*" $false | ForEach-Object{ FsEntryAclRuleWrite $modeSetAddOrDel $_ $rule $true };
                                                } }
function FsEntryTrySetOwner                   ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){ # usually account is (PrivGetGroupAdministrators)
                                                ProcessRestartInElevatedAdminMode; 
                                                PrivEnableTokenPrivilege SeTakeOwnershipPrivilege; PrivEnableTokenPrivilege SeRestorePrivilege; PrivEnableTokenPrivilege SeBackupPrivilege;
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry; 
                                                try{
                                                  [System.IO.FileSystemInfo] $fs = Get-Item -Force -LiteralPath $fsEntry;
                                                  if( $acl.Owner -ne $account ){
                                                    OutProgress "FsEntryTrySetOwner '$fsEntry' '$($account.ToString())'"; 
                                                    if( $fs.PSIsContainer ){
                                                      try{
                                                        $fs.SetAccessControl((PrivDirSecurityCreateOwner $account));
                                                      }catch{
                                                        OutProgress "taking ownership of dir '$($fs.FullName)' failed so setting fullControl for administrators of its parent '$($fs.Parent.FullName)'";
                                                        $fs.Parent.SetAccessControl((PrivDirSecurityCreateFullControl (PrivGetGroupAdministrators)));
                                                        $fs.SetAccessControl((PrivDirSecurityCreateOwner $account));
                                                      }
                                                    }else{
                                                      try{
                                                        $fs.SetAccessControl((PrivFileSecurityCreateOwner $account));
                                                      }catch{
                                                        OutProgress "taking ownership of file '$($fs.FullName)' failed so setting fullControl for administrators of its dir '$($fs.Directory.FullName)'";
                                                        $fs.Directory.SetAccessControl((PrivDirSecurityCreateFullControl (PrivGetGroupAdministrators)));
                                                        $fs.SetAccessControl((PrivFileSecurityCreateOwner $account));
                                                      }
                                                    } }
                                                  if( $recursive -and $fs.PSIsContainer ){
                                                    FsEntryListAsStringArray "$fs\*" $false | ForEach-Object{ FsEntryTrySetOwner $_ $account $true };
                                                  }
                                                }catch{
                                                  OutWarning "Ignoring: FsEntryTrySetOwner($fsEntry,$account) failed because $($_.Exception.Message)";
                                                } }
function FsEntryTrySetOwnerAndAclsIfNotSet    ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry;
                                                if( $acl.Owner -ne $account ){
                                                  FsEntryTrySetOwner $fsEntry $account $false;
                                                  $acl = FsEntryAclGet $fsEntry;
                                                }
                                                [Boolean] $isDir = FsEntryIsDir $fsEntry;
                                                $rule = (PrivFsRuleCreateFullControl $account $isDir);
                                                if( -not (PrivAclHasFullControl $acl $account $isDir) ){
                                                  FsEntryAclRuleWrite Set $fsEntry $rule $false;
                                                }
                                                if( $recursive -and $isDir ){
                                                  FsEntryListAsStringArray "$fsEntry\*" $false | ForEach-Object{ FsEntryTrySetOwnerAndAclsIfNotSet $_ $account $true };
                                                } }
function FsEntryTryForceRenaming              ( [String] $fsEntry, [String] $extension ){
                                                if( (FsEntryExists $fsEntry) ){
                                                  ProcessRestartInElevatedAdminMode; # because rename os files and change acls
                                                  [String] $newFileName = (FsEntryFindNotExistingVersionedName $fsEntry $extension);
                                                  try{
                                                    FsEntryRename $fsEntry $newFileName;
                                                  }catch{
                                                    # ex: System.UnauthorizedAccessException: Der Zugriff auf den Pfad wurde verweigert. bei System.IO.__Error.WinIOError(Int32 errorCode, String maybeFullPath) bei System.IO.FileInfo.MoveTo(String destFileName)
                                                    OutProgress "Force set owner to administrators and retry because FsEntryRename($fsEntry,$newFileName) failed because $($_.Exception.Message)";
                                                    [System.Security.Principal.IdentityReference] $account = PrivGetGroupAdministrators; 
                                                    [System.Security.AccessControl.FileSystemAccessRule] $rule = PrivFsRuleCreateFullControl $account (FsEntryIsDir $fsEntry); 
                                                    try{
                                                      # maybe for future: PrivEnableTokenPrivilege SeTakeOwnershipPrivilege; PrivEnableTokenPrivilege SeRestorePrivilege; PrivEnableTokenPrivilege SeBackupPrivilege;
                                                      [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry; 
                                                      if( $acl.Owner -ne (PrivGetGroupAdministrators) ){
                                                        OutProgress "FsEntrySetOwner '$fsEntry' '$($account.ToString())'";
                                                        $acl.SetOwner($account); Set-Acl -Path $fsEntry -AclObject $acl;
                                                      }
                                                      FsEntryAclRuleWrite "Set" $fsEntry $rule;
                                                      FsEntryRename $fsEntry $newFileName;
                                                    }catch{
                                                      OutWarning "Ignoring: FsEntryRename($fsEntry,$newFileName) failed because $($_.Exception.Message)";
                                                    } } } }
function FsEntryResetTs                       ( [String] $fsEntry, [Boolean] $recursive, [String] $tsInIsoFmt = "2000-01-01 00:00" ){
                                                # Overwrite LastWriteTime, CreationTime and LastAccessTime. Drive ts cannot be changed and so are ignored. Used for example to anonymize ts.
                                                [DateTime] $ts = DateTimeFromStringIso $tsInIsoFmt;
                                                OutProgress "FsEntrySetTs `"$fsEntry`" recursive=$recursive ts=$(DateTimeAsStringIso $ts)"; 
                                                FsEntryAssertExists $fsEntry; [Boolean] $inclDirs = $true;
                                                if( -not (FsEntryIsDir $fsEntry) ){ $recursive = $false; $inclDirs = $false; }
                                                FsEntryListAsFileSystemInfo $fsEntry $recursive $true $true $true | Where-Object{ $_ -ne $null } | ForEach-Object{ 
                                                  [String] $f = $(FsEntryFsInfoFullNameDirWithBackSlash $_);
                                                  OutProgress "Set $(DateTimeAsStringIso $ts) of $(DateTimeAsStringIso $_.LastWriteTime) $f";
                                                  try{ $_.LastWriteTime = $ts; $_.CreationTime = $ts; $_.LastAccessTime = $ts; }catch{
                                                    OutWarning "Ignoring: SetTs($f) failed because $($_.Exception.Message)";                                                    
                                                  }
                                                }; }
function DriveFreeSpace                       ( [String] $drive ){ 
                                                return [Int64] (Get-PSDrive $drive | Select-Object -ExpandProperty Free); }
function DirExists                            ( [String] $dir ){ 
                                                try{ return [Boolean] (Test-Path -PathType Container -LiteralPath $dir); }catch{ throw [Exception] "$(ScriptGetCurrentFunc)($dir) failed because $($_.Exception.Message)"; } }
function DirAssertExists                      ( [String] $dir ){ 
                                                if( -not (DirExists $dir) ){ throw [Exception] "Dir not exists: '$dir'."; } }
function DirCreate                            ( [String] $dir ){
                                                New-Item -type directory -Force (FsEntryEsc $dir) | Out-Null; } # create dir if it not yet exists,;we do not call OutProgress because is not an important change.
function DirCreateTemp                        ( [String] $prefix = "" ){ while($true){
                                               [String] $d = Join-Path ([System.IO.Path]::GetTempPath()) ($prefix + [System.IO.Path]::GetRandomFileName().Replace(".",""));
                                               if( FsEntryNotExists $d ){ DirCreate $d; return $d; } } }
function DirDelete                            ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                # remove dir recursively if it exists, be careful when using this.
                                                if( (DirExists $dir) ){ 
                                                  try{ OutProgress "DirDelete$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) '$dir'"; Remove-Item -Force:$ignoreReadonly -Recurse -LiteralPath $dir; 
                                                  }catch{ <# ex: Für das Ausführen des Vorgangs sind keine ausreichenden Berechtigungen vorhanden. #> 
                                                    throw [Exception] "$(ScriptGetCurrentFunc)$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}})('$dir') failed because $($_.Exception.Message) (maybe locked or readonly files exists)"; } } }
function DirDeleteContent                     ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                # remove dir content if it exists, be careful when using this.
                                                if( (DirExists $dir) -and (@()+(Get-ChildItem -Force -Directory -LiteralPath $dir)).Count -gt 0 ){ 
                                                  try{ OutProgress "DirDeleteContent$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) '$dir'"; 
                                                    Remove-Item -Force:$ignoreReadonly -Recurse "$(FsEntryEsc $dir)\*"; 
                                                  }catch{ <# ex: Für das Ausführen des Vorgangs sind keine ausreichenden Berechtigungen vorhanden. #> 
                                                    throw [Exception] "$(ScriptGetCurrentFunc)$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}})('$dir') failed because $($_.Exception.Message) (maybe locked or readonly files exists)"; } } }
function DirDeleteIfIsEmpty                   ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                if( (DirExists $dir) -and (@()+(Get-ChildItem -Force -LiteralPath $dir)).Count -eq 0 ){ DirDelete $dir; } }
function DirCopyToParentDirByAddAndOverwrite  ( [String] $srcDir, [String] $tarParentDir ){ 
                                                OutProgress "DirCopyToParentDirByAddAndOverwrite '$srcDir' to '$tarParentDir'"; 
                                                if( -not (DirExists $srcDir) ){ throw [Exception] "Missing source dir '$srcDir'"; } 
                                                DirCreate $tarParentDir; Copy-Item -Force -Recurse (FsEntryEsc $srcDir) (FsEntryEsc $tarParentDir); }
function FileGetSize                          ( [String] $file ){ 
                                                return [Int64] (Get-ChildItem -Force -File -LiteralPath $file).Length; }
function FileExists                           ( [String] $file ){ 
                                                if( $file -eq "" ){ throw [Exception] "$(ScriptGetCurrentFunc): Empty file name not allowed"; } 
                                                [String] $f2 = FsEntryGetAbsolutePath $file; if( Test-Path -PathType Leaf -LiteralPath $f2 ){ return $true; }
                                                # Note: Known bug: Test-Path does not work for hidden and system files, so we need an additional check.
                                                # Note2: The following would not works on vista and win7-with-ps2: [String] $d = Split-Path $f2; return ([System.IO.Directory]::EnumerateFiles($d) -contains $f2);
                                                return [System.IO.File]::Exists($f2); }
function FileNotExists                        ( [String] $file ){ 
                                                return [Boolean] -not (FileExists $file); }
function FileAssertExists                     ( [String] $file ){ 
                                                if( (FileNotExists $file) ){ throw [Exception] "File not exists: '$file'."; } }
function FileExistsAndIsNewer                 ( [String] $ftar, [String] $fsrc ){
                                                FileAssertExists $fsrc; return [Boolean] ((FileExists $ftar) -and ((FsEntryGetLastModified $ftar) -ge (FsEntryGetLastModified $fsrc))); }
function FileNotExistsOrIsOlder               ( [String] $ftar, [String] $fsrc ){ 
                                                return [Boolean] -not (FileExistsAndIsNewer $ftar $fsrc); }
function FileReadContentAsString              ( [String] $file ){ 
                                                return [String] (FileReadContentAsLines $file | Out-String -Width ([Int32]::MaxValue)); }
function FileReadContentAsLines               ( [String] $file ){ 
                                                # Note: if BOM exists then this is interpreted.
                                                OutVerbose "FileRead $file"; return [String[]] (Get-Content -Encoding Default -LiteralPath $file); }
function FileReadJsonAsObject                 ( [String] $jsonFile ){ 
                                                Get-Content -Raw -Path $jsonFile | ConvertFrom-Json; }
function FileWriteFromString                  ( [String] $file, [String] $content, [Boolean] $overwrite = $true, [String] $encoding = "UTF8" ){
                                                # will create path of file. overwrite does ignore readonly attribute.
                                                OutProgress "WriteFile $file"; FsEntryCreateParentDir $file; 
                                                Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -Inputobject $content -LiteralPath $file; }
                                                # alternative: Set-Content -Encoding $encoding -Path (FsEntryEsc $file) -Value $content; but this would lock file, and see http://stackoverflow.com/questions/10655788/powershell-set-content-and-out-file-what-is-the-difference
function FileWriteFromLines                   ( [String] $file, [String[]] $lines, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){ 
                                                OutProgress "WriteFile $file"; FsEntryCreateParentDir $file; $lines | Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -LiteralPath $file; }
function FileCreateEmpty                      ( [String] $file, [Boolean] $overwrite = $false, [Boolean] $quiet = $false ){ if( -not $quiet -and $overwrite ){ OutProgress "FileCreateEmpty-ByOverwrite $file"; } FsEntryCreateParentDir $file; Out-File -Force -NoClobber:$(-not $overwrite) -Encoding ASCII -LiteralPath $file; }
function FileAppendLineWithTs                 ( [String] $file, [String] $line ){ FileAppendLine $file "$(DateTimeNowAsStringIso "yyyy-MM-dd HH:mm") $line"; }
function FileAppendLine                       ( [String] $file, [String] $line, [Boolean] $tsPrefix = $false ){ 
                                                FsEntryCreateParentDir $file; Out-File -Encoding Default -Append -LiteralPath $file -InputObject $line; }
function FileAppendLines                      ( [String] $file, [String[]] $lines ){ 
                                                FsEntryCreateParentDir $file; $lines | Out-File -Encoding Default -Append -LiteralPath $file; }
function FileGetTempFile                      (){ return [Object] [System.IO.Path]::GetTempFileName(); }
function FileDelTempFile                      ( [String] $file ){ if( (FileExists $file) ){ OutDebug "FileDelete -Force '$file'"; Remove-Item -Force -LiteralPath $file; } } # as FileDelete but no progress msg
function FileReadEncoding                     ( [String] $file ){
                                                # read BOM = Byte order mark.
                                                [Byte[]] $b = Get-Content -Encoding Byte -ReadCount 4 -TotalCount 4 -LiteralPath $file; # works also when lesser than 4 bytes
                                                if($b.Length -ge 3 -and $b[0] -eq 0xef -and $b[1] -eq 0xbb -and $b[2] -eq 0xbf                     ){ return [String] "UTF8"             ; } # codepage=65001;
                                                if($b.Length -ge 2 -and $b[0] -eq 0xff -and $b[1] -eq 0xfe                                         ){ return [String] "UTF16LittleEndian"; } # codepage= 1200;
                                                if($b.Length -ge 2 -and $b[0] -eq 0xfe -and $b[1] -eq 0xff                                         ){ return [String] "UTF16BigEndian"   ; } # codepage= 1201;
                                                if($b.Length -ge 4 -and $b[0] -eq 0xff -and $b[1] -eq 0xfe -and $b[2] -eq 0x00 -and $b[3] -eq 0x00 ){ return [String] "UTF32LittleEndian"; } # codepage=12000;
                                                if($b.Length -ge 4 -and $b[0] -eq 0x00 -and $b[1] -eq 0x00 -and $b[2] -eq 0xfe -and $b[3] -eq 0xff ){ return [String] "UTF32BigEndian"   ; } # codepage=12001;
                                                if($b.Length -ge 4 -and $b[0] -eq 0x2b -and $b[1] -eq 0x2f -and $b[2] -eq 0x76 -and $b[3] -eq 0x38 ){ return [String] "UTF7"             ; }
                                                if($b.Length -ge 4 -and $b[0] -eq 0x2b -and $b[1] -eq 0x2f -and $b[2] -eq 0x76 -and $b[3] -eq 0x39 ){ return [String] "UTF7"             ; }
                                                if($b.Length -ge 4 -and $b[0] -eq 0x2b -and $b[1] -eq 0x2f -and $b[2] -eq 0x76 -and $b[3] -eq 0x2B ){ return [String] "UTF7"             ; }
                                                if($b.Length -ge 4 -and $b[0] -eq 0x2b -and $b[1] -eq 0x2f -and $b[2] -eq 0x76 -and $b[3] -eq 0x2F ){ return [String] "UTF7"             ; }
                                                if($b.Length -ge 3 -and $b[0] -eq 0xf7 -and $b[1] -eq 0x64 -and $b[2] -eq 0x4c                     ){ return [String] "UTF1"             ; }
                                                if($b.Length -ge 4 -and $b[0] -eq 0xdd -and $b[1] -eq 0x73 -and $b[2] -eq 0x66 -and $b[3] -eq 0x73 ){ return [String] "UTF-EBCDIC"       ; }
                                                if($b.Length -ge 3 -and $b[0] -eq 0x0e -and $b[1] -eq 0xfe -and $b[2] -eq 0xff                     ){ return [String] "SCSU"             ; }
                                                if($b.Length -ge 4 -and $b[0] -eq 0xfb -and $b[1] -eq 0xee -and $b[2] -eq 0x28                     ){ return [String] "BOCU-1"           ; }
                                                if($b.Length -ge 4 -and $b[0] -eq 0x84 -and $b[1] -eq 0x31 -and $b[2] -eq 0x95 -and $b[3] -eq 0x33 ){ return [String] "GB-18030"         ; }
                                                else                                                                                                { return [String] "Default"          ; } } # codepage=1252; =ANSI
function FileTouch                            ( [String] $file ){ OutProgress "Touch: `"$file`""; if( FileExists $file ){ (Get-Item -Force -LiteralPath $file).LastWriteTime = (Get-Date); }else{ FileCreateEmpty $file; } }
function FileContentsAreEqual                 ( [String] $f1, [String] $f2, [Boolean] $allowSecondFileNotExists = $true ){ # first file must exist
                                                FileAssertExists $f1; if( $allowSecondFileNotExists -and -not (FileExists $f2) ){ return $false; }
                                                [System.IO.FileInfo] $fi1 = Get-Item -Force -LiteralPath $f1; [System.IO.FileStream] $fs1 = $null;
                                                [System.IO.FileInfo] $fi2 = Get-Item -Force -LiteralPath $f2; [System.IO.FileStream] $fs2 = $null;
                                                [Int64] $BlockSizeInBytes = 32768; [Int32] $nrOfBlocks = [Math]::Ceiling($fi1.Length/$BlockSizeInBytes);
                                                [Byte[]] $a1 = New-Object byte[] $BlockSizeInBytes;
                                                [Byte[]] $a2 = New-Object byte[] $BlockSizeInBytes;
                                                if( $false ){ # much more performant (20 sec for 5 GB file)
                                                  if( $fi1.Length -ne $fi2.Length ){ return $false; } & "fc.exe" "/b" ($fi1.FullName) ($fi2.FullName) > $null; if( $? ){ return $true; } ScriptResetRc; return $false;
                                                }else{ # slower but more portable (longer than 5 min)
                                                  try{ $fs1 = $fi1.OpenRead(); $fs2 = $fi2.OpenRead(); [Int64] $dummyNrBytesRead = 0;
                                                    for( [Int32] $b = 0; $b -lt $nrOfBlocks; $b++ ){
                                                      $dummyNrBytesRead = $fs1.Read($a1,0,$BlockSizeInBytes); 
                                                      $dummyNrBytesRead = $fs2.Read($a2,0,$BlockSizeInBytes); 
                                                      # note: this is probably too slow, so took it inline: if( -not (ByteArraysAreEqual $a1 $a2) ){ return [Boolean] $false; }
                                                      if( $a1.Length -ne $a2.Length ){ return $false; } 
                                                      for( [Int64] $i = 0; $i -lt $a1.Length; $i++ ){ if( $a1[$i] -ne $a2[$i] ){ return $false; } }
                                                    } return [Boolean] $true;
                                                  }finally{ $fs1.Close(); $fs2.Close(); } }
                                                }
function FileDelete                           ( [String] $file, [Boolean] $ignoreReadonly = $true ){
                                                if( (FileExists $file) ){ OutProgress "FileDelete$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) '$file'"; 
                                                  Remove-Item -Force:$ignoreReadonly -LiteralPath $file; } }
function FileCopy                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){ 
                                                OutProgress "FileCopy(Overwrite=$overwrite) '$srcFile' to '$tarFile' $(switch($(FileExists $(FsEntryEsc $tarFile))){($true){'(Target exists)'}default{''}})"; 
                                                FsEntryCreateParentDir $tarFile; Copy-Item -Force:$overwrite (FsEntryEsc $srcFile) (FsEntryEsc $tarFile); }
function FileMove                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){ 
                                                OutProgress "FileMove(Overwrite=$overwrite) '$srcFile' to '$tarFile' $(switch($(FileExists $(FsEntryEsc $tarFile))){($true){'(Target exists)'}default{''}})"; 
                                                FsEntryCreateParentDir $tarFile; Move-Item -Force:$overwrite -LiteralPath $srcFile -Destination $tarFile; }
function FileGetHexStringOfHash128BitsMd5     ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "MD5"    $srcFile).Hash; }
function FileGetHexStringOfHash256BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA256" $srcFile).Hash; } # 2017-11 ps standard is SHA256, available are: SHA1;SHA256;SHA384;SHA512;MACTripleDES;MD5;RIPEMD160
function FileGetHexStringOfHash512BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA512" $srcFile).Hash; } # 2017-12: this is our standard for ps
function FileUpdateItsHashSha2FileIfNessessary( [String] $srcFile ){
                                                [String] $hashTarFile = "$srcFile.sha2"; 
                                                [String] $hashSrc = FileGetHexStringOfHash512BitsSha2 $srcFile;
                                                [String] $hashTar = $(switch((FileNotExists $hashTarFile) -or (FileGetSize $hashTarFile) -gt 8200){($true){""}default{(FileReadContentAsString $hashTarFile).TrimEnd()}})  ;
                                                if( $hashSrc -eq $hashTar ){
                                                  OutProgress "File is up to date, nothing done with '$hashTarFile'.";
                                                }else{
                                                  Out-File -Encoding UTF8 -LiteralPath $hashTarFile -Inputobject $hashSrc;
                                                  OutProgress "Created '$hashTarFile'."; 
                                                } }
function FileNtfsAlternativeDataStreamAdd     ( [String] $srcFile, [String] $adsName, [String] $val ){ Add-Content -Path $srcFile -Value $val -Stream $adsName; }
function FileNtfsAlternativeDataStreamDel     ( [String] $srcFile, [String] $adsName ){ Clear-Content -Path $srcFile -Stream $adsName; }
function FileAdsDownloadedFromInternetAdd     ( [String] $srcFile ){ FileNtfsAlternativeDataStreamAdd $srcFile 'Zone.Identifier' "[ZoneTransfer]`nZoneId=3"; }
function FileAdsDownloadedFromInternetDel     ( [String] $srcFile ){ FileNtfsAlternativeDataStreamDel $srcFile 'Zone.Identifier'; } # alternative: Unblock-File -LiteralPath $file
function DriveMapTypeToString                 ( [UInt32] $driveType ){
                                                return [String] $(switch($driveType){ 1{"NoRootDir"} 2{"RemovableDisk"} 3{"LocalDisk"} 4{"NetworkDrive"} 5{"CompactDisk"} 6{"RamDisk"} default{"UnknownDriveType=driveType"}}); }
function DriveList                            (){
                                                return [Object[]] (Get-WmiObject "Win32_LogicalDisk" | Select-Object DeviceID, FileSystem, Size, FreeSpace, VolumeName, DriveType, @{Name="DriveTypeName";Expression={(DriveMapTypeToString $_.DriveType)}}, ProviderName); }
function CredentialGetSecureStrFromHexString  ( [String] $text ){ 
                                                return [System.Security.SecureString] (ConvertTo-SecureString $text); } # will throw if it is not an encrypted string
function CredentialGetSecureStrFromText       ( [String] $text ){ 
                                                if( $text -eq "" ){ throw [Exception] "$(ScriptGetCurrentFunc) is not allowed to be called with empty string"; } return [System.Security.SecureString] (ConvertTo-SecureString $text -AsPlainText -Force); }
function CredentialGetHexStrFromSecureString  ( [System.Security.SecureString] $code ){ 
                                                return [String] (ConvertFrom-SecureString $code); } # ex: "ea32f9d30de3d3dc7fcd86a6a8f587ed9"
function CredentialGetTextFromSecureString    ( [System.Security.SecureString] $code ){ 
                                                [Object] $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($code); return [String] [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr); }
function CredentialGetPasswordTextFromCred    ( [System.Management.Automation.PSCredential] $cred ){ 
                                                return [String] $cred.GetNetworkCredential().Password; }
function CredentialWriteToFile                ( [System.Management.Automation.PSCredential] $cred, [String] $file ){ 
                                                FileWriteFromString $file ($cred.UserName+"`r`n"+(CredentialGetHexStrFromSecureString $cred.Password)); }
function CredentialRemoveFile                 ( [String] $file ){ 
                                                OutProgress "CredentialRemoveFile '$file'"; FileDelete $file; }
function CredentialReadUserFromFile           ( [String] $file ){ # return empty if credential file not exists
                                                if( FileNotExists $file ){ return [String]""; }
                                                [System.Management.Automation.PSCredential] $cred = CredentialReadFromFile $file; return $cred.UserName; }
function CredentialReadFromFile               ( [String] $file ){ 
                                                [String[]] $s = StringSplitIntoLines (FileReadContentAsString $secureCredentialFile); 
                                                try{ [String] $us = $s[0]; [System.Security.SecureString] $pwSecure = CredentialGetSecureStrFromHexString $s[1];
                                                  # alternative: New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content -Encoding Default -LiteralPath $File | ConvertTo-SecureString)
                                                  return (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure));
                                                }catch{ throw [Exception] "Credential file '$secureCredentialFile' has not expected format for credentials, you may remove it and retry"; } }
function CredentialReadFromParamOrInput       ( [String] $username = "", [String] $password = "", [String] $requestMessage = "Enter username: " ){ 
                                                [String] $us = $username; 
                                                while( $us -eq "" ){ $us = StdInReadLine $requestMessage; } 
                                                [System.Security.SecureString] $pwSecure = $null; 
                                                if( $password -eq "" ){ $pwSecure = StdInReadLinePw "Enter password for username=$($us): "; }else{ $pwSecure = CredentialGetSecureStrFromText $password; }
                                                return (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure)); }
function CredentialStandardizeUserWithDomain  ( [String] $username ){
                                                # allowed username as input: "", "u0", "u0@domain", "@domain\u0", "domain\u0"   #> <# used because for unknown reasons sometimes a username like user@domain does not work, it requires domain\user.
                                                if( $username.Contains("\") -or -not $username.Contains("@") ){ return $username; } [String[]] $u = $username -split "@",2; return [String] ($u[1]+"\"+$u[0]); }
function CredentialGetAndStoreIfNotExists     ( [String] $secureCredentialFile, [String] $username = "", [String] $password = "", [String] $requestMessage = "Enter username: " ){
                                                # if username or password is empty then they are asked from std input.
                                                # if file exists then it takes credentials from it.
                                                # if file not exists then it is written by given credentials.
                                                [System.Management.Automation.PSCredential] $cred = $null;
                                                if( $secureCredentialFile -ne "" -and (FileExists $secureCredentialFile) ){
                                                  $cred = CredentialReadFromFile $secureCredentialFile;
                                                }else{
                                                  $cred = CredentialReadFromParamOrInput $username $password $requestMessage;
                                                }
                                                if( $secureCredentialFile -ne "" -and (FileNotExists $secureCredentialFile) ){
                                                  CredentialWriteToFile $cred $secureCredentialFile;
                                                }
                                                return $cred; }
function ShareGetTypeName                     ( [UInt32] $typeNr ){ 
                                                return [String] $(switch($typeNr){ 0{"DiskDrive"} 1 {"PrintQueue"} 2{"Device"} 3{"IPC"} 
                                                2147483648{"DiskDriveAdmin"} 2147483649{"PrintQueueAdmin"} 2147483650{"DeviceAdmin"} 2147483651{"IPCAdmin"} default{"unknownNr=$typeNr"} }); }
function ShareGetTypeNr                       ( [String] $typeName ){ 
                                                return [UInt32] $(switch($typeName){ "DiskDrive"{0} "PrintQueue"{1} "Device"{2} "IPC"{3} 
                                                "DiskDriveAdmin"{2147483648} "PrintQueueAdmin"{2147483649} "DeviceAdmin"{2147483650} "IPCAdmin"{2147483651} default{4294967295} }); }
function ShareListAll                         ( [String] $computerName = ".", [String] $selectShareName = "" ){
                                                OutVerbose "List shares of machine=$computerName selectShareName='$selectShareName'";
                                                # exclude: AccessMask,InstallDate,MaximumAllowed,Description,Type,Status,@{Name="Descr";Expression={($_.Description).PadLeft(1,"-")}};
                                                [String] $filter = ""; if( $selectShareName -ne ""){ $filter = "Name='$selectShareName'"; }
                                                # Status: "OK","Error","Degraded","Unknown","Pred Fail","Starting","Stopping","Service","Stressed","NonRecover","No Contact","Lost Comm"
                                                return [PSCustomObject[]] (Get-WmiObject -Class Win32_Share -ComputerName $computerName -Filter $filter | 
                                                  Select-Object @{Name="TypeName";Expression={(ShareGetTypeName $_.Type)}}, @{Name="FullName";Expression={"\\$computerName\"+$_.Name}}, Path, Caption, Name, AllowMaximum, Status | 
                                                  Sort-Object TypeName, Name); }
function ShareRemove                          ( [String] $shareName ){
                                                [Object] $share = Get-WmiObject -Class Win32_Share -ComputerName "." -Filter "Name='$shareName'";
                                                if( $share -eq $null ){ return; }
                                                OutProgress "Remove shareName='$shareName' typeName=$(ShareGetTypeName $share.Type) path=$($share.Path)"; 
                                                [Object] $obj = $share.delete();
                                                [Int32] $rc = $obj.ReturnValue;
                                                if( $rc -ne 0 ){
                                                  [String] $errMsg = switch( $rc ){
                                                    # note: the following list was taken from create-fails, so it is not verified.
                                                    0{"Ok, Success"}
                                                    2{"Access denied"}
                                                    8{"Unknown failure"}
                                                    9{"Invalid name"}
                                                    10{"Invalid level"}
                                                    21{"Invalid parameter"}
                                                    22{"Duplicate share"}
                                                    23{"Redirected path"}
                                                    24{"Unknown device or directory"}
                                                    25{"Net name not found"}
                                                    default{"Unknown rc=$rc"}
                                                  }
                                                  throw [Exception] "$(ScriptGetCurrentFunc)(sharename='$shareName') failed because $errMsg";
                                                } }
function ShareCreate                          ( [String] $shareName, [String] $dir, [String] $typeName = "DiskDrive", [Int32] $nrOfAccessUsers = 25, [String] $descr = "", [Boolean] $ignoreIfAlreadyExists = $true ){
                                                if( !(DirExists $dir)  ){ throw [Exception] "Cannot create share because original directory not exists: '$dir'"; }
                                                FsEntryAssertExists $dir "Cannot create share";
                                                [UInt32] $typeNr = ShareGetTypeNr $typeName;
                                                [Object] $existingShare = ShareListAll "." $shareName | Where-Object{ $_.Path -ieq $dir -and $_.TypeName -eq $typeName } | Select-Object -First 1;
                                                if( $existingShare -ne $null ){
                                                  OutVerbose "Already exists shareName='$shareName' dir='$dir' typeName=$typeName"; 
                                                  if( $ignoreIfAlreadyExists ){ return; }
                                                }
                                                # Optionals:
                                                # MaximumAllowed. With this parameter, you can specify the maximum number of users allowed to concurrently use the shared resource (e.g., 25 users).
                                                # Description. You use this parameter to describe the resource being shared (e.g., temp share).
                                                # Password. Using this parameter, you can set a password for the shared resource on a server that is running with share-level security. If the server is running with user-level security, this parameter is ignored.
                                                # Access. You use this parameter to specify a Security Descriptor (SD) for user-level permissions. An SD contains information about the permissions, owner, and access capabilities of the resource.
                                                [Object] $obj = (Get-WmiObject Win32_Share -List).Create( $dir, $shareName, $typeNr, $nrOfAccessUsers, $descr );
                                                [Int32] $rc = $obj.ReturnValue;
                                                if( $rc -ne 0 ){
                                                  [String] $errMsg = switch( $rc ){ 0{"Ok, Success"} 2{"Access denied"} 8{"Unknown failure"} 9{"Invalid name"} 10{"Invalid level"} 21{"Invalid parameter"} 
                                                    22{"Duplicate share"} 23{"Redirected path"} 24{"Unknown device or directory"} 25{"Net name not found"} default{"Unknown rc=$rc"} }
                                                  throw [Exception] "$(ScriptGetCurrentFunc)(dir='$dir',sharename='$shareName',typenr=$typeNr) failed because $errMsg";
                                                } }
function SmbShareListAll2                     ( [String] $selectShareName = "*" ){
                                                # almost the same as ShareListAll
                                                OutVerbose "List shares selectShareName='$selectShareName'";
                                                # Ex: ShareState: Online, ...; ShareType: InterprocessCommunication, PrintQueue, FileSystemDirectory;
                                                return [Object] (Get-SMBShare -Name $selectShareName | Select-Object Name, ShareType, Path, Description, ShareState | Sort-Object TypeName, Name); }
function NetExtractHostName                   ( [String] $url ){ 
                                                return ([System.Uri]$url).Host; }
function NetAdapterGetConnectionStatusName    ( [Int32] $netConnectionStatusNr ){ 
                                                return [String] $(switch($netConnectionStatusNr){ 0{"Disconnected"} 1{"Connecting"} 2{"Connected"} 3{"Disconnecting"} 
                                                  4{"Hardware not present"} 5{"Hardware disabled"} 6{"Hardware malfunction"} 7{"Media disconnected"} 8{"Authenticating"} 9{"Authentication succeeded"} 
                                                  10{"Authentication failed"} 11{"Invalid address"} 12{"Credentials required"} default{"unknownNr=$netConnectionStatusNr"} }); }
function NetAdapterListAll                    (){ 
                                                return (Get-WmiObject -Class win32_networkadapter | Select-Object Name,NetConnectionID,MACAddress,Speed,@{Name="Status";Expression={(NetAdapterGetConnectionStatusName $_.NetConnectionStatus)}}); }
function NetPingHostIsConnectable             ( [String] $hostName ){
                                                if( (Test-Connection -Cn $hostName -BufferSize 16 -Count 1 -ea 0 -quiet) ){ return $true; }
                                                OutVerbose "Host $hostName not reachable, so flush dns, nslookup and retry";
                                                & "ipconfig.exe" "/flushdns" | out-null; # note option /registerdns would require more privs
                                                try{ [System.Net.Dns]::GetHostByName($hostName); }catch{}
                                                # nslookup $hostName -ErrorAction SilentlyContinue | out-null;
                                                return [Boolean] (Test-Connection -Cn $hostName -BufferSize 16 -Count 1 -ea 0 -quiet); }
function MountPointLocksListAll               (){ 
                                                OutVerbose "List all mount point locks"; return [Object] (Get-SmbConnection | 
                                                Select-Object ServerName,ShareName,UserName,Credential,NumOpens,ContinuouslyAvailable,Encrypted,PSComputerName,Redirected,Signed,SmbInstance,Dialect | 
                                                Sort-Object ServerName, ShareName, UserName, Credential); }
function MountPointListAll                    (){ 
                                                return [Object] (Get-SmbMapping | Select-Object LocalPath, RemotePath, Status); }
function MountPointGetByDrive                 ( [String] $drive ){ # return null if not found
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive='$drive' with trailing colon"; }
                                                return [Object] (Get-SmbMapping -LocalPath $drive -ErrorAction SilentlyContinue); }
function MountPointRemove                     ( [String] $drive, [String] $mountPoint = "", [Boolean] $suppressProgress = $false ){ # also remove PsDrive; drive can be empty then mountPoint must be given
                                                if( $drive -eq "" -and $mountPoint -eq "" ){ throw [Exception] "$(ScriptGetCurrentFunc): missing either drive or mountPoint."; }
                                                if( $drive -ne "" -and -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive='$drive' with trailing colon"; }
                                                if( $drive -ne "" -and (MountPointGetByDrive $drive) -ne $null ){
                                                  if( -not $suppressProgress ){ OutProgress "MountPointRemove drive=$drive"; }
                                                  Remove-SmbMapping -LocalPath $drive -Force -UpdateProfile;
                                                }
                                                if( $mountPoint -ne "" -and (Get-SmbMapping -RemotePath $mountPoint -ErrorAction SilentlyContinue) -ne $null ){
                                                  if( -not $suppressProgress ){ OutProgress "MountPointRemovePath $mountPoint"; }
                                                  Remove-SmbMapping -RemotePath $mountPoint -Force -UpdateProfile;
                                                }
                                                if( $drive -ne "" -and (Get-PSDrive -Name ($drive -replace ":","") -ErrorAction SilentlyContinue) -ne $null ){
                                                  if( -not $suppressProgress ){ OutProgress "MountPointRemovePsDrive $drive"; }
                                                  Remove-PSDrive -Name ($drive -replace ":","") -Force; # force means no confirmation
                                                } }                                                
function MountPointCreate                     ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $errorAsWarning = $false, [Boolean] $noPreLogMsg = $false ){
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive='$drive' with trailing colon"; }
                                                [String] $us = switch($cred -eq $null){ ($true){"CurrentUser($env:USERNAME)"} default{$cred.UserName}};
                                                [String] $pw = switch($cred -eq $null){ ($true){""} default{(CredentialGetPasswordTextFromCred $cred)}};
                                                [String] $traceInfo = "MountPointCreate drive=$drive mountPoint=$($mountPoint.PadRight(22)) us=$($us.PadRight(12)) pw=*** state=";
                                                if( $noPreLogMsg ){ }else{ OutProgressText $traceInfo; }
                                                [Object] $smbMap = MountPointGetByDrive $drive;
                                                if( $smbMap -ne $null -and $smbMap.RemotePath -eq $mountPoint -and $smbMap.Status -eq "OK" ){ 
                                                  if( $noPreLogMsg ){ OutProgress "$($traceInfo)OkNoChange."; }else{ OutSuccess "OkNoChange."; } return; 
                                                }
                                                MountPointRemove $drive $mountPoint $true; # required because New-SmbMapping has no force param
                                                try{
                                                  # alternative: SaveCredentials 
                                                  if( $pw -eq ""){
                                                    $obj = New-SmbMapping -LocalPath $drive -RemotePath $mountPoint -Persistent $true -UserName $us;
                                                  }else{
                                                    $obj = New-SmbMapping -LocalPath $drive -RemotePath $mountPoint -Persistent $true -UserName $us -Password $pw;
                                                  }
                                                  if( $noPreLogMsg ){ OutProgress "$($traceInfo)Ok."; }else{ OutSuccess "Ok."; }
                                                }catch{
                                                  # ex: System.Exception: New-SmbMapping(Z,\\spider\Transfer,spider\u0) failed because Mehrfache Verbindungen zu einem Server oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig. 
                                                  #     Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut.
                                                  # ex: Der Netzwerkname wurde nicht gefunden.
                                                  # ex: Der Netzwerkpfad wurde nicht gefunden.
                                                  [String] $exMsg = $_.Exception.Message.Trim();
                                                  [String] $msg = "New-SmbMapping($drive,$mountPoint,$us) failed because $exMsg";
                                                  if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                  # also see http://www.winboard.org/win7-allgemeines/137514-windows-fehler-code-liste.html http://www.megos.ch/files/content/diverses/doserrors.txt
                                                  if    ( $exMsg -eq "Der Netzwerkpfad wurde nicht gefunden." ) { $msg = "HostNotFound"; } # 53 BAD_NETPATH
                                                  elseif( $exMsg -eq "Der Netzwerkname wurde nicht gefunden." ){ $msg = "NameNotFound"; } # 67 BAD_NET_NAME
                                                  elseif( $exMsg -eq "Zugriff verweigert" ){ $msg = "AccessDenied"; } # 5 ACCESS_DENIED: 
                                                  elseif( $exMsg -eq "Mehrfache Verbindungen zu einem Server oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig. Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut." ){
                                                    $msg = "MultiConnectionsByMultiUserNamesNotAllowed"; } # 1219 SESSION_CREDENTIAL_CONFLICT
                                                  else {}
                                                  if( $noPreLogMsg ){ OutProgress "$($traceInfo)$($msg)"; }else{ OutWarning $msg 0; }
                                                  # alternative: (New-Object -ComObject WScript.Network).MapNetworkDrive("B:", "\\FPS01\users")
                                                } }
function PsDriveListAll                       (){ 
                                                OutVerbose "List PsDrives"; 
                                                return Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{Name="ShareName";Expression={$_.DisplayRoot+""}},Description,CurrentLocation,Free,Used | Sort-Object Name; }
                                                # not used: Root, Provider. PSDrive: Note are only for current session, even if persist.
function PsDriveCreate                        ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null ){
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive='$drive' with trailing colon"; }
                                                MountPointRemove $drive $mountPoint;
                                                [String] $us = switch($cred -eq $null){ ($true){"CurrentUser($env:USERNAME)"} default{$cred.UserName}};
                                                OutProgress "MountPointCreate drive=$drive mountPoint=$mountPoint cred.username=$us";
                                                try{
                                                  $obj = New-PSDrive -Name ($drive -replace ":","") -Root $mountPoint -PSProvider "FileSystem" -Scope Global -Persist -Description "$mountPoint($drive)" -Credential $cred;
                                                }catch{
                                                  # ex: System.ComponentModel.Win32Exception (0x80004005): Der lokale Gerätename wird bereits verwendet
                                                  # ex: System.Exception: Mehrfache Verbindungen zu einem Server oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig. 
                                                  #     Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut
                                                  # ex: System.Exception: New-PSDrive(Z,\\mycomp\Transfer,) failed because Das angegebene Netzwerkkennwort ist falsch
                                                  throw [Exception] "New-PSDrive($drive,$mountPoint,$us) failed because $($_.Exception.Message)";
                                                } }
function SqlGetCmdExe                         (){
                                                [String] $k1 = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\130\Tools\ClientSetup"; # sql server 2016
                                                [String] $k2 = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\120\Tools\ClientSetup"; # sql server 2014
                                                [String] $k3 = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\110\Tools\ClientSetup"; # sql server 2012
                                                [String] $k4 = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\ClientSetup"; # sql server 2008
                                                [String] $k = "";
                                                if    ( (RegistryExistsValue $k1 "Path") -and (FileExists ((RegistryGetValueAsString $k1 "Path")+"sqlcmd.EXE")) ){ $k = $k1; }
                                                elseif( (RegistryExistsValue $k2 "Path") -and (FileExists ((RegistryGetValueAsString $k2 "Path")+"sqlcmd.EXE")) ){ $k = $k2; }
                                                elseif( (RegistryExistsValue $k3 "Path") -and (FileExists ((RegistryGetValueAsString $k3 "Path")+"sqlcmd.EXE")) ){ $k = $k3; }
                                                elseif( (RegistryExistsValue $k4 "Path") -and (FileExists ((RegistryGetValueAsString $k4 "Path")+"sqlcmd.EXE")) ){ $k = $k4; }
                                                else { throw [Exception] "Wether Sql Server 2016, 2014, 2012 nor 2008 is installed, so cannot find sqlcmd.exe"; }
                                                [String] $sqlcmd = (RegistryGetValueAsString $k "Path") + "sqlcmd.EXE"; # "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\sqlcmd.EXE"
                                                return [String] $sqlcmd; }
function SqlRunScriptFile                     ( [String] $sqlserver, [String] $sqlfile, [String] $outFile, [Boolean] $continueOnErr ){
                                                FileAssertExists $sqlfile;
                                                OutProgress "SqlRunScriptFile sqlserver=$sqlserver sqlfile='$sqlfile' out='$outfile' contOnErr=$continueOnErr";
                                                [String] $sqlcmd = SqlGetCmdExe;
                                                FsEntryCreateParentDir $outfile;
                                                & $sqlcmd "-b" "-S" $sqlserver "-i" $sqlfile "-o" $outfile;
                                                if( -not $? ){ if( ! $continueOnErr ){ AssertRcIsOk; }else{ OutWarning "Ignore: SqlRunScriptFile '$sqlfile' on '$sqlserver' failed with rc=$(ScriptGetAndClearLastRc), more see outfile, will continue"; } }
                                                FileAssertExists $outfile; }
function SqlPerformFile                       ( [String] $connectionString, [String] $sqlFile, [String] $logFileToAppend = "", [Int32] $queryTimeoutInSec = 0, [Boolean] $showPrint = $true, [Boolean] $showRows = $true){
                                                # print are given out in yellow by internal verbose option; rows are currently given out only in a simple csv style without headers.
                                                # connectString example: "Server=myInstance;Database=TempDB;Integrated Security=True;"  queryTimeoutInSec: 1..65535,0=endless;  
                                                ScriptImportModuleIfNotDone "sqlserver";
                                                [String] $currentUser = "$env:USERDOMAIN\$env:USERNAME";
                                                [String] $traceInfo = "SqlPerformCmd(connectionString='$connectionString',sqlFile='$sqlFile',queryTimeoutInSec=$queryTimeoutInSec,showPrint=$showPrint,showRows=$showRows,currentUser=$currentUser)";
                                                OutProgress $traceInfo;
                                                if( $logFileToAppend -ne "" ){ FileAppendLineWithTs $logFileToAppend $traceInfo; }
                                                try{
                                                  Invoke-Sqlcmd -ConnectionString $connectionString -AbortOnError -Verbose:$showPrint -OutputSqlErrors $true -QueryTimeout $queryTimeoutInSec -InputFile $sqlFile |
                                                    ForEach-Object { 
                                                      [String] $line = $_;
                                                      if( $_.GetType() -eq [System.Data.DataRow] ){ $line = ""; if( $showRows ){ $_.ItemArray | ForEach-Object { $line += '"'+$_.ToString()+'",'; } } }
                                                      if( $line -ne "" ){ OutProgress $line; } if( $logFileToAppend -ne "" ){ FileAppendLineWithTs $logFileToAppend $line; } }
                                                }catch{ [String] $msg = "$traceInfo failed because $($_.Exception.Message)"; if( $logFileToAppend -ne "" ){ FileAppendLineWithTs $logFileToAppend $msg; } throw [Exception] $msg; } }
function SqlPerformCmd                        ( [String] $connectionString, [String] $cmd, [Boolean] $showPrint = $false, [Int32] $queryTimeoutInSec = 0 ){
                                                # connectString example: "Server=myInstance;Database=TempDB;Integrated Security=True;"  queryTimeoutInSec: 1..65535, 0=endless;  
                                                # cmd: semicolon separated commands, do not use GO, escape doublequotation marks, use bracketed identifiers [MyTable] instead of doublequotes.
                                                ScriptImportModuleIfNotDone "sqlserver";
                                                OutProgress "SqlPerformCmd connectionString='$connectionString' cmd='$cmd' showPrint=$showPrint queryTimeoutInSec=$queryTimeoutInSec";
                                                # Note: -EncryptConnection produced: Invoke-Sqlcmd : Es konnte eine Verbindung mit dem Server hergestellt werden, doch während des Anmeldevorgangs trat ein Fehler auf. (provider: SSL Provider, error: 0 - Die Zertifikatkette wurde von einer nicht vertrauenswürdigen Zertifizierungsstelle ausgestellt.)
                                                # for future use: -ConnectionTimeout inSec 0..65534,0=endless
                                                # for future use: -InputFile pathAndFileWithoutSpaces
                                                # for future use: -MaxBinaryLength  default is 1024, max nr of bytes returned for columns of type binary or varbinary.
                                                # for future use: -MaxCharLength    default is 4000, max nr of chars retunred for columns of type char, nchar, varchar, nvarchar.
                                                # for future use: -OutputAs         DataRows (=default), DataSet, DataTables.
                                                # for future use: -SuppressProviderContextWarning suppress warning from establish db context.
                                                Invoke-Sqlcmd -ConnectionString $connectionString -AbortOnError -Verbose:$showPrint -OutputSqlErrors $true -QueryTimeout $queryTimeoutInSec -Query $cmd;
                                                # note: this did not work (restore hangs):
                                                #   [Object[]] $relocateFileList = @();
                                                #   [Object] $smoRestore = New-Object Microsoft.SqlServer.Management.Smo.Restore; $smoRestore.Devices.AddDevice($bakFile , [Microsoft.SqlServer.Management.Smo.DeviceType]::File);
                                                #   $smoRestore.ReadFileList($server) | ForEach-Object{ [String] $f = Join-Path $dataDir (Split-Path $_.PhysicalName -Leaf); $relocateFileList += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($_.LogicalName, $f); }
                                                #   Restore-SqlDatabase -Partial -ReplaceDatabase -NoRecovery -ServerInstance $server -Database $dbName -BackupFile $bakFile -RelocateFile $relocateFileList;
                                              }
function RdpConnect                           ( [String] $rdpfile, [String] $mstscOptions = "" ){
                                                # some mstsc options: /edit /admin  (use /edit temporary to set password in .rdp file)
                                                OutProgress "RdpConnect: '$rdpfile' $mstscOptions";
                                                & "$env:SystemRoot\system32\mstsc.exe" $mstscOptions $rdpfile; AssertRcIsOk;
                                              }
function ToolHibernateModeEnable              (){
                                                OutInfo "Enable hibernate mode";
                                                if( (OsIsHibernateEnabled) ){
                                                  OutProgress "Ok, is enabled.";
                                                }elseif( (DriveFreeSpace 'C') -le ((OsInfoMainboardPhysicalMemorySum) * 1.3) ){
                                                  OutWarning "Warning: Cannot enable hibernate because has not enought hd-space (RAM=$(OsInfoMainboardPhysicalMemorySum),DriveC-Free=$(DriveFreeSpace 'C'); ignored.";
                                                }else{
                                                  ProcessRestartInElevatedAdminMode;
                                                  & "$env:SystemRoot\system32\POWERCFG.EXE" "-HIBERNATE" "ON"; AssertRcIsOk;
                                                }
                                              }
function ToolHibernateModeDisable             (){
                                                OutInfo "Disable hibernate mode";
                                                if( -not (OsIsHibernateEnabled) ){
                                                  OutProgress "Ok, is disabled.";
                                                }else{
                                                  ProcessRestartInElevatedAdminMode;
                                                  & "$env:SystemRoot\system32\POWERCFG.EXE" "-HIBERNATE" "OFF"; AssertRcIsOk;
                                                }
                                              }
function ToolCreate7zip                       ( [String] $srcDirOrFile, [String] $tar7zipFile ){
                                                [String] $src = "";
                                                [String] $recursiveOption = "";
                                                if( (DirExists $srcDirOrFile) ){ $recursiveOption = "-r"; $src = "$srcDirOrFile\*"; }
                                                else{ FileAssertExists $srcDirOrFile; $recursiveOption = "-r-"; $src = $srcDirOrFile; }
                                                [String] $Prog7ZipExe = ProcessGetCommandInEnvPathOrAltPaths "7z.exe" @("C:\Program Files\7-Zip\","C:\Prg\Utility\Packer\OpenSource-LGPL 7-Zip\");
                                                # options: -ms=4g : use limit of solid block 4GB; -mmt=4 : try use nr of threads; -w : use windows temp; -r : recursively; -r- : not-recursively;
                                                [Array] $arguments = "-t7z", "-mx=9", "-ms=4g", "-mmt=4", "-w", $recursiveOption, "a", "$tar7zipFile", $src;
                                                OutProgress "$Prog7ZipExe $arguments";
                                                [String] $out = & $Prog7ZipExe $arguments; AssertRcIsOk $out; }
function ToolCreateLnkIfNotExists             ( [Boolean] $forceRecreate, [String] $workDir, [String] $lnkFile, [String] $srcFile, [String[]] $arguments = @(), [Boolean] $runElevated = $false, [Boolean] $ignoreIfSrcFileNotExists = $false ){
                                                # ex: ToolCreateLnkIfNotExists $false "" "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\LinkToNotepad.lnk" "C:\Windows\notepad.exe";
                                                # ex: ToolCreateLnkIfNotExists $false "" "$env:USERPROFILE\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\LinkToNotepad.lnk" "C:\Windows\notepad.exe";
                                                # if $forceRecreate is false and target lnkfile already exists then it does nothing.
                                                [String] $descr = $srcFile;
                                                if( $ignoreIfSrcFileNotExists -and (FileNotExists $srcFile) ){
                                                  OutVerbose "NotCreatedBecauseSourceFileNotExists: $lnkFile"; return;
                                                }
                                                FileAssertExists $srcFile;
                                                if( $forceRecreate ){ FileDelete $lnkFile; }
                                                if( (FileExists $lnkFile) ){
                                                  OutVerbose "Unchanged: $lnkFile";
                                                }else{
                                                    [String] $argLine = $arguments; # array to string
                                                    if( $workDir -eq "" ){ $workDir = FsEntryGetParentDir $srcFile; }
                                                    OutProgress "CreateShortcut '$lnkFile'";
                                                    OutVerbose "WScript.Shell.CreateShortcut '$workDir' '$lnkFile' '$srcFile' '$argLine' '$descr'";
                                                    try{
                                                      FsEntryCreateParentDir $lnkFile;
                                                      [Object] $wshShell = New-Object -comObject WScript.Shell;
                                                      [Object] $s = $wshShell.CreateShortcut((FsEntryEsc $lnkFile));
                                                      $s.TargetPath = FsEntryEsc $srcFile;
                                                      $s.Arguments = $argLine; 
                                                      $s.WorkingDirectory = FsEntryEsc $workDir; 
                                                      $s.Description = $descr;
                                                      # $s.WindowStyle = 1; 1=Normal; 3=Maximized; 7=Minimized;
                                                      # $s.Hotkey = "CTRL+SHIFT+F"; # requires restart explorer
                                                      # $s.IconLocation = "myprog.exe, 0"; $s.IconLocation = "myprog.ico";
                                                      # $s.RelativePath = ...
                                                      $s.Save(); # does overwrite
                                                    }catch{
                                                      throw [Exception] "$(ScriptGetCurrentFunc)('$workDir','$lnkFile','$srcFile','$argLine','$descr') failed because $($_.Exception.Message)";
                                                    }
                                                  if( $runElevated ){ 
                                                    [Byte[]] $bytes = [IO.File]::ReadAllBytes($lnkFile); $bytes[0x15] = $bytes[0x15] -bor 0x20; [IO.File]::WriteAllBytes($lnkFile,$bytes);  # set bit 6 of byte nr 21
                                                  } } }
function ToolCreateMenuLinksByMenuItemRefFile ( [String] $targetMenuRootDir, [String] $sourceDir, [String] $srcFileExtMenuLink = ".menulink.txt", [String] $srcFileExtMenuLinkOpt = ".menulinkoptional.txt" ){
                                                # Create menu entries based on files below a dir.
                                                # ex: ToolCreateMenuLinksByMenuItemRefFile "$env:APPDATA\Microsoft\Windows\Start Menu\MyPortableProg" "D:\MyPortableProgs" ".menulink.txt";
                                                # Find all files below sourceDir with the extension (ex: ".menulink.txt"), which we call them menu-item-reference-file.
                                                # For each of these files it will create a menu item below the target menu root dir (ex: "$env:APPDATA\Microsoft\Windows\Start Menu\MyPortableProg").
                                                # The name of the target menu item (ex: "Manufactor ProgramName V1") will be taken 
                                                # from the name of the menu-item-reference-file (...\Manufactor ProgramName V1.menulink.txt) without the extension (ex: ".menulink.txt")
                                                # and the sub menu folder will be taken from the relative location of the menu-item-reference-file below the sourceDir.
                                                # The command for the target menu will be taken from the first line (ex: "D:\MyPortableProgs\Manufactor ProgramName\AnyProgram.exe")
                                                # of the content of the menu-item-reference-file. If target lnkfile already exists it does nothing.
                                                [String] $m = FsEntryGetAbsolutePath $targetMenuRootDir; # ex: "C:\Users\u1\AppData\Roaming\Microsoft\Windows\Start Menu\MyPortableProg"
                                                [String] $sdir = FsEntryGetAbsolutePath $sourceDir; # ex: "D:\MyPortableProgs"
                                                OutProgress "Create menu links to '$m' from files below '$sdir' with extension '$srcFileExtMenuLink' or '$srcFileExtMenuLinkOpt' files";
                                                Assert ($srcFileExtMenuLink    -ne "" -or (-not $srcFileExtMenuLink.EndsWith("\")   )) "srcMenuLinkFileExt='$srcFileExtMenuLink' is empty or has trailing backslash";
                                                Assert ($srcFileExtMenuLinkOpt -ne "" -or (-not $srcFileExtMenuLinkOpt.EndsWith("\"))) "srcMenuLinkOptFileExt='$srcFileExtMenuLinkOpt' is empty or has trailing backslash";
                                                if( -not (DirExists $sdir) ){ OutWarning "Ignoring dir not exists: '$sdir'"; }

                                                [String[]] $menuLinkFiles =  (FsEntryListAsStringArray "$sdir\*$srcFileExtMenuLink"    $true $false);
                                                           $menuLinkFiles += (FsEntryListAsStringArray "$sdir\*$srcFileExtMenuLinkOpt" $true $false);
                                                           $menuLinkFiles = $menuLinkFiles | Sort-Object;
                                                foreach( $f in $menuLinkFiles ){
                                                  [String] $d = FsEntryGetParentDir $f; # ex: "D:\MyPortableProgs\Appl\Graphic"  
                                                  [String] $relBelowSrcDir = FsEntryMakeRelative $d $sdir; # ex: "Appl\Graphic" or "."
                                                  [String] $workDir = "";
                                                  # ex: "C:\Users\u1\AppData\Roaming\Microsoft\Windows\Start Menu\MyPortableProg\Appl\Graphic\Manufactor ProgramName V1 en 2016.lnk"
                                                  [String] $lnkFile = "$($m)\$($relBelowSrcDir)\$((FsEntryGetFileName $f).TrimEnd($srcFileExtMenuLink).TrimEnd()).lnk";
                                                  [String] $cmdLine = FileReadContentAsLines $f | Select-Object -First 1;
                                                  [String[]] $ar = StringCommandLineToArray $cmdLine;
                                                  if( $ar.Length -eq 0 ){ throw [Exception] "Missing a command line at first line in file='$f' cmdline=$cmdLine"; }
                                                  if( ($ar.Length-1) -gt 999 ){ throw [Exception] "Command line has more than the allowed 999 arguments at first line infile='$f' nrOfArgs=$($ar.Length) cmdline='$cmdLine'"; }
                                                  [String] $srcFile = FsEntryMakeAbsolutePath $d $ar[0]; # ex: "D:\MyPortableProgs\Manufactor ProgramName\AnyProgram.exe"
                                                  [String[]] $arguments = $ar | Select-Object -Skip 1;
                                                  [Boolean] $forceRecreate = FileNotExistsOrIsOlder $lnkFile $f;
                                                  [Boolean] $ignoreIfSrcFileNotExists = $srcFile.EndsWith($srcFileExtMenuLinkOpt);
                                                  try{
                                                    ToolCreateLnkIfNotExists $forceRecreate $workDir $lnkFile $srcFile $arguments $false $ignoreIfSrcFileNotExists;
                                                  }catch{
                                                    OutWarning "Create menulink by reading file `"$f`", taking first line as cmdLine ($cmdLine) and calling (ToolCreateLnkIfNotExists $forceRecreate `"$workDir`" `"$lnkFile`" `"$srcFile`" `"$arguments`" $false $ignoreIfSrcFileNotExists) failed because $($_.Exception.Message).$(switch(-not $cmdLine.StartsWith('`"')){($true){' Maybe first file of content in menulink file should be quoted.'}default{' Maybe if first file not exists you may use file extension menulinkoptional instead of menulink.'}})";
                                                  } } }
function InfoAboutComputerOverview            (){ 
                                                return [String[]] @( "InfoAboutComputerOverview:", "", "ComputerName   : $ComputerName", "UserName       : $env:UserName", 
                                                "Datetime       : $(DateTimeNowAsStringIso 'yyyy-MM-dd HH:mm')", "ProductKey     : $(OsGetWindowsProductKey)", 
                                                "ConnetedDrives : $([System.IO.DriveInfo]::getdrives())", "PathVariable   : $env:PATH" ); }
function InfoAboutExistingShares              (){
                                                [String[]] $result = @( "Info about existing shares:", "" );
                                                foreach( $shareObj in (ShareListAll | Sort-Object Name) ){
                                                  [Object] $share = $shareObj | Select-Object -ExpandProperty Name;
                                                  [Object] $objShareSec = Get-WMIObject -Class Win32_LogicalShareSecuritySetting -Filter "name='$share'";
                                                  [String] $s = "  "+$shareObj.Name.PadRight(12)+" = "+("'"+$shareObj.Path+"'").PadRight(5)+" "+$shareObj.Caption;
                                                  try{
                                                    [Object] $sd = $objShareSec.GetSecurityDescriptor().Descriptor;
                                                    foreach( $ace in $sd.DACL ){
                                                      [Object] $username = $ace.Trustee.Name;
                                                      if( $ace.Trustee.Domain -ne $null -and $ace.Trustee.Domain -ne "" ){ $username = "$($ace.Trustee.Domain)\$username" }
                                                      if( $ace.Trustee.Name   -eq $null -or  $ace.Trustee.Name   -eq "" ){ $username = $ace.Trustee.SIDString }
                                                      [Object] $o = New-Object Security.AccessControl.FileSystemAccessRule($username,$ace.AccessMask,$ace.AceType);
                                                      # ex: FileSystemRights=FullControl; AccessControlType=Allow; IsInherited=False; InheritanceFlags=None; PropagationFlags=None; IdentityReference=Jeder;
                                                      # ex: FileSystemRights=FullControl; AccessControlType=Allow; IsInherited=False; InheritanceFlags=None; PropagationFlags=None; IdentityReference=VORDEFINIERT\Administratoren;
                                                      $s += "`r`n"+"".PadRight(26)+" (ACT="+$o.AccessControlType+",INH="+$o.IsInherited+",FSR="+$o.FileSystemRights+",INHF="+$o.InheritanceFlags+",PROP="+$o.PropagationFlags+",IDREF="+$o.IdentityReference+") ";
                                                    }
                                                  }catch{ $s += "`r`n"+"".PadRight(26)+" (unknown)"; }
                                                  $result += $s;
                                                }
                                                return [String[]] $result; }
function InfoAboutSystemInfo                  (){
                                                ProcessAssertInElevatedAdminMode; # because DISM.exe
                                                [String[]] $out = & "systeminfo.exe"; AssertRcIsOk $out;
                                                # get default associations for file extensions to programs for windows 10, this can be used later for imports.
                                                # configuring: Control Panel->Default Programs-> Set Default Program.  Choos program and "set this program as default."
                                                # View:        Control Panel->Programs-> Default Programs-> Set Association.
                                                # Edit:        for imports the xml file can be edited and stripped for your needs.
                                                # import cmd:  dism.exe /online /Import-DefaultAppAssociations:"mydefaultapps.xml"
                                                # removing:    dism.exe /Online /Remove-DefaultAppAssociations
                                                [String] $f = "$env:TEMP\EnvGetInfoAboutSystemInfo_DefaultFileExtensionToAppAssociations.xml";
                                                & "Dism.exe" "/QUIET" "/Online" "/Export-DefaultAppAssociations:$f"; AssertRcIsOk;
                                                #
                                                [String[]] $result = @( "InfoAboutSystemInfo:", "" );
                                                $result += $out;
                                                $result += "OS-SerialNumber: "+(Get-WmiObject Win32_OperatingSystem|Select-Object -ExpandProperty SerialNumber);
                                                $result += @( "", "", "List of associations of fileextensions to a filetypes:"   , (& "cmd.exe" "/c" "ASSOC") );
                                                $result += @( "", "", "List of associations of filetypes to executable programs:", (& "cmd.exe" "/c" "FTYPE") );
                                                $result += @( "", "", "List of DefaultAppAssociations:"                          , (FileReadContentAsString $f) );
                                                $result += @( "", "", "List of windows feature enabling states:"                 , (& "Dism.exe" "/online" "/Get-Features") );
                                                # for future use:
                                                # - powercfg /lastwake
                                                # - powercfg /waketimers
                                                # - Get-ScheduledTask | where{ $_.settings.waketorun }
                                                # - change:
                                                #   - Dism /online /Enable-Feature /FeatureName:TFTP /All
                                                #   - import:   ev.:  Dism.exe /Image:C:\test\offline /Import-DefaultAppAssociations:\\Server\Share\AppAssoc.xml
                                                #     remove:  Dism.exe /Image:C:\test\offline /Remove-DefaultAppAssociations
                                                return [String[]] $result; }
function InfoAboutRunningProcessesAndServices (){
                                                return [String[]] @( "Info about processes:", ""
                                                  ,"RunningProcesses:",(ProcessListRunningsAsStringArray),""
                                                  ,"RunningServices:" ,(ServiceListRunnings) ,""
                                                  ,"ExistingServices:",(ServiceListExistingsAsStringArray),""
                                                  ,"AvailablePowershellModules:" ,(Get-Module -ListAvailable)
                                                  # usually: AppLocker, BitsTransfer, PSDiagnostics, TroubleshootingPack, WebAdministration, SQLASCMDLETS, SQLPS.
                                                ); }
function NetGetIpConfig                       (){ [String[]] $out = & "IPCONFIG.EXE" "/ALL"          ; AssertRcIsOk $out; return $out; }
function NetGetNetView                        (){ [String[]] $out = & "NET.EXE" "VIEW" $ComputerName ; AssertRcIsOk $out; return $out; }
function NetGetNetStat                        (){ [String[]] $out = & "NETSTAT.EXE" "/A"             ; AssertRcIsOk $out; return $out; }
function NetGetRoute                          (){ [String[]] $out = & "ROUTE.EXE" "PRINT"            ; AssertRcIsOk $out; return $out; }
function NetGetNbtStat                        (){ [String[]] $out = & "NBTSTAT.EXE" "-N"             ; AssertRcIsOk $out; return $out; }
function InfoHdSpeed                          (){ 
                                                ProcessRestartInElevatedAdminMode;
                                                [String[]] $out1 = & "winsat.exe" "disk" "-seq" "-read"  "-drive" "c"; AssertRcIsOk $out1;
                                                [String[]] $out2 = & "winsat.exe" "disk" "-seq" "-write" "-drive" "c"; AssertRcIsOk $out2; return [String[]] @( $out1, $out2 ); }
function InfoAboutNetConfig                   (){ 
                                                return [String[]] @( "InfoAboutNetConfig:", ""
                                                ,"NetGetIpConfig:"      ,(NetGetIpConfig)                           ,""
                                                ,"NetGetNetView:"       ,(NetGetNetView)                            ,""
                                                ,"NetGetNetStat:"       ,(NetGetNetStat)                            ,""
                                                ,"NetGetRoute:"         ,(NetGetRoute)                              ,""
                                                ,"NetGetNbtStat:"       ,(NetGetNbtStat)                            ,""
                                                ,"NetGetAdapterSpeed:"  ,(NetAdapterListAll | StreamToTableString)  ,"" ); }
function StringCommandLineToArray             ( [String] $commandLine ){
                                                # care spaces or tabs separated args and doublequoted args which can contain double doublequotes for escaping single doublequotes.
                                                # ex: "my cmd.exe" arg1 "ar g2" "arg""3""" "arg4"""""  ex: StringCommandLineToArray "`"my cmd.exe`" arg1 `"ar g2`" `"arg`"`"3`"`"`" `"arg4`"`"`"`"`""
                                                [String] $line = $commandLine.Trim();
                                                [String[]] $result = @();
                                                [Int32] $i = 0;
                                                while( $i -lt $line.Length ){
                                                  [String] $s = "";
                                                  if( $line[$i] -eq '"' ){
                                                    while($true){
                                                      [Int32] $q = $line.IndexOf('"',$i + 1); if( $q -lt 0 ){ throw [Exception] "Missing closing doublequote after pos=$i in cmdline='$line'"; }
                                                      $s += $line.Substring($i + 1,$q - ($i + 1));
                                                      $i = $q+1;
                                                      if( $i -ge $line.Length -or $line[$i] -eq ' ' -or $line[$i] -eq [Char]9 ){ break; }
                                                      if( $line[$i] -eq '"' ){ $s += '"'; }
                                                      else{ throw [Exception] "Expected blank or tab char or end of string but got char=$($line[$i]) after doublequote at pos=$i in cmdline='$line'"; }
                                                    }
                                                    $result += $s;
                                                  }else{
                                                    [Int32] $w = $line.IndexOf(' ',$i + 1); if( $w -lt 0 ){ $w = $line.IndexOf([Char]9,$i + 1); } if( $w -lt 0 ){ $w = $line.Length; }
                                                    $s += $line.Substring($i,$w - $i); 
                                                    if( $s.Contains('"') ){ throw [Exception] "Expected no doublequote in word='$s' after pos=$i in cmdline='$line'"; }
                                                    $i = $w;
                                                    $result += $s;
                                                  }
                                                  while( $i -lt $line.Length -and ($line[$i] -eq ' ' -or $line[$i] -eq [Char]9) ){ $i++; }
                                                }
                                                return [String[]] $result; }
function WgetDownloadSite                     ( [String] $url, [String] $tarDir, [Int32] $level = 999, [Int32] $maxBytes = ([Int32]::MaxValue), [String] $us = "", 
                                                  [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Int32] $limitRateBytesPerSec = ([Int32]::MaxValue), [Boolean] $alsoRetrieveToParentOfUrl = $false ){
                                                # mirror site to dir; wget: HTTP, HTTPS, FTP. Logfile is written into target dir.
                                                [String] $logf = "$tarDir\.Download.$CurrentMonthIsoString.log";
                                                OutInfo "WgetDownloadSite from $url to '$tarDir' (only newer files, logfile=`"$logf`")";
                                                [String[]] $opt = @(
                                                   "--directory-prefix=$tarDir"
                                                  ,$(switch($alsoRetrieveToParentOfUrl){ ($true){""} default{"--no-parent"}})
                                                  ,"--no-verbose"
                                                  ,"--recursive"
                                                  ,"--level=$level" # alternatives: --level=inf
                                                  ,"--no-remove-listing" # leave .listing files for ftp
                                                  ,"--page-requisites" # download all files to display .html
                                                  ,"--adjust-extension" # make sure .html or .css for such types of files
                                                  ,"--backup-converted" # When converting a file, back up the original version with a ‘.orig’ suffix. optimizes incremental runs.
                                                  ,"--tries=2"
                                                  ,"--waitretry=5"
                                                  ,"--referer=$url" 
                                                  ,"-erobots=off" 
                                                  ,"--user-agent='Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0'"
                                                  ,"--quota=$maxBytes" 
                                                  ,"--limit-rate=$limitRateBytesPerSec"
                                                  #,"--wait=0.02"
                                                  ,"--user='$us'"
                                                  ,"--password='$pw'"
                                                  #,"--timestamping" 
                                                  ,"--no-clobber" # skip downloads to existing files, either noclobber or timestamping ,"--timestamping"
                                                  ,$(switch($ignoreSslCheck){ ($true){"--no-check-certificate"} default{""}})
                                                  # If a file is downloaded more than once in the same directory, Wget’s behavior depends on a few options, including ‘-nc’.
                                                  # In certain cases, the local file will be clobb  ered, or overwritten, upon repeated download.
                                                  # In other cases it will be preserved.
                                                  # When running Wget without ‘-N’, ‘-nc’, ‘-r’, or ‘-p’, downloading the same file in the same directory will result in the original copy of file being preserved and the second copy being named ‘file.1’. 
                                                  # If that file is downloaded yet again, the third copy will be named ‘file.2’, and so on. 
                                                  # (This is also the behavior with ‘-nd’, even if ‘-r’ or ‘-p’ are in effect.) When ‘-nc’ is specified, this behavior is suppressed, and Wget will refuse to download newer copies of ‘file’.
                                                  # Therefore, "no-clobber" is actually a misnomer in this mode—it’s not clobbering that’s prevented (as the numeric suffixes were already preventing clobbering), but rather the multiple version saving that’s prevented.
                                                  # When running Wget with ‘-r’ or ‘-p’, but without ‘-N’, ‘-nd’, or ‘-nc’, re-downloading a file will result in the new copy simply overwriting the old.
                                                  # Adding ‘-nc’ will prevent this behavior, instead causing the original version to be preserved and any newer copies on the server to be ignored.
                                                  # When running Wget with ‘-N’, with or without ‘-r’ or ‘-p’, the decision as to whether or not to download a newer copy of a file depends on the local and remote timestamp and size of the file (see Time-Stamping).
                                                  # ‘-nc’ may not be specified at the same time as ‘-N’.
                                                  # Note that when ‘-nc’ is specified, files with the suffixes ‘.html’ or ‘.htm’ will be loaded from the local disk and parsed as if they had been retrieved from the Web.  
                                                  #,"--convert-links"  # Convert non-relative links locally    deactivated because:  Both --no-clobber and --convert-links were specified, only --convert-links will be used.
                                                  # --force-html    # When input is read from a file, force it to be treated as an HTML file. This enables you to retrieve relative links from existing HTML files on your local disk, by adding <base href="url"> to HTML, or using the ‘--base’ command-line option.
                                                  # --input-file=$fileslist
                                                  # --ca-certificate file.crt   (more see http://users.ugent.be/~bpuype/wget/#download)
                                                  # more about logon forms: http://wget.addictivecode.org/FrequentlyAskedQuestions
                                                  # backup without file conversions: wget -mirror -p -P c:\wget_files\example2 ftp://username:password@ftp.yourdomain.com
                                                  # download:                        Wget            -P c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                  # download resume:                 Wget -c         -P c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                );
                                                # maybe we should also: $url/sitemap.xml
                                                DirCreate $tarDir;
                                                [String] $stateBefore = FsEntryReportMeasureInfo $tarDir;
                                                # alternative would be for wget: Invoke-WebRequest
                                                [String] $wgetExe = ProcessGetCommandInEnvPathOrAltPaths "wget"; # ex: D:\Work\PortableProg\Tool\...
                                                FileAppendLineWithTs $logf "$wgetExe $url $opt";
                                                OutProgress "$wgetExe $url $opt";
                                                OutProgress "Logfile: `"$logf`"";
                                                & $wgetExe $url $opt "--append-output=$logf";
                                                [Int32] $rc = ScriptGetAndClearLastRc; if( $rc -ne 0 ){
                                                  [String] $err = switch($rc){ 0 {"OK"} 1 {"Generic"} 2 {"CommandLineOption"} 3 {"FileIo"} 4 {"Network"} 5 {"SslVerification"} 6 {"Authentication"} 7 {"Protocol"} 8 {"ServerIssuedSomeResponse(ex:404NotFound)"} default {"Unknown(rc=$rc)"} };
                                                  OutWarning "Warning: Ignored one or more occurrences of error: $err. More see logfile=`"$logf`".";
                                                }
                                                [String] $state = "TargetDir: $(FsEntryReportMeasureInfo "$tarDir") (BeforeStart: $stateBefore)";
                                                FileAppendLineWithTs $logf $state;
                                                OutProgress $state; }
<# Type: ServerCertificateValidationCallback #> Add-Type -TypeDefinition "using System;using System.Net;using System.Net.Security;using System.Security.Cryptography.X509Certificates; public class ServerCertificateValidationCallback { public static void Ignore() { ServicePointManager.ServerCertificateValidationCallback += delegate( Object obj, X509Certificate certificate, X509Chain chain, SslPolicyErrors errors ){ return true; }; } } ";
function PsWebRequestLastModifiedFailSafe     ( [String] $url ){ # return DateTime.MaxValue in case of any problem
                                                [net.WebResponse] $resp = $null;
                                                try{
                                                  [net.HttpWebRequest] $webRequest = [net.WebRequest]::Create($url);
                                                  $resp = $webRequest.GetResponse();
                                                  $resp.Close();
                                                  if( $resp.StatusCode -ne [system.net.httpstatuscode]::ok ){ throw [Exception] "GetResponse($url) failed with statuscode=$($resp.StatusCode)"; }
                                                  if( $resp.LastModified -lt (DateTimeFromStringIso "1970-01-01") ){ throw [Exception] "GetResponse($url) failed because LastModified=$($resp.LastModified) is unexpected lower than 1970"; }
                                                  return [DateTime] $resp.LastModified;
                                                }catch{ return [DateTime]::MaxValue; }finally{ if( $resp -ne $null ){ $resp.Dispose(); } } }
function PsDownloadFile                       ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false ){
                                                # powershell internal implementation of curl or wget which works for http, https and ftp only. Cares 3xx for auto redirections.
                                                if( $url -eq "" ){ throw [Exception] "Wrong file url: '$url'"; } # alternative check: -or $url.EndsWith("/") 
                                                if( $us -ne "" -and $pw -eq "" ){ throw [Exception] "Missing password for username=$us"; }
                                                OutInfo "PsDownloadFile $url to '$tarFile'";
                                                if( $ignoreSslCheck ){
                                                  # note: this alternative is now obsolete (see https://msdn.microsoft.com/en-us/library/system.net.servicepointmanager.certificatepolicy(v=vs.110).aspx):
                                                  #   Add-Type -TypeDefinition " using System.Net; using System.Security.Cryptography.X509Certificates; public class TrustAllCertsPolicy : ICertificatePolicy { public bool CheckValidationResult( ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem){ return true; } } ";
                                                  #   [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy;
                                                  [ServerCertificateValidationCallback]::Ignore();
                                                  # Known Bug: we currently do not restore this option so it will influence all following calls
                                                  # maybe later we use: -SkipCertificateCheck
                                                }
                                                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls12; # default is: Ssl3, Tls.
                                                if( $onlyIfNewer -and (FileExists $tarFile) ){
                                                  [DateTime] $webTs = (PsWebRequestLastModifiedFailSafe $url);
                                                  [DateTime] $fileTs = (FsEntryGetLastModified $tarFile);
                                                  if( $webTs -le $fileTs ){
                                                    OutProgress "Ok, download not nessessary because WebFileLastChange=$(DateTimeAsStringIso $webTs) is older than TarFileLastChange=$(DateTimeAsStringIso $fileTs).";
                                                    return;
                                                  }
                                                  # old: throw [Exception] "PsDownloadFile with onlyIfNewer is not yet implemented"; 
                                                }
                                                #[String] $userAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1";
                                                [String] $tarDir = FsEntryGetParentDir $tarFile;
                                                [String] $logf = "$LogDir\Download.$CurrentMonthIsoString.$($PID)_$(ProcessGetCurrentThreadId).log";
                                                DirCreate $tarDir;
                                                OutProgress "Logfile: `"$logf`"";
                                                FileAppendLineWithTs $logf "WebClient.DownloadFile(url=$url,tar=$tarFile)";
                                                $webclient = new-object System.Net.WebClient;
                                                if( $us -ne "" ){
                                                  [System.Management.Automation.PSCredential] $cred = (CredentialReadFromParamOrInput $us $pw);
                                                  $webclient.Credentials = $cred;
                                                }
                                                try{
                                                  $webclient.DownloadFile($url,$tarFile);
                                                }catch{ 
                                                  # ex: The request was aborted: Could not create SSL/TLS secure channel.
                                                  throw [Exception] "WebClient.DownloadFile(url=$url,tar=$tarFile) failed because $($_.Exception.Message)"; 
                                                }
                                                <# alternative
                                                FileAppendLineWithTs $logf "Invoke-WebRequest -Uri $url -OutFile $tarFile";
                                                if( $us -ne "" ){
                                                  [System.Management.Automation.PSCredential] $cred = (CredentialReadFromParamOrInput $us $pw);
                                                  Invoke-WebRequest -Uri $url -OutFile $tarFile -MaximumRedirection 2 -TimeoutSec 70 -UserAgent $userAgent -Credential $cred;
                                                }else{
                                                  Invoke-WebRequest -Uri $url -OutFile $tarFile -MaximumRedirection 2 -TimeoutSec 70 -UserAgent $userAgent;
                                                }
                                                # for future use: -UseDefaultCredentials, -Headers, -MaximumRedirection, -Method, -Body, -ContentType, -TransferEncoding, -InFile
                                                #>
                                                [String] $stateMsg = "Ok, downloaded $(FileGetSize $tarFile) bytes.";
                                                FileAppendLineWithTs $logf $stateMsg;
                                                OutProgress $stateMsg; }
function CurlDownloadFile                     ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false ){
                                                # download a single file by overwrite it, requires curl.exe in path, timestamps are also taken, logging info is stored in a global logfile, 
                                                #   for user agent info a relative new mozilla firefox is set, if file curl-ca-bundle.crt exists next to curl.exe then this is taken.
                                                # Supported protocols: DICT, FILE, FTP, FTPS, Gopher, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMB, SMTP, SMTPS, Telnet and TFTP. 
                                                # Supported features:  SSL certificates, HTTP POST, HTTP PUT, FTP uploading, HTTP form based upload, proxies, HTTP/2, cookies, 
                                                #                      user+password authentication (Basic, Plain, Digest, CRAM-MD5, NTLM, Negotiate and Kerberos), file transfer resume, proxy tunneling and more. 
                                                if( $url -eq "" ){ throw [Exception] "Wrong file url: '$url'"; } # alternative check: -or $url.EndsWith("/") 
                                                if( $us -ne "" -and $pw -eq "" ){ throw [Exception] "Missing password for username=$us"; }
                                                [String[]] $opt = @( # see https://curl.haxx.se/docs/manpage.html
                                                   "--show-error"                            # Show error. With -s, make curl show errors when they occur
                                                  ,"--output", "$tarFile"                    # Write to FILE instead of stdout
                                                  ,"--silent"                                # Silent mode (don't output anything), no progress meter
                                                  ,"--create-dirs"                           # create the necessary local directory hierarchy as needed of --output file
                                                  ,"--connect-timeout", "70"                 # in sec
                                                  ,"--retry","2"                             #
                                                  ,"--retry-delay","5"                       #
                                                  ,"--remote-time"                           # Set the remote file's time on the local output
                                                  ,"--stderr","-"                            # Where to redirect stderr (use "-" for stdout)
                                                  # ,"--limit-rate","$limitRateBytesPerSec"  #
                                                  # ,"--progress-bar"                        # Display transfer progress as a progress bar
                                                  # ,"--remote-name"                         # Write output to a file named as the remote file ex: "http://a.be/c.ext"
                                                  # --remote-name-all                        # Use the remote file name for all URLs
                                                  # --max-time <seconds>                     # .
                                                  # --netrc-optional                         # .
                                                  # --ftp-create-dirs                        # for put
                                                  # --stderr <file>                          # .
                                                  # --append                                 # Append to target file when uploading (F/SFTP)
                                                  # --basic                                  # Use HTTP Basic Authentication (H)
                                                  # --capath DIR                             # CA directory to verify peer against (SSL)
                                                  # --cert CERT[:PASSWD]                     # Client certificate file and password (SSL)
                                                  # --cert-type TYPE                         # Certificate file type (DER/PEM/ENG) (SSL)
                                                  # --ciphers LIST                           # SSL ciphers to use (SSL)
                                                  # --compressed                             # Request compressed response (using deflate or gzip)
                                                  # --crlfile FILE                           # Get a CRL list in PEM format from the given file
                                                  # --data DATA                              # HTTP POST data (H)
                                                  # --data-urlencode DATA                    # HTTP POST data url encoded (H)
                                                  # --digest                                 # Use HTTP Digest Authentication (H)
                                                  # --dns-servers                            # DNS server addrs to use: 1.1.1.1;2.2.2.2
                                                  # --dump-header FILE                       # Write the headers to FILE
                                                  # --ftp-account DATA                       # Account data string (F)
                                                  # --ftp-alternative-to-user COMMAND        # String to replace "USER [name]" (F)
                                                  # --ftp-method [MULTICWD/NOCWD/SINGLECWD]  # Control CWD usage (F)
                                                  # --ftp-pasv                               # Use PASV/EPSV instead of PORT (F)
                                                  # --ftp-port ADR                           # Use PORT with given address instead of PASV (F)
                                                  # --ftp-skip-pasv-ip                       # Skip the IP address for PASV (F)
                                                  # --ftp-pret                               # Send PRET before PASV (for drftpd) (F)
                                                  # --ftp-ssl-ccc                            # Send CCC after authenticating (F)
                                                  # --ftp-ssl-ccc-mode ACTIVE/PASSIVE        # Set CCC mode (F)
                                                  # --ftp-ssl-control                        # Require SSL/TLS for FTP login, clear for transfer (F)
                                                  # --get                                    # Send the -d data with a HTTP GET (H)
                                                  # --globoff                                # Disable URL sequences and ranges using {} and []
                                                  # --header LINE                            # Pass custom header LINE to server (H)
                                                  # --head                                   # Show document info only
                                                  # --help                                   # This help text
                                                  # --hostpubmd5 MD5                         # Hex-encoded MD5 string of the host public key. (SSH)
                                                  # --http1.0                                # Use HTTP 1.0 (H)
                                                  # --http1.1                                # Use HTTP 1.1 (H)
                                                  # --http2                                  # Use HTTP 2 (H)
                                                  # --ignore-content-length                  # Ignore the HTTP Content-Length header
                                                  # --include                                # Include protocol headers in the output (H/F)
                                                  # --interface INTERFACE                    # Use network INTERFACE (or address)
                                                  # --ipv4                                   # Resolve name to IPv4 address
                                                  # --ipv6                                   # Resolve name to IPv6 address
                                                  # --junk-session-cookies                   # Ignore session cookies read from file (H)
                                                  # --keepalive-time SECONDS                 # Wait SECONDS between keepalive probes
                                                  # --key KEY                                # Private key file name (SSL/SSH)
                                                  # --key-type TYPE                          # Private key file type (DER/PEM/ENG) (SSL)
                                                  # --krb LEVEL                              # Enable Kerberos with security LEVEL (F)
                                                  # --libcurl FILE                           # Dump libcurl equivalent code of this command line
                                                  # --limit-rate RATE                        # Limit transfer speed to RATE
                                                  # --list-only                              # List only mode (F/POP3)
                                                  # --local-port RANGE                       # Force use of RANGE for local port numbers
                                                  # --location                               # Follow redirects (H)
                                                  # --location-trusted                       # Like '--location', and send auth to other hosts (H)
                                                  # --login-options                          # OPTIONS Server login options (IMAP, POP3, SMTP)
                                                  # --manual                                 # Display the full manual
                                                  # --mail-from FROM                         # Mail from this address (SMTP)
                                                  # --mail-rcpt TO                           # Mail to this/these addresses (SMTP)
                                                  # --mail-auth AUTH                         # Originator address of the original email (SMTP)
                                                  # --max-filesize BYTES                     # Maximum file size to download (H/F)
                                                  # --max-redirs NUM                         # Maximum number of redirects allowed (H)
                                                  # --max-time SECONDS                       # Maximum time allowed for the transfer
                                                  # --metalink                               # Process given URLs as metalink XML file
                                                  # --negotiate                              # Use HTTP Negotiate (SPNEGO) authentication (H)
                                                  # --netrc                                  # Must read .netrc for user name and password
                                                  # --netrc-optional                         # Use either .netrc or URL; overrides -n
                                                  # --netrc-file FILE                        # Specify FILE for netrc
                                                  # --next                                   # Allows the following URL to use a separate set of options
                                                  # --no-alpn                                # Disable the ALPN TLS extension (H)
                                                  # --no-buffer                              # Disable buffering of the output stream
                                                  # --no-keepalive                           # Disable keepalive use on the connection
                                                  # --no-npn                                 # Disable the NPN TLS extension (H)
                                                  # --no-sessionid                           # Disable SSL session-ID reusing (SSL)
                                                  # --noproxy                                # List of hosts which do not use proxy
                                                  # --ntlm                                   # Use HTTP NTLM authentication (H)
                                                  # --oauth2-bearer TOKEN                    # OAuth 2 Bearer Token (IMAP, POP3, SMTP)
                                                  # --pass PASS                              # Pass phrase for the private key (SSL/SSH)
                                                  # --pinnedpubkey FILE                      # Public key (PEM/DER) to verify peer against (OpenSSL/GnuTLS/GSKit only)
                                                  # --post301                                # Do not switch to GET after following a 301 redirect (H)
                                                  # --post302                                # Do not switch to GET after following a 302 redirect (H)
                                                  # --post303                                # Do not switch to GET after following a 303 redirect (H)
                                                  # --proto PROTOCOLS                        # Enable/disable PROTOCOLS
                                                  # --proto-redir PROTOCOLS                  # Enable/disable PROTOCOLS on redirect
                                                  # --proxy [PROTOCOL://]HOST[:PORT]         # Use proxy on given port
                                                  # --proxy-anyauth                          # Pick "any" proxy authentication method (H)
                                                  # --proxy-basic                            # Use Basic authentication on the proxy (H)
                                                  # --proxy-digest                           # Use Digest authentication on the proxy (H)
                                                  # --proxy-negotiate                        # Use HTTP Negotiate (SPNEGO) authentication on the proxy (H)
                                                  # --proxy-ntlm                             # Use NTLM authentication on the proxy (H)
                                                  # --proxy-user USER[:PASSWORD]             # Proxy user and password
                                                  # --proxy1.0 HOST[:PORT]                   # Use HTTP/1.0 proxy on given port
                                                  # --proxytunnel                            # Operate through a HTTP proxy tunnel (using CONNECT)
                                                  # --pubkey KEY                             # Public key file name (SSH)
                                                  # --quote CMD                              # Send command(s) to server before transfer (F/SFTP)
                                                  # --random-file FILE                       # File for reading random data from (SSL)
                                                  # --range RANGE                            # Retrieve only the bytes within RANGE
                                                  # --raw                                    # Do HTTP "raw"; no transfer decoding (H)
                                                  # --referer                                # Referer URL (H)
                                                  # --remote-header-name                     # Use the header-provided filename (H)
                                                  # --remote-name                            # Write output to a file named as the remote file
                                                  # --remote-name-all                        # Use the remote file name for all URLs
                                                  # --remote-time                            # Set the remote file's time on the local output
                                                  # --request COMMAND                        # Specify request command to use
                                                  # --resolve HOST:PORT:ADDRESS              # Force resolve of HOST:PORT to ADDRESS
                                                  # --retry NUM                              # Retry request NUM times if transient problems occur
                                                  # --retry-delay SECONDS                    # Wait SECONDS between retries
                                                  # --retry-max-time SECONDS                 # Retry only within this period
                                                  # --sasl-ir                                # Enable initial response in SASL authentication
                                                  # --socks4 HOST[:PORT]                     # SOCKS4 proxy on given host + port
                                                  # --socks4a HOST[:PORT]                    # SOCKS4a proxy on given host + port
                                                  # --socks5 HOST[:PORT]                     # SOCKS5 proxy on given host + port
                                                  # --socks5-hostname HOST[:PORT]            # SOCKS5 proxy, pass host name to proxy
                                                  # --socks5-gssapi-service NAME             # SOCKS5 proxy service name for GSS-API
                                                  # --socks5-gssapi-nec                      # Compatibility with NEC SOCKS5 server
                                                  # --speed-limit RATE                       # Stop transfers below RATE for 'speed-time' secs
                                                  # --speed-time SECONDS                     # Trigger 'speed-limit' abort after SECONDS (default: 30)
                                                  # --ssl                                    # Try SSL/TLS (FTP, IMAP, POP3, SMTP)
                                                  # --ssl-reqd                               # Require SSL/TLS (FTP, IMAP, POP3, SMTP)
                                                  # --sslv2                                  # Use SSLv2 (SSL)
                                                  # --sslv3                                  # Use SSLv3 (SSL)
                                                  # --ssl-allow-beast                        # Allow security flaw to improve interop (SSL)
                                                  # --tcp-nodelay                            # Use the TCP_NODELAY option
                                                  # --telnet-option OPT=VAL                  # Set telnet option
                                                  # --tftp-blksize VALUE                     # Set TFTP BLKSIZE option (must be >512)
                                                  # --time-cond TIME                         # Transfer based on a time condition, for TIME a file can be specified to take its modification time
                                                  # --tlsv1                                  # Use => TLSv1 (SSL)
                                                  # --tlsv1.0                                # Use TLSv1.0 (SSL)
                                                  # --tlsv1.1                                # Use TLSv1.1 (SSL)
                                                  # --tlsv1.2                                # Use TLSv1.2 (SSL)
                                                  # --trace FILE                             # Write a debug trace to FILE
                                                  # --trace-ascii FILE                       # Like --trace, but without hex output
                                                  # --trace-time                             # Add time stamps to trace/verbose output
                                                  # --tr-encoding                            # Request compressed transfer encoding (H)
                                                  # --upload-file FILE                       # Transfer FILE to destination
                                                  # --use-ascii                              # Use ASCII/text transfer
                                                  # --user USER[:PASSWORD]                   # Server user and password
                                                  # --tlsuser USER                           # TLS username
                                                  # --tlspassword STRING                     # TLS password
                                                  # --tlsauthtype STRING                     # TLS authentication type (default: SRP)
                                                  # --unix-socket FILE                       # Connect through this Unix domain socket
                                                  # --verbose                                # Make the operation more talkative
                                                  # --write-out FORMAT                       # Use output FORMAT after completion
                                                  # --xattr                                  # Store metadata in extended file attributes
                                                  #
                                                  # --url URL                                # URL to work with
                                                  # --insecure                               # Allow connections to SSL sites without certs check
                                                  # --cacert cacert.pem                      # CA certificate to verify peer against (SSL), see https://curl.haxx.se/docs/caextract.html, .pem or .crt file
                                                  ,"--user-agent", "`"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1`""  # Send User-Agent STRING to server (H)
                                                );
                                                if( $us -ne "" ){ $opt += @( "--user", "$($us):$pw" ); }
                                                if( $ignoreSslCheck ){ $opt += "--insecure"; }
                                                if( $onlyIfNewer -and (FileExists $tarFile) ){ $opt += @( "--time-cond", $tarFile); }
                                                [String] $curlExe = ProcessGetCommandInEnvPathOrAltPaths "curl.exe" @() "Please download it from http://curl.haxx.se/download.html and install it and add dir to path env var.";
                                                [String] $curlCaCert = "$(FsEntryGetParentDir $curlExe)\curl-ca-bundle.crt";
                                                if( -not $url.StartsWith("http:") -and (FileExists $curlCaCert) ){ $opt += @( "--cacert", $curlCaCert); }
                                                OutInfo "CurlDownloadFile $url to '$tarFile'";
                                                [String] $tarDir = FsEntryGetParentDir $tarFile;
                                                [String] $logf = "$LogDir\Download.$CurrentMonthIsoString.$($PID)_$(ProcessGetCurrentThreadId).log";
                                                DirCreate $tarDir;
                                                FileAppendLineWithTs $logf "$curlExe $opt --url $url";
                                                OutProgress "Logfile: `"$logf`"";
                                                [String[]] $out = & $curlExe $opt "--url" $url;
                                                if( $LASTEXITCODE -eq 60 ){
                                                  # curl: (60) SSL certificate problem: unable to get local issuer certificate. More details here: http://curl.haxx.se/docs/sslcerts.html
                                                  # curl performs SSL certificate verification by default, using a "bundle" of Certificate Authority (CA) public keys (CA certs). 
                                                  # If the default bundle file isn't adequate, you can specify an alternate file using the --cacert option.
                                                  # If this HTTPS server uses a certificate signed by a CA represented in the bundle, the certificate verification probably failed 
                                                  # due to a problem with the certificate (it might be expired, or the name might not match the domain name in the URL).
                                                  # If you'd like to turn off curl's verification of the certificate, use the -k (or --insecure) option.
                                                  throw [Exception] "Curl($url) failed because SSL certificate problem as expired or domain name not matches, alternatively use option to ignore ssl check.";
                                                }elseif( $LASTEXITCODE -eq 6 ){
                                                  # curl: (6) Could not resolve host: github.com
                                                  throw [Exception] "Curl($url) failed because host not found.";
                                                }
                                                # trace example:
                                                #   Warning: Transient problem: timeout Will retry in 5 seconds. 2 retries left.
                                                AssertRcIsOk $out;
                                                FileAppendLines $logf (StringArrayInsertIndent $out 2);
                                                [String] $stateMsg = "Ok, downloaded $(FileGetSize $tarFile) bytes.";
                                                FileAppendLineWithTs $logf $stateMsg;
                                                OutProgress $stateMsg;
                                                AssertRcIsOk; }
function CurlDownloadToString                 ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false ){
                                                [String] $tmp = (FileGetTempFile); CurlDownloadFile $url $tmp $us $pw $ignoreSslCheck $onlyIfNewer;
                                                [String] $result = (FileReadContentAsString $tmp); FileDelTempFile $tmp; return [String] $result; }
function PSDownloadToString                   ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false ){
                                                [String] $tmp = (FileGetTempFile); PsDownloadFile $url $tmp $us $pw $ignoreSslCheck $onlyIfNewer;
                                                [String] $result = (FileReadContentAsString $tmp); FileDelTempFile $tmp; return [String] $result; }
<# Type: SvnEnvInfo #>                        Add-Type -TypeDefinition "public struct SvnEnvInfo {public string Url; public string Path; public string RealmPattern; public string CachedAuthorizationFile; public string CachedAuthorizationUser; public string Revision; }";
                                                # ex: Url="https://myhost/svn/Work"; Path="D:\Work"; RealmPattern="https://myhost:443"; CachedAuthorizationFile="$env:APPDATA\Subversion\auth\svn.simple\25ff84926a354d51b4e93754a00064d6"; CachedAuthorizationUser="myuser"; Revision="1234"
function SvnExe                               (){ 
                                                return [String] ((RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "Directory") + ".\bin\svn.exe"); }
<# Script local variable: svnLogFile #>       [String] $script:svnLogFile = "$script:LogDir\Svn.$CurrentMonthIsoString.$($PID)_$(ProcessGetCurrentThreadId).log";
function SvnEnvInfoGet                        ( [String] $workDir ){
                                                # return SvnEnvInfo; no param is null.
                                                OutProgress "SvnEnvInfo - Get svn environment info";
                                                FileAppendLineWithTs $svnLogFile "SvnEnvInfoGet(`"$workDir`")";
                                                # example:
                                                #   Path: D:\Work
                                                #   Working Copy Root Path: D:\Work
                                                #   URL: https://myhost/svn/Work
                                                #   Relative URL: ^/
                                                #   Repository Root: https://myhost/svn/Work
                                                #   Repository UUID: 123477de-b5c2-7042-84be-024e23dc4af5
                                                #   Revision: 1234
                                                #   Node Kind: directory
                                                #   Schedule: normal
                                                #   Last Changed Author: xy
                                                #   Last Changed Rev: 1234
                                                #   Last Changed Date: 2013-12-31 23:59:59 +0100 (Mi, 31 Dec 2013)
                                                [String[]] $out = & (SvnExe) "info" $workDir; AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                [String[]] $out2 = & (SvnExe) "propget" "svn:ignore" "-R" $workDir; AssertRcIsOk $out2;
                                                # example:
                                                #   work\Users\MyName - test?.txt
                                                #   test2*.txt
                                                FileAppendLineWithTs $svnLogFile "  Ignore Properties:";
                                                FileAppendLines $svnLogFile (StringArrayInsertIndent $out2 2);
                                                #
                                                # Note: svn:ignore properties works flat only and could be edited by:
                                                #   set svn_editor=notepad.exe
                                                #   svn propedit svn:ignore                      $anyDirBelowSvnWorkDir   # Set overwrite the property with multiple patterns, opens an editor to modify property, after save the hardcoded name 'svn-prop.tmp' it changes pattern of this dir
                                                #   svn propset  svn:ignore myFsEntryToIgnore    $anyDirBelowSvnWorkDir   # Set overwrite the property with an new single fs entry pattern (without backslash)
                                                #   svn propset  svn:ignore myFsEntryToIgnore -R $anyDirBelowSvnWorkDir   # Set overwrite the property with an new single fs entry pattern (without backslash) recursively
                                                #   svn propset  svn:ignore -F patternlist       $anyDirBelowSvnWorkDir   # Set overwrite the property with some new single fs entry patterns (without backslash)
                                                #   svn propset  svn:ignore -F patternlist    -R $anyDirBelowSvnWorkDir   # Set overwrite the property with some new single fs entry patterns (without backslash) recursively
                                                #   svn propdel  svn:ignore                      $anyDirBelowSvnWorkDir   # Remove the properties
                                                #   svn propdel  svn:ignore                   -R $anyDirBelowSvnWorkDir   # Remove the properties recursively
                                                #   svn propget  svn:ignore                      $anyDirBelowSvnWorkDir   # list properties
                                                #   svn propget  svn:ignore                   -R $anyDirBelowSvnWorkDir   # list properties recursively
                                                #   svn status --no-ignore                                                # You should see an 'I' next to the ignored files
                                                #   svn commit -m "..."                                                   # You must commit the new property change
                                                # Note: If the file is already under version control or shows up as ‘M’ instead of ‘I’, then you’ll first have to svn delete the file from the repository (make a backup of it somewhere first), 
                                                #   then svn ignore the file using the steps above and copy the file back into the repository.
                                                #
                                                [SvnEnvInfo] $result = New-Object SvnEnvInfo;
                                                foreach( $line in $out ){
                                                  if(     $line.StartsWith("URL: " ) ){ $result.Url  = $line.Substring("URL: ".Length); }
                                                  elseif( $line.StartsWith("Path: ") ){ $result.Path = $line.Substring("Path: ".Length); }
                                                  elseif( $line.StartsWith("Revision: ") ){ $result.Revision = $line.Substring("Revision: ".Length); }
                                                }
                                                if( (StringIsNullOrEmpty $result.Url     ) ){ throw [Exception] "missing URL tag in svn info"; }
                                                if( (StringIsNullOrEmpty $result.Path    ) ){ throw [Exception] "missing Path tag in svn info"; }
                                                if( (StringIsNullOrEmpty $result.Revision) ){ throw [Exception] "missing Revision tag in svn info"; }
                                                $result.RealmPattern = ($result.Url -Split "/svn/")[0] + $(switch(($result.Url -split "/")[0]){ "https:"{":443"} "http:"{":80"} default{""} });
                                                $result.CachedAuthorizationFile = "";
                                                $result.CachedAuthorizationUser = "";
                                                # svn can cache more than one server connection option,
                                                # so we need to find the correct one by matching the realmPattern in realmstring which identifies a server connection.
                                                [String] $svnCachedAuthorizationDir = "$env:APPDATA\Subversion\auth\svn.simple";
                                                # care only file names like "25ff84926a354d51b4e93754a00064d6"
                                                [String[]] $files = FsEntryListAsStringArray "$svnCachedAuthorizationDir\*" $false $false | 
                                                    Where-Object{ (FsEntryGetFileName $_) -match "^[0-9a-f]{32}$" } | Sort-Object;
                                                foreach( $f in $files ){
                                                  [String[]] $lines = FileReadContentAsLines $f;
                                                  # filecontent example:
                                                  #   K 8
                                                  #   passtype
                                                  #   V 8
                                                  #   wincrypt
                                                  #   K 8
                                                  #   password
                                                  #   V 372
                                                  #   AQAAANCMnd8BFdERjHoAwE/Cl+sBAAA...CyYFl6mdAgM/J+hAAAADXKelrAkkWAOt1Tm5kQ
                                                  #   K 15
                                                  #   svn:realmstring
                                                  #   V 35
                                                  #   <https://myhost:443> VisualSVN Server
                                                  #   K 8
                                                  #   username
                                                  #   V 2
                                                  #   xy
                                                  #   END
                                                  [String] $realm = "";
                                                  [String] $user = "";
                                                  for ($i = 1; $i -lt $lines.Length; $i += 2){
                                                    if(     $lines[$i] -eq "svn:realmstring" ){ $realm = $lines[$i+2]; }
                                                    elseif( $lines[$i] -eq "username"        ){ $user  = $lines[$i+2]; }
                                                  }
                                                  if( $realm -ne "" ){
                                                    if( $realm.StartsWith("<$($result.RealmPattern)>") ){
                                                      if( $result.CachedAuthorizationFile -ne "" ){ throw [Exception] "There exist more than one file with realmPattern='$($result.RealmPattern)': '$($result.CachedAuthorizationFile)' and '$f'. "; }
                                                      $result.CachedAuthorizationFile = $f;
                                                      $result.CachedAuthorizationUser = $user;
                                                    }
                                                  }
                                                }
                                                OutProgress "SvnEnvInfo: Url=$($result.Url) Path='$($result.Path)' User='$($result.CachedAuthorizationUser)' Revision='$($result.Revision)'"; # not used: RealmPattern='$($r.RealmPattern)' CachedAuthorizationFile='$($r.CachedAuthorizationFile)' 
                                                return $result; }
function SvnGetDotSvnDir                      ( $workSubDir ){
                                                # return absolute .svn dir up from given dir which must exists
                                                [String] $d = FsEntryGetAbsolutePath $workSubDir;
                                                for( [Int32] $i = 0; $i -lt 200; $i++ ){
                                                  if( DirExists "$d\.svn" ){ return [String] "$d\.svn"; }
                                                  $d = FsEntryGetAbsolutePath (Join-Path $d "..");
                                                }
                                                throw [Exception] "Missing directory '.svn' within or up from the path '$workSubDir'"; }
function SvnAuthorizationSave                ( [String] $workDir, [String] $user ){
                                                # if this part fails then you should clear authorization account in svn settings
                                                OutProgress "SvnAuthorizationSave user=$user";
                                                FileAppendLineWithTs $svnLogFile "SvnAuthorizationSave(`"$workDir`")";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                DirCopyToParentDirByAddAndOverwrite "$env:APPDATA\Subversion\auth\svn.simple" "$dotSvnDir\OwnSvnAuthSimpleSaveUser_$user\"; }
function SvnAuthorizationTryLoadFile          ( [String] $workDir, [String] $user ){
                                                # if work auth dir exists then copy content to svn cache dir
                                                OutProgress "SvnAuthorizationTryLoadFile - try to reload from an earlier save";
                                                FileAppendLineWithTs $svnLogFile "SvnAuthorizationTryLoadFile(`"$workDir`")";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                [String] $svnWorkAuthDir = "$dotSvnDir\OwnSvnAuthSimpleSaveUser_$user\svn.simple";
                                                [String] $svnAuthDir = "$env:APPDATA\Subversion\auth\";
                                                if( DirExists $svnWorkAuthDir ){
                                                  DirCopyToParentDirByAddAndOverwrite $svnWorkAuthDir $svnAuthDir;
                                                }else{
                                                  OutProgress "Load not done because not found dir: '$svnWorkAuthDir'";
                                                } } # for later usage: function SvnAuthorizationClear (){ FileAppendLineWithTs $svnLogFile "SvnAuthorizationClear"; [String] $svnAuthCurr = "$env:APPDATA\Subversion\auth\svn.simple"; DirCopyToParentDirByAddAndOverwrite $svnAuthCurr $svnAuthWork; }
function SvnCleanup                           ( [String] $workDir ){
                                                # cleanup a previously failed checkout, update or commit operation.
                                                FileAppendLineWithTs $svnLogFile "SvnCleanup(`"$workDir`")";
                                                # for future alternative option: --trust-server-cert-failures unknown-ca,cn-mismatch,expired,not-yet-valid,other
                                                [String[]] $out = & (SvnExe) "cleanup" --non-interactive $workDir; AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2); }
function SvnStatus                            ( [String] $workDir, [Boolean] $showFiles ){
                                                # return true if it has any pending changes, otherwise false.
                                                # example: "M       D:\Work\..."
                                                # first char: Says if item was added, deleted, or otherwise changed
                                                #   ' ' no modifications
                                                #   'A' Added
                                                #   'C' Conflicted
                                                #   'D' Deleted
                                                #   'I' Ignored
                                                #   'M' Modified
                                                #   'R' Replaced
                                                #   'X' an unversioned directory created by an externals definition
                                                #   '?' item is not under version control
                                                #   '!' item is missing (removed by non-svn command) or incomplete, maybe an update was aborted
                                                #   '~' versioned item obstructed by some item of a different kind
                                                # Second column: Modifications of a file's or directory's properties
                                                #   ' ' no modifications
                                                #   'C' Conflicted
                                                #   'M' Modified
                                                # Third column: Whether the working copy is locked for writing by another Subversion client modifying the working copy
                                                #   ' ' not locked for writing
                                                #   'L' locked for writing
                                                # Fourth column: Scheduled commit will contain addition-with-history
                                                #   ' ' no history scheduled with commit
                                                #   '+' history scheduled with commit
                                                # Fifth column: Whether the item is switched or a file external
                                                #   ' ' normal
                                                #   'S' the item has a Switched URL relative to the parent
                                                #   'X' a versioned file created by an eXternals definition
                                                # Sixth column: Whether the item is locked in repository for exclusive commit (without -u)
                                                #   ' ' not locked by this working copy
                                                #   'K' locked by this working copy, but lock might be stolen or broken (with -u)
                                                #   ' ' not locked in repository, not locked by this working copy
                                                #   'K' locked in repository, lock owned by this working copy
                                                #   'O' locked in repository, lock owned by another working copy
                                                #   'T' locked in repository, lock owned by this working copy was stolen
                                                #   'B' not locked in repository, lock owned by this working copy is broken
                                                # Seventh column: Whether the item is the victim of a tree conflict
                                                #   ' ' normal
                                                #   'C' tree-Conflicted
                                                # If the item is a tree conflict victim, an additional line is printed after the item's status line, explaining the nature of the conflict.
                                                FileAppendLineWithTs $svnLogFile "SvnStatus(`"$workDir`")";
                                                OutVerbose "SvnStatus - List pending changes";
                                                [String[]] $out = & (SvnExe) "status" $workDir; AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                [Int32] $nrOfPendingChanges = $out | wc -l; # maybe we can ignore lines with '!'
                                                OutProgress "NrOfPendingChanged=$nrOfPendingChanges";
                                                FileAppendLineWithTs $svnLogFile "  NrOfPendingChanges=$nrOfPendingChanges";
                                                [Boolean] $hasAnyChange = $nrOfPendingChanges -gt 0;
                                                if( $showFiles -and $hasAnyChange ){ $out | %{ OutProgress $_; }; }
                                                return [Boolean] $hasAnyChange; }
function SvnRevert                            ( [String] $workDir, [String[]] $relativeRevertFsEntries ){
                                                # undo the specified fs-entries if they have any pending change
                                                foreach( $f in $relativeRevertFsEntries ){
                                                  FileAppendLineWithTs $svnLogFile "SvnRevert(`"$workDir\$f`")";
                                                  [String[]] $out = & (SvnExe) "revert" "--recursive" "$workDir\$f"; AssertRcIsOk $out;
                                                  FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                } }
function SvnCommit                            ( [String] $workDir ){
                                                FileAppendLineWithTs $svnLogFile "SvnCommit(`"$workDir`") call checkin dialog";
                                                [String] $tortoiseExe = (RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "Directory") + ".\bin\TortoiseProc.exe";
                                                Start-Process -NoNewWindow -Wait -FilePath "$tortoiseExe" -ArgumentList @("/closeonend:2","/command:commit","/path:`"$workDir`""); AssertRcIsOk; }
function SvnUpdate                            ( [String] $workDir, [String] $user ){ SvnCheckoutAndUpdate $workDir "" $user $true; }
function SvnCheckoutAndUpdate                 ( [String] $workDir, [String] $url, [String] $user, [Boolean] $doUpdateOnly = $false, [String] $pw = "" ){
                                                # init working copy and get (init and update) last changes. If pw is empty then it uses svn-credential-cache.
                                                # If specified update-only then no url is nessessary but if given then it verifies it.
                                                # note: we do not use svn-update because svn-checkout does the same (the difference is only the use of an url).
                                                # note: sometimes often after 5-20 GB received there is network problem which aborts svn-checkout,
                                                #   if it is recognised as a known exception then it will automatically cleanup, 30 sec wait and retry (max 100 times).
                                                if( $doUpdateOnly ){ 
                                                  Assert ((DirExists $workDir) -and (SvnGetDotSvnDir $workDir)) "Missing work dir or it is not a svn repo: '$workDir'";
                                                  [String] $repoUrl = (SvnEnvInfoGet $workDir).Url;
                                                  if( $url -eq "" ){ $url = $repoUrl; }else{ Assert ($url -eq $repoUrl) "Given url=$url does not match url in repository: $repoUrl"; }
                                                }
                                                [String] $tmp = (FileGetTempFile);
                                                [Int32] $maxNrOfTries = 100; [Int32] $nrOfTries = 0;
                                                while($true){ $nrOfTries++;
                                                  OutProgress "SvnCheckoutAndUpdate: get all changes from $url to '$workDir' $(switch($doUpdateOnly){($true){''}default{'and if it not exists and then init working copy first'}}).";
                                                  FileAppendLineWithTs $svnLogFile "SvnCheckoutAndUpdate(`"$workDir`",$url,$user)";
                                                  # for future alternative option: --trust-server-cert-failures unknown-ca,cn-mismatch,expired,not-yet-valid,other
                                                  # for future alternative option: --quite
                                                  [String[]] $opt = @( "--non-interactive", "--ignore-externals" );
                                                  if( $user -ne "" ){ $opt += @( "--username", $user ); }
                                                  if( $pw -ne "" ){ $opt += @( "--password", $pw, "--no-auth-cache" ); } # is visible in process list.
                                                  # alternative for checkout: tortoiseExe /closeonend:2 /command:checkout /path:$workDir /url:$url
                                                  if( $doUpdateOnly ){ $opt = @( "update"  ) + $opt + @(       $workDir ); }
                                                  else               { $opt = @( "checkout") + $opt + @( $url, $workDir ); }
                                                  FileAppendLineWithTs $svnLogFile "`"$(SvnExe)`" $opt";
                                                  try{
                                                    & (SvnExe) $opt 2> $tmp | %{ FileAppendLineWithTs $svnLogFile ("  "+$_); OutProgress $_ 2; };
                                                    AssertRcIsOk (FileReadContentAsLines $tmp) $true;
                                                    # ex: svn: E170013: Unable to connect to a repository at URL 'https://mycomp/svn/Work/mydir'
                                                    #     svn: E230001: Server SSL certificate verification failed: issuer is not trusted   Exception: Last operation failed [rc=1].
                                                    break;
                                                  }catch{
                                                    # ex: "svn: E120106: ra_serf: The server sent a truncated HTTP response body"
                                                    # ex: "svn: E155037: Previous operation has not finished; run 'cleanup' if it was interrupted"
                                                    # ex: "svn: E155004: Run 'svn cleanup' to remove locks (type 'svn help cleanup' for details)"
                                                    # ex: "svn: E175002: REPORT request on '/svn/Work/!svn/me' failed"
                                                    # ex: "svn: E170013: Unable to connect to a repository at URL 'https://myserver/svn/myrepo'."
                                                    # ex: "svn: E200030: sqlite[S10]: disk I/O error, executing statement 'VACUUM '"
                                                    # ex: "svn: E205000: Try 'svn help checkout' for more information"
                                                    [String] $m = $_.Exception.Message;
                                                    [String] $msg = "$(ScriptGetCurrentFunc)(dir=`"$workDir`",url=$url,user=$user) failed because $m. Logfile='$svnLogFile'.";
                                                    FileAppendLineWithTs $svnLogFile $msg;
                                                    [Boolean] $isKnownProblemToSolveWithRetry = $m.Contains(" E120106:") -or $m.Contains(" E155037:") -or $m.Contains(" E155004:") -or $m.Contains(" E170013:") -or $m.Contains(" E175002:") -or $m.Contains(" E200030:");
                                                    if( -not $isKnownProblemToSolveWithRetry -or $nrOfTries -ge $maxNrOfTries ){ throw [Exception] $msg; }
                                                    [String] $msg2 = "Is try nr $nrOfTries of $maxNrOfTries, will do cleanup, wait 30 sec and if not reached max then retry.";
                                                    OutWarning "$msg $msg2";
                                                    FileAppendLineWithTs $svnLogFile $msg2;
                                                    SvnCleanup $workDir;
                                                    ProcessSleepSec 30;
                                                  }finally{ FileDelTempFile $tmp; } } }
function SvnPreCommitCleanupRevertAndDelFiles ( [String] $workDir, [String[]] $relativeDelFsEntryPatterns, [String[]] $relativeRevertFsEntries ){
                                                OutInfo "SvnPreCommitCleanupRevertAndDelFiles '$workDir'";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                [String] $svnRequiresCleanup = "$dotSvnDir\OwnSvnRequiresCleanup.txt";
                                                if( (FileExists $svnRequiresCleanup) ){ # optimized because it is slow
                                                  OutProgress "SvnCleanup - Perform cleanup because previous run was not completed";
                                                  SvnCleanup $workDir;
                                                  FileDelete $svnRequiresCleanup;
                                                }
                                                OutProgress "Remove known unused temp, cache and log directories and files";
                                                FsEntryJoinRelativePatterns $workDir $relativeDelFsEntryPatterns | 
                                                  ForEach-Object{ FsEntryListAsStringArray $_ } | Where-Object{ $_ -ne "" } |
                                                  ForEach-Object{ FileAppendLines $svnLogFile "  Delete: `"$_`""; FsEntryDelete $_; };
                                                OutProgress "SvnRevert - Restore known unwanted changes of directories and files";
                                                SvnRevert $workDir $relativeRevertFsEntries; }
function SvnCommitAndGet                      ( [String] $workDir, [String] $svnUrl, [String] $svnUser, [Boolean] $ignoreIfHostNotReachable ){
                                                # assumes stored credentials are matching specified svn user, check svn dir, do svn cleanup, check svn user, delete temporary files, svn commit, svn update
                                                [String] $traceInfo = "SvnCommitAndGet workdir='$workDir' url=$svnUrl user=$svnUser";
                                                OutInfo "$traceInfo svnLogFile=`"$svnLogFile`"";
                                                FileAppendLineWithTs $svnLogFile ("`r`n"+("-"*80)+"`r`n"+(DateTimeNowAsStringIso "yyyy-MM-dd HH:mm")+" "+$traceInfo);
                                                try{
                                                  [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                  [String] $svnRequiresCleanup = "$dotSvnDir\OwnSvnRequiresCleanup.txt";
                                                  # check preconditions
                                                  if( $svnUrl  -eq "" ){ throw [Exception] "SvnUrl is empty which is not allowed"; }
                                                  if( $svnUser -eq "" ){ throw [Exception] "SvnUser is empty which is not allowed"; }
                                                  #
                                                  [SvnEnvInfo] $r = SvnEnvInfoGet $workDir;
                                                  #
                                                  OutProgress "Verify expected SvnUser='$svnUser' matches CachedAuthorizationUser='$($r.CachedAuthorizationUser)' - if last user was not found then try to load it";
                                                  if( $r.CachedAuthorizationUser -eq "" ){
                                                    SvnAuthorizationTryLoadFile $workDir $svnUser;
                                                    $r = SvnEnvInfoGet $workDir;
                                                  }
                                                  if( $r.CachedAuthorizationUser -eq "" ){ throw [Exception] "This script asserts that configured SvnUser='$svnUser' matches last accessed user because it requires stored credentials, but last user was not saved, please call svn-repo-browser, login, save authentication and then retry."; }
                                                  if( $svnUser -ne $r.CachedAuthorizationUser ){ throw [Exception] "Configured SvnUser='$svnUser' does not match last accessed user='$($r.CachedAuthorizationUser)', please call svn-settings, clear cached authentication-data, call svn-repo-browser, login, save authentication and then retry."; }
                                                  #
                                                  [String] $host = NetExtractHostName $svnUrl;
                                                  if( $ignoreIfHostNotReachable -and -not (NetPingHostIsConnectable $host) ){
                                                    OutWarning "Host '$host' is not reachable, so ignored.";
                                                    return;
                                                  }
                                                  #
                                                  FileAppendLineWithTs $svnRequiresCleanup "";
                                                  [Boolean] $hasAnyChange = SvnStatus $workDir $false;
                                                  while( $hasAnyChange ){
                                                    OutProgress "SvnCommit - Calling dialog to checkin all pending changes and wait for end of it";
                                                    SvnCommit $workDir;
                                                    $hasAnyChange = SvnStatus $workDir $true;
                                                  }
                                                  #
                                                  SvnCheckoutAndUpdate $workDir $svnUrl $svnUser;
                                                  SvnAuthorizationSave $workDir $svnUser;
                                                  [SvnEnvInfo] $r = SvnEnvInfoGet $workDir;
                                                  #
                                                  FileDelete $svnRequiresCleanup;
                                                }catch{
                                                  FileAppendLineWithTs $svnLogFile (StringFromException $_.Exception);
                                                  throw;
                                                } }
function GitCmd                               ( [String] $cmd, [String] $tarRootDir, [String] $url, [Boolean] $errorAsWarning = $false ){
                                                # ex: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib"
                                                # $cmd == "Clone": target dir must not exist.
                                                # $cmd == "Fetch": target dir must exist.
                                                # $cmd == "Pull" : target dir must exist. [git pull] is the same as [git fetch] and then [git merge FETCH_HEAD]. [git pull -rebase] runs [git rebase] instead of [git merge].
                                                if( @("Clone","Fetch","Pull") -notcontains $cmd ){ throw [Exception] "Expected one of (Clone,Fetch,Pull) instead of: $cmd"; }
                                                [Boolean] $doChangeDir = @("Fetch","Pull") -contains $cmd;
                                                [String] $dir = FsEntryGetAbsolutePath (GitBuildLocalDirFromUrl $tarRootDir $url);
                                                [String[]] $out = $null;
                                                try{
                                                  if( $doChangeDir ){
                                                    OutProgressText "cd '$dir'; ";
                                                    Push-Location -Path $dir; # required depending on repo config
                                                  } 
                                                  # ex: remote: Counting objects: 123, done. \n Receiving objects: 56% (33/123)  0 (delta 0), pack-reused ... \n Receiving objects: 100% (123/123), 205.12 KiB | 0 bytes/s, done. \n Resolving deltas: 100% (123/123), done.
                                                  if( $cmd -eq "Clone" ){
                                                    $out = ProcessStart "git" @( "--git-dir=$dir\.git", "clone", "--quiet", $url, $dir) $false $true; # writes to stderr: Cloning into 'c:\temp\test'...
                                                  }elseif( $cmd -eq "Fetch" ){
                                                    $out = ProcessStart "git" @( "--git-dir=$dir\.git", "fetch", "--quiet", $url) $false $true; # writes to stderr: From https://github.com/myrepo  * branch  HEAD  -> FETCH_HEAD.
                                                  }elseif( $cmd -eq "Pull" ){
                                                    $out = ProcessStart "git" @( "--git-dir=$dir\.git", "pull", "--quiet", "--no-stat", $url) $false; # defaults: "--no-rebase" "origin"; writes to stderr: Checking out files:  47% (219/463)  Already up to date. From https://github.com/myrepo  * branch  HEAD  -> FETCH_HEAD
                                                  }else{ throw [Exception] "Unknown git cmd='$cmd'"; }
                                                  OutSuccess "  Ok. $out";
                                                }catch{
                                                  # ex: fatal: AggregateException encountered.
                                                  # ex: Logon failed, use ctrl+c to cancel basic credential prompt.
                                                  # ex: remote: Repository not found. fatal: repository 'https://github.com/mniederw/UnknownRepo/' not found
                                                  # ex: fatal: Not a git repository: 'D:\WorkGit\mniederw\UnknownRepo\.git'
                                                  # ex: error: Your local changes to the following files would be overwritten by merge:
                                                  # ex: error: unknown option `anyUnknownOption'
                                                  $msg = "$(ScriptGetCurrentFunc)($cmd,$tarRootDir,$url) failed because $($_.Exception.Message)";
                                                  ScriptResetRc;
                                                  if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                  OutWarning $msg;
                                                }finally{
                                                  if( $doChangeDir ){ Pop-Location; }
                                                } }
function GitCloneOrFetchOrPull                ( [String] $tarRootDir, [String] $url, [Boolean] $usePullNotFetch = $false, [Boolean] $errorAsWarning = $false ){
                                                # extracts path of url below host as relative dir, uses this path below target root dir to create or update git; 
                                                # ex: GitCloneOrFetchOrPull "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib"
                                                [String] $tarDir = (GitBuildLocalDirFromUrl $tarRootDir $url);
                                                if( (DirExists $tarDir) ){
                                                  if( $usePullNotFetch ){
                                                    GitCmd "Pull" $tarRootDir $url $errorAsWarning;
                                                  }else{
                                                    GitCmd "Fetch" $tarRootDir $url $errorAsWarning;
                                                  }
                                                }else{
                                                  GitCmd "Clone" $tarRootDir $url $errorAsWarning;
                                                } }
function GitListCommitComments                ( [String] $tarDir, [String] $localRepoDir, [String] $fileExtension = ".tmp", [String] $prefix = "Log.", [Int32] $doOnlyIfOlderThanAgeInDays = 14 ){
                                                # overwrite git log info files below specified target dir, 
                                                # For the name of the repo it takes the two last dir parts separated with a dot (NameOfRepoParent.NameOfRepo).
                                                # it writes files as Log.NameOfRepoParent.NameOfRepo.CommittedComments.tmp and Log.NameOfRepoParent.NameOfRepo.CommittedChangedFiles.tmp 
                                                # it is quite slow about 10 sec per repo, so it can controlled by $doOnlyIfOlderThanAgeInDays.
                                                # ex: GitListCommitComments "C:\WorkGit\_CommitComments" "C:\WorkGit\mniederw\MnCommonPsToolLib"
                                                [String] $dir = FsEntryGetAbsolutePath $localRepoDir;
                                                [String] $repoName =  (Split-Path -Leaf (Split-Path -Parent $dir)) + "." + (Split-Path -Leaf $dir);
                                                function GitGetLog ([String] $mode, [String] $fout) {
                                                  if( -not (FsEntryNotExistsOrIsOlderThanNrDays $fout $doOnlyIfOlderThanAgeInDays) ){
                                                    OutProgress "Process git log not nessessary because file is newer than $doOnlyIfOlderThanAgeInDays days: $fout";
                                                  }else{
                                                    [String[]] $options = @( "--git-dir=$dir\.git", "log", "--after=1990-01-01", "--pretty=format:%ci %cn/%ce %s", $mode );
                                                    OutProgressText "git $options ; ";
                                                    [String[]] $out = @();
                                                    try{
                                                      $out = & "git" $options 2>&1; AssertRcIsOk $out;
                                                    }catch{
                                                      if( $_.Exception.Message -eq "fatal: your current branch 'master' does not have any commits yet" ){ # Last operation failed [rc=128]
                                                        $out += "Info: your current branch 'master' does not have any commits yet.";
                                                        OutProgressText "Info: empty master.";
                                                      }else{
                                                        $out += "Warning: GitListCommitComments($localRepoDir) failed because $($_.Exception.Message)";
                                                        OutProgressText $out;
                                                      }
                                                      ScriptResetRc;
                                                    }
                                                    FileWriteFromLines $fout $out $true;
                                                  }
                                                }
                                                GitGetLog ""          "$tarDir\$prefix$repoName.CommittedComments$fileExtension";
                                                GitGetLog "--summary" "$tarDir\$prefix$repoName.CommittedChangedFiles$fileExtension"; }
function GitCloneOrFetchIgnoreError           ( [String] $tarRootDir, [String] $url ){ GitCloneOrFetchOrPull $tarRootDir $url $false $true; }
function GitCloneOrPullIgnoreError            ( [String] $tarRootDir, [String] $url ){ GitCloneOrFetchOrPull $tarRootDir $url $true  $true; }
function GitBuildLocalDirFromUrl              ( [String] $tarRootDir, [String] $url ){ return [String] (FsEntryGetAbsolutePath (Join-Path $tarRootDir ([System.Uri]$url).AbsolutePath.Replace("/","\"))); }
                                                # ex: GitBuildLocalDirFromUrl(".\gitdir","http://myhost/mydir1/dir2") == "C:\gitdir\mydir1\dir2";
function PrivShowTokenPrivileges              (){ 
                                                whoami /priv; }
function PrivEnableTokenPrivilege             (){
                                                # required for example for Set-ACL if it returns "The security identifier is not allowed to be the owner of this object."; Then you need for example the Privilege SeRestorePrivilege;
                                                # taken from https://gist.github.com/fernandoacorreia/3997188 or http://www.leeholmes.com/blog/2010/09/24/adjusting-token-privileges-in-powershell/ 
                                                #   or https://social.technet.microsoft.com/forums/windowsserver/en-US/e718a560-2908-4b91-ad42-d392e7f8f1ad/take-ownership-of-a-registry-key-and-change-permissions
                                                # alternative: https://www.powershellgallery.com/packages/PoshPrivilege/0.3.0.0/Content/Scripts%5CEnable-Privilege.ps1
                                                param(
                                                  # The privilege to adjust. This set is taken from http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
                                                  [ValidateSet(
                                                    "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege", "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege", "SeCreatePermanentPrivilege", 
                                                    "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege", "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege", 
                                                    "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege", "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege", 
                                                    "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege", "SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege", "SeSystemEnvironmentPrivilege", 
                                                    "SeSystemProfilePrivilege", "SeSystemtimePrivilege", "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege", "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
                                                    $Privilege,
                                                  # The process on which to adjust the privilege. Defaults to the current process.
                                                  $ProcessId = $PID,
                                                  # Switch to disable the privilege, rather than enable it.
                                                  [Switch] $Disable
                                                )
                                                ## Taken from P/Invoke.NET with minor adjustments.
                                                [String] $t = '';
                                                $t += ' using System; using System.Runtime.InteropServices; public class AdjPriv { ';
                                                $t += '  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)] internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen); ';
                                                $t += '  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)] internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok); ';
                                                $t += '  [DllImport("advapi32.dll",                       SetLastError = true)] internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid); ';
                                                $t += '  [StructLayout(LayoutKind.Sequential, Pack = 1)] internal struct TokPriv1Luid { public int Count; public long Luid; public int Attr; } ';
                                                $t += '  internal const int SE_PRIVILEGE_ENABLED = 0x00000002; internal const int SE_PRIVILEGE_DISABLED = 0x00000000; internal const int TOKEN_QUERY = 0x00000008; internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020; ';
                                                $t += '  public static bool EnablePrivilege( long processHandle, string privilege, bool disable ){ ';
                                                $t += '    IntPtr hproc = new IntPtr(processHandle); IntPtr htok = IntPtr.Zero; ';
                                                $t += '    bool retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok); ';
                                                $t += '    TokPriv1Luid tp; tp.Count = 1; tp.Luid = 0; if(disable){ tp.Attr = SE_PRIVILEGE_DISABLED; }else{ tp.Attr = SE_PRIVILEGE_ENABLED; } ';
                                                $t += '    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid); ';
                                                $t += '    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero); ';
                                                $t += '    return retVal; ';
                                                $t += '  } ';
                                                $t += '} ';
                                                $processHandle = (Get-Process -id $ProcessId).Handle;
                                                $type = Add-Type -TypeDefinition $t -PassThru; # -PassThru makes that you get: System.Reflection.TypeInfo
                                                $priv = $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable); }
function PrivEnableTokenAll                   (){
                                                PrivEnableTokenPrivilege SeLockMemoryPrivilege          ;
                                                PrivEnableTokenPrivilege SeIncreaseQuotaPrivilege       ;
                                                PrivEnableTokenPrivilege SeSecurityPrivilege            ;
                                                PrivEnableTokenPrivilege SeTakeOwnershipPrivilege       ; # to override file permissions
                                                PrivEnableTokenPrivilege SeLoadDriverPrivilege          ;
                                                PrivEnableTokenPrivilege SeSystemProfilePrivilege       ;
                                                PrivEnableTokenPrivilege SeSystemtimePrivilege          ;
                                                PrivEnableTokenPrivilege SeProfileSingleProcessPrivilege;
                                                PrivEnableTokenPrivilege SeIncreaseBasePriorityPrivilege;
                                                PrivEnableTokenPrivilege SeCreatePagefilePrivilege      ;
                                                PrivEnableTokenPrivilege SeBackupPrivilege              ; # to bypass traverse checking
                                                PrivEnableTokenPrivilege SeRestorePrivilege             ; # to set owner permissions
                                                PrivEnableTokenPrivilege SeShutdownPrivilege            ;
                                                PrivEnableTokenPrivilege SeDebugPrivilege               ;
                                                PrivEnableTokenPrivilege SeSystemEnvironmentPrivilege   ;
                                                PrivEnableTokenPrivilege SeChangeNotifyPrivilege        ;
                                                PrivEnableTokenPrivilege SeRemoteShutdownPrivilege      ;
                                                PrivEnableTokenPrivilege SeUndockPrivilege              ;
                                                PrivEnableTokenPrivilege SeManageVolumePrivilege        ;
                                                PrivEnableTokenPrivilege SeImpersonatePrivilege         ;
                                                PrivEnableTokenPrivilege SeCreateGlobalPrivilege        ;
                                                PrivEnableTokenPrivilege SeIncreaseWorkingSetPrivilege  ;
                                                PrivEnableTokenPrivilege SeTimeZonePrivilege            ;
                                                PrivEnableTokenPrivilege SeCreateSymbolicLinkPrivilege  ;
                                                whoami /priv;
                                              }
function JuniperNcEstablishVpnConn            ( [String] $secureCredentialFile, [String] $url, [String] $realm ){
                                                [String] $serviceName = "DsNcService";
                                                [String] $vpnProg = "${env:ProgramFiles(x86)}\Juniper Networks\Network Connect 8.0\nclauncher.exe";
                                                # using: nclauncher [-url Url] [-u username] [-p password] [-r realm] [-help] [-stop] [-signout] [-version] [-d DSID] [-cert client certificate] [-t Time(Seconds min:45, max:600)] [-ir true | false]
                                                # alternatively we could take: "HKLM\SOFTWARE\Wow6432Node\Juniper Networks\Network Connect 8.0\InstallPath":  C:\Program Files (x86)\Juniper Networks\Network Connect 8.0
                                                function JuniperNetworkConnectStop(){
                                                  OutProgress "Call: '$vpnProg' -signout";
                                                  try{
                                                    [String] $out = & "$vpnProg" "-signout";
                                                    if( $out -eq "Network Connect is not running. Unable to signout from Secure Gateway." ){
                                                      # ex: "Network Connect wird nicht ausgef³hrt. Die Abmeldung vom sicheren Gateway ist nicht m÷glich."
                                                      ScriptResetRc; OutVerbose "Service is not running.";
                                                    }else{ AssertRcIsOk $out; }
                                                  }catch{ ScriptResetRc; OutProgress "Ignoring signout exception: $($_)"; }
                                                }
                                                function JuniperNetworkConnectStart( [Int32] $maxPwTries = 9 ){
                                                  for ($i = 1; $i -le $maxPwTries; $i += 1){
                                                    OutVerbose "Read last saved encrypted username and password: '$secureCredentialFile'";
                                                    [System.Management.Automation.PSCredential] $cred = CredentialGetAndStoreIfNotExists $secureCredentialFile;
                                                    [String] $username = $cred.UserName;
                                                    [String] $password = CredentialGetTextFromSecureString $cred.Password;
                                                    OutDebug "UserName='$username'  Password='$password'";
                                                    OutProgress "Call: $vpnProg -url $url -u $username -r $realm -t 75 -p *** ";
                                                    [String] $out = & $vpnProg "-url" $url "-u" $username "-r" $realm "-t" "75" "-p" $password; ScriptResetRc;
                                                    ProcessSleepSec 2; # required to make ready to use rdp
                                                    if( $out -eq "The specified credentials do not authenticate." -or $out -eq "Die Authentifizierung ist mit den angegebenen Anmeldeinformationen nicht m÷glich." ){
                                                      # on some machines we got german messages
                                                      OutProgress "Handling authentication failure by removing credential file and retry";
                                                      CredentialRemoveFile $secureCredentialFile; }
                                                    elseif( $out -eq "Network Connect has started." -or $out -eq "Network Connect is already running" -or $out -eq "Network Connect wurde gestartet." ){ return; }
                                                    else{ OutWarning "Ignoring unexpected program output: '$out', will continue but maybe it does not work"; ProcessSleepSec 5; return; }
                                                  }
                                                  throw [Exception] "Authentication failed with specified credentials, credential file was removed, please retry";
                                                }
                                                OutProgress "Using vpn program '$vpnProg'";
                                                OutProgress "Arguments: credentialFile='$secureCredentialFile', url='$url', realm='$realm'";
                                                if( $url -eq "" -or $secureCredentialFile -eq "" -or $url -eq "" -or $realm  -eq "" ){ throw [Exception] "Missing an argument"; }
                                                FileAssertExists $vpnProg;
                                                ServiceAssertExists $serviceName;
                                                ServiceStart $serviceName;
                                                JuniperNetworkConnectStop;
                                                JuniperNetworkConnectStart;
                                              }
function JuniperNcEstablishVpnConnAndRdp      ( [String] $rdpfile, [String] $url, [String] $realm ){
                                                [String] $secureCredentialFile = "$rdpfile.vpn-uspw.$ComputerName.txt";
                                                JuniperNcEstablishVpnConn $secureCredentialFile $url $realm;
                                                RdpConnect $rdpfile; }
function ToolTailFile                         ( [String] $file ){ OutProgress "Show tail of file until ctrl-c is entered"; Get-Content -Wait $file; }
function ToolSignDotNetAssembly               ( [String] $keySnk, [String] $srcDllOrExe, [String] $tarDllOrExe, [Boolean] $overwrite = $false ){
                                                # note: generate a key: sn.exe -k mykey.snk
                                                OutInfo "Sign dot-net assembly: keySnk='$keySnk' srcDllOrExe='$srcDllOrExe' tarDllOrExe='$tarDllOrExe' overwrite=$overwrite ";
                                                [Boolean] $isDllNotExe = $srcDllOrExe.ToLower().EndsWith(".dll");
                                                if( -not $isDllNotExe -and -not $srcDllOrExe.ToLower().EndsWith(".exe") ){ throw [Exception] "Expected ends with .dll or .exe, srcDllOrExe='$srcDllOrExe'"; }
                                                if( -not $overwrite -and (FileExists $tarDllOrExe) ){ OutProgress "Ok, target already exists: $tarDllOrExe"; return; }
                                                FsEntryCreateParentDir  $tarDllOrExe;
                                                [String] $n = FsEntryGetFileName $tarDllOrExe;
                                                [String] $d = DirCreateTemp "SignAssembly_";
                                                OutProgress "ildasm.exe -NOBAR -all `"$srcDllOrExe`" `"-out=$d\$n.il`"";
                                                & "ildasm.exe" -TEXT -all $srcDllOrExe "-out=$d\$n.il"; AssertRcIsOk;
                                                OutProgress "ilasm.exe -QUIET -DLL -PDB `"-KEY=$keySnk`" `"$d\$n.il`" `"-RESOURCE=$d\$n.res`" `"-OUTPUT=$tarDllOrExe`"";
                                                & "ilasm.exe" -QUIET -DLL -PDB "-KEY=$keySnk" "$d\$n.il" "-RESOURCE=$d\$n.res" "-OUTPUT=$tarDllOrExe"; AssertRcIsOk;
                                                DirDelete $d;
                                                # disabled because if we would take the pdb of unsigned assembly then ilmerge failes because pdb is outdated.
                                                #   [String] $srcPdb = (StringRemoveRightNr $srcDllOrExe 4) + ".pdb";
                                                #   [String] $tarPdb = (StringRemoveRightNr $tarDllOrExe 4) + ".pdb";
                                                #   if( FileExists $srcPdb ){ FileCopy $srcPdb $tarPdb $true; }
                                                [String] $srcXml = (StringRemoveRightNr $srcDllOrExe 4) + ".xml";
                                                [String] $tarXml = (StringRemoveRightNr $tarDllOrExe 4) + ".xml";
                                                if( FileExists $srcXml ){ FileCopy $srcXml $tarXml $true; }
                                                }
function ToolPerformFileUpdateAndIsActualized ( [String] $targetFile, [String] $url, [Boolean] $requireElevatedAdminMode, [Boolean] $doWaitIfFailed = $false, [String] $additionalOkUpdMsg = "" ){
                                                # Assert the correct installed environment by requiring that the file to be update previously exists.
                                                # Assert the network is prepared by checking if host is reachable.
                                                # Then it downloads the hash file and checks it with the current installed file.
                                                # If there is any change then it requests for running as admin, it downloads the module and verifies it with the previously downloaded hash file.
                                                # Then the current module is actualized by overwriting its file and a success message is given out.
                                                # Otherwise if it failed it will output a warning message and optionally wait for pressing enter key.
                                                # It returns true if the file is now actualized.
                                                try{
                                                  [String] $hash512BitsSha2Url = "$url.sha2";
                                                  OutInfo "Check for update of $targetFile `n  from $url";
                                                  if( (FileNotExists $targetFile) ){ 
                                                    throw [Exception] "Unexpected environment, for updating it is required that target file previously exists but it does not: '$targetFile'";
                                                  }
                                                  [String] $host = (NetExtractHostName $url);
                                                  if( -not (Test-Connection -Cn $host -BufferSize 16 -Count 1 -ea 0 -Quiet) ){ 
                                                    throw [Exception] "Host '$host' is not pingable."; 
                                                  }
                                                  [String] $hash = (PsDownloadToString $hash512BitsSha2Url).TrimEnd();
                                                  [String] $hash2 = FileGetHexStringOfHash512BitsSha2 $targetFile;
                                                  if( $hash -eq $hash2 ){
                                                    OutProgress "Ok, is up to date, nothing done.";
                                                  }else{
                                                    OutProgress "There are changes between the current file and that from url, so going to download and install it.";
                                                    if( $requireElevatedAdminMode ){ 
                                                      ProcessRestartInElevatedAdminMode; 
                                                    }
                                                    [String] $tmp = (FileGetTempFile); PsDownloadFile $url $tmp;
                                                    [String] $hash3 = (FileGetHexStringOfHash512BitsSha2 $tmp);
                                                    if( $hash -ne $hash3 ){
                                                      throw [Exception] ("The hash of the downloaded file from $url`n"`
                                                        +"  (=$hash3)"`
                                                        +"  does not match the content of $hash512BitsSha2Url.`n"`
                                                        +"  (=$hash)"`
                                                        +"  Probably author did not update hash after updating source, then you must manually get source or wait until author updates hash."`
                                                        +"  "); 
                                                    }
                                                    FileMove $tmp $targetFile $true;
                                                    OutSuccess "Ok, updated '$targetFile'. $additionalOkUpdMsg";
                                                  }
                                                  return [Boolean] $true;
                                                }catch{
                                                  OutWarning "update failed because $($_.Exception.Message)";
                                                  if( $doWaitIfFailed ){ 
                                                    StdInReadLine "Press enter to continue."; 
                                                  }
                                                  return [Boolean] $false;
                                                } }
function MnCommonPsToolLibSelfUpdate          ( [Boolean] $doWaitForEnterKeyIfFailed = $false ){
                                                # If installed in standard mode (saved under c:\Program Files\WindowsPowerShell\Modules\...) then it performs a self update to the newest version from github.
                                                [String] $moduleName = "MnCommonPsToolLib";
                                                [String] $tarRootDir = "$Env:ProgramW6432\WindowsPowerShell\Modules"; # more see: https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx
                                                [String] $moduleFile = "$tarRootDir\$moduleName\$moduleName.psm1";                                               
                                                [String] $url = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/$moduleName/$moduleName.psm1";
                                                [String] $additionalOkUpdMsg = "`n  Please restart all processes which may have an old version of the modified env-vars before using functions of this library.";
                                                [Boolean] $dummyResult = ToolPerformFileUpdateAndIsActualized $moduleFile $url $true $doWaitForEnterKeyIfFailed $additionalOkUpdMsg;
                                              }

function MnLibCommonSelfTest(){ # perform some tests
  Assert ((2 + 3) -eq 5);
  Assert ([Math]::Min(-5,-9) -eq -9);
  Assert ("xyz".substring(1,0) -eq "");
  Assert ((DateTimeFromStringIso "2011-12-31"             ) -eq (Get-Date -Date "2011-12-31 00:00:00"    ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59"       ) -eq (Get-Date -Date "2011-12-31 23:59:00"    ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59"    ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59."   ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59.0"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.0"  ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59.9"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.9"  ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59.99" ) -eq (Get-Date -Date "2011-12-31 23:59:59.99" ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert ((DateTimeFromStringIso "2011-12-31T23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert (("abc" -split ",").Count -eq 1 -and "abc,".Split(",").Count -eq 2 -and ",abc".Split(",").Count -eq 2);
  Assert ((ByteArraysAreEqual @()               @()              ) -eq $true );
  Assert ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01,0xFF)) -eq $true );
  Assert ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x02,0xFF)) -eq $false);
  Assert ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01     )) -eq $false);
  Assert ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir") -eq "Dir1\Dir2\");
  Assert ((FsEntryMakeRelative "C:\MyDir" "C:\MyDir\") -eq ".");
  Assert ((Int32Clip -5 0 9) -eq 0 -and (Int32Clip 5 0 9) -eq 5 -and (Int32Clip 15 0 9) -eq 9);
  Assert ((StringRemoveRight "abc" "c") -eq "ab");
  Assert ((StringLeft          "abc" 5) -eq "abc" -and (StringLeft          "abc" 2) -eq "ab");
  Assert ((StringRight         "abc" 5) -eq "abc" -and (StringRight         "abc" 2) -eq "bc");
  Assert ((StringRemoveRightNr "abc" 5) -eq ""    -and (StringRemoveRightNr "abc" 1) -eq "ab");
  OutSuccess "Ok";
} # MnLibCommonSelfTest; # is deactivated because we know it works :-)

# ----------------------------------------------------------------------------------------------------

Export-ModuleMember -function *; # export all functions from this script which are above this line (types are implicit usable)

# Powershell useful additional documentation
# ==========================================
#
# - Common parameters used enable stdandard options:
#   [-Verbose] [-Debug] [-ErrorAction <ActionPreference>] [-WarningAction <ActionPreference>] [-ErrorVariable <String>] [-WarningVariable <String>] [-OutVariable <String>] [-OutBuffer <Int32>]
# - Parameter attribute declarations (ex: Mandatory, Position): https://msdn.microsoft.com/en-us/library/ms714348(v=vs.85).aspx 
# - Parameter validation attributes (ex: ValidateRange): https://social.technet.microsoft.com/wiki/contents/articles/15994.powershell-advanced-function-parameter-attributes.aspx#Parameter_Validation_Attributes
# - Enable powershell: before using any powershell script you must enable on 64bit and on 32bit environment!
#   It requires admin rights so either run a cmd.exe shell with admin mode and call:
#     64bit:  %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe Set-Executionpolicy -Scope LocalMachine Unrestricted
#     32bit:  %SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe Set-Executionpolicy -Scope LocalMachine Unrestricted
#   or the Set-Executionpolicy Unrestricted commandlet in both powershells
#   or run: reg.exe add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /f /t REG_SZ /v "ExecutionPolicy" /d "Unrestricted"
#   or run any ps1 even when in restricted mode with:  PowerShell.exe -ExecutionPolicy Unrestricted -NoProfile -File "myfile.ps1"
#   default is: powershell.exe Set-Executionpolicy Restricted
#   more: get-help about_signing
#   in Systemsteuerung->Standardprogramme you can associate .ps1 with C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe and make a shortcut ony any .ps1 file, then on clicking on shortcut it will run, but does not work if .ps1 is doubleclicked.
# - Not use: Note: we do not use $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") or Write-Error because different behaviour of powershell.exe and powershell_ise.exe
# - Extensions: download and install PowerShell Community Extensions (PSCX) for ntfs-junctions and symlinks.
# - Special predefined variables which are not yet used in this script (use by $global:anyprefefinedvar; names are case insensitive):
#   $null, $true, $false  - some constants
#   $args                 - Contains an array of the parameters passed to a function.
#   $error                - Contains objects for which an error occurred while being processed in a cmdlet.
#   $HOME                 - Specifies the user’s home directory. (C:\Users\myuser)
#   $PsHome               - The directory where the Windows PowerShell is installed. (C:\Windows\SysWOW64\WindowsPowerShell\v1.0)
#   $PROFILE              - C:\Users\myuser\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#   $PS...                - some variables
#   $MaximumAliasCount, $MaximumDriveCount, $MaximumErrorCount, $MaximumFunctionCount, $MaximumHistoryCount, $MaximumVariableCount   - some maximum values
#   $StackTrace, $ConsoleFileName, $ErrorView, $ExecutionContext, $Host, $input, $NestedPromptLevel, $PID, $PWD, $ShellId            - some environment values
#   $PSScriptRoot         - folder of current running script
# - Comparison operators; -eq, -ne, -lt, -le, -gt, -ge, "abcde" -like "aB?d*", -notlike, 
#   @( "a1", "a2" ) -contains "a2", -notcontains, "abcdef" -match "b[CD]", -notmatch, "abcdef" -cmatch "b[cd]", -notcmatch, -not
# - Automatic variables see: http://technet.microsoft.com/en-us/library/dd347675.aspx
#   $?            : Contains True if last operation succeeded and False otherwise.
#   $LASTEXITCODE : Contains the exit code of the last Win32 executable execution. should never manually set, even not: $global:LASTEXITCODE = $null;
# - Available colors for options -foregroundcolor and -backgroundcolor: 
#   Black DarkBlue DarkGreen DarkCyan DarkRed DarkMagenta DarkYellow Gray DarkGray Blue Green Cyan Red Magenta Yellow White
# - Manifest .psd1 file can be created with: New-ModuleManifest MnCommonPsToolLib.psd1 -ModuleVersion "1.0" -Author "Marc Niederwieser"
# - Know Bugs:
#   - Powershell V2 Bug: checking strings for $null is different between if and switch tests:
#     http://stackoverflow.com/questions/12839479/powershell-treats-empty-string-as-equivalent-to-null-in-switch-statements-but-no
#   - Variable or function argument of type String is never $null, if $null is assigned then always empty is stored. [String] $s; $s = $null; Assert ($s -ne $null); Assert ($s -eq "");
#     But if type String is within a struct then it can be null.  Add-Type -TypeDefinition "public struct MyStruct {public string MyVar;}"; Assert( (New-Object MyStruct).MyVar -eq $null );
#   - GetFullPath() works not with the current dir but with the working dir where powershell was started (ex. when running as administrator).
#     http://stackoverflow.com/questions/4071775/why-is-powershell-resolving-paths-from-home-instead-of-the-current-directory/4072205
#     powershell.exe         ; pwd <# ex: C:\Users\myuser     #>; echo hi > .\a.tmp ; [System.IO.Path]::GetFullPath(".\a.tmp")     <# is correct "C:\Users\myuser\a.tmp"     #>;
#     powershell.exe as Admin; pwd <# ex: C:\WINDOWS\system32 #>; cd C:\Users\myuser; [System.IO.Path]::GetFullPath(".\a.tmp")     <# is wrong   "C:\WINDOWS\system32\a.tmp" #>;
#                                                                                     [System.IO.Directory]::GetCurrentDirectory() <# is         "C:\WINDOWS\system32"       #>;
#                                                                                     (get-location).Path                          <# is         "C:\Users\myuser"           #>;
#                                                                                     Resolve-Path .\a.tmp                         <# is correct "C:\Users\myuser\a.tmp"     #>;
#                                                                                     (Get-Item -Path ".\a.tmp" -Verbose).FullName <# is correct "C:\Users\myuser\a.tmp"     #>;
#     Possible reasons: PS can have a regkey as current location. GetFullPath works with [System.IO.Directory]::GetCurrentDirectory().
#     Recommendation: do not use [System.IO.Path]::GetFullPath, use Resolve-Path.
#   - ForEach-Object iterates once with $null in pipeline:    see http://stackoverflow.com/questions/4356758/how-to-handle-null-in-the-pipeline
#     $null | ForEach-Object{ write-host "badly reached." }
#     But:  @() | ForEach-Object{ write-host "ok not reached." }
#     Workaround if array variable can be null, then use:  $null | Where-Object{ $_ -ne $null } | ForEach-Object{ write-host "ok not reached." }
#     Alternative: $null | ForEach-Object -Begin{if($_ -eq $null){continue}} -Process {do your stuff here}
#     Recommendation: Make sure an array variable is never null.
#   - Empty array in pipeline is converted to $null:  $r = ([String[]]@()) | Where-Object{ $_ -ne "bla" }; if( $r -eq $null ){ write-host "ok reached" };
#     Workaround:  $r = @()+(([String[]]@()) | Where-Object{ $_ -ne "bla" }); if( !$r ){ write-host "ok reached, var is not null" };
#   - Compare empty array with $null:  [Object[]] $r = @(); if( $r.gettype().Name -eq "Object[]" ){ write-host "ok reached" };
#     if( $r.count -eq 0 ){ write-host "ok reached"; }
#     if( $r -eq $null ){ write-host "never reached"; }   if( -not ($r -eq $null) ){ write-host "ok reached"; }
#     if( $r -ne $null ){ write-host "never reached"; }   if( -not ($r -ne $null) ){ write-host "ok reached"; }
#     Recommendation: Make sure an array variable is never null.
# - Standard module paths:
#   - %windir%\system32\WindowsPowerShell\v1.0\Modules    location for windows modules for all users
#   - %ProgramW6432%\WindowsPowerShell\Modules\           location for any modules     for all users
#   - %ProgramFiles%\WindowsPowerShell\Modules\           location for any modules     for all users but on PowerShell-32bit only, PowerShell-64bit does not have this path
#   - %USERPROFILE%\Documents\WindowsPowerShell\Modules   location for any modules     for current users
# - Scopes for variables, aliases, functions and psdrives:
#   - Local           : Current scope, is one of the other scopes: global, script, private, numbered scopes.
#   - Global          : Active after first script start, includes automatic variables (http://ss64.com/ps/syntax-automatic-variables.html), 
#                       preference variables (http://ss64.com/ps/syntax-preference.html) and profiles (http://ss64.com/ps/syntax-profile.html).
#   - Script          : While script runs. Is the default for scripts.
#   - Private         : Cannot be seen outside of current scope.
#   - Numbered Scopes : Relative position to another scope, 0=local, 1=parent, 2=parent of parent, and so on.
# - Scope Inheritance: 
#     A child scope does not inherit variables, functions, etc., but it is allowed to view and even change them by accessing parent scope.
#     However, a child scope is created with a set of items. Typically, it includes all the aliases and variables that have the AllScope option, 
#     plus some variables that can be used to customize the scope, such as MaximumFunctionCount. 
#   Examples: $global:MyVar = "a1"; $script:MyVar = "a2"; $private:MyVar = "a3"; function global:MyFunc(){..};  $local.MyVar = "a4"; $MyVar = "a5"; get-variable -scope global;
# - Run script:C:\Users\u4\a.tmp
#   - runs script in script scope, variables and functions do not persists in shell after script end:
#       ".\myscript.ps1"
#   - runs script in local scope, variables and functions persists in shell after script end, used to include ps artefacts:
#       . ".\myscript.ps1"
#       . { Write-Host "Test"; }    
#       powershell.exe -command ". .\myscript.ps1" 
#       powershell.exe -file ".\myscript.ps1"
#   - Call operator, runs a script, executable, function or scriptblock, creates a new script scope which is deleted after script end. Changes to global variables are also lost.
#       & "./myscript.ps1" ...arguments... ; & $mycmd ...args... ; & { mycmd1; mycmd2 }
#     Use quotes when calling non-powershell executables. 
#     Very important: if an empty argument should be specified then two quotes as '' or "" or $null or $myEmptyVar do not work (will make the argument not present), it requires '""' or "`"`"", really bad!
#     Precedence of commands: Alias > Function > Filter > Cmdlet > Application > ExternalScript > Script.
#     Override precedence of commands by using get-command, ex: Get-Command -commandType Application Ping
#   - Evaluate (string expansion) and run a command given in a string, does not create a new script scope and so works in local scope. Care for code injection. 
#       Invoke-Expression [-command] string [CommonParameters]
#     Very important: It performs string expansion before running, so it can be a severe problem if the string contains character $.
#     This behaviour is very bad and so avoid using Invoke-Expression and use & or . operators instead.
#     Ex: $cmd1 = "echo `$PSHome"; $cmd2 = "echo $PSHome"; Invoke-Expression $cmd1; Invoke-Expression $cmd2;
#   - Run a script or command remotely. See http://ss64.com/ps/invoke-command.html
#     Invoke-Command 
#     If you use Invoke-Command to run a script or command on a remote computer, then it will not run elevated even if the local session is. 
#     This is because any prompt for elevation will happen on the remote machine in a non-interactive session and so will fail
#     Example:  invoke-command -LiteralPath "c:\scripts\test.ps1" -computerName "Server64";  invoke-command -computername "server64" -credential "domain64\user64" -scriptblock {get-culture};
#   - Invoke the (provider-specific) default action on an item (like double click). For example open pdf viewer for a .pdf file.
#       Invoke-Item ./myfile.xls
#   - Start a process waiting for end or not.
#       Start-Process -FilePath myfile.exe -ArgumentList myargs
#     Examples: start-process -FilePath notepad.exe -ArgumentList Test.txt; 
#       [Diagnostics.Process]::Start("notepad.exe","test.txt");
#       start-process -FilePath  C:\batch\demo.cmd -verb runas;
#       start-process -FilePath notepad -wait -windowstyle Maximized
#       start-process -FilePath Sort.exe -RedirectStandardInput C:\Demo\Testsort.txt -RedirectStandardOutput C:\Demo\Sorted.txt -RedirectStandardError C:\Demo\SortError.txt
#       $pclass = [wmiclass]'root\cimv2:Win32_Process'; $new_pid = $pclass.Create('notepad.exe', '.', $null).ProcessId;
#     Run powershell with elevated rights: Start-Process -FilePath powershell.exe -Verb runAs
# - Call module with arguments: ex:  Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1" -ArgumentList $myinvocation.mycommand.Path;
# - FsEntries: -LiteralPath means no interpretation of wildcards
# - Extensions and libraries: https://www.powershellgallery.com/  http://ss64.com/links/pslinks.html
# - Important to know:
#   - Alternative for Split-Path has problems: [System.IO.Path]::GetDirectoryName("c:\") -eq $null; [System.IO.Path]::GetDirectoryName("\\mymach\myshare\") -eq "\\mymach\myshare\";
#   - Split(): $a = "".Split(";",[System.StringSplitOptions]::RemoveEmptyEntries); # returns correctly an empty array and not null: $a.Count -eq 0;
#     Usually Split is used with the option RemoveEmptyEntries.
