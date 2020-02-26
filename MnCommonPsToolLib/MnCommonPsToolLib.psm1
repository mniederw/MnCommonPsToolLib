# Common powershell tool library
# 2013-2019 produced by Marc Niederwieser, Switzerland. Licensed under GPL3. This is freeware.
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
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "Hello world";
#      OutProgress "Working";
#      StdInReadLine "Press enter to exit.";
# or
#      # Simple example for using MnCommonPsToolLib with standard interactive mode
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "Simple example for using MnCommonPsToolLib with standard interactive mode";
#      StdOutBegMsgCareInteractiveMode; # will ask: if you are sure (y/n)
#      OutProgress "Working";
#      StdOutEndMsgCareInteractiveMode; # will write: Ok, done. Press Enter to Exit
# or
#      # Simple example for using MnCommonPsToolLib with standard interactive mode without request or waiting
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
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
#   Major version changes will reflect breaking changes and minor identifies extensions and third number are for urgent bugfixes.
[String] $MnCommonPsToolLibVersion = "5.0"; # more see Releasenotes.txt

Set-StrictMode -Version Latest; # Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).

# Assert that the following executed statements from here to end of this script (not the functions) are not ignored.
# The functions which are called by a caller are not affected by this trap statement.
# Trap statement are not cared if a catch block is used!
# It is strongly recommended that caller places after the import-module statement the following set and trap statement 
#   for unhandeled exceptions:   Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
# It is also strongy recommended for client code to use catch blocks for handling exceptions.
trap [Exception] { $Host.UI.WriteErrorLine($_); break; }

# Define global variables if they are not yet defined; caller of this script can anytime set or change these variables to control the specified behaviour.

if( -not [Boolean] (Get-Variable ModeHideOutProgress               -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeHideOutProgress               -value $false; }
                                                                    # If true then OutProgress does nothing.
if( -not [Boolean] (Get-Variable ModeDisallowInteractions          -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeDisallowInteractions          -value $false; }
                                                                    # If true then any call to a known read-from-input function will throw. For example 
                                                                    # it will not restart script for entering elevated admin mode which must be acknowledged by the user 
                                                                    # and after any unhandled exception it does not wait for a key (uses a delay of 1 sec instead). 
                                                                    # So it can be more assured that a script works unattended.
                                                                    # The effect is comparable to that if the stdin pipe would be closed.
if( -not [String]  (Get-Variable ModeNoWaitForEnterAtEnd           -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeNoWaitForEnterAtEnd           -value $false; }
                                                                    # if true then it will not wait for enter in StdOutBegMsgCareInteractiveMode.
if( -not [String[]](Get-Variable ArgsForRestartInElevatedAdminMode -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ArgsForRestartInElevatedAdminMode -value @()   ; }
                                                                    # if restarted for entering elevated admin mode then it additionally adds these parameters.

# Set some powershell predefined global variables:
$Global:ErrorActionPreference         = "Stop"                    ; # abort if a called exe will write to stderr, default is 'Continue'. Can be overridden in each command by [-ErrorAction actionPreference]
$Global:ReportErrorShowExceptionClass = $true                     ; # on trap more detail exception info
$Global:ReportErrorShowInnerException = $true                     ; # on trap more detail exception info
$Global:ReportErrorShowStackTrace     = $true                     ; # on trap more detail exception info
$Global:FormatEnumerationLimit        = 999                       ; # used for Format-Table, but seams not to work, default is 4
$Global:OutputEncoding                = [Console]::OutputEncoding ; # for pipe to native applications use the same as current console, default is 'System.Text.ASCIIEncoding'

# Leave the following global variables on their default values, is here written just for documentation:
#   $Global:InformationPreference   SilentlyContinue   # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $Global:VerbosePreference       SilentlyContinue   # Available: Stop, Inquire, Continue(=show verbose and continue), SilentlyContinue(=default=no verbose).
#   $Global:DebugPreference         SilentlyContinue   # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $Global:ProgressPreference      Continue           # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $Global:WarningPreference       Continue           # Available: Stop, Inquire, Continue, SilentlyContinue. Can be overridden in each command by [-WarningAction actionPreference]
#   $Global:ConfirmPreference       High               # Available: None, Low, Medium, High.
#   $Global:WhatIfPreference        False              # Available: False, True.

# We like english error messages
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US');
  # alternatives: [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US'); Set-Culture en-US;

# Import some modules (because it is more performant to do it once than doing this in each function using methods of this module).
# Note: for example on "Windows Server 2008 R2" we currently are missing these modules but we ignore the errors because it its enough if the functions which uses these modules will fail.
#   The specified module 'ScheduledTasks'/'SmbShare' was not loaded because no valid module file was found in any module directory.
if( (Import-Module -NoClobber -Name "ScheduledTasks" -ErrorAction Continue 2>&1) -ne $null ){ $error.clear(); Write-Host -ForegroundColor Yellow "Ignored failing of Import-Module ScheduledTasks because it will fail later if a function is used from it."; }
if( (Import-Module -NoClobber -Name "SmbShare"       -ErrorAction Continue 2>&1) -ne $null ){ $error.clear(); Write-Host -ForegroundColor Yellow "Ignored failing of Import-Module SmbShare       because it will fail later if a function is used from it."; }
# For later usage: Import-Module -NoClobber -Name "SmbWitness";

# types
Add-Type -Name Window -Namespace Console -MemberDefinition '[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);';
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Window { [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect); [DllImport("User32.dll")] public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw); } public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }';

# Statement extensions
function ForEachParallel {
  # Based on https://powertoe.wordpress.com/2012/05/03/foreach-parallel/  
  # ex: (0..20) | ForEachParallel { echo "Nr: $_"; Start-Sleep 1; }; (0..5) | ForEachParallel -MaxThreads 2 { echo "Nr: $_"; Start-Sleep 1; }
  param( [Parameter(Mandatory=$true,position=0)]              [System.Management.Automation.ScriptBlock] $ScriptBlock,
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [PSObject]                                 $InputObject,
         [Parameter(Mandatory=$false)]                        [Int32]                                    $MaxThreads=8 )
  # Note: for some unknown reason we sometimes get a red line "One or more errors occurred." but it continuous successfully.
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
              }catch{ [String] $msg = $_; $error.clear(); Write-Host -ForegroundColor DarkGray "ForEachParallel-endinvoke: Ignoring $msg"; }
              $threads[$i].instance.dispose(); 
              $threads[$i].handle = $null; 
              [gc]::Collect();
            }else{ $notdone = $true; }
          }
        }
      }
    }catch{
      $Host.UI.WriteErrorLine("ForEachParallel-END: $($_)"); # ex: 2018-07: Exception calling "EndInvoke" with "1" argument(s) "Der ausgeführte Befehl wurde beendet, da die Einstellungsvariable "ErrorActionPreference" oder ein allgemeiner Parameter auf "Stop" festgelegt ist: Es ist ein allgemeiner Fehler aufgetreten, für den kein spezifischerer Fehlercode verfügbar ist.."
    } 
    $error.clear();
  }
}


# Set some self defined constant global variables
if( (Get-Variable -Scope global -ErrorAction SilentlyContinue -Name ComputerName) -eq $null ){ # check wether last variable already exists because reload safe
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
function GlobalSetModeHideOutProgress         ( [Boolean] $val = $true ){ $Global:ModeHideOutProgress      = $val; }
function GlobalSetModeDisallowInteractions    ( [Boolean] $val = $true ){ $Global:ModeDisallowInteractions = $val; }
function GlobalSetModeNoWaitForEnterAtEnd     ( [Boolean] $val = $true ){ $Global:ModeNoWaitForEnterAtEnd  = $val; }
function GlobalSetModeEnableAutoLoadingPref   ( [Boolean] $val = $true ){ $Global:PSModuleAutoLoadingPreference = $(switch($val){($true){$null}default{"none"}}); } # enable or disable autoloading modules, available internal values: All (=default), ModuleQualified, None.

function StringIsNullOrEmpty                  ( [String] $s ){ return [Boolean] [String]::IsNullOrEmpty($s); }
function StringIsNotEmpty                     ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrEmpty($s)); }
function StringIsNullOrWhiteSpace             ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrWhiteSpace($s)); }
function StringLeft                           ( [String] $s, [Int32] $len ){ return [String] $s.Substring(0,(Int32Clip $len 0 $s.Length)); }
function StringRight                          ( [String] $s, [Int32] $len ){ return [String] $s.Substring($s.Length-(Int32Clip $len 0 $s.Length)); }
function StringRemoveRightNr                  ( [String] $s, [Int32] $len ){ return StringLeft $s ($s.Length-$len); }
function StringSplitIntoLines                 ( [String] $s ){ return [String[]] (($s -replace "`r`n", "`n") -split "`n"); } # for empty string it returns an array with one item.
function StringReplaceNewlines                ( [String] $s, [String] $repl = " " ){ return [String] ($s -replace "`r`n", "`n" -replace "`r", "" -replace "`n", $repl); }
function StringArrayInsertIndent              ( [String[]] $lines, [Int32] $nrOfBlanks ){ if( $lines -eq $null ){ return [String[]] $null; } return [String[]] ($lines | %{ ((" "*$nrOfBlanks)+$_); }); }
function StringArrayDistinct                  ( [String[]] $lines ){ return [String[]] ($lines | Select-Object -Unique); }
function StringPadRight                       ( [String] $s, [Int32] $len, [Boolean] $doQuote = $false  ){ [String] $r = $s; if( $doQuote ){ $r = '"'+$r+'"'; } return [String] $r.PadRight($len); }
function StringSplitToArray                   ( [String] $sepChars, [String] $s, [Boolean] $removeEmptyEntries = $true ){ return [String[]] (@()+$s.Split($sepChars,$(switch($removeEmptyEntries){($true){[System.StringSplitOptions]::RemoveEmptyEntries}default{[System.StringSplitOptions]::None}}))); }
function StringArrayConcat                    ( [String[]] $lines, [String] $sep = [Environment]::NewLine ){ return [String] ($lines -join $sep); }
function StringReplaceEmptyByTwoQuotes        ( [String] $str ){ return [String] $(switch((StringIsNullOrEmpty $str)){($true){"`"`""}default{$str}}); }
function StringRemoveLeft                     ( [String] $str, [String] $strLeft , [Boolean] $ignoreCase = $true ){ [String] $s = StringLeft  $str $strLeft.Length; return [String] $(switch(($ignoreCase -and $s -eq $strLeft) -or $s -ceq $strLeft){ ($true){$str.Substring($strLeft.Length,$str.Length-$strLeft.Length)} default{$str} }); }
function StringRemoveRight                    ( [String] $str, [String] $strRight, [Boolean] $ignoreCase = $true ){ [String] $s = StringRight $str $strRight.Length; return [String] $(switch(($ignoreCase -and $s -eq $strRight) -or $s -ceq $strRight){ ($true){StringRemoveRightNr $str $strRight.Length} default{$str} }); }
function StringIsInt32                        ( [String] $s ){ [String] $tmp = ""; return [Int32]::TryParse($s,[ref]$tmp); }
function StringIsInt64                        ( [String] $s ){ [String] $tmp = ""; return [Int64]::TryParse($s,[ref]$tmp); }
function StringAsInt32                        ( [String] $s ){ if( ! (StringIsInt32 $s) ){ throw [Exception] "Is not an Int32: $s"; } return $s -as [Int32]; }
function StringAsInt64                        ( [String] $s ){ if( ! (StringIsInt64 $s) ){ throw [Exception] "Is not an Int64: $s"; } return $s -as [Int64]; }
function StringFromException                  ( [Exception] $ex ){ return [String] "$($ex.GetType().Name): $($ex.Message -replace `"`r`n`",`" `") $($ex.Data|Where-Object{$_.Values -ne $null}|ForEach-Object{`"`r`n Data: [$($_.Values)]`"})`r`n StackTrace:`r`n$($ex.StackTrace)"; } # use this if $_.Exception.Message is not enough. note: .Data is never null.
function StringCommandLineToArray             ( [String] $commandLine ){
                                                # Care spaces or tabs separated args and doublequoted args which can contain double doublequotes for escaping single doublequotes.
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
                                                      else{ throw [Exception] "Expected blank or tab char or end of string but got char='$($line[$i])' after doublequote at pos=$i in cmdline='$line'"; }
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
function DateTimeAsStringIso                  ( [DateTime] $ts, [String] $fmt = "yyyy-MM-dd HH:mm:ss" ){ return [String] $ts.ToString($fmt); }
function DateTimeNowAsStringIso               ( [String] $fmt = "yyyy-MM-dd HH:mm:ss" ){ return [String] (Get-Date -format $fmt); }
function DateTimeNowAsStringIsoDate           (){ return [String] (Get-Date -format "yyyy-MM-dd"); }
function DateTimeNowAsStringIsoMonth          (){ return [String] (Get-Date -format "yyyy-MM"); }
function DateTimeNowAsStringIsoInMinutes      (){ return [String] (Get-Date -format "yyyy-MM-dd HH:mm"); }
function DateTimeFromStringIso                ( [String] $s ){ # "yyyy-MM-dd HH:mm:ss.fff" or "yyyy-MM-ddTHH:mm:ss.fff".
                                                [String] $fmt = "yyyy-MM-dd HH:mm:ss.fff"; if( $s.Length -le 10 ){ $fmt = "yyyy-MM-dd"; }elseif( $s.Length -le 16 ){ $fmt = "yyyy-MM-dd HH:mm"; }elseif( $s.Length -le 19 ){ $fmt = "yyyy-MM-dd HH:mm:ss"; }
                                                elseif( $s.Length -le 20 ){ $fmt = "yyyy-MM-dd HH:mm:ss."; }elseif( $s.Length -le 21 ){ $fmt = "yyyy-MM-dd HH:mm:ss.f"; }elseif( $s.Length -le 22 ){ $fmt = "yyyy-MM-dd HH:mm:ss.ff"; }
                                                if( $s.Length -gt 10 -and $s[10] -ceq 'T' ){ $fmt = $fmt.remove(10,1).insert(10,'T'); }
                                                try{ return [DateTime] [datetime]::ParseExact($s,$fmt,$null); 
                                                }catch{ <# ex: Ausnahme beim Aufrufen von "ParseExact" mit 3 Argument(en): Die Zeichenfolge wurde nicht als gültiges DateTime erkannt. #> 
                                                  throw [Exception] "DateTimeFromStringIso(`"$s`") is not a valid datetime in format `"$fmt`""; } }
function ByteArraysAreEqual                   ( [Byte[]] $a1, [Byte[]] $a2 ){ if( $a1.LongLength -ne $a2.LongLength ){ return $false; } for( [Int64] $i = 0; $i -lt $a1.LongLength; $i++ ){ if( $a1[$i] -ne $a2[$i] ){ return $false; } } return $true; }
function Int32Clip                            ( [Int32] $i, [Int32] $lo, [Int32] $hi ){ if( $i -lt $lo ){ return $lo; } elseif( $i -gt $hi ){ return $hi; }else{ return $i; } } 
function ConsoleHide                          (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,0); } #0 hide (also by PowerShell.exe -WindowStyle Hidden)
function ConsoleShow                          (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,5); } #5 nohide
function ConsoleRestore                       (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,1); } #1 show
function ConsoleMinimize                      (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,6); } #6 minimize
Function ConsoleSetPos                        ( [Int32] $x, [Int32] $y ){
                                                [RECT] $r = New-Object RECT; [Object] $hd = (Get-Process -ID $PID).MainWindowHandle;
                                                [Object] $t = [Window]::GetWindowRect($hd,[ref]$r);
                                                [Int32] $w = $r.Right - $r.Left; [Int32] $h = $r.Bottom - $r.Top;
                                                If( $t ){ [Boolean] $dummy = [Window]::MoveWindow($hd, $x, $y, $w, $h, $true); } }
function ConsoleSetGuiProperties              (){ # set standard sizes which makes sense, display-hight 46 lines for HD with 125% zoom. It is performed only once per shell.
                                                if( -not [Boolean] (Get-Variable consoleSetGuiProperties_DoneOnce -Scope script -ErrorAction SilentlyContinue) ){
                                                  $error.clear(); New-Variable -Scope script -name consoleSetGuiProperties_DoneOnce -value $false;
                                                }
                                                if( $script:consoleSetGuiProperties_DoneOnce ){ return; } 
                                                [Object] $w = (get-host).ui.rawui; $w.windowtitle = "$PSCommandPath"; $w.foregroundcolor = "Gray"; 
                                                $w.backgroundcolor = switch(ProcessIsRunningInElevatedAdminMode){($true){"DarkMagenta"}default{"DarkBlue";}}; 
                                                # for future use: $ = $host.PrivateData; $.VerboseForegroundColor = "white"; $.VerboseBackgroundColor = "blue"; 
                                                #   $.WarningForegroundColor = "yellow"; $.WarningBackgroundColor = "darkgreen"; $.ErrorForegroundColor = "white"; $.ErrorBackgroundColor = "red";
                                                # set buffer sizes before setting window sizes otherwise PSArgumentOutOfRangeException: Window cannot be wider than the screen buffer.
                                                $w = (get-host).ui.rawui; # refresh values, maybe meanwhile windows was resized
                                                [Object] $buf = $w.buffersize; $buf.height = 9999; $buf.width = [math]::max(300,[System.Console]::WindowWidth);
                                                try{
                                                  $w.buffersize = $buf;
                                                }catch{ # seldom we got: PSArgumentOutOfRangeException: Cannot set the buffer size because the size specified is too large or too small.
                                                  OutWarning "Ignore: Setting buffersize failed because $($_.Exception.Message)"; 
                                                }
                                                $w = (get-host).ui.rawui; # refresh values, maybe meanwhile windows was resized
                                                if( $w.WindowSize -ne $null ){ # is null in case of powershell-ISE
                                                  [Object] $m = $w.windowsize; $m.height =   48; $m.width = [math]::min(150,[system.console]::BufferWidth); $w.windowsize = $m;
                                                  ConsoleSetPos 40 40; # little indended from top and left
                                                }
                                                $script:consoleSetGuiProperties_DoneOnce = $true; }
function StdInAssertAllowInteractions         (){ if( $global:ModeDisallowInteractions ){ throw [Exception] "Cannot read for input because all interactions are disallowed, either caller should make sure variable ModeDisallowInteractions is false or he should not call an input method."; } }
function StdInReadLine                        ( [String] $line ){ Write-Host -ForegroundColor Cyan -nonewline $line; StdInAssertAllowInteractions; return [String] (Read-Host); }
function StdInReadLinePw                      ( [String] $line ){ Write-Host -ForegroundColor Cyan -nonewline $line; StdInAssertAllowInteractions; return [System.Security.SecureString] (Read-Host -AsSecureString); }
function StdInAskForEnter                     (){ [String] $line = StdInReadLine "Press Enter to Exit"; }
function StdInAskForBoolean                   ( [String] $msg =  "Enter Yes or No (y/n)?", [String] $strForYes = "y", [String] $strForNo = "n" ){ while($true){ Write-Host -ForegroundColor Magenta -NoNewline $msg; [String] $answer = StdInReadLine ""; if( $answer -eq $strForYes ){ return [Boolean] $true ; } if( $answer -eq $strForNo  ){ return [Boolean] $false; } } }
function StdInWaitForAKey                     (){ StdInAssertAllowInteractions; $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null; } # does not work in powershell-ise, so in general do not use it, use StdInReadLine()
function StdOutLine                           ( [String] $line ){ $Host.UI.WriteLine($line); } # Writes an stdout line in default color, normally not used, rather use OutInfo because it gives more information what to output.
function StdOutRedLine                        ( [String] $line ){ OutError $line; } # deprecated
function StdOutRedLineAndPerformExit          ( [String] $line, [Int32] $delayInSec = 1 ){ OutError $line; if( $global:ModeDisallowInteractions ){ ProcessSleepSec $delayInSec; }else{ StdInReadLine "Press Enter to Exit"; }; Exit 1; }
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
                                                OutError $msg;
                                                if( -not $global:ModeDisallowInteractions ){ 
                                                  OutError "Press enter to exit"; 
                                                  try{
                                                    Read-Host; return;
                                                  }catch{ # ex: PSInvalidOperationException:  Read-Host : Windows PowerShell is in NonInteractive mode. Read and Prompt functionality is not available.
                                                    OutError "Note: Cannot Read-Host because $($_.Exception.Message)"; 
                                                  }
                                                }
                                                if( $delayInSec -gt 0 ){ StdOutLine "Waiting for $delayInSec seconds."; }
                                                ProcessSleepSec $delayInSec; }
function StdPipelineErrorWriteMsg             ( [String] $msg ){ Write-Error $msg; } # does not work in powershell-ise, so in general do not use it, use throw
function StdOutBegMsgCareInteractiveMode      ( [String] $mode = "" ){ # Available mode: ""="DoRequestAtBegin", "NoRequestAtBegin", "NoWaitAtEnd", "MinimizeConsole". 
                                                # Usually this is the first statement in a script after an info line. So you can give your scripts a standard styling.
                                                if( $mode -eq "" ){ $mode = "DoRequestAtBegin"; }
                                                ScriptResetRc; [String[]] $modes = @()+($mode -split "," | ForEach-Object{ $_.Trim() });
                                                Assert ((@()+($modes | Where-Object{ $_ -ne "DoRequestAtBegin" -and $_ -ne "NoRequestAtBegin" -and $_ -ne "NoWaitAtEnd" -and $_ -ne "MinimizeConsole"})).Count -eq 0 ) "StdOutBegMsgCareInteractiveMode was called with unknown mode='$mode'";
                                                $Global:ModeNoWaitForEnterAtEnd = $modes -contains "NoWaitAtEnd";
                                                if( -not $global:ModeDisallowInteractions -and $modes -notcontains "NoRequestAtBegin" ){ StdInAskForAnswerWhenInInteractMode "Are you sure (y/n)? "; }
                                                if( $modes -contains "MinimizeConsole" ){ OutProgress "Minimize console"; ProcessSleepSec 0; ConsoleMinimize; } }
function StdInAskForAnswerWhenInInteractMode  ( [String] $line, [String] $expectedAnswer = "y" ){ # works case insensitive; is ignored if interactions are suppressed by global var ModeDisallowInteractions
                                                if( -not $global:ModeDisallowInteractions ){ [String] $answer = StdInReadLine $line; if( $answer -ne $expectedAnswer ){ StdOutRedLineAndPerformExit "Aborted"; } } }
function StdInAskAndAssertExpectedAnswer      ( [String] $line = "Are you sure (y/n)? ", [String] $expectedAnswer = "y" ){ # works case insensitive
                                                [String] $answer = StdInReadLine $line; if( $answer -ne $expectedAnswer ){ StdOutRedLineAndPerformExit "Aborted"; } }
function StdOutEndMsgCareInteractiveMode      ( [Int32] $delayInSec = 1 ){ if( $global:ModeDisallowInteractions -or $global:ModeNoWaitForEnterAtEnd ){ 
                                                OutSuccess "Ok, done. Ending in $delayInSec second(s)."; ProcessSleepSec $delayInSec; }else{ OutSuccess "Ok, done. Press Enter to Exit;"; StdInReadLine; } }
function Assert                               ( [Boolean] $cond, [String] $msg = "" ){ if( -not $cond ){ throw [Exception] "Assertion failed $msg"; } }
function AssertRcIsOk                         ( [String[]] $linesToOutProgress = $null, [Boolean] $useLinesAsExcMessage = $false, [String] $logFileToOutProgressIfFailed = "", [String] $encodingIfNoBom = "Default" ){
                                                # Can also be called with a single string; only nonempty progress lines are given out.
                                                [Int32] $rc = ScriptGetAndClearLastRc; 
                                                if( $rc -ne 0 ){
                                                  if( -not $useLinesAsExcMessage ){ $linesToOutProgress | Where-Object{ -not [String]::IsNullOrWhiteSpace($_) } | ForEach-Object{ OutProgress $_ }; }
                                                  [String] $msg = "Last operation failed [rc=$rc]. "; 
                                                  if( $useLinesAsExcMessage ){ $msg = $(switch($rc -eq 1 -and $out -ne ""){($true){""}default{$msg}}) + ([String]$linesToOutProgress).Trim(); }
                                                  try{ OutProgress "Dump of logfile=$($logFileToOutProgressIfFailed):"; 
                                                    FileReadContentAsLines $logFileToOutProgressIfFailed $encodingIfNoBom | ForEach-Object { OutProgress "  $_"; } }catch{}                                               
                                                  throw [Exception] $msg; } }
function ScriptImportModuleIfNotDone          ( [String] $moduleName ){ if( -not (Get-Module $moduleName) ){ OutProgress "Import module $moduleName (can take some seconds on first call)"; Import-Module -NoClobber $moduleName -DisableNameChecking; } }
function ScriptGetCurrentFunc                 (){ return [String] ((Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name); }
function ScriptGetAndClearLastRc              (){ [Int32] $rc = 0; 
                                                if( ((test-path "variable:LASTEXITCODE") -and $LASTEXITCODE -ne $null <# if no windows command was done then $LASTEXITCODE is null #> -and $LASTEXITCODE -ne 0) -or -not $? ){ $rc = $LASTEXITCODE; ScriptResetRc; }
                                                return [Int32] $rc; }
function ScriptResetRc                        (){ $error.clear(); & "cmd.exe" "/C" "EXIT 0"; $error.clear(); AssertRcIsOk; } # reset ERRORLEVEL to 0
function ScriptNrOfScopes                     (){ [Int32] $i = 1; while($true){ 
                                                try{ Get-Variable null -Scope $i -ValueOnly -ErrorAction SilentlyContinue | Out-Null; $i++; 
                                                }catch{ <# ex: System.Management.Automation.PSArgumentOutOfRangeException #> return [Int32] ($i-1); } } }
function ScriptGetProcessCommandLine          (){ return [String] ([environment]::commandline); } # ex: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "& \"C:\myscript.ps1\"";
function ScriptGetDirOfLibModule              (){ return [String] $PSScriptRoot ; } # Get dir       of this script file of this function or empty if not from a script; alternative: (Split-Path -Parent -Path ($script:MyInvocation.MyCommand.Path))
function ScriptGetFileOfLibModule             (){ return [String] $PSCommandPath; } # Get full path of this script file of this function or empty if not from a script. alternative1: try{ return [String] (Get-Variable MyInvocation -Scope 1 -ValueOnly).MyCommand.Path; }catch{ return [String] ""; }  alternative2: $script:MyInvocation.MyCommand.Path
function ScriptGetCallerOfLibModule           (){ return [String] $MyInvocation.PSCommandPath; } # Result can be empty or implicit module if called interactive. alternative for dir: $MyInvocation.PSScriptRoot.
function ScriptGetTopCaller                   (){ # return the command line with correct doublequotes
                                                [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); # Result can be empty or implicit module if called interactive. usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
                                                if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; }
                                                if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
                                                if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
                                                return [String] $f; }
function ScriptIsProbablyInteractive          (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); # Result can be empty or implicit module if called interactive. usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
                                                return [Boolean] $f -eq "" -or $f -eq "ScriptGetTopCaller" -or -not $f.StartsWith("&"); }
function StreamAllProperties                  (){ $input | Select-Object *; }
function StreamAllPropertyTypes               (){ $input | Get-Member -Type Property; }
function StreamFilterWhitespaceLines          (){ $input | Where-Object{ -not [String]::IsNullOrWhiteSpace($_) }; }
function StreamToNull                         (){ $input | Out-Null; }
function StreamToString                       (){ $input | Out-String -Width 999999999; }
function StreamToStringDelEmptyLeadAndTrLines (){ $input | Out-String -Width 999999999 | ForEach-Object{ $_ -replace "[ \f\t\v]]+\r\n","\r\n" -replace "^(\r\n)+","" -replace "(\r\n)+$","" }; }
function StreamToGridView                     (){ $input | Out-GridView -Title "TableData"; }
function StreamToCsvStrings                   (){ $input | ConvertTo-Csv -NoTypeInformation; } # Note: For a simple string array as ex: @("one","two")|StreamToCsvStrings  it results with 3 lines "Length","one","two".
function StreamToJsonString                   (){ $input | ConvertTo-Json -Depth 100; }
function StreamToJsonCompressedString         (){ $input | ConvertTo-Json -Depth 100 -Compress; }
function StreamToXmlString                    (){ $input | ConvertTo-Xml -Depth 999999999 -As String -NoTypeInformation; }
function StreamToHtmlTableStrings             (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As Table; }
function StreamToHtmlListStrings              (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As List; }
function StreamToListString                   (){ $input | Format-List -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToFirstPropMultiColumnString   (){ $input | Format-Wide -AutoSize -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToCsvFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){ # If overwrite is false then nothing done if target already exists.
                                                $input | Export-Csv -Force:$overwrite -NoClobber:$(-not $overwrite) -NoTypeInformation -Encoding $encoding -Path (FsEntryEsc $file); }
function StreamToXmlFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){ # If overwrite is false then nothing done if target already exists.
                                                $input | Export-Clixml -Force:$overwrite -NoClobber:$(-not $overwrite) -Depth 999999999 -Encoding $encoding -Path (FsEntryEsc $file); }
function StreamToDataRowsString               ( [String[]] $propertyNames ){ if( $propertyNames -eq $null -or $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); } 
                                                $input | Format-Table -Wrap -Force -autosize -HideTableHeaders $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToTableString                  ( [String[]] $propertyNames ){ # Note: For a simple string array as ex: @("one","two")|StreamToCsvStrings  it results with 3 lines "Length","one","two".
                                                if( $propertyNames -eq $null -or $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); } 
                                                $input | Format-Table -Wrap -Force -autosize $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function OutInfo                              ( [String] $line ){ Write-Host -ForegroundColor $InfoLineColor -NoNewline "$line`r`n"; } # NoNewline is used because on multi threading usage line text and newline can be interrupted between.
function OutSuccess                           ( [String] $line ){ Write-Host -ForegroundColor Green -NoNewline "$line`r`n"; }
function OutWarning                           ( [String] $line, [Int32] $indentLevel = 1 ){ Write-Host -ForegroundColor Yellow -NoNewline (("  "*$indentLevel)+$line+"`r`n"); }
function OutError                             ( [String] $line ){ $Host.UI.WriteErrorLine($line); } # Writes an stderr line in red.
function OutProgress                          ( [String] $line, [Int32] $indentLevel = 1 ){ if( $Global:ModeHideOutProgress ){ return; } Write-Host -ForegroundColor DarkGray -NoNewline (("  "*$indentLevel) +$line+"`r`n"); } # Used for tracing changing actions, otherwise use OutVerbose.
function OutProgressText                      ( [String] $str  ){ if( $Global:ModeHideOutProgress ){ return; } Write-Host -ForegroundColor DarkGray -NoNewline $str; }
function OutVerbose                           ( [String] $line ){ Write-Verbose -Message $line; } # Output depends on $VerbosePreference, used tracing read or network operations
function OutDebug                             ( [String] $line ){ Write-Debug -Message $line; } # Output depends on $DebugPreference, used tracing read or network operations
function OutClear                             (){ Clear-Host; }
function ProcessFindExecutableInPath          ( [String] $exec ){ # Return full path or empty if not found.
                                                [Object] $p = (Get-Command $exec -ErrorAction SilentlyContinue); if( $p -eq $null ){ return [String] ""; } return [String] $p.Source; }
function ProcessIsRunningInElevatedAdminMode  (){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
function ProcessAssertInElevatedAdminMode     (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){ throw [Exception] "Assertion failed because requires to be in elevated admin mode"; } }
function ProcessRestartInElevatedAdminMode    (){ if( (ProcessIsRunningInElevatedAdminMode) ){ return; }
                                                # ex: "C:\myscr.ps1" or if interactive then statement name ex: "ProcessRestartInElevatedAdminMode"
                                                [String] $cmd = @( (ScriptGetTopCaller) ) + $Global:ArgsForRestartInElevatedAdminMode;
                                                if( $Global:ModeDisallowInteractions ){ 
                                                  [String] $msg = "Script `"$cmd`" is currently not in elevated admin mode and function ProcessRestartInElevatedAdminMode was called ";
                                                  $msg += "but currently the mode ModeDisallowInteractions=$Global:ModeDisallowInteractions, ";
                                                  $msg += "and so restart will not be performed. Now it will continue but it probably will fail."; 
                                                  OutWarning $msg;
                                                }else{
                                                  $cmd = $cmd -replace "`"","`"`"`""; # see https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.arguments
                                                  $cmd = ([String[]]$(switch(ScriptIsProbablyInteractive){ ($true){@("-NoExit")} default{@()} })) + @("&") + @("`"$cmd`"");
                                                  OutProgress "Not running in elevated administrator mode so elevate current script and exit:";
                                                  OutProgress "  powershell.exe $cmd";
                                                  Start-Process -Verb "RunAs" -FilePath "powershell.exe" -ArgumentList $cmd; # ex: InvalidOperationException: This command cannot be run due to the error: Der Vorgang wurde durch den Benutzer abgebrochen.
                                                  OutProgress "Exiting in 10 seconds";
                                                  ProcessSleepSec 10;
                                                  [Environment]::Exit("0"); # Note: 'Exit 0;' would only leave the last '. mycommand' statement.
                                                  throw [Exception] "Exit done, but it did not work, so it throws now an exception.";
                                                } }
function ProcessGetCurrentThreadId            (){ return [Int32] [Threading.Thread]::CurrentThread.ManagedThreadId; }
function ProcessListRunnings                  (){ return (Get-Process * | Where-Object{ $_.Id -ne 0 } | Sort-Object ProcessName); }
function ProcessListRunningsAsStringArray     (){ return (ProcessListRunnings | Format-Table -auto -HideTableHeaders " ",ProcessName,ProductVersion,Company | StreamToStringDelEmptyLeadAndTrLines); }
function ProcessIsRunning                     ( [String] $processName ){ return [Boolean] ((Get-Process -ErrorAction SilentlyContinue ($processName -replace ".exe","")) -ne $null); }
function ProcessKill                          ( [String] $processName ){ # kill all with the specified name, note if processes are not from owner then it requires to previously call ProcessRestartInElevatedAdminMode
                                                [System.Diagnostics.Process[]] $p = Get-Process ($processName -replace ".exe","") -ErrorAction SilentlyContinue; 
                                                if( $p -ne $null ){ OutProgress "ProcessKill $processName"; $p.Kill(); } }
function ProcessSleepSec                      ( [Int32] $sec ){ Start-Sleep -s $sec; }
function ProcessListInstalledAppx             (){ return [String[]] (Get-AppxPackage | Select-Object PackageFullName | Sort PackageFullName); }
function ProcessGetCommandInEnvPathOrAltPaths ( [String] $commandNameOptionalWithExtension, [String[]] $alternativePaths = @(), [String] $downloadHintMsg = ""){
                                                [System.Management.Automation.CommandInfo] $cmd = Get-Command -CommandType Application -Name $commandNameOptionalWithExtension -ErrorAction SilentlyContinue | Select-Object -First 1;
                                                if( $cmd -ne $null ){ return [String] $cmd.Path; }
                                                foreach( $d in $alternativePaths ){ [String] $f = (Join-Path $d $commandNameOptionalWithExtension); if( (FileExists $f) ){ return $f; } }
                                                throw [Exception] "$(ScriptGetCurrentFunc): commandName=`"$commandNameOptionalWithExtension`" was wether found in env-path=`"$env:PATH`" nor in alternativePaths=`"$alternativePaths`". $downloadHintMsg"; }
function ProcessStart                         ( [String] $cmd, [String[]] $cmdArgs = @(), [Boolean] $careStdErrAsOut = $false ){ 
                                                # Return output as string. If stderr is not empty then it throws its text. 
                                                # But if ErrorActionPreference is Continue or $careStdErrAsOut is true then stderr is simply appended to output.
                                                # If it fails with an error then it will OutProgress the non empty lines of output before throwing.
                                                AssertRcIsOk;
                                                [String] $traceInfo = "`"$cmd`""; $cmdArgs | Where-Object { $_ -ne $null } | ForEach-Object{ $traceInfo += " `"$_`""; };
                                                OutProgress $traceInfo; 
                                                # We use an implementation which stores stdout and stderr internally to variables and not temporary files.
                                                $prInfo = New-Object System.Diagnostics.ProcessStartInfo; 
                                                $prInfo.FileName = (Get-Command $cmd).Path; $prInfo.Arguments = $cmdArgs; $prInfo.CreateNoWindow = $true; $prInfo.WindowStyle = "Normal";
                                                $prInfo.UseShellExecute = $false; <# nessessary for redirect io #> 
                                                $prInfo.RedirectStandardError = $true; $prInfo.RedirectStandardOutput = $true; $prInfo.RedirectStandardInput = $false;
                                                $pr = New-Object System.Diagnostics.Process; $pr.StartInfo = $prInfo;
                                                # Note: We can not simply call WaitForExit() and after that read stdout and stderr streams because it could hang endless.
                                                # The reason is the called program can produce child processes which can inherit redirect handles which can be still open 
                                                # while a subprocess exited and so WaitForExit which does wait for EOFs can block forever.
                                                # See https://stackoverflow.com/questions/26713373/process-waitforexit-doesnt-return-even-though-process-hasexited-is-true
                                                # Uses async read of stdout and stderr to avoid deadlocks.
                                                [System.Text.StringBuilder] $bufStdOut = New-Object System.Text.StringBuilder;
                                                [System.Text.StringBuilder] $bufStdErr = New-Object System.Text.StringBuilder;
                                                $actionReadStdOut = { if( -not [String]::IsNullOrWhiteSpace($Event.SourceEventArgs.Data) ){ [void]$Event.MessageData.AppendLine($Event.SourceEventArgs.Data); } };
                                                $actionReadStdErr = { if( -not [String]::IsNullOrWhiteSpace($Event.SourceEventArgs.Data) ){ [void]$Event.MessageData.AppendLine($Event.SourceEventArgs.Data); } };
                                                [Object] $eventStdOut = Register-ObjectEvent -InputObject $pr -EventName OutputDataReceived -Action $actionReadStdOut -MessageData $bufStdOut;
                                                [Object] $eventStdErr = Register-ObjectEvent -InputObject $pr -EventName ErrorDataReceived  -Action $actionReadStdErr -MessageData $bufStdErr;
                                                [void]$pr.Start();
                                                $pr.BeginOutputReadLine();
                                                $pr.BeginErrorReadLine();
                                                $pr.WaitForExit();
                                                Unregister-Event -SourceIdentifier $eventStdOut.Name; $eventStdOut.Dispose();
                                                Unregister-Event -SourceIdentifier $eventStdErr.Name; $eventStdErr.Dispose();
                                                [String[]] $out = $bufStdOut.ToString();
                                                [String] $err = $bufStdErr.ToString().Trim();
                                                [Boolean] $hasStdErrToThrow = $err -ne ""; if( $careStdErrAsOut -or $Global:ErrorActionPreference -eq "Continue" ){ $hasStdErrToThrow = $false; }
                                                if( $Global:ErrorActionPreference -ne "Continue" -and ($pr.ExitCode -ne 0 -or $hasStdErrToThrow) ){
                                                  if( $out -ne "" ){ StringSplitIntoLines $out | Where-Object{ -not [String]::IsNullOrWhiteSpace($_) } | ForEach-Object{ OutProgress $_; }; }
                                                  throw [Exception] "ProcessStart($traceInfo) failed with rc=$($pr.ExitCode) $err";
                                                }
                                                if( $err -ne "" ){ $out += $err; }
                                                $pr.Dispose();
                                                return [String[]] $out; }
function JobStart                             ( [ScriptBlock] $scr, [Object[]] $scrArgs = $null, [String] $name = "Job" ){ # Return job object of type PSRemotingJob, the returned object of the script block can later be requested.
                                                return [System.Management.Automation.Job] (Start-Job -name $name -ScriptBlock $scr -ArgumentList $scrArgs); }
function JobGet                               ( [String] $id ){ return [System.Management.Automation.Job] (Get-Job -Id $id); } # Return job object.
function JobGetState                          ( [String] $id ){ return [String] (JobGet $id).State; } # NotStarted, Running, Completed, Stopped, Failed, and Blocked.
function JobWaitForNotRunning                 ( [Int32] $id, [Int32] $timeoutInSec = -1 ){ $job = Wait-Job -Id $id -Timeout $timeoutInSec; }
function JobWaitForState                      ( [Int32] $id, [String] $state, [Int32] $timeoutInSec = -1 ){ $job = Wait-Job -Id $id -State $state -Force -Timeout $timeoutInSec; }
function JobWaitForEnd                        ( [Int32] $id ){ JobWaitForNotRunning $id; return [Object] (Receive-Job -Id $id); } # Return result object of script block, job is afterwards deleted.
function HelpHelp                             (){ Get-Help     | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllVariables               (){ Get-Variable | Sort-Object Name | ForEach-Object{ OutInfo "$($_.Name.PadRight(32)) $($_.Value)"; } } # Select-Object Name, Value | StreamToListString
function HelpListOfAllAliases                 (){ Get-Alias    | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllCommands                (){ Get-Command  | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllModules                 (){ Get-Module -ListAvailable | Sort-Object Name | Select-Object Name, ModuleType, Version, ExportedCommands; }
function HelpListOfAllExportedCommands        (){ (Get-Module -ListAvailable).ExportedCommands.Values | Sort-Object Name | Select-Object Name, ModuleName; }
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
function PrivGetGroupEveryone                 (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0"                                                       )).Translate([System.Security.Principal.NTAccount]); } # Jeder
function PrivGetUserTrustedInstaller          (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464")).Translate([System.Security.Principal.NTAccount]); } # NT SERVICE\TrustedInstaller
function PrivFsRuleAsString                   ( [System.Security.AccessControl.FileSystemAccessRule] $rule ){
                                                return [String] "($($rule.IdentityReference);$(($rule.FileSystemRights) -replace ' ','');$($rule.InheritanceFlags -replace ' ','');$($rule.PropagationFlags -replace ' ','');$($rule.AccessControlType);IsInherited=$($rule.IsInherited))";
                                                } # for later: CentralAccessPolicyId, CentralAccessPolicyName, Sddl="O:BAG:SYD:PAI(A;OICI;FA;;;SY)(A;;FA;;;BA)"
function PrivAclAsString                      ( [System.Security.AccessControl.FileSystemSecurity] $acl ){
                                                [String] $s = "Owner=$($acl.Owner);Group=$($acl.Group);Acls="; foreach( $a in $acl.Access){ $s += PrivFsRuleAsString $a; } return [String] $s; }
function PrivAclSetProtection                 ( [System.Security.AccessControl.ObjectSecurity] $acl, [Boolean] $isProtectedFromInheritance, [Boolean] $preserveInheritance ){
                                                # set preserveInheritance to false to remove inherited access rules, param is ignored if $isProtectedFromInheritance is false.
                                                $acl.SetAccessRuleProtection($isProtectedFromInheritance, $preserveInheritance); }
function PrivFsRuleCreate                     ( [System.Security.Principal.IdentityReference] $account, [System.Security.AccessControl.FileSystemRights] $rights,
                                                [System.Security.AccessControl.InheritanceFlags] $inherit, [System.Security.AccessControl.PropagationFlags] $propagation, [System.Security.AccessControl.AccessControlType] $access ){
                                                # usually account is (PrivGetGroupAdministrators)
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
                                                [Object] $a = $acl.Access | Where-Object{ $_.IdentityReference -eq $account } |
                                                   Where-Object{ $_.FileSystemRights -eq "FullControl" -and $_.AccessControlType -eq "Allow" } |
                                                   Where-Object{ -not $isDir -or ($_.InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ContainerInherit) -and $_.InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ObjectInherit)) };
                                                   Where-Object{ -not $isDir -or $_.PropagationFlags -eq [System.Security.AccessControl.PropagationFlags]::None }
                                                 return [Boolean] ($a -ne $null); }
function PrivShowTokenPrivileges              (){ 
                                                whoami /priv; }
function PrivEnableTokenPrivilege             (){
                                                # Required for example for Set-ACL if it returns "The security identifier is not allowed to be the owner of this object.";
                                                # Then you need for example the Privilege SeRestorePrivilege;
                                                # Taken from https://gist.github.com/fernandoacorreia/3997188 
                                                #   or http://www.leeholmes.com/blog/2010/09/24/adjusting-token-privileges-in-powershell/ 
                                                #   or https://social.technet.microsoft.com/forums/windowsserver/en-US/e718a560-2908-4b91-ad42-d392e7f8f1ad/take-ownership-of-a-registry-key-and-change-permissions
                                                # Alternative: https://www.powershellgallery.com/packages/PoshPrivilege/0.3.0.0/Content/Scripts%5CEnable-Privilege.ps1
                                                param(
                                                  # The privilege to adjust. This set is taken from http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
                                                  [ValidateSet(
                                                    "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege", "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", 
                                                    "SeCreatePagefilePrivilege", "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege", "SeDebugPrivilege", 
                                                    "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege", "SeIncreaseQuotaPrivilege", 
                                                    "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege", "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege", 
                                                    "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege", "SeRestorePrivilege", "SeSecurityPrivilege", 
                                                    "SeShutdownPrivilege", "SeSyncAgentPrivilege", "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege", 
                                                    "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege", "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
                                                    $Privilege,
                                                  # The process on which to adjust the privilege. Defaults to the current process.
                                                  $ProcessId = $PID,
                                                  # Switch to disable the privilege, rather than enable it.
                                                  [Switch] $Disable
                                                )
                                                ## Taken from P/Invoke.NET with minor adjustments.
                                                [String] $t = '';
                                                $t += 'using System; using System.Runtime.InteropServices; public class AdjPriv { ';
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
function RegistryMapToShortKey                ( [String] $key ){ # Note: HKCU: will be replaced by HKLM:\SOFTWARE\Classes" otherwise it would not work
                                                if( -not $key.StartsWith("HKEY_","CurrentCultureIgnoreCase") ){ return [String] $key; }
                                                return [String] $key -replace "HKEY_LOCAL_MACHINE:","HKLM:" -replace "HKEY_CURRENT_USER:","HKCU:" -replace "HKEY_CLASSES_ROOT:","HKCR:" -replace "HKCR:","HKLM:\SOFTWARE\Classes" -replace "HKEY_USERS:","HKU:" -replace "HKEY_CURRENT_CONFIG:","HKCC:"; }
function RegistryRequiresElevatedAdminMode    ( [String] $key ){ 
                                                if( (RegistryMapToShortKey $key).StartsWith("HKLM:","CurrentCultureIgnoreCase") ){ ProcessRestartInElevatedAdminMode; } }
function RegistryAssertIsKey                  ( [String] $key ){ 
                                                $key = RegistryMapToShortKey $key; if( $key.StartsWith("HK","CurrentCultureIgnoreCase") ){ return; } throw [Exception] "Missing registry key instead of: `"$key`""; }
function RegistryExistsKey                    ( [String] $key ){
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key; return [Boolean] (Test-Path $key); }
function RegistryExistsValue                  ( [String] $key, [String] $name = ""){
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key; if( $name -eq "" ){ $name = "(default)"; } 
                                                [Object] $k = Get-Item -Path $key -ErrorAction SilentlyContinue; 
                                                return [Boolean] $k -and $k.GetValue($name, $null) -ne $null; }
function RegistryCreateKey                    ( [String] $key ){  # creates key if not exists
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key; 
                                                if( ! (RegistryExistsKey $key) ){ OutProgress "RegistryCreateKey `"$key`""; RegistryRequiresElevatedAdminMode $key; New-Item -Force -Path $key | Out-Null; } }
function RegistryGetValueAsObject             ( [String] $key, [String] $name = ""){ # Return null if value not exists.
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key; if( $name -eq "" ){ $name = "(default)"; }
                                                [Object] $v = Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue;
                                                if( $v -eq $null ){ return [Object] $null; }else{ return [Object] $v.$name; } }
function RegistryGetValueAsString             ( [String] $key, [String] $name = "" ){ # return empty string if value not exists
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key; [Object] $obj = RegistryGetValueAsObject $key $name; 
                                                if( $obj -eq $null ){ return ""; } return [String] $obj.ToString(); }
function RegistryListValueNames               ( [String] $key ){
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key; 
                                                return [String[]] (Get-Item -Path $key).GetValueNames(); } # Throws if key not found, if (default) value is assigned then empty string is returned for it.
function RegistryDelKey                       ( [String] $key ){
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key; 
                                                if( !(RegistryExistsKey $key) ){ return; } 
                                                OutProgress "RegistryDelKey `"$key`""; 
                                                RegistryRequiresElevatedAdminMode; 
                                                Remove-Item -Path "$key"; }
function RegistryDelValue                     ( [String] $key, [String] $name = "" ){ 
                                                $key = RegistryMapToShortKey $key; 
                                                RegistryAssertIsKey $key; if( $name -eq "" ){ $name = "(default)"; } 
                                                if( !(RegistryExistsValue $key $name) ){ return; } 
                                                OutProgress "RegistryDelValue `"$key`" `"$name`""; 
                                                RegistryRequiresElevatedAdminMode;  
                                                Remove-ItemProperty -Path $key -Name $name; }
function RegistrySetValue                     ( [String] $key, [String] $name, [String] $type, [Object] $val, [Boolean] $overwriteEvenIfStringValueIsEqual = $false ){
                                                # Creates key-value if it not exists; value is changed only if it is not equal than previous value; available types: Binary, DWord, ExpandString, MultiString, None, QWord, String, Unknown.
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key; if( $name -eq "" ){ $name = "(default)"; } RegistryCreateKey $key; if( !$overwriteEvenIfStringValueIsEqual ){ 
                                                  [Object] $obj = RegistryGetValueAsObject $key $name;
                                                  if( $obj -ne $null -and $val -ne $null -and $obj.GetType() -eq $val.GetType() -and $obj.ToString() -eq $val.ToString() ){ return; }
                                                } 
                                                try{
                                                  OutProgress "RegistrySetValue `"$key`" `"$name`" `"$type`" `"$val`""; 
                                                  Set-ItemProperty -Path $key -Name $name -Type $type -Value $val; 
                                                }catch{ # ex: SecurityException: Requested registry access is not allowed.
                                                  throw [Exception] "$(ScriptGetCurrentFunc)($key,$name) failed because $($_.Exception.Message) (often it requires elevated mode)"; } }                                                
function RegistryImportFile                   ( [String] $regFile ){
                                                OutProgress "RegistryImportFile `"$regFile`""; FileAssertExists $regFile;
                                                try{ <# stupid, it writes success to stderr #> & "$env:SystemRoot\system32\reg.exe" "IMPORT" $regFile 2>&1 | Out-Null; AssertRcIsOk; 
                                                }catch{ <# ignore always: System.Management.Automation.RemoteException Der Vorgang wurde erfolgreich beendet. #> [String] $expectedMsg = "Der Vorgang wurde erfolgreich beendet."; 
                                                  if( $_.Exception.Message -ne $expectedMsg ){ throw [Exception] "$(ScriptGetCurrentFunc)(`"$regFile`") failed. We expected an exc but this must match '$expectedMsg' but we got: '$($_.Exception.Message)'"; } ScriptResetRc; } }
function RegistryKeyGetAcl                    ( [String] $key ){
                                                $key = RegistryMapToShortKey $key;
                                                return [System.Security.AccessControl.RegistrySecurity] (Get-Acl -Path $key); } # must be called with shortkey form
function RegistryKeyGetHkey                   ( [String] $key ){
                                                $key = RegistryMapToShortKey $key;
                                                if    ( $key.StartsWith("HKLM:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.RegistryHive]::LocalMachine; }
                                                elseif( $key.StartsWith("HKCU:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.RegistryHive]::CurrentUser; }
                                                elseif( $key.StartsWith("HKCR:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.RegistryHive]::ClassesRoot; }
                                                elseif( $key.StartsWith("HKCC:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.RegistryHive]::CurrentConfig; }
                                                elseif( $key.StartsWith("HKPD:","CurrentCultureIgnoreCase") ){ return [Microsoft.Win32.RegistryHive]::PerformanceData; }
                                                elseif( $key.StartsWith("HKU:","CurrentCultureIgnoreCase")  ){ return [Microsoft.Win32.RegistryHive]::Users; }
                                                else{ throw [Exception] "$(ScriptGetCurrentFunc): Unknown HKey in: `"$key`""; } } # not used: [Microsoft.Win32.RegistryHive]::DynData
function RegistryKeyGetSubkey                 ( [String] $key ){ 
                                                $key = RegistryMapToShortKey $key;
                                                if( $key.Contains(":\\") ){ throw [Exception] "Must not contain double backslashes after colon in `"$key`""; }
                                                [String[]] $s = ($key -split ":\\",2); # means only one backslash
                                                if( $s.Count -le 1 ){ throw [Exception] "Missing `":\`" in `"$key`""; }
                                                return [String] $s[1]; }
function RegistryPrivRuleCreate               ( [System.Security.Principal.IdentityReference] $account, [String] $regRight = "" ){
                                                # ex: (PrivGetGroupAdministrators) "FullControl";
                                                # regRight ex: "ReadKey", available enums: https://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights(v=vs.110).aspx 
                                                if( $regRight -eq "" ){ return [System.Security.AccessControl.AccessControlSections]::None; }
                                                $inh = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit";
                                                $pro = [System.Security.AccessControl.PropagationFlags]::None;
                                                return New-Object System.Security.AccessControl.RegistryAccessRule($account,[System.Security.AccessControl.RegistryRights]$regRight,$inh,$pro,[System.Security.AccessControl.AccessControlType]::Allow); }
                                                # alternative: "ObjectInherit,ContainerInherit"
function RegistryPrivRuleToString             ( [System.Security.AccessControl.RegistryAccessRule] $rule ){
                                                # ex: RegistryPrivRuleToString (RegistryPrivRuleCreate (PrivGetGroupAdministrators) "FullControl")
                                                [String] $s = "$($rule.IdentityReference.ToString()):"; # ex: VORDEFINIERT\Administratoren
                                                if( $rule.AccessControlType -band [System.Security.AccessControl.AccessControlType]::Allow             ){ $s += "+"; }
                                                if( $rule.AccessControlType -band [System.Security.AccessControl.AccessControlType]::Deny              ){ $s += "-"; }
                                                if( $rule.IsInherited ){
                                                  $s += "I,";
                                                  if(   $rule.InheritanceFlags -eq   [System.Security.AccessControl.InheritanceFlags]::None              ){ $s += ""; }else{
                                                    if( $rule.InheritanceFlags -band [System.Security.AccessControl.InheritanceFlags]::ContainerInherit  ){ $s += "IC,"; }
                                                    if( $rule.InheritanceFlags -band [System.Security.AccessControl.InheritanceFlags]::ObjectInherit     ){ $s += "IO,"; }
                                                  }
                                                  if(   $rule.PropagationFlags -eq   [System.Security.AccessControl.PropagationFlags]::None              ){ $s += ""; }else{
                                                    if( $rule.PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::NoPropagateInherit){ $s += "PN,"; }
                                                    if( $rule.PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::InheritOnly       ){ $s += "PI,"; }
                                                  }
                                                }
                                                if(   $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::FullControl         ){ $s += "F,"; }else{
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::ReadKey             ){ $s += "R,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::WriteKey            ){ $s += "W,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::CreateSubKey        ){ $s += "C,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::Delete              ){ $s += "D,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::TakeOwnership       ){ $s += "O,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::EnumerateSubKeys    ){ $s += "L,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::QueryValues         ){ $s += "r,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::SetValue            ){ $s += "w,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::ReadPermissions     ){ $s += "p,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::ChangePermissions   ){ $s += "c,"; }
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.FileSystemRights]::Notify              ){ $s += "n,"; }
                                                } return [String] $s; }
function RegistryKeySetOwner                  ( [String] $key, [System.Security.Principal.IdentityReference] $account ){
                                                # ex: "HKLM:\Software\MyManufactor" (PrivGetGroupAdministrators);
                                                # Changes only if owner is not yet the required one.
                                                # Note: Throws PermissionDenied if object is protected by TrustedInstaller.
                                                # Use force this if object is protected by TrustedInstaller, then it asserts elevated mode and enables some token privileges.
                                                $key = RegistryMapToShortKey $key;
                                                OutProgress "RegistryKeySetOwner `"$key`" `"$($account.ToString())`"";
                                                RegistryRequiresElevatedAdminMode;
                                                PrivEnableTokenPrivilege SeTakeOwnershipPrivilege; 
                                                PrivEnableTokenPrivilege SeRestorePrivilege; 
                                                PrivEnableTokenPrivilege SeBackupPrivilege;
                                                try{
                                                  [Microsoft.Win32.RegistryKey] $hk = [Microsoft.Win32.RegistryKey]::OpenBaseKey((RegistryKeyGetHkey $key),[Microsoft.Win32.RegistryView]::Default);
                                                  [Microsoft.Win32.RegistryKey] $k = $hk.OpenSubKey((RegistryKeyGetSubkey $key),[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership);
                                                  [System.Security.AccessControl.RegistrySecurity] $acl = $k.GetAccessControl([System.Security.AccessControl.AccessControlSections]::All); # alternatives: None, Audit, Access, Owner, Group, All
                                                  if( $acl.Owner -eq $account.Value ){ return; }
                                                  $acl.SetOwner($account); $k.SetAccessControl($acl); 
                                                  $k.Close(); $hk.Close();
                                                  # alternative but sometimes access denied: [System.Security.AccessControl.RegistrySecurity] $acl = RegistryKeyGetAcl $key; $acl.SetOwner($account); Set-Acl -Path $key -AclObject $acl;
                                                }catch{ throw [Exception] "$(ScriptGetCurrentFunc)($key,$account) failed because $($_.Exception.Message)"; } }
function RegistryKeySetAclRight               ( [String] $key, [System.Security.Principal.IdentityReference] $account, [String] $regRight = "FullControl" ){
                                                # ex: "HKLM:\Software\MyManufactor" (PrivGetGroupAdministrators) "FullControl";
                                                RegistryKeySetAclRule $key (RegistryPrivRuleCreate $account $regRight); }
function RegistryKeyAddAclRule                ( [String] $key, [System.Security.AccessControl.RegistryAccessRule] $rule ){
                                                RegistryKeySetAclRule $key $rule $true; }
function RegistryKeySetAclRule                ( [String] $key, [System.Security.AccessControl.RegistryAccessRule] $rule, [Boolean] $useAddNotSet = $false ){
                                                # ex: "HKLM:\Software\MyManufactor" (PrivGetGroupAdministrators) "FullControl";
                                                $key = RegistryMapToShortKey $key;
                                                OutProgress "RegistryKeySetAclRule `"$key`" `"$(RegistryPrivRuleToString $rule)`"";
                                                RegistryRequiresElevatedAdminMode;
                                                PrivEnableTokenPrivilege SeTakeOwnershipPrivilege;
                                                PrivEnableTokenPrivilege SeRestorePrivilege; 
                                                PrivEnableTokenPrivilege SeBackupPrivilege;
                                                try{
                                                  [Microsoft.Win32.RegistryKey] $hk = [Microsoft.Win32.RegistryKey]::OpenBaseKey((RegistryKeyGetHkey $key),[Microsoft.Win32.RegistryView]::Default);
                                                  [Microsoft.Win32.RegistryKey] $k = $hk.OpenSubKey((RegistryKeyGetSubkey $key),[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions);
                                                  [System.Security.AccessControl.RegistrySecurity] $acl = $k.GetAccessControl([System.Security.AccessControl.AccessControlSections]::All); # alternatives: None, Audit, Access, Owner, Group, All
                                                  if( $useAddNotSet ){ $acl.AddAccessRule($rule); }
                                                  else               { $acl.SetAccessRule($rule); }
                                                  $k.SetAccessControl($acl); 
                                                  $k.Close(); $hk.Close();
                                                }catch{ throw [Exception] "$(ScriptGetCurrentFunc)($key,$(RegistryPrivRuleToString $rule),$useAddNotSet) failed because $($_.Exception.Message)"; } }
function OsGetWindowsProductKey               (){
                                                [String] $map = "BCDFGHJKMPQRTVWXY2346789"; 
                                                [Object] $value = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").digitalproductid[0x34..0x42]; [String] $p = ""; 
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
function ServiceListExistings                 (){ # We could also use Get-Service but members are lightly differnet; 2017-06 we got (RuntimeException: You cannot call a method on a null-valued expression.) so we added null check.
                                                return [System.Management.ManagementObject[]] (Get-WmiObject win32_service | Sort-Object ProcessId,Name); }
function ServiceListExistingsAsStringArray    (){ 
                                                return (ServiceListExistings | Format-Table -auto -HideTableHeaders " ",ProcessId,Name,StartMode,State | StreamToStringDelEmptyLeadAndTrLines); }
function ServiceNotExists                     ( [String] $serviceName ){ 
                                                return [Boolean] -not (ServiceExists $serviceName); }
function ServiceExists                        ( [String] $serviceName ){ 
                                                return [Boolean] ((Get-Service $serviceName -ErrorAction SilentlyContinue) -ne $null); }
function ServiceAssertExists                  ( [String] $serviceName ){ 
                                                OutVerbose "Assert service exists: $serviceName"; if( ServiceNotExists $serviceName ){ throw [Exception] "Assertion failed because service not exists: $serviceName"; } }
function ServiceGet                           ( [String] $serviceName ){ 
                                                return [Object] (Get-Service -Name $serviceName -ErrorAction SilentlyContinue); } # Standard result is name,displayname,status.
function ServiceGetState                      ( [String] $serviceName ){ 
                                                [Object] $s = ServiceGet $serviceName; if( $s -eq $null ){ return [String] ""; } return [String] $s.Status; }
                                                # ServiceControllerStatus: "","ContinuePending","Paused","PausePending","Running","StartPending","Stopped","StopPending".
function ServiceStop                          ( [String] $serviceName ){
                                                [String] $s = ServiceGetState $serviceName; if( $s -eq "" -or $s -eq "stopped" ){ return; }
                                                OutProgress "ServiceStop $serviceName"; ProcessRestartInElevatedAdminMode;
                                                Stop-Service -Name $serviceName; } # Instead of check for stopped service we could also use -PassThru.
function ServiceStart                         ( [String] $serviceName ){ 
                                                OutVerbose "Check if either service $ServiceName is running or otherwise go in elevate mode and start service"; 
                                                [String] $s = ServiceGetState $serviceName; if( $s -eq "" ){ throw [Exception] "Service not exists: `"$serviceName`""; } if( $s -eq "Running" ){ return; } 
                                                OutProgress "ServiceStart $serviceName"; ProcessRestartInElevatedAdminMode; Start-Service -Name $serviceName; } # alternative: -displayname or Restart-Service
function ServiceSetStartType                  ( [String] $serviceName, [String] $startType, [Boolean] $errorAsWarning = $false ){
                                                [String] $startTypeExt = switch($startType){ "Disabled" {$startType} "Manual" {$startType} "Automatic" {$startType} "Automatic_Delayed" {"Automatic"} 
                                                  default { throw [Exception] "Unknown startType=$startType expected Disabled,Manual,Automatic,Automatic_Delayed."; } };
                                                [Nullable[UInt32]] $targetDelayedAutostart = switch($startType){ "Automatic" {0} "Automatic_Delayed" {1} default {$null} };
                                                [String] $key = "HKLM:\System\CurrentControlSet\Services\$serviceName";
                                                [String] $regName = "DelayedAutoStart";
                                                [UInt32] $delayedAutostart = RegistryGetValueAsObject $key $regName; # null converted to 0
                                                [Object] $s = ServiceGet $serviceName; if( $s -eq $null ){ throw [Exception] "Service $serviceName not exists"; }
                                                if( $s.StartType -ne $startTypeExt -or ($targetDelayedAutostart -ne $null -and $targetDelayedAutostart -ne $delayedAutostart) ){
                                                  OutProgress "$(ScriptGetCurrentFunc) `"$serviceName`" $startType"; 
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
                                                     # Default autostart delay of 120 sec is stored at: HKLM\SYSTEM\CurrentControlSet\services\$serviceName\AutoStartDelay = DWORD n
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
                                                catch{ OutWarning "Ignore failing of disabling task `"$taskPathAndName`" because $($_.Exception.Message)"; } } }
function FsEntryEsc                           ( [String] $fsentry ){ 
                                                if( $fsentry -eq "" ){ throw [Exception] "Empty file name not allowed"; } # Escaping is not nessessary if a command supports -LiteralPath.
                                                return [String] [Management.Automation.WildcardPattern]::Escape($fsentry); } # Important for chars as [,], etc.
function FsEntryMakeValidFileName             ( [String] $str ){ [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object{ $str = $str.Replace($_,'_') }; return [String] $str; }
function FsEntryMakeRelative                  ( [String] $fsEntry, [String] $belowDir, [Boolean] $prefixWithDotDir = $false ){
                                                # Works without IO to file system; if $fsEntry is not equal or below dir then it throws;
                                                # if fs-entry is equal the below-dir then it returns a dot;
                                                # a trailing backslash of the fs entry is not changed;
                                                # trailing backslashes for belowDir are not nessessary. ex: "Dir1\Dir2" -eq (FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir");
                                                Assert ($belowDir -ne "") "belowDir is empty.";
                                                $belowDir = FsEntryMakeTrailingBackslash (FsEntryGetAbsolutePath $belowDir);
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                if( (FsEntryMakeTrailingBackslash $fsEntry) -eq $belowDir ){ $fsEntry += "\."; }
                                                Assert ($fsEntry.StartsWith($belowDir,"CurrentCultureIgnoreCase")) "Expected `"$fsEntry`" is below `"$belowDir`"";
                                                return [String] ($(switch($prefixWithDotDir){($true){".\"}default{""}})+$fsEntry.Substring($belowDir.Length)); }

function FsEntryGetAbsolutePath               ( [String] $fsEntry ){ # works without IO, so no check to file system; does not change a trailing backslash
                                                # Note: We cannot use (Resolve-Path -LiteralPath $fsEntry) because it will throw if path not exists, 
                                                # see http://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist
                                                try{ return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
                                                catch [System.Management.Automation.DriveNotFoundException] { # ex: DriveNotFoundException: Cannot find drive. A drive with the name 'Z' does not exist.
                                                  return [String] [IO.Path]::GetFullPath($fsEntry); # maybe this is not working for psdrives. Solve this if it occurrs.
                                                } }
function FsEntryHasTrailingBackslash          ( [String] $fsEntry ){ return [Boolean] $fsEntry.EndsWith("\"); }
function FsEntryRemoveTrailingBackslash       ( [String] $fsEntry ){ 
                                                [String] $result = $fsEntry; if( $result -ne "" ){ while( $result.EndsWith("\") ){ $result = $result.Remove($result.Length-1); }
                                                if( $result -eq "" ){ $result = $fsEntry; } } return [String] $result; } # leading backslashes are not removed.
function FsEntryMakeTrailingBackslash         ( [String] $fsEntry ){ 
                                                [String] $result = $fsEntry; if( -not $result.EndsWith("\") ){ $result += "\"; } return [String] $result; }
function FsEntryJoinRelativePatterns          ( [String] $rootDir, [String[]] $relativeFsEntriesPatternsSemicolonSeparated ){
                                                # Create an array ex: @( "c:\myroot\bin\", "c:\myroot\obj\", "c:\myroot\*.tmp", ... ) from input as @( "bin\;obj\;", ";*.tmp;*.suo", ".\dir\d1?\", ".\dir\file*.txt");
                                                # If an fs entry specifies a dir patterns then it must be specified by a trailing backslash. 
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
function FsEntryGetParentDir                  ( [String] $fsEntry ){ # Returned path does not contain trailing backslash; for c:\ or \\mach\share it return "";
                                                return [String] (Split-Path -LiteralPath (FsEntryGetAbsolutePath $fsEntry)); }
function FsEntryExists                        ( [String] $fsEntry ){ 
                                                return [Boolean] (DirExists $fsEntry) -or (FileExists $fsEntry); }
function FsEntryNotExists                     ( [String] $fsEntry ){ 
                                                return [Boolean] -not (FsEntryExists $fsEntry); }
function FsEntryAssertExists                  ( [String] $fsEntry, [String] $text = "Assertion failed" ){ 
                                                if( !(FsEntryExists $fsEntry) ){ throw [Exception] "$text because fs entry not exists: `"$fsEntry`""; } }
function FsEntryAssertNotExists               ( [String] $fsEntry, [String] $text = "Assertion failed" ){ 
                                                if(  (FsEntryExists $fsEntry) ){ throw [Exception] "$text because fs entry already exists: `"$fsEntry`""; } }
function FsEntryGetLastModified               ( [String] $fsEntry ){ 
                                                return [DateTime] (Get-Item -Force -LiteralPath $fsEntry).LastWriteTime; }
function FsEntryNotExistsOrIsOlderThanNrDays  ( [String] $fsEntry, [Int32] $maxAgeInDays ){ 
                                                return [Boolean] ((FsEntryNotExists $fsEntry) -or ((FsEntryGetLastModified $fsEntry).AddDays($maxAgeInDays) -lt (Get-Date))); }
function FsEntrySetAttributeReadOnly          ( [String] $fsEntry, [Boolean] $val ){ 
                                                OutProgress "FsFileSetAttributeReadOnly $fsEntry $val"; Set-ItemProperty (FsEntryEsc $fsEntry) -name IsReadOnly -value $val; }
function FsEntryFindFlatSingleByPattern       ( [String] $fsEntryPattern, [Boolean] $allowNotFound = $false ){
                                                # it throws if file not found or more than one file exists. if allowNotFound is true then if return empty if not found.
                                                [System.IO.FileSystemInfo[]] $r = @()+(Get-ChildItem -Force -ErrorAction SilentlyContinue -Path $fsEntryPattern | Where-Object{ $_ -ne $null });
                                                if( $r.Count -eq 0 ){ if( $allowNotFound ){ return [String] ""; } throw [Exception] "No file exists: `"$fsEntryPattern`""; }
                                                if( $r.Count -gt 1 ){ throw [Exception] "More than one file exists: `"$fsEntryPattern`""; }
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
                                                OutVerbose "FsEntryListAsFileSystemInfo `"$pa`" recursive=$recursive includeDirs=$includeDirs includeFiles=$includeFiles";
                                                [System.IO.FileSystemInfo[]] $result = @();
                                                if( $trailingBackslashMode -and $pa.Contains("\*\") ){
                                                  # enable that ".\*\dir\" can also find dir as top dir
                                                  $pa = $pa.Replace("\*\","\.\"); # Otherwise Get-ChildItem would find dirs.
                                                }
                                                if( $inclTopDir -and $includeDirs -and -not ($pa -eq "*" -or $pa.EndsWith("\*")) ){
                                                  $result += (Get-Item -Force -ErrorAction SilentlyContinue -Path $pa) | Where-Object{ $_.PSIsContainer } | Where-Object{ $_ -ne $null };
                                                }
                                                try{
                                                  $result += (Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse:$recursive -Path $pa | 
                                                    Where-Object{ $_ -ne $null } | 
                                                    Where-Object{ ($includeDirs -and $includeFiles) -or ($includeDirs -and $_.PSIsContainer) -or ($includeFiles -and -not $_.PSIsContainer) });
                                                }catch [System.UnauthorizedAccessException] { # BUG: why is this not handled by SilentlyContinue?
                                                  OutWarning "Ignoring UnauthorizedAccessException for Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse:$recursive -Path `"$pa`"";
                                                } return $result; }
                                                
function FsEntryListAsStringArray             ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
                                                # Output of directories will have a trailing backslash. more see FsEntryListAsFileSystemInfo.
                                                return [String[]] (@() + (FsEntryListAsFileSystemInfo $fsEntryPattern $recursive $includeDirs $includeFiles $inclTopDir |
                                                  ForEach-Object{ FsEntryFsInfoFullNameDirWithBackSlash $_} )); }
function FsEntryDelete                        ( [String] $fsEntry ){ 
                                                if( $fsEntry.EndsWith("\") ){ DirDelete $fsEntry; }else{ FileDelete $fsEntry; } }
function FsEntryDeleteToRecycleBin            ( [String] $fsEntry ){
                                                Add-Type -AssemblyName Microsoft.VisualBasic;
                                                [String] $e = FsEntryGetAbsolutePath $fsEntry;
                                                OutProgress "FsEntryDeleteToRecycleBin `"$e`"";
                                                FsEntryAssertExists $e "Not exists: `"$e`"";
                                                if( FsEntryIsDir $e ){ [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($e,'OnlyErrorDialogs','SendToRecycleBin');
                                                }else{                 [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($e,'OnlyErrorDialogs','SendToRecycleBin'); } }
function FsEntryRename                        ( [String] $fsEntryFrom, [String] $fsEntryTo ){
                                                # for files or dirs, relative or absolute, origin must exists, directory parts must be identic.
                                                OutProgress "FsEntryRename `"$fsEntryFrom`" `"$fsEntryTo`""; 
                                                FsEntryAssertExists $fsEntryFrom; FsEntryAssertNotExists $fsEntryTo; 
                                                [String] $fs1 = (FsEntryGetAbsolutePath (FsEntryRemoveTrailingBackslash $fsEntryFrom));
                                                [String] $fs2 = (FsEntryGetAbsolutePath (FsEntryRemoveTrailingBackslash $fsEntryTo));
                                                Rename-Item -Path $fs1 -newName $fs2 -force; }
function FsEntryCreateSymLink                 ( [String] $newSymLink, [String] $fsEntryOrigin ){
                                                # (junctions (=~symlinksToDirs) do not) (https://superuser.com/questions/104845/permission-to-make-symbolic-links-in-windows-7/105381).
                                                New-Item -ItemType SymbolicLink -Name (FsEntryEsc $newSymLink) -Value (FsEntryEsc $fsEntryOrigin); }
function FsEntryCreateHardLink                ( [String] $newHardLink, [String] $fsEntryOrigin ){ # for files or dirs, origin must exists, it requires elevated rights.
                                                New-Item -ItemType HardLink -Name (FsEntryEsc $newHardLink) -Value (FsEntryEsc $fsEntryOrigin); }
function FsEntryCreateDirSymLink              ( [String] $symLinkDir, [String] $symLinkOriginDir ){ # Creates junctions which are symlinks to dirs with some slightly other behaviour around privileges and local/remote usage.
                                                if( !(DirExists $symLinkOriginDir)  ){ throw [Exception] "Cannot create dir sym link because original directory not exists: `"$symLinkOriginDir`""; }
                                                FsEntryAssertNotExists $symLinkDir "Cannot create dir sym link";
                                                [String] $cd = Get-Location;
                                                Set-Location (FsEntryGetParentDir $symLinkDir);
                                                [String] $symLinkName = FsEntryGetFileName $symLinkDir;
                                                & "cmd.exe" "/c" ('mklink /J "'+$symLinkName+'" "'+$symLinkOriginDir+'"'); AssertRcIsOk;
                                                Set-Location $cd; }
function FsEntryReportMeasureInfo             ( [String] $fsEntry ){ # Must exists, works recursive.
                                                if( FsEntryNotExists $fsEntry ){ throw [Exception] "File system entry not exists: `"$fsEntry`""; }
                                                [Microsoft.PowerShell.Commands.GenericMeasureInfo] $size = Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse -LiteralPath $fsEntry |
                                                  Where-Object{ $_ -ne $null } | Measure-Object -Property length -sum;
                                                if( $size -eq $null ){ return [String] "SizeInBytes=0; NrOfFsEntries=0;"; }
                                                return [String] "SizeInBytes=$($size.sum); NrOfFsEntries=$($size.count);"; }
function FsEntryCreateParentDir               ( [String] $fsEntry ){ [String] $dir = FsEntryGetParentDir $fsEntry; DirCreate $dir; }
function FsEntryMoveByPatternToDir            ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $showProgressFiles = $false ){ # Target dir must exists. pattern is non-recursive scanned.
                                                OutProgress "FsEntryMoveByPatternToDir `"$fsEntryPattern`" to `"$targetDir`""; DirAssertExists $targetDir;
                                                FsEntryListAsStringArray $fsEntryPattern $false | Sort-Object | 
                                                  ForEach-Object{ if( $showProgressFiles ){ OutProgress "Source: $_"; }; Move-Item -Force -Path $_ -Destination (FsEntryEsc $targetDir); }; }
function FsEntryCopyByPatternByOverwrite      ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $continueOnErr = $false ){
                                                OutProgress "FsEntryCopyByPatternByOverwrite `"$fsEntryPattern`" to `"$targetDir`" continueOnErr=$continueOnErr";
                                                DirCreate $targetDir; Copy-Item -ErrorAction SilentlyContinue -Recurse -Force -Path $fsEntryPattern -Destination (FsEntryEsc $targetDir);
                                                if( -not $? ){ if( ! $continueOnErr ){ AssertRcIsOk; }else{ OutWarning "CopyFiles `"$fsEntryPattern`" to `"$targetDir`" failed, will continue"; } } }
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
function FsEntryAclRuleWrite                  ( [String] $modeSetAddOrDel, [String] $fsEntry, [System.Security.AccessControl.FileSystemAccessRule] $rule, [Boolean] $recursive = $false ){
                                                # $modeSetAddOrDel = "Set", "Add", "Del".
                                                OutProgress "FsEntryAclRuleWrite $modeSetAddOrDel `"$fsEntry`" '$(PrivFsRuleAsString $rule)'"; 
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry; 
                                                if    ( $modeSetAddOrDel -eq "Set" ){ $acl.SetAccessRule($rule); } 
                                                elseif( $modeSetAddOrDel -eq "Add" ){ $acl.AddAccessRule($rule); }
                                                elseif( $modeSetAddOrDel -eq "Del" ){ $acl.RemoveAccessRule($rule); } 
                                                else{ throw [Exception] "For modeSetAddOrDel expected 'Set', 'Add' or 'Del' but got '$modeSetAddOrDel'"; } 
                                                Set-Acl -Path (FsEntryEsc $fsEntry) -AclObject $acl; <# Set-Acl does set or add #>
                                                if( $recursive -and (FsEntryIsDir $fsEntry) ){
                                                  FsEntryListAsStringArray "$fsEntry\*" $false | ForEach-Object{ FsEntryAclRuleWrite $modeSetAddOrDel $_ $rule $true };
                                                } }
function FsEntryTrySetOwner                   ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){
                                                # usually account is (PrivGetGroupAdministrators)
                                                ProcessRestartInElevatedAdminMode; 
                                                PrivEnableTokenPrivilege SeTakeOwnershipPrivilege; 
                                                PrivEnableTokenPrivilege SeRestorePrivilege; 
                                                PrivEnableTokenPrivilege SeBackupPrivilege;
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry; 
                                                try{
                                                  [System.IO.FileSystemInfo] $fs = Get-Item -Force -LiteralPath $fsEntry;
                                                  if( $acl.Owner -ne $account ){
                                                    OutProgress "FsEntryTrySetOwner `"$fsEntry`" `"$($account.ToString())`""; 
                                                    if( $fs.PSIsContainer ){
                                                      try{
                                                        $fs.SetAccessControl((PrivDirSecurityCreateOwner $account));
                                                      }catch{
                                                        OutProgress "taking ownership of dir `"$($fs.FullName)`" failed so setting fullControl for administrators of its parent `"$($fs.Parent.FullName)`"";
                                                        $fs.Parent.SetAccessControl((PrivDirSecurityCreateFullControl (PrivGetGroupAdministrators)));
                                                        $fs.SetAccessControl((PrivDirSecurityCreateOwner $account));
                                                      }
                                                    }else{
                                                      try{
                                                        $fs.SetAccessControl((PrivFileSecurityCreateOwner $account));
                                                      }catch{
                                                        OutProgress "taking ownership of file `"$($fs.FullName)`" failed so setting fullControl for administrators of its dir `"$($fs.Directory.FullName)`"";
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
                                                # usually account is (PrivGetGroupAdministrators)
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
                                                      # Maybe for future: PrivEnableTokenPrivilege SeTakeOwnershipPrivilege; PrivEnableTokenPrivilege SeRestorePrivilege; PrivEnableTokenPrivilege SeBackupPrivilege;
                                                      [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry; 
                                                      if( $acl.Owner -ne (PrivGetGroupAdministrators) ){
                                                        OutProgress "FsEntrySetOwner `"$fsEntry`" `"$($account.ToString())`"";
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
                                                if( -not (DirExists $dir) ){ throw [Exception] "Dir not exists: `"$dir`"."; } }
function DirCreate                            ( [String] $dir ){
                                                New-Item -type directory -Force (FsEntryEsc $dir) | Out-Null; } # create dir if it not yet exists,;we do not call OutProgress because is not an important change.
function DirCreateTemp                        ( [String] $prefix = "" ){ while($true){
                                               [String] $d = Join-Path ([System.IO.Path]::GetTempPath()) ($prefix + [System.IO.Path]::GetRandomFileName().Replace(".",""));
                                               if( FsEntryNotExists $d ){ DirCreate $d; return $d; } } }
function DirDelete                            ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                # Remove dir recursively if it exists, be careful when using this.
                                                if( (DirExists $dir) ){ 
                                                  try{ OutProgress "DirDelete$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) `"$dir`""; Remove-Item -Force:$ignoreReadonly -Recurse -LiteralPath $dir; 
                                                  }catch{ <# ex: Für das Ausführen des Vorgangs sind keine ausreichenden Berechtigungen vorhanden. #> 
                                                    throw [Exception] "$(ScriptGetCurrentFunc)$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}})(`"$dir`") failed because $($_.Exception.Message) (maybe locked or readonly files exists)"; } } }
function DirDeleteContent                     ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                # remove dir content if it exists, be careful when using this.
                                                if( (DirExists $dir) -and (@()+(Get-ChildItem -Force -Directory -LiteralPath $dir)).Count -gt 0 ){ 
                                                  try{ OutProgress "DirDeleteContent$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) `"$dir`""; 
                                                    Remove-Item -Force:$ignoreReadonly -Recurse "$(FsEntryEsc $dir)\*"; 
                                                  }catch{ <# ex: Für das Ausführen des Vorgangs sind keine ausreichenden Berechtigungen vorhanden. #> 
                                                    throw [Exception] "$(ScriptGetCurrentFunc)$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}})(`"$dir`") failed because $($_.Exception.Message) (maybe locked or readonly files exists)"; } } }
function DirDeleteIfIsEmpty                   ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                if( (DirExists $dir) -and (@()+(Get-ChildItem -Force -LiteralPath $dir)).Count -eq 0 ){ DirDelete $dir; } }
function DirCopyToParentDirByAddAndOverwrite  ( [String] $srcDir, [String] $tarParentDir ){ 
                                                OutProgress "DirCopyToParentDirByAddAndOverwrite `"$srcDir`" to `"$tarParentDir`""; 
                                                if( -not (DirExists $srcDir) ){ throw [Exception] "Missing source dir `"$srcDir`""; } 
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
                                                if( (FileNotExists $file) ){ throw [Exception] "File not exists: `"$file`"."; } }
function FileExistsAndIsNewer                 ( [String] $ftar, [String] $fsrc ){
                                                FileAssertExists $fsrc; return [Boolean] ((FileExists $ftar) -and ((FsEntryGetLastModified $ftar) -ge (FsEntryGetLastModified $fsrc))); }
function FileNotExistsOrIsOlder               ( [String] $ftar, [String] $fsrc ){ 
                                                return [Boolean] -not (FileExistsAndIsNewer $ftar $fsrc); }
function FileReadContentAsString              ( [String] $file, [String] $encodingIfNoBom = "Default" ){ 
                                                return [String] (FileReadContentAsLines $file $encodingIfNoBom | Out-String -Width ([Int32]::MaxValue)); }
function FileReadContentAsLines               ( [String] $file, [String] $encodingIfNoBom = "Default" ){ 
                                                # Note: if BOM exists then this is taken. Otherwise often use "UTF8".
                                                OutVerbose "FileRead $file"; return [String[]] (Get-Content -Encoding $encodingIfNoBom -LiteralPath $file); }
function FileReadJsonAsObject                 ( [String] $jsonFile ){ 
                                                Get-Content -Raw -Path $jsonFile | ConvertFrom-Json; }
function FileWriteFromString                  ( [String] $file, [String] $content, [Boolean] $overwrite = $true, [String] $encoding = "UTF8" ){
                                                # Will create path of file. overwrite does ignore readonly attribute.
                                                OutProgress "WriteFile $file"; FsEntryCreateParentDir $file; 
                                                Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -Inputobject $content -LiteralPath $file; }
                                                # alternative: Set-Content -Encoding $encoding -Path (FsEntryEsc $file) -Value $content; but this would lock file, 
                                                # more see http://stackoverflow.com/questions/10655788/powershell-set-content-and-out-file-what-is-the-difference
function FileWriteFromLines                   ( [String] $file, [String[]] $lines, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){ 
                                                OutProgress "WriteFile $file"; 
                                                FsEntryCreateParentDir $file; $lines | Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -LiteralPath $file; }
function FileCreateEmpty                      ( [String] $file, [Boolean] $overwrite = $false, [Boolean] $quiet = $false ){ 
                                                if( -not $quiet -and $overwrite ){ OutProgress "FileCreateEmpty-ByOverwrite $file"; } 
                                                FsEntryCreateParentDir $file; Out-File -Force -NoClobber:$(-not $overwrite) -Encoding ASCII -LiteralPath $file; }
function FileAppendLineWithTs                 ( [String] $file, [String] $line ){ FileAppendLine $file "$(DateTimeNowAsStringIso "yyyy-MM-dd HH:mm") $line"; }
function FileAppendLine                       ( [String] $file, [String] $line, [Boolean] $tsPrefix = $false ){ 
                                                FsEntryCreateParentDir $file; Out-File -Encoding Default -Append -LiteralPath $file -InputObject $line; }
function FileAppendLines                      ( [String] $file, [String[]] $lines ){ 
                                                FsEntryCreateParentDir $file; $lines | Out-File -Encoding Default -Append -LiteralPath $file; }
function FileGetTempFile                      (){ return [Object] [System.IO.Path]::GetTempFileName(); }
function FileDelTempFile                      ( [String] $file ){ if( (FileExists $file) ){ OutDebug "FileDelete -Force `"$file`""; 
                                                Remove-Item -Force -LiteralPath $file; } } # As FileDelete but no progress msg.
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
function FileTouch                            ( [String] $file ){ OutProgress "Touch: `"$file`""; 
                                                if( FileExists $file ){ (Get-Item -Force -LiteralPath $file).LastWriteTime = (Get-Date); }else{ FileCreateEmpty $file; } }
function FileGetLastLines                     ( [String] $file, [Int32] $nrOfLines ){ Get-content -tail $nrOfLines -LiteralPath $file; }
function FileContentsAreEqual                 ( [String] $f1, [String] $f2, [Boolean] $allowSecondFileNotExists = $true ){ # first file must exist
                                                FileAssertExists $f1; if( $allowSecondFileNotExists -and -not (FileExists $f2) ){ return $false; }
                                                [System.IO.FileInfo] $fi1 = Get-Item -Force -LiteralPath $f1; [System.IO.FileStream] $fs1 = $null;
                                                [System.IO.FileInfo] $fi2 = Get-Item -Force -LiteralPath $f2; [System.IO.FileStream] $fs2 = $null;
                                                [Int64] $BlockSizeInBytes = 32768; [Int32] $nrOfBlocks = [Math]::Ceiling($fi1.Length/$BlockSizeInBytes);
                                                [Byte[]] $a1 = New-Object byte[] $BlockSizeInBytes;
                                                [Byte[]] $a2 = New-Object byte[] $BlockSizeInBytes;
                                                if( $false ){ # Much more performant (20 sec for 5 GB file).
                                                  if( $fi1.Length -ne $fi2.Length ){ return $false; } 
                                                  & "fc.exe" "/b" ($fi1.FullName) ($fi2.FullName) > $null; if( $? ){ return $true; } ScriptResetRc; return $false;
                                                }else{ # Slower but more portable (longer than 5 min).
                                                  try{ $fs1 = $fi1.OpenRead(); $fs2 = $fi2.OpenRead(); [Int64] $dummyNrBytesRead = 0;
                                                    for( [Int32] $b = 0; $b -lt $nrOfBlocks; $b++ ){
                                                      $dummyNrBytesRead = $fs1.Read($a1,0,$BlockSizeInBytes); 
                                                      $dummyNrBytesRead = $fs2.Read($a2,0,$BlockSizeInBytes); 
                                                      # Note: this is probably too slow, so took it inline: if( -not (ByteArraysAreEqual $a1 $a2) ){ return [Boolean] $false; }
                                                      if( $a1.Length -ne $a2.Length ){ return $false; } 
                                                      for( [Int64] $i = 0; $i -lt $a1.Length; $i++ ){ if( $a1[$i] -ne $a2[$i] ){ return $false; } }
                                                    } return [Boolean] $true;
                                                  }finally{ $fs1.Close(); $fs2.Close(); } }
                                                }
function FileDelete                           ( [String] $file, [Boolean] $ignoreReadonly = $true ){
                                                if( (FileExists $file) ){ OutProgress "FileDelete$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) `"$file`""; 
                                                  Remove-Item -Force:$ignoreReadonly -LiteralPath $file; } }
function FileCopy                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){ 
                                                OutProgress "FileCopy(Overwrite=$overwrite) `"$srcFile`" to `"$tarFile`" $(switch($(FileExists $(FsEntryEsc $tarFile))){($true){'(Target exists)'}default{''}})"; 
                                                FsEntryCreateParentDir $tarFile; Copy-Item -Force:$overwrite (FsEntryEsc $srcFile) (FsEntryEsc $tarFile); }
function FileMove                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){ 
                                                OutProgress "FileMove(Overwrite=$overwrite) `"$srcFile`" to `"$tarFile`"$(switch($(FileExists $(FsEntryEsc $tarFile))){($true){'(Target exists)'}default{''}})"; 
                                                FsEntryCreateParentDir $tarFile; Move-Item -Force:$overwrite -LiteralPath $srcFile -Destination $tarFile; }
function FileGetHexStringOfHash128BitsMd5     ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "MD5"    $srcFile).Hash; }
function FileGetHexStringOfHash256BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA256" $srcFile).Hash; } # 2017-11 ps standard is SHA256, available are: SHA1;SHA256;SHA384;SHA512;MACTripleDES;MD5;RIPEMD160
function FileGetHexStringOfHash512BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA512" $srcFile).Hash; } # 2017-12: this is our standard for ps
function FileUpdateItsHashSha2FileIfNessessary( [String] $srcFile ){
                                                [String] $hashTarFile = "$srcFile.sha2"; 
                                                [String] $hashSrc = FileGetHexStringOfHash512BitsSha2 $srcFile;
                                                [String] $hashTar = $(switch((FileNotExists $hashTarFile) -or (FileGetSize $hashTarFile) -gt 8200){($true){""}default{(FileReadContentAsString $hashTarFile "Default").TrimEnd()}})  ;
                                                if( $hashSrc -eq $hashTar ){
                                                  OutProgress "File is up to date, nothing done with `"$hashTarFile`".";
                                                }else{
                                                  Out-File -Encoding UTF8 -LiteralPath $hashTarFile -Inputobject $hashSrc;
                                                  OutProgress "Created `"$hashTarFile`"."; 
                                                } }
function FileNtfsAlternativeDataStreamAdd     ( [String] $srcFile, [String] $adsName, [String] $val ){ Add-Content -Path $srcFile -Value $val -Stream $adsName; }
function FileNtfsAlternativeDataStreamDel     ( [String] $srcFile, [String] $adsName ){ Clear-Content -Path $srcFile -Stream $adsName; }
function FileAdsDownloadedFromInternetAdd     ( [String] $srcFile ){ FileNtfsAlternativeDataStreamAdd $srcFile 'Zone.Identifier' "[ZoneTransfer]`nZoneId=3"; }
function FileAdsDownloadedFromInternetDel     ( [String] $srcFile ){ FileNtfsAlternativeDataStreamDel $srcFile 'Zone.Identifier'; } # alternative: Unblock-File -LiteralPath $file
function DriveMapTypeToString                 ( [UInt32] $driveType ){
                                                return [String] $(switch($driveType){ 1{"NoRootDir"} 2{"RemovableDisk"} 3{"LocalDisk"} 4{"NetworkDrive"} 5{"CompactDisk"} 6{"RamDisk"} default{"UnknownDriveType=driveType"}}); }
function DriveList                            (){
                                                return [Object[]] (Get-WmiObject "Win32_LogicalDisk" | Select-Object DeviceID, FileSystem, Size, FreeSpace, VolumeName, DriveType, @{Name="DriveTypeName";Expression={(DriveMapTypeToString $_.DriveType)}}, ProviderName); }
function CredentialStandardizeUserWithDomain  ( [String] $username ){
                                                # Allowed username as input: "", "u0", "u0@domain", "@domain\u0", "domain\u0"   used because for unknown reasons sometimes a username like user@domain does not work, it requires domain\user.
                                                if( $username.Contains("\") -or -not $username.Contains("@") ){ return $username; } [String[]] $u = $username -split "@",2; return [String] ($u[1]+"\"+$u[0]); }
function CredentialGetSecureStrFromHexString  ( [String] $text ){ 
                                                return [System.Security.SecureString] (ConvertTo-SecureString $text); } # Will throw if it is not an encrypted string.
function CredentialGetSecureStrFromText       ( [String] $text ){ 
                                                if( $text -eq "" ){ throw [Exception] "$(ScriptGetCurrentFunc) is not allowed to be called with empty string"; } 
                                                return [System.Security.SecureString] (ConvertTo-SecureString $text -AsPlainText -Force); }
function CredentialGetHexStrFromSecureString  ( [System.Security.SecureString] $code ){ 
                                                return [String] (ConvertFrom-SecureString $code); } # ex: "ea32f9d30de3d3dc7fcd86a6a8f587ed9"
function CredentialGetTextFromSecureString    ( [System.Security.SecureString] $code ){ 
                                                [Object] $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($code); 
                                                return [String] [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr); }
function CredentialGetUsername                ( [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $onNullCredGetCurrentUserInsteadOfEmpty = $false ){
                                                # if cred is null then take current user.
                                                return [String] $(switch($cred -eq $null){ ($true){$(switch($onNullCredGetCurrentUserInsteadOfEmpty){($true){$env:USERNAME}default{""}})} default{$cred.UserName}}); }
function CredentialGetPassword                ( [System.Management.Automation.PSCredential] $cred = $null ){
                                                # if cred is null then return empty string.
                                                # $cred.GetNetworkCredential().Password is the same as (CredentialGetTextFromSecureString $cred.Password)
                                                return [String] $(switch($cred -eq $null){ ($true){""} default{$cred.GetNetworkCredential().Password}}); }
function CredentialWriteToFile                ( [System.Management.Automation.PSCredential] $cred, [String] $secureCredentialFile ){ 
                                                FileWriteFromString $secureCredentialFile ($cred.UserName+"`r`n"+(CredentialGetHexStrFromSecureString $cred.Password)); }
function CredentialRemoveFile                 ( [String] $secureCredentialFile ){ 
                                                OutProgress "CredentialRemoveFile `"$secureCredentialFile`""; FileDelete $secureCredentialFile; }
function CredentialReadFromFile               ( [String] $secureCredentialFile ){
                                                [String[]] $s = StringSplitIntoLines (FileReadContentAsString $secureCredentialFile "Default");
                                                try{ [String] $us = $s[0]; [System.Security.SecureString] $pwSecure = CredentialGetSecureStrFromHexString $s[1];
                                                  # alternative: New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content -Encoding Default -LiteralPath $secureCredentialFile | ConvertTo-SecureString)
                                                  return (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure));
                                                }catch{ throw [Exception] "Credential file `"$secureCredentialFile`" has not expected format for credentials, you may remove it and retry"; } }
function CredentialCreate                     ( [String] $username = "", [String] $password = "", [String] $accessShortDescription = "" ){ 
                                                [String] $us = $username;
                                                [String] $descr = switch($accessShortDescription -eq ''){($true){''}default{(' for '+$accessShortDescription)}};
                                                while( $us -eq "" ){ $us = StdInReadLine "Enter username$($descr): "; }
                                                if( $username -eq "" ){ $descr = ""; <# display descr only once #> }
                                                [System.Security.SecureString] $pwSecure = $null; 
                                                if( $password -eq "" ){ $pwSecure = StdInReadLinePw "Enter password for username=$($us)$($descr): "; }
                                                else{ $pwSecure = CredentialGetSecureStrFromText $password; }
                                                return (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure)); }
function CredentialGetAndStoreIfNotExists     ( [String] $secureCredentialFile, [String] $username = "", [String] $password = "", [String] $accessShortDescription = ""){
                                                # If username or password is empty then they are asked from std input.
                                                # If file exists and non-empty-user matches then it takes credentials from it.
                                                # If file not exists or non-empty-user not matches then it is written by given credentials.
                                                # For access description enter a message hint which is added to request for user as "login host xy", "mountpoint xy", etc.
                                                # For secureCredentialFile usually use: "$env:LOCALAPPDATA\MyNameOrCompany\MyOperation.secureCredentials.txt";
                                                Assert ($secureCredentialFile -ne "") "Missing secureCredentialFile.";
                                                [System.Management.Automation.PSCredential] $cred = $null;
                                                if( FileExists $secureCredentialFile ){
                                                  $cred = CredentialReadFromFile $secureCredentialFile;
                                                  if( $username -ne "" -and (CredentialGetUsername $cred) -ne (CredentialStandardizeUserWithDomain $username)){ $cred = null; }
                                                }
                                                if( $cred -eq $null ){
                                                  $cred = CredentialCreate $username $password $accessShortDescription;
                                                }
                                                if( FileNotExists $secureCredentialFile ){
                                                  CredentialWriteToFile $cred $secureCredentialFile;
                                                }
                                                return $cred; }
function ShareGetTypeName                     ( [UInt32] $typeNr ){ 
                                                return [String] $(switch($typeNr){ 0{"DiskDrive"} 1 {"PrintQueue"} 2{"Device"} 3{"IPC"} 
                                                2147483648{"DiskDriveAdmin"} 2147483649{"PrintQueueAdmin"} 2147483650{"DeviceAdmin"} 2147483651{"IPCAdmin"} default{"unknownNr=$typeNr"} }); }
function ShareGetTypeNr                       ( [String] $typeName ){ 
                                                return [UInt32] $(switch($typeName){ "DiskDrive"{0} "PrintQueue"{1} "Device"{2} "IPC"{3} 
                                                "DiskDriveAdmin"{2147483648} "PrintQueueAdmin"{2147483649} "DeviceAdmin"{2147483650} "IPCAdmin"{2147483651} default{4294967295} }); }
function ShareExists                          ( [String] $shareName ){
                                                return [Boolean] ((Get-SMBShare | Where-Object { $shareName -ne "" -and $_.Name -eq $shareName }) -ne $null); }
function ShareListAll                         ( [String] $selectShareName = "" ){
                                                # uses newer module SmbShare
                                                OutVerbose "List shares selectShareName=`"$selectShareName`"";
                                                # Ex: ShareState: Online, ...; ShareType: InterprocessCommunication, PrintQueue, FileSystemDirectory;
                                                return [Object] (Get-SMBShare | where { $selectShareName -eq "" -or $_.Name -eq $selectShareName } | Select-Object Name, ShareType, Path, Description, ShareState, ConcurrentUserLimit, CurrentUsers | Sort-Object TypeName, Name); }
function ShareListAllByWmi                    ( [String] $selectShareName = "" ){
                                                # As ShareListAll but uses older wmi and not newer module SmbShare
                                                [String] $computerName = ".";
                                                OutVerbose "List shares of machine=$computerName selectShareName=`"$selectShareName`"";
                                                # Exclude: AccessMask,InstallDate,MaximumAllowed,Description,Type,Status,@{Name="Descr";Expression={($_.Description).PadLeft(1,"-")}};
                                                [String] $filter = ""; if( $selectShareName -ne ""){ $filter = "Name='$selectShareName'"; }
                                                # Status: "OK","Error","Degraded","Unknown","Pred Fail","Starting","Stopping","Service","Stressed","NonRecover","No Contact","Lost Comm"
                                                return [PSCustomObject[]] (Get-WmiObject -Class Win32_Share -ComputerName $computerName -Filter $filter | 
                                                  Select-Object @{Name="TypeName";Expression={(ShareGetTypeName $_.Type)}}, @{Name="FullName";Expression={"\\$computerName\"+$_.Name}}, Path, Caption, Name, AllowMaximum, Status | 
                                                  Sort-Object TypeName, Name); }
function ShareLocksList                       ( [String] $path = "" ){ # list currenty read or readwrite locked open files of a share, requires elevated admin mode
                                                ProcessRestartInElevatedAdminMode;
                                                return [Object] (Get-SmbOpenFile | Where-Object { $_.Path.StartsWith($path,"OrdinalIgnoreCase") } | 
                                                  Select-Object FileId, SessionId, Path, ClientComputerName, ClientUserName, Locks | Sort-Object Path); }
function ShareLocksClose                      ( [String] $path = "" ){ # closes locks, ex: $path="D:\Transfer\" or $path="D:\Transfer\MyFile.txt"
                                                ProcessRestartInElevatedAdminMode;
                                                ShareLocksList $path | ForEach-Object{ OutProgress "ShareLocksClose `"$($_.Path)`""; Close-SmbOpenFile -Force -FileId $_.FileId; }; }
function ShareCreate                          ( [String] $shareName, [String] $dir, [String] $descr = "", [Int32] $nrOfAccessUsers = 25, [Boolean] $ignoreIfAlreadyExists = $true ){
                                                ProcessRestartInElevatedAdminMode;
                                                if( !(DirExists $dir)  ){ throw [Exception] "Cannot create share because original directory not exists: `"$dir`""; }
                                                FsEntryAssertExists $dir "Cannot create share";
                                                [Object] $existingShare = ShareListAll $shareName | Where-Object{ $_.Path -ieq $dir } | Select-Object -First 1;
                                                if( $existingShare -ne $null ){
                                                  OutVerbose "Already exists shareName=`"$shareName`" dir=`"$dir`" ";
                                                  if( $ignoreIfAlreadyExists ){ return; }
                                                }
                                                OutVerbose "CreateShare name=`"$shareName`" dir=`"$dir`" "; 
                                                # alternative: -FolderEnumerationMode AccessBased; Note: this is not allowed but it is the default: -ContinuouslyAvailable $true 
                                                [Object] $obj = New-SmbShare -Path $dir -Name $shareName -Description $descr -ConcurrentUserLimit $nrOfAccessUsers -FolderEnumerationMode Unrestricted -FullAccess (PrivGetGroupEveryone); }
function ShareCreateByWmi                     ( [String] $shareName, [String] $dir, [String] $descr = "", [Int32] $nrOfAccessUsers = 25, [Boolean] $ignoreIfAlreadyExists = $true ){
                                                [String] $typeName = "DiskDrive";
                                                if( !(DirExists $dir) ){ throw [Exception] "Cannot create share because original directory not exists: `"$dir`""; }
                                                FsEntryAssertExists $dir "Cannot create share";
                                                [UInt32] $typeNr = ShareGetTypeNr $typeName;
                                                [Object] $existingShare = ShareListAll $shareName | Where-Object{ $_.Path -ieq $dir -and $_.TypeName -eq $typeName } | Select-Object -First 1;
                                                if( $existingShare -ne $null ){
                                                  OutVerbose "Already exists shareName=`"$shareName`" dir=`"$dir`" typeName=$typeName"; 
                                                  if( $ignoreIfAlreadyExists ){ return; }
                                                }
                                                # Optionals:
                                                # MaximumAllowed: With this parameter, you can specify the maximum number of users allowed to concurrently use the shared resource (e.g., 25 users).
                                                # Description   : You use this parameter to describe the resource being shared (e.g., temp share).
                                                # Password      : Using this parameter, you can set a password for the shared resource on a server that is running 
                                                #                 with share-level security. If the server is running with user-level security, this parameter is ignored.
                                                # Access        : You use this parameter to specify a Security Descriptor (SD) for user-level permissions. 
                                                #                 An SD contains information about the permissions, owner, and access capabilities of the resource.
                                                [Object] $obj = (Get-WmiObject Win32_Share -List).Create( $dir, $shareName, $typeNr, $nrOfAccessUsers, $descr );
                                                [Int32] $rc = $obj.ReturnValue;
                                                if( $rc -ne 0 ){
                                                  [String] $errMsg = switch( $rc ){ 0{"Ok, Success"} 2{"Access denied"} 8{"Unknown failure"} 9{"Invalid name"} 10{"Invalid level"} 21{"Invalid parameter"} 
                                                    22{"Duplicate share"} 23{"Redirected path"} 24{"Unknown device or directory"} 25{"Net name not found"} default{"Unknown rc=$rc"} }
                                                  throw [Exception] "$(ScriptGetCurrentFunc)(dir=`"$dir`",sharename=`"$shareName`",typenr=$typeNr) failed because $errMsg";
                                                } }
                                                # TODO later add function ShareCreate by using New-SmbShare https://docs.microsoft.com/en-us/powershell/module/smbshare/new-smbshare?view=win10-ps
function ShareRemove                          ( [String] $shareName ){ # no action if it not exists
                                                if( -not (ShareExists $shareName) ){ return; }
                                                OutProgress "Remove shareName=`"$shareName`""; 
                                                Remove-SmbShare -Name $shareName -Confirm:$false; }
function ShareRemoveByWmi                     ( [String] $shareName ){
                                                [Object] $share = Get-WmiObject -Class Win32_Share -ComputerName "." -Filter "Name='$shareName'";
                                                if( $share -eq $null ){ return; }
                                                OutProgress "Remove shareName=`"$shareName`" typeName=$(ShareGetTypeName $share.Type) path=$($share.Path)"; 
                                                [Object] $obj = $share.delete();
                                                [Int32] $rc = $obj.ReturnValue;
                                                if( $rc -ne 0 ){
                                                  [String] $errMsg = switch( $rc ){
                                                    # Note: The following list was taken from create-fails, so it is not verified.
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
                                                  throw [Exception] "$(ScriptGetCurrentFunc)(sharename=`"$shareName`") failed because $errMsg";
                                                } }
function MountPointLocksListAll               (){ 
                                                OutVerbose "List all mount point locks"; return [Object] (Get-SmbConnection | 
                                                Select-Object ServerName,ShareName,UserName,Credential,NumOpens,ContinuouslyAvailable,Encrypted,PSComputerName,Redirected,Signed,SmbInstance,Dialect | 
                                                Sort-Object ServerName, ShareName, UserName, Credential); }
function MountPointListAll                    (){ 
                                                return [Object] (Get-SmbMapping | Select-Object LocalPath, RemotePath, Status); }
function MountPointGetByDrive                 ( [String] $drive ){ # return null if not found
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
                                                return [Object] (Get-SmbMapping -LocalPath $drive -ErrorAction SilentlyContinue); }
function MountPointRemove                     ( [String] $drive, [String] $mountPoint = "", [Boolean] $suppressProgress = $false ){
                                                # Also remove PsDrive; drive can be empty then mountPoint must be given
                                                if( $drive -eq "" -and $mountPoint -eq "" ){ throw [Exception] "$(ScriptGetCurrentFunc): missing either drive or mountPoint."; }
                                                if( $drive -ne "" -and -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
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
                                                  Remove-PSDrive -Name ($drive -replace ":","") -Force; # Force means no confirmation
                                                } }                                                
function MountPointCreate                     ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $errorAsWarning = $false, [Boolean] $noPreLogMsg = $false ){
                                                # $noPreLogMsg is usually true if mount points are called parallel when order of output strings is not sequentially
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
                                                [String] $us = CredentialGetUsername $cred $true;
                                                [String] $pw = CredentialGetPassword $cred;
                                                [String] $traceInfo = "MountPointCreate drive=$drive mountPoint=$($mountPoint.PadRight(22)) us=$($us.PadRight(12)) pw=*** state=";
                                                if( -not $noPreLogMsg ){ OutProgressText $traceInfo; }
                                                [Object] $smbMap = MountPointGetByDrive $drive;
                                                if( $smbMap -ne $null -and $smbMap.RemotePath -eq $mountPoint -and $smbMap.Status -eq "OK" ){ 
                                                  if( $noPreLogMsg ){ OutProgress "$($traceInfo)OkNoChange."; }else{ OutSuccess "OkNoChange."; } return; 
                                                }
                                                MountPointRemove $drive $mountPoint $true; # Required because New-SmbMapping has no force param.
                                                try{
                                                  # alternative: SaveCredentials 
                                                  if( $pw -eq ""){
                                                    $obj = New-SmbMapping -LocalPath $drive -RemotePath $mountPoint -Persistent $true -UserName $us;
                                                  }else{
                                                    $obj = New-SmbMapping -LocalPath $drive -RemotePath $mountPoint -Persistent $true -UserName $us -Password $pw;
                                                  }
                                                  if( $noPreLogMsg ){ OutProgress "$($traceInfo)Ok."; }else{ OutSuccess "Ok."; }
                                                }catch{
                                                  # ex: System.Exception: New-SmbMapping(Z,\\spider\Transfer,spider\u0) failed because Mehrfache Verbindungen zu einem Server 
                                                  #     oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig. 
                                                  #     Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut.
                                                  # ex: Der Netzwerkname wurde nicht gefunden.
                                                  # ex: Der Netzwerkpfad wurde nicht gefunden.
                                                  # ex: Das angegebene Netzwerkkennwort ist falsch.
                                                  [String] $exMsg = $_.Exception.Message.Trim();
                                                  [String] $msg = "New-SmbMapping($drive,$mountPoint,$us) failed because $exMsg";
                                                  if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                  # also see http://www.winboard.org/win7-allgemeines/137514-windows-fehler-code-liste.html http://www.megos.ch/files/content/diverses/doserrors.txt
                                                  if    ( $exMsg -eq "Der Netzwerkpfad wurde nicht gefunden."      ){ $msg = "HostNotFound";  } # 53 BAD_NETPATH
                                                  elseif( $exMsg -eq "Der Netzwerkname wurde nicht gefunden."      ){ $msg = "NameNotFound";  } # 67 BAD_NET_NAME
                                                  elseif( $exMsg -eq "Zugriff verweigert"                          ){ $msg = "AccessDenied";  } # 5 ACCESS_DENIED: 
                                                  elseif( $exMsg -eq "Das angegebene Netzwerkkennwort ist falsch." ){ $msg = "WrongPassword"; } # 86 INVALID_PASSWORD
                                                  elseif( $exMsg -eq "Mehrfache Verbindungen zu einem Server oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig. Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut." )
                                                                                                                    { $msg = "MultiConnectionsByMultiUserNamesNotAllowed"; } # 1219 SESSION_CREDENTIAL_CONFLICT
                                                  else {}
                                                  if( $noPreLogMsg ){ OutProgress "$($traceInfo)$($msg)"; }else{ OutWarning $msg 0; }
                                                  # alternative: (New-Object -ComObject WScript.Network).MapNetworkDrive("B:", "\\FPS01\users")
                                                } }
function PsDriveListAll                       (){ 
                                                OutVerbose "List PsDrives"; 
                                                return Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{Name="ShareName";Expression={$_.DisplayRoot+""}},Description,CurrentLocation,Free,Used | Sort-Object Name; }
                                                # Not used: Root, Provider. PSDrive: Note are only for current session, even if persist.
function PsDriveCreate                        ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null ){
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
                                                MountPointRemove $drive $mountPoint;
                                                [String] $us = CredentialGetUsername $cred $true;
                                                OutProgress "PsDriveCreate drive=$drive mountPoint=$mountPoint username=$us";
                                                try{
                                                  $obj = New-PSDrive -Name ($drive -replace ":","") -Root $mountPoint -PSProvider "FileSystem" -Scope Global -Persist -Description "$mountPoint($drive)" -Credential $cred;
                                                }catch{
                                                  # ex: System.ComponentModel.Win32Exception (0x80004005): Der lokale Gerätename wird bereits verwendet
                                                  # ex: System.Exception: Mehrfache Verbindungen zu einem Server oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig. 
                                                  #     Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut
                                                  # ex: System.Exception: New-PSDrive(Z,\\mycomp\Transfer,) failed because Das angegebene Netzwerkkennwort ist falsch
                                                  throw [Exception] "New-PSDrive($drive,$mountPoint,$us) failed because $($_.Exception.Message)";
                                                } }
function NetExtractHostName                   ( [String] $url ){ 
                                                return ([System.Uri]$url).Host; }
function NetAdapterGetConnectionStatusName    ( [Int32] $netConnectionStatusNr ){ 
                                                return [String] $(switch($netConnectionStatusNr){ 0{"Disconnected"} 1{"Connecting"} 2{"Connected"} 3{"Disconnecting"} 
                                                  4{"Hardware not present"} 5{"Hardware disabled"} 6{"Hardware malfunction"} 7{"Media disconnected"} 8{"Authenticating"} 9{"Authentication succeeded"} 
                                                  10{"Authentication failed"} 11{"Invalid address"} 12{"Credentials required"} default{"unknownNr=$netConnectionStatusNr"} }); }
function NetAdapterListAll                    (){ 
                                                return (Get-WmiObject -Class win32_networkadapter | Select-Object Name,NetConnectionID,MACAddress,Speed,@{Name="Status";Expression={(NetAdapterGetConnectionStatusName $_.NetConnectionStatus)}}); }
function NetPingHostIsConnectable             ( [String] $hostName, [Boolean] $doRetryWithFlushDns = $false ){
                                                if( (Test-Connection -Cn $hostName -BufferSize 16 -Count 1 -ea 0 -quiet) ){ return $true; } # later in ps V6 use -TimeoutSeconds 3 default is 5 sec
                                                if( -not $doRetryWithFlushDns ){ return $false; }
                                                OutVerbose "Host $hostName not reachable, so flush dns, nslookup and retry";
                                                & "ipconfig.exe" "/flushdns" | out-null; # note option /registerdns would require more privs
                                                try{ [System.Net.Dns]::GetHostByName($hostName); }catch{}
                                                # nslookup $hostName -ErrorAction SilentlyContinue | out-null;
                                                return [Boolean] (Test-Connection -Cn $hostName -BufferSize 16 -Count 1 -ea 0 -quiet); }
function NetGetIpConfig                       (){ [String[]] $out = & "IPCONFIG.EXE" "/ALL"          ; AssertRcIsOk $out; return $out; }
function NetGetNetView                        (){ [String[]] $out = & "NET.EXE" "VIEW" $ComputerName ; AssertRcIsOk $out; return $out; }
function NetGetNetStat                        (){ [String[]] $out = & "NETSTAT.EXE" "/A"             ; AssertRcIsOk $out; return $out; }
function NetGetRoute                          (){ [String[]] $out = & "ROUTE.EXE" "PRINT"            ; AssertRcIsOk $out; return $out; }
function NetGetNbtStat                        (){ [String[]] $out = & "NBTSTAT.EXE" "-N"             ; AssertRcIsOk $out; return $out; }
<# Type: ServerCertificateValidationCallback #> Add-Type -TypeDefinition "using System;using System.Net;using System.Net.Security;using System.Security.Cryptography.X509Certificates; public class ServerCertificateValidationCallback { public static void Ignore() { ServicePointManager.ServerCertificateValidationCallback += delegate( Object obj, X509Certificate certificate, X509Chain chain, SslPolicyErrors errors ){ return true; }; } } ";
function NetWebRequestLastModifiedFailSafe    ( [String] $url ){ # Requests metadata from a downloadable file. Return DateTime.MaxValue in case of any problem
                                                [net.WebResponse] $resp = $null;
                                                try{
                                                  [net.HttpWebRequest] $webRequest = [net.WebRequest]::Create($url);
                                                  $resp = $webRequest.GetResponse();
                                                  $resp.Close();
                                                  if( $resp.StatusCode -ne [system.net.httpstatuscode]::ok ){ throw [Exception] "GetResponse($url) failed with statuscode=$($resp.StatusCode)"; }
                                                  if( $resp.LastModified -lt (DateTimeFromStringIso "1970-01-01") ){ throw [Exception] "GetResponse($url) failed because LastModified=$($resp.LastModified) is unexpected lower than 1970"; }
                                                  return [DateTime] $resp.LastModified;
                                                }catch{ return [DateTime]::MaxValue; }finally{ if( $resp -ne $null ){ $resp.Dispose(); } } }
function NetDownloadFile                      ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [Boolean] $errorAsWarning = $false ){
                                                # Download a single file by overwrite it (as NetDownloadFileByCurl), powershell internal implementation of curl or wget which works for http, https and ftp only. 
                                                # Cares http response code 3xx for auto redirections.
                                                # If url not exists then it will throw.
                                                if( $url -eq "" ){ throw [Exception] "Wrong file url: $url"; } # alternative check: -or $url.EndsWith("/") 
                                                if( $us -ne "" -and $pw -eq "" ){ throw [Exception] "Missing password for username=$us"; }
                                                OutProgress "NetDownloadFile(onlyIfNewer=$onlyIfNewer) $url to `"$tarFile`" ";
                                                if( $ignoreSslCheck ){
                                                  # Note: This alternative is now obsolete (see https://msdn.microsoft.com/en-us/library/system.net.servicepointmanager.certificatepolicy(v=vs.110).aspx):
                                                  #   Add-Type -TypeDefinition "using System.Net; using System.Security.Cryptography.X509Certificates; public class TrustAllCertsPolicy : ICertificatePolicy { public bool CheckValidationResult( ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem){ return true; } } ";
                                                  #   [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy;
                                                  [ServerCertificateValidationCallback]::Ignore();
                                                  # Known Bug: We currently do not restore this option so it will influence all following calls.
                                                  # Maybe later we use: -SkipCertificateCheck
                                                }
                                                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls12; # default is: Ssl3, Tls.
                                                if( $onlyIfNewer -and (FileExists $tarFile) ){
                                                  [DateTime] $srcTs = (NetWebRequestLastModifiedFailSafe $url);
                                                  [DateTime] $fileTs = (FsEntryGetLastModified $tarFile);
                                                  if( $srcTs -le $fileTs ){
                                                    OutProgress "Ok, download not nessessary because timestamp of src $(DateTimeAsStringIso $srcTs) is older than target $(DateTimeAsStringIso $fileTs).";
                                                    return;
                                                  }
                                                }
                                                [String] $userAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1"; # some servers as api.github.com requires at least a string as "Mozilla/5.0"
                                                [String] $tarDir = FsEntryGetParentDir $tarFile;
                                                [String] $logf = "$LogDir\Download.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
                                                DirCreate $tarDir;
                                                OutProgress "Logfile: `"$logf`"";
                                                FileAppendLineWithTs $logf "WebClient.DownloadFile(url=$url,tar=$tarFile)";
                                                $webclient = new-object System.Net.WebClient;
                                                # Defaults: AllowAutoRedirect is true.
                                                $webclient.Headers.Add("User-Agent",$userAgent);
                                                # For future use: $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded");
                                                # not relevant because getting byte array: $webclient.Encoding = "Default"; "UTF8";
                                                [System.Management.Automation.PSCredential] $cred = $(switch($us -eq ""){ ($true){$null} default{(CredentialCreate $us $pw)} });
                                                if( $us -ne "" ){
                                                  $webclient.Credentials = $cred;
                                                }
                                                try{
                                                  [Boolean] $useWebclient = $false; # we use now Invoke-WebRequest
                                                  if( $useWebclient ){
                                                    $webclient.DownloadFile($url,$tarFile);
                                                  }else{
                                                    # For future use: -UseDefaultCredentials, -Method, -Body, -ContentType, -TransferEncoding, -InFile
                                                    if( $us -ne "" ){
                                                      $base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${us}:$pw"));
                                                      $headers = @{ Authorization = "Basic $base64" };
                                                      # Note: on api.github.com the $cred were ignored, so it requires the basic auth in header, but we also add $cred maybe for other servers. By the way curl -u works.
                                                      FileAppendLineWithTs $logf "Invoke-WebRequest -Uri `"$url`" -OutFile `"$tarFile`" -MaximumRedirection 2 -TimeoutSec 70 -UserAgent `"$userAgent`" -Headers `"$headers`" (Credential-User=`"$us`");";
                                                      Invoke-WebRequest -Uri $url -OutFile $tarFile -MaximumRedirection 2 -TimeoutSec 70 -UserAgent $userAgent -Headers $headers -Credential $cred;
                                                    }else{
                                                      FileAppendLineWithTs $logf "Invoke-WebRequest -Uri $url -OutFile $tarFile -MaximumRedirection 2 -TimeoutSec 70 -UserAgent $userAgent;";
                                                      Invoke-WebRequest -Uri $url -OutFile $tarFile -MaximumRedirection 2 -TimeoutSec 70 -UserAgent $userAgent;
                                                    }
                                                  }
                                                  [String] $stateMsg = "Ok, downloaded $(FileGetSize $tarFile) bytes.";
                                                  FileAppendLineWithTs $logf "  $stateMsg";
                                                  OutProgress $stateMsg;
                                                }catch{ 
                                                  # ex: The request was aborted: Could not create SSL/TLS secure channel.
                                                  # ex: Ausnahme beim Aufrufen von "DownloadFile" mit 2 Argument(en):  "The server committed a protocol violation. Section=ResponseStatusLine"
                                                  # ex: System.Net.WebException: Der Remoteserver hat einen Fehler zurückgegeben: (404) Nicht gefunden.
                                                  # for future use: $fileNotExists = $_.Exception -is [System.Net.WebException] -and (([System.Net.WebException]($_.Exception)).Response.StatusCode.value__) -eq 404;
                                                  [String] $msg = $_.Exception.Message;
                                                  if( $msg.Contains("Section=ResponseStatusLine") ){ $msg = "Server returned not a valid HTTP response. "+$msg; }
                                                  $msg = "NetDownloadFile(url=$url ,us=$us,tar=$tarFile) failed because $msg";
                                                  FileAppendLineWithTs $logf "  $msg";
                                                  if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                  OutWarning $msg;
                                                } }
function NetDownloadFileByCurl                ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [Boolean] $errorAsWarning = $false ){
                                                # Download a single file by overwrite it (as NetDownloadFile), requires curl.exe in path, 
                                                # timestamps are also taken, logging info is stored in a global logfile, redirections are followed,
                                                # for user agent info a mozilla firefox is set, 
                                                # if file curl-ca-bundle.crt exists next to curl.exe then this is taken.
                                                # Supported protocols: DICT, FILE, FTP, FTPS, Gopher, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMB, SMTP, SMTPS, Telnet and TFTP. 
                                                # Supported features:  SSL certificates, HTTP POST, HTTP PUT, FTP uploading, HTTP form based upload, proxies, HTTP/2, cookies, 
                                                #                      user+password authentication (Basic, Plain, Digest, CRAM-MD5, NTLM, Negotiate and Kerberos), file transfer resume, proxy tunneling and more. 
                                                # ex: curl.exe --show-error --output $tarFile --silent --create-dirs --connect-timeout 70 --retry 2 --retry-delay 5 --remote-time --stderr - --user "$($us):$pw" $url;
                                                if( $url -eq "" ){ throw [Exception] "Wrong file url: $url"; } # alternative check: -or $url.EndsWith("/") 
                                                if( $us -ne "" -and $pw -eq "" ){ throw [Exception] "Missing password for username=$us"; }
                                                [String[]] $opt = @( # see https://curl.haxx.se/docs/manpage.html
                                                   "--show-error"                            # Show error. With -s, make curl show errors when they occur
                                                  ,"--fail"                                  # if http response code is 4xx or 5xx then fail, but 3XX (redirects) are ok.
                                                  ,"--output", "`"$tarFile`""                # Write to FILE instead of stdout
                                                  ,"--silent"                                # Silent mode (don't output anything), no progress meter
                                                  ,"--create-dirs"                           # create the necessary local directory hierarchy as needed of --output file
                                                  ,"--connect-timeout", "70"                 # in sec
                                                  ,"--retry","2"                             #
                                                  ,"--retry-delay","5"                       #
                                                  ,"--remote-time"                           # Set the remote file's time on the local output
                                                  ,"--location"                              # Follow redirects (H)
                                                  ,"--max-redirs","50"                       # Maximum number of redirects allowed, default is 50, 0 means error on redir (H)
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
                                                  # --location-trusted                       # Like '--location', and send auth to other hosts (H)
                                                  # --login-options                          # OPTIONS Server login options (IMAP, POP3, SMTP)
                                                  # --manual                                 # Display the full manual
                                                  # --mail-from FROM                         # Mail from this address (SMTP)
                                                  # --mail-rcpt TO                           # Mail to this/these addresses (SMTP)
                                                  # --mail-auth AUTH                         # Originator address of the original email (SMTP)
                                                  # --max-filesize BYTES                     # Maximum file size to download (H/F)
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
                                                OutProgress "NetDownloadFileByCurl $url to `"$tarFile`"";
                                                [String] $tarDir = FsEntryGetParentDir $tarFile;
                                                [String] $logf = "$LogDir\Download.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
                                                DirCreate $tarDir;
                                                FileAppendLineWithTs $logf "$curlExe $opt --url $url";
                                                OutProgress "Logfile: `"$logf`"";
                                                try{
                                                  [String[]] $out = & $curlExe $opt "--url" $url;
                                                  if( $LASTEXITCODE -eq 60 ){
                                                    # Curl: (60) SSL certificate problem: unable to get local issuer certificate. More details here: http://curl.haxx.se/docs/sslcerts.html
                                                    # Curl performs SSL certificate verification by default, using a "bundle" of Certificate Authority (CA) public keys (CA certs). 
                                                    # If the default bundle file isn't adequate, you can specify an alternate file using the --cacert option.
                                                    # If this HTTPS server uses a certificate signed by a CA represented in the bundle, the certificate verification probably failed 
                                                    # due to a problem with the certificate (it might be expired, or the name might not match the domain name in the URL).
                                                    # If you'd like to turn off curl's verification of the certificate, use the -k (or --insecure) option.
                                                    throw [Exception] "SSL certificate problem as expired or domain name not matches, alternatively use option to ignore ssl check.";
                                                  }elseif( $LASTEXITCODE -eq 6 ){
                                                    # curl: (6) Could not resolve host: github.com
                                                    throw [Exception] "host not found.";
                                                  }elseif( $LASTEXITCODE -eq 22 ){
                                                    # curl: (22) The requested URL returned error: 404 Not Found
                                                    throw [Exception] "file not found.";
                                                  }elseif( $LASTEXITCODE -ne 0 ){
                                                    throw [Exception] "LastExitCode=$LASTEXITCODE.";
                                                  }
                                                  AssertRcIsOk $out $true;
                                                  FileAppendLines $logf (StringArrayInsertIndent $out 2);
                                                  # Trace example:  Warning: Transient problem: timeout Will retry in 5 seconds. 2 retries left.
                                                  [String] $stateMsg = "Ok, downloaded $(FileGetSize $tarFile) bytes.";
                                                  FileAppendLineWithTs $logf "  $stateMsg";
                                                  OutProgress $stateMsg;
                                                }catch{
                                                  [String] $msg = "Curl($url ,us=$us,tar=$tarFile) failed because $($_.Exception.Message)";
                                                  FileAppendLines $logf (StringArrayInsertIndent $msg 2);
                                                  if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                  OutWarning $msg;
                                                } }
function NetDownloadToString                  ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [String] $encodingIfNoBom = "UTF8" ){
                                                [String] $tmp = (FileGetTempFile); NetDownloadFile $url $tmp $us $pw $ignoreSslCheck $onlyIfNewer;
                                                [String] $result = (FileReadContentAsString $tmp $encodingIfNoBom); FileDelTempFile $tmp; return [String] $result; }
function NetDownloadToStringByCurl            ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [String] $encodingIfNoBom = "UTF8" ){
                                                [String] $tmp = (FileGetTempFile); NetDownloadFileByCurl $url $tmp $us $pw $ignoreSslCheck $onlyIfNewer;
                                                [String] $result = (FileReadContentAsString $tmp $encodingIfNoBom); FileDelTempFile $tmp; return [String] $result; }
function NetDownloadSite                      ( [String] $url, [String] $tarDir, [Int32] $level = 999, [Int32] $maxBytes = ([Int32]::MaxValue), [String] $us = "", 
                                                  [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Int32] $limitRateBytesPerSec = ([Int32]::MaxValue), [Boolean] $alsoRetrieveToParentOfUrl = $false ){
                                                # Mirror site to dir; wget: HTTP, HTTPS, FTP. Logfile is written into target dir.
                                                [String] $logf = "$tarDir\.Download.$(DateTimeNowAsStringIsoMonth).log";
                                                OutProgress "NetDownloadSite from $url to `"$tarDir`" (only newer files, logfile=`"$logf`")";
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
                                                  ,"--execute=robots=off" 
                                                  ,"--user-agent='Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0'"
                                                  ,"--quota=$maxBytes" 
                                                  ,"--limit-rate=$limitRateBytesPerSec"
                                                 #,"--wait=0.02"
                                                  ,"--user='$us'"
                                                  ,"--password='$pw'"
                                                 #,"--timestamping" 
                                                  ,$(switch($ignoreSslCheck){ ($true){"--no-check-certificate"} default{""}})
                                                    # Otherwise: ERROR: cannot verify ...'s certificate, issued by 'CN=Let\'s Encrypt Authority X3,O=Let\'s Encrypt,C=US': Unable to locally verify the issuer's authority. To connect to ... insecurely, use `--no-check-certificate'.
                                                 #,"--convert-links"            # Convert non-relative links locally    deactivated because:  Both --no-clobber and --convert-links were specified, only --convert-links will be used.
                                                 #,"--force-html"               # When input is read from a file, force it to be treated as an HTML file. This enables you to retrieve relative links from existing HTML files on your local disk, by adding <base href="url"> to HTML, or using the ‘--base’ command-line option.
                                                 #,"--input-file=$fileslist"    # 
                                                 #,"--ca-certificate file.crt"  # (more see http://users.ugent.be/~bpuype/wget/#download)
                                                  ,"--no-clobber"               # skip downloads to existing files, either noclobber or timestamping ,"--timestamping"
                                                      # If a file is downloaded more than once in the same directory, Wget’s behavior depends on a few options, including ‘--no-clobber’.
                                                      # In certain cases, the local file will be clobb  ered, or overwritten, upon repeated download.
                                                      # In other cases it will be preserved.
                                                      # When running Wget without ‘--timestamping’, ‘--no-clobber’, ‘--recursive’ or ‘--page-requisites’ downloading the same file 
                                                      # in the same directory will result in the original copy of file being preserved and the second copy being named ‘file.1’. 
                                                      # If that file is downloaded yet again, the third copy will be named ‘file.2’, and so on. 
                                                      # This is also the behavior with ‘-nd’, even if ‘--recursive’ or ‘--page-requisites’ are in effect. 
                                                      # When ‘--no-clobber’ is specified, this behavior is suppressed, and Wget will refuse to download newer copies of ‘file’.
                                                      # Therefore, "no-clobber" is actually a misnomer in this mode—it’s not clobbering that’s prevented (as the numeric 
                                                      # suffixes were already preventing clobbering), but rather the multiple version saving that’s prevented.
                                                      # When running Wget with ‘--recursive’ or ‘--page-requisites’, but without ‘--timestamping’, ‘--no-directories’, or ‘--no-clobber’, re-downloading
                                                      # a file will result in the new copy simply overwriting the old. Adding ‘--no-clobber’ will prevent this behavior, instead 
                                                      # causing the original version to be preserved and any newer copies on the server to be ignored.
                                                      # When running Wget with ‘--timestamping’, with or without ‘--recursive’ or ‘--page-requisites’, the decision as to whether 
                                                      # or not to download a newer copy of a file depends on the local and remote timestamp and size of the file (see Time-Stamping).
                                                      # ‘--no-clobber’ may not be specified at the same time as ‘--timestamping’.
                                                      # Note that when ‘--no-clobber’ is specified, files with the suffixes ‘.html’ or ‘.htm’ will be loaded from the local disk 
                                                      # and parsed as if they had been retrieved from the Web.
                                                  # more about logon forms: http://wget.addictivecode.org/FrequentlyAskedQuestions
                                                  # backup without file conversions: wget -mirror --page-requisites --directory-prefix=c:\wget_files\example2 ftp://username:password@ftp.yourdomain.com
                                                  # download:                        Wget                           --directory-prefix=c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                  # download resume:                 Wget --continue                --directory-prefix=c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
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
                                                  OutWarning "Warning: Ignored one or more occurrences of error category: $err. More see logfile=`"$logf`".";
                                                }
                                                [String] $state = "TargetDir: $(FsEntryReportMeasureInfo "$tarDir") (BeforeStart: $stateBefore)";
                                                FileAppendLineWithTs $logf $state;
                                                OutProgress $state; }
<# Script local variable: gitLogFile #>       [String] $script:gitLogFile = "$script:LogDir\Git.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
function GitBuildLocalDirFromUrl              ( [String] $tarRootDir, [String] $urlAndBranch ){
                                                # Note for branches: Our standard is to expect .../reponame#branchname in url and map this to local dir ...\reponame#branchname 
                                                # ex: GitBuildLocalDirFromUrl(".\gitdir","http://myhost/mydir1/dir2") == "C:\gitdir\mydir1\dir2";
                                                return [String] (FsEntryGetAbsolutePath (Join-Path $tarRootDir (([System.Uri]$urlAndBranch).AbsolutePath+([System.Uri]$urlAndBranch).Fragment).Replace("/","\"))); }
function GitCmd                               ( [String] $cmd, [String] $tarRootDir, [String] $urlAndBranch, [Boolean] $errorAsWarning = $false ){
                                                # ex: GitCmd Clone "C:\WorkGit"          "https://github.com/mniederw/MnCommonPsToolLib"
                                                # ex: GitCmd Clone "C:\WorkGit\Branches" "https://github.com/mniederw/MnCommonPsToolLib#V1.0"
                                                # $cmd == "Clone": target dir must not exist. Branch can be optionally specified.
                                                # $cmd == "Fetch": target dir must exist. Branch can be optionally specified.
                                                # $cmd == "Pull" : target dir must exist. Branch can be optionally specified.
                                                #   [git pull] is the same as [git fetch] and then [git merge FETCH_HEAD]. [git pull -rebase] runs [git rebase] instead of [git merge].
                                                # $urlAndBranch defines url and with sharp-char separated a branch which is used if you do not need the standard remote HEAD is pointing to, usually the master branch.
                                                if( @("Clone","Fetch","Pull") -notcontains $cmd ){ throw [Exception] "Expected one of (Clone,Fetch,Pull) instead of: $cmd"; }
                                                [String[]] $urlOpt = StringSplitToArray "#" $urlAndBranch;
                                                [String] $url = $urlOpt[0];
                                                [String] $branch = ""; if( $urlOpt.Count -gt 1 ){ $branch = $urlOpt[1]; if( $branch -eq ""){ throw [Exception] "Missing branch in urlAndBranch=`"$urlAndBranch`". "; } }
                                                if( $urlOpt.Count -gt 2 ){ throw [Exception] "Unknown third param in urlAndBranch=`"$urlAndBranch`". "; }
                                                [String] $dir = FsEntryGetAbsolutePath (GitBuildLocalDirFromUrl $tarRootDir $urlAndBranch);
                                                try{
                                                  [Object] $usedTime = [System.Diagnostics.Stopwatch]::StartNew();
                                                  [String[]] $gitArgs = @(); 
                                                  if( $cmd -eq "Clone" ){
                                                    # Writes to stderr: Cloning into 'c:\temp\test'...
                                                    $gitArgs = @( "clone", "--quiet" );
                                                    if( $branch -ne "" ){ $gitArgs += @( "--branch", $branch ); }
                                                    $gitArgs += @( "--", $url, $dir);
                                                  }elseif( $cmd -eq "Fetch" ){
                                                     # Writes to stderr: From https://github.com/myrepo  * branch  HEAD  -> FETCH_HEAD.
                                                    $gitArgs = @( "-C", $dir, "--git-dir=.git", "fetch", "--quiet", $url);
                                                    if( $branch -ne "" ){ $gitArgs += @( $branch ); }
                                                  }elseif( $cmd -eq "Pull" ){
                                                    # Defaults: "--no-rebase" "origin"; 
                                                    $gitArgs = @( "-C", $dir, "--git-dir=.git", "pull", "--quiet", "--no-stat", $url);
                                                    if( $branch -ne "" ){ $gitArgs += @( $branch ); }
                                                  }else{ throw [Exception] "Unknown git cmd=`"$cmd`""; }
                                                  # ex: "git" "-C" "C:\Temp\mniederw\myrepo" "--git-dir=.git" "pull" "--quiet" "--no-stat" "https://github.com/mniederw/myrepo"
                                                  FileAppendLineWithTs $gitLogFile "GitCmd(`"$tarRootDir`",$urlAndBranch) git $gitArgs";
                                                  [String] $out = ProcessStart "git" $gitArgs $true; # care stderr as stdout
                                                  # Skip known unused strings which are written to stderr as:
                                                  # - "Checking out files:  47% (219/463)" or "Checking out files: 100% (463/463), done."
                                                  # - warning: You appear to have cloned an empty repository.
                                                  # - The string "Already up to date." is presumebly suppressed by quiet option.
                                                  StringSplitIntoLines $out | Where-Object{ -not [String]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() } |
                                                    Where-Object { -not ($_.StartsWith("Checking out files: ") -and ($_.EndsWith(")") -or $_.EndsWith(", done."))) } |
                                                    ForEach-Object{ OutProgress $_; }
                                                  OutSuccess "  Ok, usedTimeInSec=$([Int64]($usedTime.Elapsed.TotalSeconds+0.999)).";
                                                }catch{
                                                  # ex: fatal: HttpRequestException encountered.
                                                  # ex: Fehler beim Senden der Anforderung.
                                                  # ex: fatal: AggregateException encountered.
                                                  # ex: Logon failed, use ctrl+c to cancel basic credential prompt.
                                                  # ex: remote: Repository not found.\nfatal: repository 'https://github.com/mniederw/UnknownRepo/' not found   (Clone rc=128)
                                                  # ex: fatal: Not a git repository: 'D:\WorkGit\mniederw\UnknownRepo\.git'
                                                  # ex: error: unknown option `anyUnknownOption'
                                                  # ex: fatal: refusing to merge unrelated histories   (pull rc=128)
                                                  # ex: fatal: Couldn't find remote ref HEAD    (in case the repo contains no content)
                                                  # ex: error: Your local changes to the following files would be overwritten by merge:   (Then the lines: "        ...file..." "Aborting" "Please commit your changes or stash them before you merge.")
                                                  # ex: error: The following untracked working tree files would be overwritten by merge:   (Then the lines: "        ....file..." "Please move or remove them before you merge." "Aborting")
                                                  $msg = "$(ScriptGetCurrentFunc)($cmd,$tarRootDir,$url) failed because $(StringReplaceNewlines $_.Exception.Message ' - ')";
                                                  ScriptResetRc;
                                                  if( $cmd -eq "Pull" -and $msg.Contains("error: Your local changes to the following files would be overwritten by merge:") ){
                                                    OutProgress "Note: If you would like to ignore and reset all local changes then call:  git -C `"$dir`" --git-dir=.git reset --hard"; # alternative option: --hard origin/master
                                                  }
                                                  if( $cmd -eq "Pull" -and $msg.Contains("fatal: refusing to merge unrelated histories") ){
                                                    OutProgress "Note: If you would like to ignore and reset all local changes then call:  git -C `"$dir`" --git-dir=.git reset --hard";
                                                    OutProgress "      Afterwards you can retry pull with the option --allow-unrelated-histories  but if it still results in (error: The following untracked ...) then remove dir and clone it."
                                                  }
                                                  if( $cmd -eq "Pull" -and $msg.Contains("fatal: Couldn't find remote ref HEAD") ){
                                                    OutSuccess "  Ok, repository has no content."; return;
                                                  }
                                                  if( $msg.Contains("remote: Repository not found.") -and $msg.Contains("fatal: repository ") ){
                                                    $msg = "$cmd failed because not found repository: $url .";
                                                  }
                                                  if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                  OutWarning $msg;
                                                } }
function GitCloneOrFetchOrPull                ( [String] $tarRootDir, [String] $urlAndBranch, [Boolean] $usePullNotFetch = $false, [Boolean] $errorAsWarning = $false ){
                                                # Extracts path of url below host as relative dir, uses this path below target root dir to create or update git; 
                                                # ex: GitCloneOrFetchOrPull "C:\WorkGit"          "https://github.com/mniederw/MnCommonPsToolLib"
                                                # ex: GitCloneOrFetchOrPull "C:\WorkGit\Branches" "https://github.com/mniederw/MnCommonPsToolLib#V1.0"
                                                [String] $tarDir = (GitBuildLocalDirFromUrl $tarRootDir $urlAndBranch);
                                                if( (DirExists $tarDir) ){
                                                  if( $usePullNotFetch ){
                                                    GitCmd "Pull" $tarRootDir $urlAndBranch $errorAsWarning;
                                                  }else{
                                                    GitCmd "Fetch" $tarRootDir $urlAndBranch $errorAsWarning;
                                                  }
                                                }else{
                                                  GitCmd "Clone" $tarRootDir $urlAndBranch $errorAsWarning;
                                                } }
function GitCloneOrFetchIgnoreError           ( [String] $tarRootDir, [String] $url ){ GitCloneOrFetchOrPull $tarRootDir $url $false $true; }
function GitCloneOrPullIgnoreError            ( [String] $tarRootDir, [String] $url ){ GitCloneOrFetchOrPull $tarRootDir $url $true  $true; }
function GitListCommitComments                ( [String] $tarDir, [String] $localRepoDir, [String] $fileExtension = ".tmp", [String] $prefix = "Log.", [Int32] $doOnlyIfOlderThanAgeInDays = 14 ){
                                                # Overwrite git log info files below specified target dir, 
                                                # For the name of the repo it takes the two last dir parts separated with a dot (NameOfRepoParent.NameOfRepo).
                                                # It writes files as Log.NameOfRepoParent.NameOfRepo.CommittedComments.tmp and Log.NameOfRepoParent.NameOfRepo.CommittedChangedFiles.tmp 
                                                # It is quite slow about 10 sec per repo, so it can controlled by $doOnlyIfOlderThanAgeInDays.
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
                                                      # ex: "warning: inexact rename detection was skipped due to too many files."
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
<# Type: SvnEnvInfo #>                        Add-Type -TypeDefinition "public struct SvnEnvInfo {public string Url; public string Path; public string RealmPattern; public string CachedAuthorizationFile; public string CachedAuthorizationUser; public string Revision; }";
                                                # ex: Url="https://myhost/svn/Work"; Path="D:\Work"; RealmPattern="https://myhost:443"; 
                                                # CachedAuthorizationFile="$env:APPDATA\Subversion\auth\svn.simple\25ff84926a354d51b4e93754a00064d6"; CachedAuthorizationUser="myuser"; Revision="1234"
function SvnExe                               (){ 
                                                return [String] ((RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "Directory") + ".\bin\svn.exe"); }
<# Script local variable: svnLogFile #>       [String] $script:svnLogFile = "$script:LogDir\Svn.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
function SvnEnvInfoGet                        ( [String] $workDir ){
                                                # Return SvnEnvInfo; no param is null.
                                                OutProgress "SvnEnvInfo - Get svn environment info of workDir=`"$workDir`"; ";
                                                FileAppendLineWithTs $svnLogFile "SvnEnvInfoGet(`"$workDir`")";
                                                # Example:
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
                                                # Example:
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
                                                # Svn can cache more than one server connection option, so we need to find the correct one by matching the realmPattern in realmstring which identifies a server connection.
                                                [String] $svnCachedAuthorizationDir = "$env:APPDATA\Subversion\auth\svn.simple";
                                                # Care only file names like "25ff84926a354d51b4e93754a00064d6"
                                                [String[]] $files = FsEntryListAsStringArray "$svnCachedAuthorizationDir\*" $false $false | 
                                                    Where-Object{ (FsEntryGetFileName $_) -match "^[0-9a-f]{32}$" } | Sort-Object;
                                                [String] $encodingIfNoBom = "Default";
                                                foreach( $f in $files ){
                                                  [String[]] $lines = FileReadContentAsLines $f $encodingIfNoBom;
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
                                                      if( $result.CachedAuthorizationFile -ne "" ){ 
                                                        throw [Exception] "There exist more than one file with realmPattern=`"$($result.RealmPattern)`": `"$($result.CachedAuthorizationFile)`" and `"$f`". "; }
                                                      $result.CachedAuthorizationFile = $f;
                                                      $result.CachedAuthorizationUser = $user;
                                                    }
                                                  }
                                                }
                                                # Not used: RealmPattern=`"$($r.RealmPattern)`" CachedAuthorizationFile=`"$($r.CachedAuthorizationFile)`" 
                                                OutProgress "SvnEnvInfo: Url=$($result.Url) Path=`"$($result.Path)`" User=`"$($result.CachedAuthorizationUser)`" Revision=$($result.Revision) ";
                                                return $result; }
function SvnGetDotSvnDir                      ( $workSubDir ){
                                                # Return absolute .svn dir up from given dir which must exists.
                                                [String] $d = FsEntryGetAbsolutePath $workSubDir;
                                                for( [Int32] $i = 0; $i -lt 200; $i++ ){
                                                  if( DirExists "$d\.svn" ){ return [String] "$d\.svn"; }
                                                  $d = FsEntryGetAbsolutePath (Join-Path $d "..");
                                                }
                                                throw [Exception] "Missing directory '.svn' within or up from the path `"$workSubDir`""; }
function SvnAuthorizationSave                ( [String] $workDir, [String] $user ){
                                                # If this part fails then you should clear authorization account in svn settings.
                                                OutProgress "SvnAuthorizationSave user=$user";
                                                FileAppendLineWithTs $svnLogFile "SvnAuthorizationSave(`"$workDir`")";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                DirCopyToParentDirByAddAndOverwrite "$env:APPDATA\Subversion\auth\svn.simple" "$dotSvnDir\OwnSvnAuthSimpleSaveUser_$user\"; }
function SvnAuthorizationTryLoadFile          ( [String] $workDir, [String] $user ){
                                                # If work auth dir exists then copy content to svn cache dir.
                                                OutProgress "SvnAuthorizationTryLoadFile - try to reload from an earlier save";
                                                FileAppendLineWithTs $svnLogFile "SvnAuthorizationTryLoadFile(`"$workDir`")";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                [String] $svnWorkAuthDir = "$dotSvnDir\OwnSvnAuthSimpleSaveUser_$user\svn.simple";
                                                [String] $svnAuthDir = "$env:APPDATA\Subversion\auth\";
                                                if( DirExists $svnWorkAuthDir ){
                                                  DirCopyToParentDirByAddAndOverwrite $svnWorkAuthDir $svnAuthDir;
                                                }else{
                                                  OutProgress "Load not done because not found dir: `"$svnWorkAuthDir`"";
                                                } } # For later usage: function SvnAuthorizationClear (){ FileAppendLineWithTs $svnLogFile "SvnAuthorizationClear"; [String] $svnAuthCurr = "$env:APPDATA\Subversion\auth\svn.simple"; DirCopyToParentDirByAddAndOverwrite $svnAuthCurr $svnAuthWork; }
function SvnCleanup                           ( [String] $workDir ){
                                                # Cleanup a previously failed checkout, update or commit operation.
                                                FileAppendLineWithTs $svnLogFile "SvnCleanup(`"$workDir`")";
                                                # For future alternative option: --trust-server-cert-failures unknown-ca,cn-mismatch,expired,not-yet-valid,other
                                                [String[]] $out = & (SvnExe) "cleanup" --non-interactive $workDir; AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2); }
function SvnStatus                            ( [String] $workDir, [Boolean] $showFiles ){
                                                # Return true if it has any pending changes, otherwise false.
                                                # Example: "M       D:\Work\..."
                                                # First char: Says if item was added, deleted, or otherwise changed
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
                                                [String[]] $out = @()+(& (SvnExe) "status" $workDir); AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                [Int32] $nrOfPendingChanges = $out.Count;
                                                [Int32] $nrOfCommitRelevantChanges = ([String[]](@()+($out | Where-Object {$_ -ne $null -and -not $_.StartsWith("!") }))).Count; # ignore lines with leading '!' because these would not occurre in commit dialog
                                                OutProgress "NrOfPendingChanged=$nrOfPendingChanges;  NrOfCommitRelevantChanges=$nrOfCommitRelevantChanges;";
                                                FileAppendLineWithTs $svnLogFile "  NrOfPendingChanges=$nrOfPendingChanges;  NrOfCommitRelevantChanges=$nrOfCommitRelevantChanges;";
                                                [Boolean] $hasAnyChange = $nrOfCommitRelevantChanges -gt 0;
                                                if( $showFiles -and $hasAnyChange ){ $out | %{ OutProgress $_; }; }
                                                return [Boolean] $hasAnyChange; }
function SvnRevert                            ( [String] $workDir, [String[]] $relativeRevertFsEntries ){
                                                # Undo the specified fs-entries if they have any pending change.
                                                foreach( $f in $relativeRevertFsEntries ){
                                                  FileAppendLineWithTs $svnLogFile "SvnRevert(`"$workDir\$f`")";
                                                  [String[]] $out = & (SvnExe) "revert" "--recursive" "$workDir\$f"; AssertRcIsOk $out;
                                                  FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                } }
function SvnTortoiseCommit                    ( [String] $workDir ){
                                                FileAppendLineWithTs $svnLogFile "SvnTortoiseCommit(`"$workDir`") call checkin dialog";
                                                [String] $tortoiseExe = (RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "Directory") + ".\bin\TortoiseProc.exe";
                                                Start-Process -NoNewWindow -Wait -FilePath "$tortoiseExe" -ArgumentList @("/closeonend:2","/command:commit","/path:`"$workDir`""); AssertRcIsOk; }
function SvnUpdate                            ( [String] $workDir, [String] $user ){ SvnCheckoutAndUpdate $workDir "" $user $true; }
function SvnCheckoutAndUpdate                 ( [String] $workDir, [String] $url, [String] $user, [Boolean] $doUpdateOnly = $false, [String] $pw = "" ){
                                                # Init working copy and get (init and update) last changes. If pw is empty then it uses svn-credential-cache.
                                                # If specified update-only then no url is nessessary but if given then it verifies it.
                                                # Note: we do not use svn-update because svn-checkout does the same (the difference is only the use of an url).
                                                # Note: sometimes often after 5-20 GB received there is a network problem which aborts svn-checkout,
                                                #   so if it is recognised as a known exception then it will automatically do a cleanup, wait for 30 sec and retry (max 100 times).
                                                if( $doUpdateOnly ){ 
                                                  Assert ((DirExists $workDir) -and (SvnGetDotSvnDir $workDir)) "Missing work dir or it is not a svn repo: `"$workDir`"";
                                                  [String] $repoUrl = (SvnEnvInfoGet $workDir).Url;
                                                  if( $url -eq "" ){ $url = $repoUrl; }else{ Assert ($url -eq $repoUrl) "Given url=$url does not match url in repository: $repoUrl"; }
                                                }
                                                [String] $tmp = (FileGetTempFile);
                                                [Int32] $maxNrOfTries = 100; [Int32] $nrOfTries = 0;
                                                while($true){ $nrOfTries++;
                                                  OutProgress "SvnCheckoutAndUpdate: get all changes from $url to `"$workDir`" $(switch($doUpdateOnly){($true){''}default{'and if it not exists and then init working copy first'}}).";
                                                  FileAppendLineWithTs $svnLogFile "SvnCheckoutAndUpdate(`"$workDir`",$url,$user)";
                                                  # For future alternative option: --trust-server-cert-failures unknown-ca,cn-mismatch,expired,not-yet-valid,other
                                                  # For future alternative option: --quite
                                                  [String[]] $opt = @( "--non-interactive", "--ignore-externals" );
                                                  if( $user -ne "" ){ $opt += @( "--username", $user ); }
                                                  if( $pw -ne "" ){ $opt += @( "--password", $pw, "--no-auth-cache" ); } # is visible in process list.
                                                  # Alternative for checkout: tortoiseExe /closeonend:2 /command:checkout /path:$workDir /url:$url
                                                  if( $doUpdateOnly ){ $opt = @( "update"  ) + $opt + @(       $workDir ); }
                                                  else               { $opt = @( "checkout") + $opt + @( $url, $workDir ); }
                                                  FileAppendLineWithTs $svnLogFile "`"$(SvnExe)`" $opt";
                                                  try{
                                                    & (SvnExe) $opt 2> $tmp | %{ FileAppendLineWithTs $svnLogFile ("  "+$_); OutProgress $_ 2; };
                                                    [String] $encodingIfNoBom = "Default";
                                                    AssertRcIsOk (FileReadContentAsLines $tmp $encodingIfNoBom) $true;
                                                    # ex: svn: E170013: Unable to connect to a repository at URL 'https://mycomp/svn/Work/mydir'
                                                    #     svn: E230001: Server SSL certificate verification failed: issuer is not trusted   Exception: Last operation failed [rc=1].
                                                    break;
                                                  }catch{
                                                    # ex: "svn: E120106: ra_serf: The server sent a truncated HTTP response body"
                                                    # ex: "svn: E155037: Previous operation has not finished; run 'cleanup' if it was interrupted"
                                                    # ex: "svn: E155004: Run 'svn cleanup' to remove locks (type 'svn help cleanup' for details)"
                                                    # ex: "svn: E175002: REPORT request on '/svn/Work/!svn/me' failed"
                                                    # ex: "svn: E170013: Unable to connect to a repository at URL 'https://myserver/svn/myrepo'."
                                                    # ex: "svn: E200014: Checksum mismatch for '...file...'"
                                                    # ex: "svn: E200030: sqlite[S10]: disk I/O error, executing statement 'VACUUM '"
                                                    # ex: "svn: E205000: Try 'svn help checkout' for more information"
                                                    [String] $m = $_.Exception.Message;
                                                    [String] $msg = "$(ScriptGetCurrentFunc)(dir=`"$workDir`",url=$url,user=$user) failed because $m. Logfile=`"$svnLogFile`".";
                                                    FileAppendLineWithTs $svnLogFile $msg;
                                                    [Boolean] $isKnownProblemToSolveWithRetry = $m.Contains(" E120106:") -or $m.Contains(" E155037:") -or $m.Contains(" E155004:") -or $m.Contains(" E170013:") -or $m.Contains(" E175002:") -or $m.Contains(" E200014:") -or $m.Contains(" E200030:");
                                                    if( -not $isKnownProblemToSolveWithRetry -or $nrOfTries -ge $maxNrOfTries ){ throw [Exception] $msg; }
                                                    [String] $msg2 = "Is try nr $nrOfTries of $maxNrOfTries, will do cleanup, wait 30 sec and if not reached max then retry.";
                                                    OutWarning "$msg $msg2";
                                                    FileAppendLineWithTs $svnLogFile $msg2;
                                                    SvnCleanup $workDir;
                                                    ProcessSleepSec 30;
                                                  }finally{ FileDelTempFile $tmp; } } }
function SvnPreCommitCleanupRevertAndDelFiles ( [String] $workDir, [String[]] $relativeDelFsEntryPatterns, [String[]] $relativeRevertFsEntries ){
                                                OutInfo "SvnPreCommitCleanupRevertAndDelFiles `"$workDir`"";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                [String] $svnRequiresCleanup = "$dotSvnDir\OwnSvnRequiresCleanup.txt";
                                                if( (FileExists $svnRequiresCleanup) ){ # Optimized because it is slow.
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
function SvnTortoiseCommitAndUpdate           ( [String] $workDir, [String] $svnUrl, [String] $svnUser, [Boolean] $ignoreIfHostNotReachable, [String] $pw = "" ){
                                                # Check svn dir, do svn cleanup, check svn user by asserting it matches previously used svn user, delete temporary files, svn commit (interactive), svn update.
                                                # If pw is empty then it takes it from svn-credential-cache.
                                                [String] $traceInfo = "SvnTortoiseCommitAndUpdate workdir=`"$workDir`" url=$svnUrl user=$svnUser";
                                                OutInfo $traceInfo;
                                                OutProgress "SvnLogFile: `"$svnLogFile`"";
                                                FileAppendLineWithTs $svnLogFile ("`r`n"+("-"*80)+"`r`n"+(DateTimeNowAsStringIso "yyyy-MM-dd HH:mm")+" "+$traceInfo);
                                                try{
                                                  [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                  [String] $svnRequiresCleanup = "$dotSvnDir\OwnSvnRequiresCleanup.txt";
                                                  # Check preconditions.
                                                  if( $svnUrl  -eq "" ){ throw [Exception] "SvnUrl is empty which is not allowed"; }
                                                  if( $svnUser -eq "" ){ throw [Exception] "SvnUser is empty which is not allowed"; }
                                                  #
                                                  [SvnEnvInfo] $r = SvnEnvInfoGet $workDir;
                                                  #
                                                  OutProgress "Verify expected SvnUser=$svnUser matches CachedAuthorizationUser=$($r.CachedAuthorizationUser) - if last user was not found then try to load it";
                                                  if( $r.CachedAuthorizationUser -eq "" ){
                                                    SvnAuthorizationTryLoadFile $workDir $svnUser;
                                                    $r = SvnEnvInfoGet $workDir;
                                                  }
                                                  if( $r.CachedAuthorizationUser -eq "" ){ throw [Exception] "This script asserts that configured SvnUser=$svnUser matches last accessed user because it requires stored credentials, but last user was not saved, please call svn-repo-browser, login, save authentication and then retry."; }
                                                  if( $svnUser -ne $r.CachedAuthorizationUser ){ throw [Exception] "Configured SvnUser=$svnUser does not match last accessed user=$($r.CachedAuthorizationUser), please call svn-settings, clear cached authentication-data, call svn-repo-browser, login, save authentication and then retry."; }
                                                  #
                                                  [String] $host = NetExtractHostName $svnUrl;
                                                  if( $ignoreIfHostNotReachable -and -not (NetPingHostIsConnectable $host) ){
                                                    OutWarning "Host $host is not reachable, so ignored.";
                                                    return;
                                                  }
                                                  #
                                                  FileAppendLineWithTs $svnRequiresCleanup "";
                                                  [Boolean] $hasAnyChange = SvnStatus $workDir $false;
                                                  while( $hasAnyChange ){
                                                    OutProgress "SvnTortoiseCommit - Calling dialog to checkin all pending changes and wait for end of it";
                                                    SvnTortoiseCommit $workDir;
                                                    $hasAnyChange = SvnStatus $workDir $true;
                                                  }
                                                  #
                                                  SvnCheckoutAndUpdate $workDir $svnUrl $svnUser $false $pw;
                                                  SvnAuthorizationSave $workDir $svnUser;
                                                  [SvnEnvInfo] $r = SvnEnvInfoGet $workDir;
                                                  #
                                                  FileDelete $svnRequiresCleanup;
                                                }catch{
                                                  FileAppendLineWithTs $svnLogFile (StringFromException $_.Exception);
                                                  throw;
                                                } }
function TfsExe                               (){ # return tfs executable
                                                [String[]] $a = @(
                                                  "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                       "${env:ProgramFiles}\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                  "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                       "${env:ProgramFiles}\Microsoft Visual Studio\2019\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                  "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                       "${env:ProgramFiles}\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                  "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                       "${env:ProgramFiles}\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                  "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                       "${env:ProgramFiles}\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                  "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                       "${env:ProgramFiles}\Microsoft Visual Studio\2017\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe",
                                                  (FsEntryMakeAbsolutePath "$env:VS140COMNTOOLS\..\IDE\TF.exe"),
                                                  (FsEntryMakeAbsolutePath "$env:VS120COMNTOOLS\..\IDE\TF.exe"),
                                                  (FsEntryMakeAbsolutePath "$env:VS100COMNTOOLS\..\IDE\TF.exe") );
                                                foreach( $i in $a ){ if( FileExists $i ) { return [String] $i; } }
                                                throw [Exception] "Missing one of the files: $a"; }
                                                # for future use: tf.exe checkout /lock:checkout /recursive file
                                                # for future use: tf.exe merge /baseless /recursive /version:C234~C239 branchFrom branchTo
                                                # for future use: tf.exe workfold /workspace:ws /cloak 
<# Script local variable: tfsLogFile #>       [String] $script:tfsLogFile = "$script:LogDir\Tfs.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
function TfsGetNewestNoOverwrite              ( [String] $wsdir, [String] $tfsPath ){ # ex: TfsGetNewestNoOverwrite C:\MyWorkspace\Src $/Src
                                                [String] $tfExe = (TfsExe);
                                                OutProgress "CD `"$wsdir`"; `"$tfExe`" vc get /noprompt /recursive /version:T `"$tfsPath`" ";
                                                FileAppendLineWithTs $tfsLogFile "TfsGetNewestNoOverwrite(`"$wsdir`",`"$tfsPath`")";
                                                [String] $cd = (Get-Location);
                                                Set-Location $wsdir;
                                                try{ [String[]] $a = @()+(& "$tfExe" vc get /noprompt /recursive /version:T $tfsPath); # Output: "Alle Dateien sind auf dem neuesten Stand."
                                                  if( $a.Count -gt 0 ){ $a | ForEach-Object { OutProgress "  $_"; }; }
                                                }finally{ Set-Location $cd; } }

function TfsListOwnLocks                      ( [String] $wsdir, [String] $tfsPath ){
                                                [String] $tfExe = (TfsExe);
                                                OutProgress "CD `"$wsdir`"; `"$tfExe`" vc status /noprompt /recursive /format:brief `"$tfsPath`" ";
                                                [String] $cd = (Get-Location);
                                                Set-Location $wsdir;
                                                try{
                                                  [String[]] $a = @()+((& "$tfExe" vc status /noprompt /recursive /format:brief $tfsPath 2>&1 ) | Select-Object -Skip 2 | Where-Object { -not [String]::IsNullOrWhiteSpace($_) });
                                                  # ex:
                                                  #    Dateiname    Ändern     Lokaler Pfad
                                                  #    ------------ ---------- -------------------------------------
                                                  #    $/Src/MyBranch
                                                  #    MyFile.txt   bearbeiten C:\MyWorkspace\Src\MyBranch\MyFile.txt
                                                  #    
                                                  #    1 Änderungen
                                                  # ex: Es sind keine ausstehenden Änderungen vorhanden.
                                                  return [String[]] $a;
                                                }finally{
                                                  Set-Location $cd;
                                                } }
function TfsAssertNoLocksInDir                ( [String] $wsdir, [String] $tfsPath ){ # ex: "C:\MyWorkspace" "$/Src";
                                                [String[]] $allLocks = @()+(TfsListOwnLocks $wsdir $tfsPath);
                                                if( $allLocks.Count -gt 0 ){
                                                  $allLocks | Foreach { OutProgress "Found Lock: $_"; };
                                                  throw [Exception] "Assertion failed because there exists pending locks under `"$tfsPath`""; 
                                                } }
function TfsMergeDir                          ( [String] $wsdir, [String] $tfsPath, [String] $tfsTargetBranch ){
                                                [String] $tfExe = (TfsExe);
                                                OutProgress "CD `"$wsdir`"; `"$tfExe`" vc merge /noprompt /recursive /format:brief /version:T `"$tfsPath`" `"$tfsTargetBranch`" ";
                                                [String] $cd = (Get-Location);
                                                Set-Location $wsdir;
                                                try{
                                                  [String[]] $a = (& "$tfExe" vc merge /noprompt /recursive /format:brief /version:T "$tfsPath" "$tfsTargetBranch"); # later we would like to suppres stderr
                                                  ScriptResetRc;
                                                  # ex:
                                                  #    Konflikt ("mergen, bearbeiten"): $/Src/MyBranch1/MyFile.txt;C123~C129 -> $/Src/MyBranch2/MyFile.txt;C121
                                                  #    3 Konflikte. Geben Sie "/format:detailed" an, um die einzelnen Konflikte in der Zusammenfassung aufzulisten.
                                                  #    mergen, bearbeiten: $/Src/MyBranch1/MyFile2.txt;C123~C129 -> $/Src/MyBranch2/MyFile2.txt;C121
                                                  #    The item $/Src/MyBranch1/MyFile2.txt is locked for check-out by MyDomain\MyUser in workspace MYMACH.
                                                  #    
                                                  #    ---- Zusammenfassung: 31 Konflikte, 0 Warnungen, 0 Fehler ----
                                                  # does not work: | Where-Object { $_ -contains "---- Zusammenfassung:*" }
                                                  #
                                                  #return [String[]] $a;
                                                #}catch{ ScriptResetRc; OutProgress "Ignoring Error: $($_.Exception)";
                                                }finally{
                                                  Set-Location $cd;
                                                } }
function TfsResolveMergeConflict              ( [String] $wsdir, [String] $tfsPath, [Boolean] $keepTargetAndNotTakeSource ){
                                                [String] $tfExe = (TfsExe);
                                                [String] $resolveMode = switch( $keepTargetAndNotTakeSource ){ $true{"TakeTheirs"} $false{"AcceptYours"} };
                                                OutProgress "CD `"$wsdir`"; `"$tfExe`" vc resolve /noprompt /recursive /auto:$resolveMode `"$tfsPath`" ";
                                                [String] $cd = (Get-Location);
                                                Set-Location $wsdir;
                                                try{
                                                  [String[]] $a = (& "$tfExe" vc resolve /noprompt /recursive /auto:$resolveMode "$tfsPath" );
                                                #}catch{ ScriptResetRc; OutProgress "Ignoring Error: $($_.Exception)";
                                                }finally{
                                                  Set-Location $cd;
                                                } }
function TfsCheckinDirWhenNoConflict          ( [String] $wsdir, [String] $tfsPath, [String] $comment, [Boolean] $handleErrorsAsWarnings ){
                                                # Return true if checkin was successful.
                                                [String] $tfExe = (TfsExe);
                                                OutProgress "CD `"$wsdir`"; `"$tfExe`" vc checkin /noprompt /recursive /noautoresolve /comment:`"$comment`" `"$tfsPath`" ";
                                                [String] $cd = (Get-Location);
                                                Set-Location $wsdir;
                                                try{
                                                  # Note: sometimes it seem to write this to stderror:
                                                  #  "Es sind keine ausstehenden Änderungen vorhanden, die mit den angegebenen Elementen übereinstimmen.\nEs wurden keine Dateien eingecheckt."
                                                  [String[]] $a = (& "$tfExe" vc checkin /noprompt /recursive /noautoresolve /comment:"$comment" $tfsPath);
                                                  ScriptResetRc;
                                                  return $true;
                                                }catch{
                                                  if( -not $handleErrorsAsWarnings ){ throw; }
                                                  OutWarning "Warning: Ignoring checkin problem which requires manually resolving: $($_.Exception.Message)";
                                                  return $false;
                                                }finally{
                                                  Set-Location $cd;
                                                } }
function TfsUndoAllLocksInDir                 ( [String] $dir ){ # Undo all locks below dir to cleanup a previous failed operation as from merging.
                                                [String] $tfExe = (TfsExe);
                                                OutProgress "`"$tfExe`" vc undo /noprompt /recursive `"$dir`"";
                                                . $tfExe vc undo /noprompt /recursive $dir; }
function SqlGetCmdExe                         (){ # old style. It is recommended to use: SqlPerformFile
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
function SqlRunScriptFile                     ( [String] $sqlserver, [String] $sqlfile, [String] $outFile, [Boolean] $continueOnErr ){ # old style. It is recommended to use: SqlPerformFile
                                                FileAssertExists $sqlfile;
                                                OutProgress "SqlRunScriptFile sqlserver=$sqlserver sqlfile=`"$sqlfile`" out=`"$outfile`" contOnErr=$continueOnErr";
                                                [String] $sqlcmd = SqlGetCmdExe;
                                                FsEntryCreateParentDir $outfile;
                                                & $sqlcmd "-b" "-S" $sqlserver "-i" $sqlfile "-o" $outfile;
                                                if( -not $? ){ if( ! $continueOnErr ){ AssertRcIsOk; }
                                                else{ OutWarning "Ignore: SqlRunScriptFile `"$sqlfile`" on `"$sqlserver`" failed with rc=$(ScriptGetAndClearLastRc), more see outfile, will continue"; } }
                                                FileAssertExists $outfile; }
function SqlPerformFile                       ( [String] $connectionString, [String] $sqlFile, [String] $logFileToAppend = "", [Int32] $queryTimeoutInSec = 0, [Boolean] $showPrint = $true, [Boolean] $showRows = $true){
                                                # Print are given out in yellow by internal verbose option; rows are currently given out only in a simple csv style without headers.
                                                # ConnectString example: "Server=myInstance;Database=TempDB;Integrated Security=True;"  queryTimeoutInSec: 1..65535,0=endless;  
                                                ScriptImportModuleIfNotDone "sqlserver";
                                                [String] $currentUser = "$env:USERDOMAIN\$env:USERNAME";
                                                [String] $traceInfo = "SqlPerformCmd(connectionString=`"$connectionString`",sqlFile=`"$sqlFile`",queryTimeoutInSec=$queryTimeoutInSec,showPrint=$showPrint,showRows=$showRows,currentUser=$currentUser)";
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
                                                # ConnectString example: "Server=myInstance;Database=TempDB;Integrated Security=True;"  queryTimeoutInSec: 1..65535, 0=endless;  
                                                # cmd: semicolon separated commands, do not use GO, escape doublequotation marks, use bracketed identifiers [MyTable] instead of doublequotes.
                                                ScriptImportModuleIfNotDone "sqlserver";
                                                OutProgress "SqlPerformCmd connectionString=`"$connectionString`" cmd=`"$cmd`" showPrint=$showPrint queryTimeoutInSec=$queryTimeoutInSec";
                                                # Note: -EncryptConnection produced: Invoke-Sqlcmd : Es konnte eine Verbindung mit dem Server hergestellt werden, doch während des Anmeldevorgangs trat ein Fehler auf. 
                                                #   (provider: SSL Provider, error: 0 - Die Zertifikatkette wurde von einer nicht vertrauenswürdigen Zertifizierungsstelle ausgestellt.)
                                                # For future use: -ConnectionTimeout inSec 0..65534,0=endless
                                                # For future use: -InputFile pathAndFileWithoutSpaces
                                                # For future use: -MaxBinaryLength  default is 1024, max nr of bytes returned for columns of type binary or varbinary.
                                                # For future use: -MaxCharLength    default is 4000, max nr of chars retunred for columns of type char, nchar, varchar, nvarchar.
                                                # For future use: -OutputAs         DataRows (=default), DataSet, DataTables.
                                                # For future use: -SuppressProviderContextWarning suppress warning from establish db context.
                                                Invoke-Sqlcmd -ConnectionString $connectionString -AbortOnError -Verbose:$showPrint -OutputSqlErrors $true -QueryTimeout $queryTimeoutInSec -Query $cmd;
                                                # Note: This did not work (restore hangs):
                                                #   [Object[]] $relocateFileList = @();
                                                #   [Object] $smoRestore = New-Object Microsoft.SqlServer.Management.Smo.Restore; $smoRestore.Devices.AddDevice($bakFile , [Microsoft.SqlServer.Management.Smo.DeviceType]::File);
                                                #   $smoRestore.ReadFileList($server) | ForEach-Object{ [String] $f = Join-Path $dataDir (Split-Path $_.PhysicalName -Leaf); 
                                                #     $relocateFileList += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($_.LogicalName, $f); }
                                                #   Restore-SqlDatabase -Partial -ReplaceDatabase -NoRecovery -ServerInstance $server -Database $dbName -BackupFile $bakFile -RelocateFile $relocateFileList;
                                              }
function SqlGenerateFullDbSchemaFiles         ( [String] $logicalEnv, [String] $dbInstanceServerName, [String] $dbName, [String] $targetRootDir, 
                                                  [Boolean] $errorAsWarning = $false, [Boolean] $inclIfNotExists = $false, [Boolean] $inclDropStmts = $false, [Boolean] $inclDataAsInsertStmts = $false ){
                                                # Create all creation files for a specified sql server database with current user to a specified target directory which must not exists. 
                                                # This includes tables (including unique indexes), indexes (non-unique), views, stored procedures, functions, roles, schemas, db-triggers and table-Triggers.
                                                # If a stored procedure, a function or a trigger is encrypted then a single line is put to its sql file indicating encrypted code cannot be dumped.
                                                # It creates file "DbInfo.dbname.out" with some db infos. In case of an error it creates file "DbInfo.dbname.err".
                                                # ex: SqlGenerateFullDbSchemaFiles "MyLogicEnvironment" "MySqlInstance" "MyDbName" "$env:TEMP\DumpFullDbSchemas"
                                                [String] $currentUser = "$env:USERDOMAIN\$env:USERNAME";
                                                [String] $traceInfo = "SqlGenerateFullDbSchemaFiles(logicalEnv=$logicalEnv,dbInstanceServerName=$dbInstanceServerName,dbname=$dbName,targetRootDir=$targetRootDir,currentUser=$currentUser)";
                                                OutInfo $traceInfo;
                                                [String] $tarDir = "$targetRootDir\$(Get-Date -Format yyyy-MM-dd)\$logicalEnv\$dbName";
                                                if( DirExists $tarDir ){
                                                  [String] $msg = "Nothing done because target dir already exists: `"$tarDir`"";
                                                  if( $errorAsWarning ){ OutWarning $msg; return; }
                                                  throw [Exception] $msg;
                                                }
                                                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null;
                                                [System.Reflection.Assembly]::LoadWithPartialName("System.Data") | Out-Null;
                                                [Microsoft.SqlServer.Management.Smo.Server] $srv = new-object "Microsoft.SqlServer.Management.SMO.Server" $dbInstanceServerName;
                                                # ex: $srv.Name = "MySqlInstance"; $srv.State = "Existing"; $srv.ConnectionContext = "Data Source=MySqlInstance;Integrated Security=True;MultipleActiveResultSets=False;Encrypt=False;TrustServerCertificate=False;Application Name=`"SQL Management`""
                                                try{
                                                   # can throw: MethodInvocationException: Exception calling "SetDefaultInitFields" with "2" argument(s): "Failed to connect to server MySqlInstance."
                                                  try{ $srv.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject");
                                                  }catch{ throw [Exception] $_.Exception.Message; }
                                                  [Microsoft.SqlServer.Management.Smo.Scripter] $scr = New-Object "Microsoft.SqlServer.Management.Smo.Scripter";
                                                  $scr.Server = $srv;
                                                  [Microsoft.SqlServer.Management.SMO.ScriptingOptions] $options = New-Object "Microsoft.SqlServer.Management.SMO.ScriptingOptions";
                                                  # more see: https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.scriptingoptions?view=sql-smo-140.17283.0
                                                  $options.AllowSystemObjects = $false;
                                                  $options.IncludeDatabaseContext = $true;
                                                  $options.IncludeIfNotExists = $inclIfNotExists;
                                                  $options.Indexes = $false;
                                                  $options.ClusteredIndexes = $false;
                                                  $options.NonClusteredIndexes = $false;
                                                  $options.IncludeHeaders = $false;
                                                  $options.Default = $true;
                                                  $options.DriAll = $true; # includes all Declarative Referential Integrity objects such as constraints.
                                                  $options.NoCollation = $true;
                                                  $options.ToFileOnly = $true;
                                                  $options.AppendToFile = $false; # means overwriting
                                                  $options.AnsiFile = $true;
                                                  $options.ScriptDrops = $inclDropStmts;
                                                  $options.OptimizerData = $false; # include: UPDATE STATISTICS [dbo].[MyTable] WITH ROWCOUNT = nrofrows, PAGECOUNT = nrofpages
                                                  $options.ScriptData = $inclDataAsInsertStmts;
                                                  $scr.Options = $options; # Set options for SMO.Scripter
                                                  # not yet used: [Microsoft.SqlServer.Management.Smo.DependencyType] $deptype = New-Object "Microsoft.SqlServer.Management.Smo.DependencyType";
                                                  [Microsoft.SqlServer.Management.Smo.Database] $db = $srv.Databases[$dbName];
                                                  if( $db -eq $null ){ throw [Exception] "Not found database with current user."; }
                                                  [String] $fileDbInfo = "$tarDir\DbInfo.$dbName.out";
                                                  #try{
                                                  #  [String] $dummy = $db.Parent; # check for read access
                                                  #}catch{
                                                  #  # ex: ExtendedTypeSystemException: The following exception occurred while trying to enumerate the collection: "An exception occurred while executing a Transact-SQL statement or batch.".
                                                  #  throw [Exception] "Accessing database $dbName failed because $_";
                                                  #}
                                                  [Array] $tables              = @()+($db.Tables               | Where-Object {$_ -ne $null} | Where-Object {$_.IsSystemObject -eq $false}); # including unique indexes
                                                  [Array] $views               = @()+($db.Views                | Where-Object {$_ -ne $null} | Where-Object {$_.IsSystemObject -eq $false});
                                                  [Array] $storedProcedures    = @()+($db.StoredProcedures     | Where-Object {$_ -ne $null} | Where-Object {$_.IsSystemObject -eq $false});
                                                  [Array] $userDefFunctions    = @()+($db.UserDefinedFunctions | Where-Object {$_ -ne $null} | Where-Object {$_.IsSystemObject -eq $false});
                                                  [Array] $dbSchemas           = @()+($db.Schemas              | Where-Object {$_ -ne $null} | Where-Object {$_.IsSystemObject -eq $false});
                                                  [Array] $dbTriggers          = @()+($db.Triggers             | Where-Object {$_ -ne $null} | Where-Object {$_.IsSystemObject -eq $false});
                                                  [Array] $dbRoles             = @()+($db.Roles                | Where-Object {$_ -ne $null});
                                                  [Array] $tableTriggers       = @()+($tables                  | Where-Object {$_ -ne $null} | ForEach-Object {$_.triggers } | Where-Object {$_ -ne $null});
                                                  [Array] $indexesNonUnique    = @()+($tables                  | Where-Object {$_ -ne $null} | ForEach-Object {$_.indexes  } | Where-Object {$_ -ne $null} | Where-Object {-not $_.IsUnique});
                                                  [Int64] $spaceUsedDataInMB   = [Math]::Ceiling(($db.DataSpaceUsage + $db.IndexSpaceUsage) / 1000000);
                                                  [Int64] $spaceUsedIndexInMB  = [Math]::Ceiling( $db.IndexSpaceUsage                       / 1000000);
                                                  [Int64] $spaceAvailableInMB  = [Math]::Ceiling( $db.SpaceAvailable                        / 1000000);
                                                  [String[]] $fileDbInfoContent = @(
                                                      "DbInfo: $dbName (current-user=$env:USERDOMAIN\$env:USERNAME)"
                                                      ,"  Parent               : $($db.Parent                 )" # ex: [MySqlInstance.MyDomain.ch]
                                                      ,"  Collation            : $($db.Collation              )" # ex: Latin1_General_CI_AS
                                                      ,"  CompatibilityLevel   : $($db.CompatibilityLevel     )" # ex: Version100
                                                      ,"  SpaceUsedDataInMB    : $spaceUsedDataInMB            " # ex: 40
                                                      ,"  SpaceUsedIndexInMB   : $spaceUsedIndexInMB           " # ex: 12
                                                      ,"  SpaceAvailableInMB   : $spaceAvailableInMB           " # ex: 11
                                                      ,"  DefaultSchema        : $($db.DefaultSchema          )" # ex: dbo
                                                      ,"  NrOfTables           : $($tables.Count              )" # ex: 2
                                                      ,"  NrOfViews            : $($views.Count               )" # ex: 2
                                                      ,"  NrOfStoredProcedures : $($storedProcedures.Count    )" # ex: 2
                                                      ,"  NrOfUserDefinedFuncs : $($userDefFunctions.Count    )" # ex: 2
                                                      ,"  NrOfDbTriggers       : $($dbTriggers.Count          )" # ex: 2
                                                      ,"  NrOfTableTriggers    : $($tableTriggers.Count       )" # ex: 2
                                                      ,"  NrOfIndexesNonUnique : $($indexesNonUnique.Count    )" # ex: 20
                                                  );
                                                  FileWriteFromLines $fileDbInfo $fileDbInfoContent $false; # throws if it already exists
                                                  OutProgress ("DbInfo: $dbName Collation=$($db.Collation) CompatibilityLevel=$($db.CompatibilityLevel) " + 
                                                    "UsedDataInMB=$spaceUsedDataInMB; " + "UsedIndexInMB=$spaceUsedIndexInMB; " +
                                                    "NrOfTabs=$($tables.Count); Views=$($views.Count); StProcs=$($storedProcedures.Count); " +
                                                    "Funcs=$($userDefFunctions.Count); DbTriggers=$($dbTriggers.Count); "+
                                                    "TabTriggers=$($tableTriggers.Count); "+"IndexesNonUnique=$($indexesNonUnique.Count); ");
                                                  OutProgressText "  Process: ";
                                                  OutProgressText "Schemas ";
                                                  Foreach ($i in $dbSchemas){
                                                    [String] $name = FsEntryMakeValidFileName $i.Name;
                                                    $options.FileName = "$tarDir\Schema.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgressText "Roles ";
                                                  Foreach ($i in $dbRoles){
                                                    [String] $name = FsEntryMakeValidFileName $i.Name;
                                                    $options.FileName = "$tarDir\Role.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgressText "DbTriggers ";
                                                  foreach ($i in $dbTriggers){
                                                    [String] $name = FsEntryMakeValidFileName $i.Name;
                                                    $options.FileName = "$tarDir\DbTrigger.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    if( $i.IsEncrypted ){
                                                      FileAppendLine $options.FileName "Note: DbTrigger $name is encrypted, so cannot be dumped.";
                                                    }else{
                                                      $scr.Script($i);
                                                    }
                                                  }
                                                  OutProgressText "Tables "; # inclusive unique indexes
                                                  Foreach ($i in $tables){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir\Table.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $smoObjects = New-Object Microsoft.SqlServer.Management.Smo.UrnCollection;
                                                    $smoObjects.Add($i.Urn);
                                                    $i.indexes | Where-Object {$_ -ne $null -and $_.IsUnique} | ForEach-Object { $smoObjects.Add($_.Urn); };
                                                    $scr.Script($smoObjects);
                                                  }
                                                  OutProgressText "Views ";
                                                  Foreach ($i in $views){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir\View.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgressText "StoredProcedures";
                                                  Foreach ($i in $storedProcedures){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir\StoredProcedure.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    if( $i.IsEncrypted ){
                                                      FileAppendLine $options.FileName "Note: StoredProcedure $name is encrypted, so cannot be dumped.";
                                                    }else{
                                                      $scr.Script($i);
                                                    }
                                                  }
                                                  OutProgressText "UserDefinedFunctions ";
                                                  Foreach ($i in $userDefFunctions){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir\UserDefinedFunction.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    if( $i.IsEncrypted ){
                                                      FileAppendLine $options.FileName "Note: UserDefinedFunction $name is encrypted, so cannot be dumped.";
                                                    }else{
                                                      $scr.Script($i);
                                                    }
                                                  }
                                                  OutProgressText "TableTriggers ";
                                                  Foreach ($i in $tableTriggers){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Parent.Schema).$($i.Parent.Name).$($i.Name)";
                                                    $options.FileName = "$tarDir\TableTrigger.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    if( $i.IsEncrypted ){
                                                      FileAppendLine $options.FileName "Note: TableTrigger $name is encrypted, so cannot be dumped.";
                                                    }else{
                                                      $scr.Script($i);
                                                    }
                                                  }
                                                  OutProgressText "IndexesNonUnique ";
                                                  Foreach ($i in $indexesNonUnique){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Parent.Schema).$($i.Parent.Name).$($i.Name)";
                                                    $options.FileName = "$tarDir\IndexesNonUnique.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  # for future use: remove the lines when in sequence: "SET ANSI_NULLS ON","GO","SET QUOTED_IDENTIFIER ON","GO".
                                                  OutProgress "";
                                                  OutSuccess "ok, done. Written files below: `"$tarDir`"";
                                                }catch{
                                                  # ex: "The given path's format is not supported."
                                                  # ex: "Illegal characters in path."  (if table name contains double quotes)
                                                  # ex: System.Management.Automation.ExtendedTypeSystemException: The following exception occurred while trying to enumerate the collection: 
                                                  #       "An exception occurred while executing a Transact-SQL statement or batch.". 
                                                  #       ---> Microsoft.SqlServer.Management.Common.ExecutionFailureException: An exception occurred while executing a Transact-SQL statement or batch. 
                                                  #       ---> System.Data.SqlClient.SqlException: The server principal "MyDomain\MyUser" is not able to access the database "MyDatabaseName" under the current security context.
                                                  # ex: System.Management.Automation.MethodInvocationException: Exception calling "Script" with "1" argument(s): 
                                                  #       "The StoredProcedure '[mySchema].[MyTable]' cannot be scripted as its data is not accessible." 
                                                  #       ---> Microsoft.SqlServer.Management.Smo.FailedOperationException: The StoredProcedure '[mySchema].[MyTable]' cannot be scripted as its data is not accessible. 
                                                  #       ---> Microsoft.SqlServer.Management.Smo.PropertyCannotBeRetrievedException: Property TextHeader is not available for StoredProcedure '[mySchema].[MyTable]'. 
                                                  #       This property may not exist for this object, or may not be retrievable due to insufficient access rights. The text is encrypted.
                                                  #       at Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase.GetTextProperty(String requestingProperty, ScriptingPreferences sp, Boolean bThrowIfCreating)
                                                  [String] $msg = $traceInfo + " failed because $($_.Exception)";
                                                  FileWriteFromLines "$tarDir\DbInfo.$dbName.err" $msg;
                                                  if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                  OutWarning "Ignore failing of $msg `nCreated `"$tarDir\DbInfo.$dbName.err`".";
                                                }
                                              }
function JuniperNcEstablishVpnConn            ( [String] $secureCredentialFile, [String] $url, [String] $realm ){
                                                [String] $serviceName = "DsNcService";
                                                [String] $vpnProg = "${env:ProgramFiles(x86)}\Juniper Networks\Network Connect 8.0\nclauncher.exe";
                                                # Using: nclauncher [-url Url] [-u username] [-p password] [-r realm] [-help] [-stop] [-signout] [-version] [-d DSID] [-cert client certificate] [-t Time(Seconds min:45, max:600)] [-ir true | false]
                                                # Alternatively we could take: "HKLM:\SOFTWARE\Wow6432Node\Juniper Networks\Network Connect 8.0\InstallPath":  C:\Program Files (x86)\Juniper Networks\Network Connect 8.0
                                                function JuniperNetworkConnectStop(){
                                                  OutProgress "Call: `"$vpnProg`" -signout";
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
                                                    OutVerbose "Read last saved encrypted username and password: `"$secureCredentialFile`"";
                                                    [System.Management.Automation.PSCredential] $cred = CredentialGetAndStoreIfNotExists $secureCredentialFile;
                                                    [String] $us = CredentialGetUsername $cred;
                                                    [String] $pw = CredentialGetPassword $cred;
                                                    OutDebug "UserName=`"$us`"  Password=`"$pw`"";
                                                    OutProgress "Call: $vpnProg -url $url -u $us -r $realm -t 75 -p *** ";
                                                    [String] $out = & $vpnProg "-url" $url "-u" $us "-r" $realm "-t" "75" "-p" $pw; ScriptResetRc;
                                                    ProcessSleepSec 2; # Required to make ready to use rdp.
                                                    if( $out -eq "The specified credentials do not authenticate." -or $out -eq "Die Authentifizierung ist mit den angegebenen Anmeldeinformationen nicht m÷glich." ){
                                                      # On some machines we got german messages.
                                                      OutProgress "Handling authentication failure by removing credential file and retry";
                                                      CredentialRemoveFile $secureCredentialFile; }
                                                    elseif( $out -eq "Network Connect has started." -or $out -eq "Network Connect is already running" -or $out -eq "Network Connect wurde gestartet." ){ return; }
                                                    else{ OutWarning "Ignoring unexpected program output: `"$out`", will continue but maybe it does not work"; ProcessSleepSec 5; return; }
                                                  }
                                                  throw [Exception] "Authentication failed with specified credentials, credential file was removed, please retry";
                                                }
                                                OutProgress "Using vpn program `"$vpnProg`"";
                                                OutProgress "Arguments: credentialFile=`"$secureCredentialFile`", url=$url , realm=`"$realm`"";
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
                                                # Get default associations for file extensions to programs for windows 10, this can be used later for imports.
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
                                                $result += @( "", "", "List of DefaultAppAssociations:"                          , (FileReadContentAsString $f "Default") );
                                                $result += @( "", "", "List of windows feature enabling states:"                 , (& "Dism.exe" "/online" "/Get-Features") );
                                                # For future use:
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
function InfoGetInstalledDotNetVersion        ( [Boolean] $alsoOutInstalledClrAndRunningProc = $false ){ # Requires clrver.exe in path, for example "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7.1 Tools\x64\clrver.exe"
                                                if( $alsoOutInstalledClrAndRunningProc ){
                                                  [String[]] $a = @();
                                                  $a += "List Installed DotNet CLRs (clrver.exe):"; 
                                                  $a += . "clrver.exe"        | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("Copyright (c) Microsoft Corporation.  All rights reserved.") -and 
                                                    -not $_.StartsWith("Microsoft (R) .NET CLR Version Tool") -and -not $_.StartsWith("Versions installed on the machine:") } | ForEach-Object { "  Installed CLRs: $_" };
                                                  $a += "List running DotNet Processes (clrver.exe -all):";
                                                  $a += . "clrver.exe" "-all" | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("Copyright (c) Microsoft Corporation.  All rights reserved.") -and 
                                                    -not $_.StartsWith("Microsoft (R) .NET CLR Version Tool") -and -not $_.StartsWith("Versions installed on the machine:") } | ForEach-Object { "  Running Processes and its CLR: $_" };
                                                  $a | Foreach-Object { OutProgress $_; };
                                                }
                                                [Int32] $relKey = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release;
                                                # see: https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
                                                [String]                      $relStr = "No 4.5 or later version detected.";
                                                if    ( $relKey -ge 461814 ){ $relStr = "4.7.2 or later ($relKey)"; } # on Win10CreatorsUpdate
                                                elseif( $relKey -ge 461808 ){ $relStr = "4.7.2 or later"; }
                                                elseif( $relKey -ge 461308 ){ $relStr = "4.7.1"         ; }
                                                elseif( $relKey -ge 460798 ){ $relStr = "4.7"           ; }
                                                elseif( $relKey -ge 394802 ){ $relStr = "4.6.2"         ; }
                                                elseif( $relKey -ge 394254 ){ $relStr = "4.6.1"         ; }
                                                elseif( $relKey -ge 393295 ){ $relStr = "4.6"           ; }
                                                elseif( $relKey -ge 379893 ){ $relStr = "4.5.2"         ; }
                                                elseif( $relKey -ge 378675 ){ $relStr = "4.5.1"         ; }
                                                elseif( $relKey -ge 378389 ){ $relStr = "4.5"           ; }
                                                return $relStr; }
function ToolTailFile                         ( [String] $file ){ OutProgress "Show tail of file until ctrl-c is entered"; Get-Content -Wait $file; }
function ToolRdpConnect                       ( [String] $rdpfile, [String] $mstscOptions = "" ){
                                                # Some mstsc options: /edit /admin  (use /edit temporary to set password in .rdp file)
                                                OutProgress "RdpConnect: `"$rdpfile`" $mstscOptions";
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
                                                # Options: -ms=4g : use limit of solid block 4GB; -mmt=4 : try use nr of threads; -w : use windows temp; -r : recursively; -r- : not-recursively;
                                                [Array] $arguments = "-t7z", "-mx=9", "-ms=4g", "-mmt=4", "-w", $recursiveOption, "a", "$tar7zipFile", $src;
                                                OutProgress "$Prog7ZipExe $arguments";
                                                [String] $out = & $Prog7ZipExe $arguments; AssertRcIsOk $out; }
function ToolUnzip                            ( [String] $srcZipFile, [String] $tarDir ){ # tarDir is created if it not exists, no overwriting, requires DotNetFX4.5.
                                                Add-Type -AssemblyName "System.IO.Compression.FileSystem";
                                                $srcZipFile = FsEntryGetAbsolutePath $srcZipFile; $tarDir = FsEntryGetAbsolutePath $tarDir;
                                                OutProgress "Unzip `"$srcZipFile`" to `"$tarDir`"";
                                                # alternative: in PS5 there is: Expand-Archive zipfile -DestinationPath tardir
                                                [System.IO.Compression.ZipFile]::ExtractToDirectory($srcZipFile, $tarDir); }
function ToolCreateLnkIfNotExists             ( [Boolean] $forceRecreate, [String] $workDir, [String] $lnkFile, [String] $srcFile, [String[]] $arguments = @(), [Boolean] $runElevated = $false, [Boolean] $ignoreIfSrcFileNotExists = $false ){
                                                # ex: ToolCreateLnkIfNotExists $false "" "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\LinkToNotepad.lnk" "C:\Windows\notepad.exe";
                                                # ex: ToolCreateLnkIfNotExists $false "" "$env:USERPROFILE\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\LinkToNotepad.lnk" "C:\Windows\notepad.exe";
                                                # If $forceRecreate is false and target lnkfile already exists then it does nothing.
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
                                                    OutProgress "CreateShortcut `"$lnkFile`"";
                                                    OutVerbose "WScript.Shell.CreateShortcut `"$workDir`" `"$lnkFile`" `"$srcFile`" `"$argLine`" `"$descr`"";
                                                    try{
                                                      FsEntryCreateParentDir $lnkFile;
                                                      [Object] $wshShell = New-Object -comObject WScript.Shell;
                                                      [Object] $s = $wshShell.CreateShortcut($lnkFile); # do not use FsEntryEsc otherwise [ will be created as `[
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
                                                      throw [Exception] "$(ScriptGetCurrentFunc)(`"$workDir`",`"$lnkFile`",`"$srcFile`",`"$argLine`",`"$descr`") failed because $($_.Exception.Message)";
                                                    }
                                                  if( $runElevated ){ 
                                                    [Byte[]] $bytes = [IO.File]::ReadAllBytes($lnkFile); $bytes[0x15] = $bytes[0x15] -bor 0x20; [IO.File]::WriteAllBytes($lnkFile,$bytes);  # set bit 6 of byte nr 21
                                                  } } }
function ToolCreateMenuLinksByMenuItemRefFile ( [String] $targetMenuRootDir, [String] $sourceDir, [String] $srcFileExtMenuLink = ".menulink.txt", 
                                                  [String] $srcFileExtMenuLinkOpt = ".menulinkoptional.txt" ){
                                                # Create menu entries based on files below a dir.
                                                # ex: ToolCreateMenuLinksByMenuItemRefFile "$env:APPDATA\Microsoft\Windows\Start Menu\MyPortableProg" "D:\MyPortableProgs" ".menulink.txt";
                                                # Find all files below sourceDir with the extension (ex: ".menulink.txt"), 
                                                # which we call them menu-item-reference-file.
                                                # For each of these files it will create a menu item below the target menu root dir 
                                                # (ex: "$env:APPDATA\Microsoft\Windows\Start Menu\MyPortableProg").
                                                # The name of the target menu item (ex: "Manufactor ProgramName V1") will be taken 
                                                # from the name of the menu-item-reference-file (...\Manufactor ProgramName V1.menulink.txt) 
                                                # without the extension (ex: ".menulink.txt") and the sub menu folder will be taken 
                                                # from the relative location of the menu-item-reference-file below the sourceDir.
                                                # The command for the target menu will be taken from the first line 
                                                # (ex: "D:\MyPortableProgs\Manufactor ProgramName\AnyProgram.exe")
                                                # of the content of the menu-item-reference-file. If target lnkfile already exists it does nothing.
                                                [String] $m = FsEntryGetAbsolutePath $targetMenuRootDir; # ex: "C:\Users\u1\AppData\Roaming\Microsoft\Windows\Start Menu\MyPortableProg"
                                                [String] $sdir = FsEntryGetAbsolutePath $sourceDir; # ex: "D:\MyPortableProgs"
                                                OutProgress "Create menu links to `"$m`" from files below `"$sdir`" with extension `"$srcFileExtMenuLink`" or `"$srcFileExtMenuLinkOpt`" files";
                                                Assert ($srcFileExtMenuLink    -ne "" -or (-not $srcFileExtMenuLink.EndsWith("\")   )) "srcMenuLinkFileExt=`"$srcFileExtMenuLink`" is empty or has trailing backslash";
                                                Assert ($srcFileExtMenuLinkOpt -ne "" -or (-not $srcFileExtMenuLinkOpt.EndsWith("\"))) "srcMenuLinkOptFileExt=`"$srcFileExtMenuLinkOpt`" is empty or has trailing backslash";
                                                if( -not (DirExists $sdir) ){ OutWarning "Ignoring dir not exists: `"$sdir`""; }
                                                [String[]] $menuLinkFiles =  (FsEntryListAsStringArray "$sdir\*$srcFileExtMenuLink"    $true $false);
                                                           $menuLinkFiles += (FsEntryListAsStringArray "$sdir\*$srcFileExtMenuLinkOpt" $true $false);
                                                           $menuLinkFiles = $menuLinkFiles | Sort-Object;
                                                foreach( $f in $menuLinkFiles ){ # ex: "...\MyProg .menulinkoptional.txt"
                                                  [String] $d = FsEntryGetParentDir $f; # ex: "D:\MyPortableProgs\Appl\Graphic"  
                                                  [String] $relBelowSrcDir = FsEntryMakeRelative $d $sdir; # ex: "Appl\Graphic" or "."
                                                  [String] $workDir = "";
                                                  # ex: "C:\Users\u1\AppData\Roaming\Microsoft\Windows\Start Menu\MyPortableProg\Appl\Graphic\Manufactor ProgramName V1 en 2016.lnk"
                                                  [String] $fn = FsEntryGetFileName $f; $fn = StringRemoveRight $fn $srcFileExtMenuLink; 
                                                  $fn = StringRemoveRight $fn $srcFileExtMenuLinkOpt; $fn = $fn.TrimEnd();
                                                  [String] $lnkFile = "$($m)\$($relBelowSrcDir)\$fn.lnk";
                                                  [String] $encodingIfNoBom = "Default";
                                                  [String] $cmdLine = FileReadContentAsLines $f $encodingIfNoBom | Select-Object -First 1;
                                                  [String] $addTraceInfo = "";
                                                  [Boolean] $forceRecreate = FileNotExistsOrIsOlder $lnkFile $f;
                                                  [Boolean] $ignoreIfSrcFileNotExists = $f.EndsWith($srcFileExtMenuLinkOpt);
                                                  try{
                                                    [String[]] $ar = StringCommandLineToArray $cmdLine; # can throw: Expected blank or tab char or end of string but got char ...
                                                    if( $ar.Length -eq 0 ){ throw [Exception] "Missing a command line at first line in file=`"$f`" cmdline=`"$cmdLine`""; }
                                                    if( ($ar.Length-1) -gt 999 ){ throw [Exception] "Command line has more than the allowed 999 arguments at first line infile=`"$f`" nrOfArgs=$($ar.Length) cmdline=`"$cmdLine`""; }
                                                    [String] $srcFile = FsEntryMakeAbsolutePath $d $ar[0]; # ex: "D:\MyPortableProgs\Manufactor ProgramName\AnyProgram.exe"
                                                    [String[]] $arguments = $ar | Select-Object -Skip 1;
                                                    $addTraceInfo = "and calling (ToolCreateLnkIfNotExists $forceRecreate `"$workDir`" `"$lnkFile`" `"$srcFile`" `"$arguments`" $false $ignoreIfSrcFileNotExists) ";
                                                    ToolCreateLnkIfNotExists $forceRecreate $workDir $lnkFile $srcFile $arguments $false $ignoreIfSrcFileNotExists;
                                                  }catch{
                                                    [String] $msg = "$($_.Exception.Message).$(switch(-not $cmdLine.StartsWith('`"')){($true){' Maybe first file of content in menulink file should be quoted.'}default{' Maybe if first file not exists you may use file extension `".menulinkoptional`" instead of `".menulink`".'}})";
                                                    OutWarning "Create menulink by reading file `"$f`", taking first line as cmdLine ($cmdLine) $addTraceInfo failed because $msg";
                                                  } } }
function ToolSignDotNetAssembly               ( [String] $keySnk, [String] $srcDllOrExe, [String] $tarDllOrExe, [Boolean] $overwrite = $false ){
                                                # Note: Generate a key: sn.exe -k mykey.snk
                                                OutInfo "Sign dot-net assembly: keySnk=`"$keySnk`" srcDllOrExe=`"$srcDllOrExe`" tarDllOrExe=`"$tarDllOrExe`" overwrite=$overwrite ";
                                                [Boolean] $isDllNotExe = $srcDllOrExe.ToLower().EndsWith(".dll");
                                                if( -not $isDllNotExe -and -not $srcDllOrExe.ToLower().EndsWith(".exe") ){ 
                                                  throw [Exception] "Expected ends with .dll or .exe, srcDllOrExe=`"$srcDllOrExe`""; }
                                                if( -not $overwrite -and (FileExists $tarDllOrExe) ){ OutProgress "Ok, target already exists: $tarDllOrExe"; return; }
                                                FsEntryCreateParentDir  $tarDllOrExe;
                                                [String] $n = FsEntryGetFileName $tarDllOrExe;
                                                [String] $d = DirCreateTemp "SignAssembly_";
                                                OutProgress "ildasm.exe -NOBAR -all `"$srcDllOrExe`" `"-out=$d\$n.il`"";
                                                & "ildasm.exe" -TEXT -all $srcDllOrExe "-out=$d\$n.il"; AssertRcIsOk;
                                                OutProgress "ilasm.exe -QUIET -DLL -PDB `"-KEY=$keySnk`" `"$d\$n.il`" `"-RESOURCE=$d\$n.res`" `"-OUTPUT=$tarDllOrExe`"";
                                                & "ilasm.exe" -QUIET -DLL -PDB "-KEY=$keySnk" "$d\$n.il" "-RESOURCE=$d\$n.res" "-OUTPUT=$tarDllOrExe"; AssertRcIsOk;
                                                DirDelete $d;
                                                # Disabled because if we would take the pdb of unsigned assembly then ilmerge failes because pdb is outdated.
                                                #   [String] $srcPdb = (StringRemoveRightNr $srcDllOrExe 4) + ".pdb";
                                                #   [String] $tarPdb = (StringRemoveRightNr $tarDllOrExe 4) + ".pdb";
                                                #   if( FileExists $srcPdb ){ FileCopy $srcPdb $tarPdb $true; }
                                                [String] $srcXml = (StringRemoveRightNr $srcDllOrExe 4) + ".xml";
                                                [String] $tarXml = (StringRemoveRightNr $tarDllOrExe 4) + ".xml";
                                                if( FileExists $srcXml ){ FileCopy $srcXml $tarXml $true; }
                                                }
function ToolGithubApiListOrgRepos            ( [String] $org, [System.Management.Automation.PSCredential] $cred ){
                                                # List all repos which an org has on github, if user is specified 
                                                # then not only public but also private repos are listed. Ordered by archived, Url.
                                                [String] $us = CredentialGetUsername $cred;
                                                [String] $pw = CredentialGetPassword $cred;
                                                OutInfo "List all github repos from $org with user=$us.";
                                                [Array] $result = @();
                                                for( [Int32] $i = 1; $i -lt 100; $i++ ){
                                                  # REST API doc: https://developer.github.com/v3/repos/
                                                  # maximum 100 items per page
                                                  # ex: https://api.github.com/orgs/arduino/repos?type=all&sort=id&per_page=100&page=2&affiliation=owner,collaborator,organization_member
                                                  [String] $url = "https://api.github.com/orgs/$org/repos?per_page=100&page=$i";
                                                  [Object] $json = NetDownloadToString $url $us $pw | ConvertFrom-Json;
                                                  [Array] $a = $json | Select-Object @{N='Url';E={$_.html_url}}, archived, private, fork, forks, language, 
                                                    @{N='CreatedAt';E={$_.created_at.SubString(0,10)}}, @{N='UpdatedAt';E={$_.updated_at.SubString(0,10)}}, 
                                                    @{N='PermAdm';E={$_.permissions.admin}}, @{N='PermPush';E={$_.permissions.push}}, @{N='PermPull';E={$_.permissions.pull}},
                                                    default_branch, @{N='LicName';E={$_.license.name}},
                                                    @{N='Description';E={$_.description.SubString(0,200)}};
                                                  if( $a -eq $null -or $a.Count -eq 0 ){ break; }
                                                  $result +=$a;
                                                } return $result | Sort-Object archived, Url; }
function ToolGithubApiAssertValidRepoUrl      ( [String] $repoUrl ){ # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
                                                [String] $githubUrl = "https://github.com/";
                                                Assert $repoUrl.StartsWith($githubUrl) "Expected url begins with $githubUrl but got: $repoUrl";
                                                [String[]] $a = StringSplitToArray "/" (StringRemoveLeft (StringRemoveRight $repoUrl "/") $githubUrl $false);
                                                Assert ($a.Count -eq 2 -and $a[0].Length -ge 2 -and $a[1].Length -ge 2) "Expected url contains user/reponame but got: $repoUrl"; }
function ToolGithubApiDownloadLatestReleaseDir( [String] $repoUrl ){
                                                # Creates a unique temp dir, downloads zip, return folder of extracted zip; You shoud remove dir after usage.
                                                # Latest release is the most recent non-prerelease, non-draft release, sorted by its last commit-date.
                                                # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
                                                ToolGithubApiAssertValidRepoUrl $repoUrl;
                                                [String] $apiUrl = "https://api.github.com/repos/" + (StringRemoveLeft (StringRemoveRight $repoUrl "/") "https://github.com/" $false);
                                                # ex: $apiUrl = "https://api.github.com/repos/mniederw/MnCommonPsToolLib"
                                                [String] $url = "$apiUrl/releases/latest";
                                                OutProgress "Download: $url";
                                                [Object] $apiObj = (. "curl.exe" -s $url) | ConvertFrom-Json;
                                                [String] $relName = "$($apiObj.name) [$($apiObj.target_commitish),$($apiObj.created_at.Substring(0,10)),$($apiObj.tag_name)]";
                                                OutProgress "Selected: `"$relName`"";
                                                # ex: $apiObj.zipball_url = "https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball/V4.9"
                                                # ex: $relName = "OpenSource-GPL3 MnCommonPsToolLib V4.9 en 2020-02-13 [master,2020-02-13,V4.9]"
                                                [String] $tarDir = DirCreateTemp "MnCoPsToLib_";
                                                [String] $tarZip = "$tarDir\$relName.zip";
                                                # We can download latest release zip by one of:
                                                # - https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball
                                                # - https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball/V4.9
                                                # - https://github.com/mniederw/MnCommonPsToolLib/archive/V4.9.zip
                                                # - https://codeload.github.com/mniederw/MnCommonPsToolLib/legacy.zip/master
                                                NetDownloadFileByCurl "$apiUrl/zipball" $tarZip;
                                                ToolUnzip $tarZip $tarDir; # Ex: ./mniederw-MnCommonPsToolLib-25dbfb0/*
                                                FileDelete $tarZip;
                                                 # list flat dirs, ex: "C:\Temp\User_u2\MnCoPsToLib_catkmrpnfdp\mniederw-MnCommonPsToolLib-25dbfb0\"
                                                [String[]] $dirs = FsEntryListAsStringArray $tarDir $false $true $false;
                                                if( $dirs.Count -ne 1 ){ throw [Exception] "Expected one dir in `"$tarDir`" instead of: $dirs"; }
                                                [String] $dir0 = $dirs[0];
                                                FsEntryMoveByPatternToDir "$dir0\*" $tarDir;
                                                DirDelete $dir0;
                                                return [String] $tarDir; }
function ToolSetAssocFileExtToCmd             ( [String[]] $fileExtensions, [String] $cmd, [String] $ftype = "", [Boolean] $assertPrgExists = $false ){
                                                # Sets the association of a file extension to a command by overwriting it. 
                                                # FileExtensions: must begin with a dot, must not content blanks or commas, 
                                                #   if it is only a dot then it is used for files without a file ext.
                                                # Cmd: if it is empty then association is deleted. 
                                                #  Can contain variables as %SystemRoot% which will be replaced at runtime.
                                                #   If cmd does not begin with embedded double quotes then it is interpreted as a full path to an executable
                                                #   otherwise it uses the cmd as it is.
                                                # Ftype: Is a group of file extensions. If it not yet exists then a default will be created 
                                                #   in the style {extWithoutDot}file (ex: ps1file).
                                                # AssertPrgExists: You can assert that the program in the command must exist but note that 
                                                #   variables enclosed in % char cannot be expanded because these are not powershell variables.
                                                # ex: ToolSetAssocFileExtToCmd @(".log",".out") "$env:SystemRoot\System32\notepad.exe" "" $true;
                                                # ex: ToolSetAssocFileExtToCmd ".log"           "$env:SystemRoot\System32\notepad.exe";
                                                # ex: ToolSetAssocFileExtToCmd ".log"           "%SystemRoot%\System32\notepad.exe" "txtfile";
                                                # ex: ToolSetAssocFileExtToCmd ".out"           "`"C:\Any.exe`" `"%1`" -xy";
                                                # ex: ToolSetAssocFileExtToCmd ".out" "";
                                                [String] $prg = $cmd; if( $cmd.StartsWith("`"") ){ $prg = ($prg -split "`"")[1]; }
                                                [String] $exec = $cmd; if( -not $cmd.StartsWith("`"") ){ $exec = "`"$cmd`" `"%1`"";}
                                                [String] $traceInfo = "ToolSetAssocFileExtToCmd($fileExtensions,`"$cmd`",$ftype,$assertPrgExists)";
                                                if( $assertPrgExists -and $cmd -ne "" -and (FileNotExists $prg) ){ throw [Exception] "$traceInfo failed because not exists: `"$prg`""; }
                                                $fileExtensions | ForEach-Object { 
                                                  if( -not $_.StartsWith(".") ){ throw [Exception] "$traceInfo failed because file ext not starts with dot: `"$_`""; };
                                                  if( $_.Contains(" ") ){ throw [Exception] "$traceInfo failed because file ext contains blank: `"$_`""; };
                                                  if( $_.Contains(",") ){ throw [Exception] "$traceInfo failed because file ext contains blank: `"$_`""; };
                                                };
                                                $fileExtensions | ForEach-Object {
                                                  [String] $ext = $_; # ex: ".ps1"
                                                  if( $cmd -eq "" ){
                                                    OutProgress "DelFileAssociation ext=$ext :  cmd /c assoc $ext=";
                                                    [String] $out = (& cmd.exe /c "assoc $ext=" 2>&1); # ex: ""
                                                  }else{
                                                    [String] $ft = $ftype;
                                                    if( $ftype -eq "" ){
                                                      try{
                                                        $ft = (& cmd.exe /c "assoc $ext" 2>&1); AssertRcIsOk; # ex: ".ps1=Microsoft.PowerShellScript.1"
                                                      }catch{ # "Dateizuordnung für die Erweiterung .ps9 nicht gefunden."
                                                        $ft = (& cmd.exe /c "assoc $ext=$($ext.Substring(1))file" 2>&1); # ex: ".ps1=ps1file"
                                                      }
                                                      $ft = $ft.Split("=")[-1]; # "Microsoft.PowerShellScript.1" or "ps1file"
                                                    }
                                                     # ex: Microsoft.PowerShellScript.1="C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe" "%1"
                                                    [String] $out = (& cmd.exe /c "ftype $ft=$exec");
                                                    OutProgress "SetFileAssociation ext=$($ext.PadRight(6)) ftype=$($ft.PadRight(20)) cmd=$exec";
                                                  }
                                                }; }
function ToolPerformFileUpdateAndIsActualized ( [String] $targetFile, [String] $url, [Boolean] $requireElevatedAdminMode = $false, 
                                                  [Boolean] $doWaitIfFailed = $false, [String] $additionalOkUpdMsg = "", 
                                                  [Boolean] $assertFilePreviouslyExists = $true, [Boolean] $performPing = $true ){
                                                # Check if target file exists, checking wether host is reachable by ping, downloads the file, check for differences, 
                                                # check for admin mode, overwriting the file and a success message is given out.
                                                # Otherwise if it failed it will output a warning message and optionally wait for pressing enter key.
                                                # It returns true if the file is now actualized.
                                                # Note: if not in elevated admin mode and if it is required then it will download file twice, 
                                                #   once to check for differences and once after switching to elevated admin mode.
                                                # Example: ToolPerformFileUpdateAndIsActualized "C:\Temp\a.psm1" "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/MnCommonPsToolLib/MnCommonPsToolLib.psm1" $true $true "Please restart" $false $true;
                                                try{
                                                  OutInfo "Update file `"$targetFile`" `n  from $url";
                                                  [String] $hashInstalled = "";
                                                  [Boolean] $targetFileExists = (FileExists $targetFile);
                                                  if( $assertFilePreviouslyExists -and (-not $targetFileExists) ){
                                                    throw [Exception] "Unexpected environment, for updating it is required that target file previously exists but it does not: `"$targetFile`"";
                                                  }
                                                  if( $targetFileExists ){
                                                    OutProgress "Reading hash of target file";
                                                    $hashInstalled = FileGetHexStringOfHash512BitsSha2 $targetFile;
                                                  }
                                                  if( $performPing ){
                                                    OutProgress "Checking host of url wether it is reachable by ping";
                                                    [String] $host = (NetExtractHostName $url);
                                                    if( -not (NetPingHostIsConnectable $host) ){ 
                                                      throw [Exception] "Host $host is not pingable."; 
                                                    }
                                                  }
                                                  [String] $tmp = (FileGetTempFile); NetDownloadFile $url $tmp;
                                                  OutProgress "Checking for differences."; 
                                                  if( $targetFileExists -and $hashInstalled -eq (FileGetHexStringOfHash512BitsSha2 $tmp) ){
                                                    OutProgress "Ok, is up to date, nothing done.";
                                                  }else{
                                                    OutProgress "There are changes between the current file and the downloaded file, so overwrite it.";
                                                    if( $requireElevatedAdminMode ){ 
                                                      ProcessRestartInElevatedAdminMode;
                                                      OutProgress "Is running in elevated admin mode.";
                                                    }
                                                    FileMove $tmp $targetFile $true;
                                                    OutSuccess "Ok, updated `"$targetFile`". $additionalOkUpdMsg";
                                                  }
                                                  return [Boolean] $true;
                                                }catch{
                                                  OutWarning "Update failed because $($_.Exception.Message)";
                                                  if( $doWaitIfFailed ){ 
                                                    StdInReadLine "Press enter to continue."; 
                                                  }
                                                  return [Boolean] $false;
                                                } }
function MnCommonPsToolLibSelfUpdate          ( [Boolean] $doWaitForEnterKeyIfFailed = $false ){
                                                # If installed in standard mode (saved under c:\Program Files\WindowsPowerShell\Modules\...) 
                                                # then it performs a self update to the newest version from github.
                                                [String]  $moduleName = "MnCommonPsToolLib";
                                                [String]  $tarRootDir = "$Env:ProgramW6432\WindowsPowerShell\Modules"; # more see: https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx
                                                [String]  $moduleFile = "$tarRootDir\$moduleName\$moduleName.psm1";                                               
                                                [String]  $url = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/$moduleName/$moduleName.psm1";
                                                [String]  $additionalOkUpdMsg = "`n  Please restart all processes which currently loaded this module before using changed functions of this library.";
                                                [Boolean] $requireElevatedAdminMode = $true;
                                                [Boolean] $assertFilePreviouslyExists = $true;
                                                [Boolean] $performPing = $true;
                                                [Boolean] $dummyResult = ToolPerformFileUpdateAndIsActualized $moduleFile $url $requireElevatedAdminMode $doWaitForEnterKeyIfFailed $additionalOkUpdMsg $assertFilePreviouslyExists $performPing;
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
  Assert ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir") -eq "Dir1\Dir2");
  Assert ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir" $true) -eq ".\Dir1\Dir2");
  Assert ((FsEntryMakeRelative "C:\MyDir" "C:\MyDir\") -eq ".");
  Assert ((Int32Clip -5 0 9) -eq 0 -and (Int32Clip 5 0 9) -eq 5 -and (Int32Clip 15 0 9) -eq 9);
  Assert ((StringRemoveRight "abc" "c") -eq "ab");
  Assert ((StringLeft          "abc" 5) -eq "abc" -and (StringLeft          "abc" 2) -eq "ab");
  Assert ((StringRight         "abc" 5) -eq "abc" -and (StringRight         "abc" 2) -eq "bc");
  Assert ((StringRemoveRightNr "abc" 5) -eq ""    -and (StringRemoveRightNr "abc" 1) -eq "ab");
  OutSuccess "Ok";
} # MnLibCommonSelfTest; # is deactivated because we know it works :-)

# ----------------------------------------------------------------------------------------------------

Export-ModuleMember -function *; # Export all functions from this script which are above this line (types are implicit usable).

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
#   in Systemsteuerung->Standardprogramme you can associate .ps1 with C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe 
#   and make a shortcut ony any .ps1 file, then on clicking on shortcut it will run, but does not work if .ps1 is doubleclicked.
# - Do Not Use: Avoid using $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") or Write-Error because different behaviour of powershell.exe and powershell_ise.exe
# - Extensions: download and install PowerShell Community Extensions (PSCX) for ntfs-junctions and symlinks.
# - Special predefined variables which are not yet used in this script (use by $global:anyprefefinedvar; names are case insensitive):
#   $null, $true, $false  - some constants
#   $args                 - Contains an array of the parameters passed to a function.
#   $error                - Contains objects for which an error occurred while being processed in a cmdlet.
#   $HOME                 - Specifies the user’s home directory. (C:\Users\myuser)
#   $PsHome               - The directory where the Windows PowerShell is installed. (C:\Windows\SysWOW64\WindowsPowerShell\v1.0)
#   $PROFILE              - C:\Users\myuser\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#   $PS...                - some variables
#   $MaximumAliasCount, $MaximumDriveCount, $MaximumErrorCount, $MaximumFunctionCount, $MaximumHistoryCount, $MaximumVariableCount  - some maximum values
#   $StackTrace, $ConsoleFileName, $ErrorView, $ExecutionContext, $Host, $input, $NestedPromptLevel, $PID, $PWD, $ShellId           - some environment values
#   $PSScriptRoot         - folder of current running script
# - Comparison operators; -eq, -ne, -lt, -le, -gt, -ge, "abcde" -like "aB?d*", -notlike, 
#   @( "a1", "a2" ) -contains "a2", -notcontains, "abcdef" -match "b[CD]", -notmatch, "abcdef" -cmatch "b[cd]", -notcmatch, -not
# - Automatic variables see: http://technet.microsoft.com/en-us/library/dd347675.aspx
#   $?            : Contains True if last operation succeeded and False otherwise.
#   $LASTEXITCODE : Contains the exit code of the last Win32 executable execution. should never manually set, even not: $global:LASTEXITCODE = $null;
# - Available colors for options -foregroundcolor and -backgroundcolor: 
#   Black DarkBlue DarkGreen DarkCyan DarkRed DarkMagenta DarkYellow Gray DarkGray Blue Green Cyan Red Magenta Yellow White
# - Manifest .psd1 file can be created with: New-ModuleManifest MnCommonPsToolLib.psd1 -ModuleVersion "1.0" -Author "Marc Niederwieser"
# - Known Bugs or Problems:
#   - Powershell V2 Bug: checking strings for $null is different between if and switch tests:
#     http://stackoverflow.com/questions/12839479/powershell-treats-empty-string-as-equivalent-to-null-in-switch-statements-but-no
#   - Variable or function argument of type String is never $null, if $null is assigned then always empty is stored.
#     [String] $s; $s = $null; Assert ($s -ne $null); Assert ($s -eq "");
#     But if type String is within a struct then it can be null.  
#     Add-Type -TypeDefinition "public struct MyStruct {public string MyVar;}"; Assert( (New-Object MyStruct).MyVar -eq $null );
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
#   - ForEach-Object iterates once with $null in pipeline:    
#     see http://stackoverflow.com/questions/4356758/how-to-handle-null-in-the-pipeline
#     $null | ForEach-Object{ write-host "badly reached." }
#     But:  @() | ForEach-Object{ write-host "ok not reached." }
#     Workaround if array variable can be null, then use:  
#       $null | Where-Object{ $_ -ne $null } | ForEach-Object{ write-host "ok not reached." }
#     Alternative: $null | ForEach-Object -Begin{if($_ -eq $null){continue}} -Process {do your stuff here}
#     Recommendation: Make sure an array variable is never null.
#   - Empty array in pipeline is converted to $null:  
#     $r = ([String[]]@()) | Where-Object{ $_ -ne "bla" }; if( $r -eq $null ){ write-host "ok reached" };
#     Workaround:  $r = @()+(([String[]]@()) | Where-Object{ $_ -ne "bla" }); if( !$r ){ write-host "ok reached, var is not null" };
#   - Compare empty array with $null:  [Object[]] $r = @(); if( $r.gettype().Name -eq "Object[]" ){ write-host "ok reached" };
#     if( $r.count -eq 0 ){ write-host "ok reached"; }
#     if( $r -eq $null ){ write-host "never reached"; }   if( -not ($r -eq $null) ){ write-host "ok reached"; }
#     if( $r -ne $null ){ write-host "never reached"; }   if( -not ($r -ne $null) ){ write-host "ok reached"; }
#     Recommendation: Make sure an array variable is never null.
#   - Variable name conflict: ... | ForEach-Object { [String[]] $a = $_; ... }; [Array] $a = ...;
#     Can result in:  SessionStateUnauthorizedAccessException: Cannot overwrite variable a because the variable has been optimized. 
#       Try using the New-Variable or Set-Variable cmdlet (without any aliases), 
#       or dot-source the command that you are using to set the variable.
#     Recommendation: Rename one of the variables.
#   - Exceptions are always catched within Expression statement and instead of expecting the throw it returns $null:
#     [Object[]] $a = @( "a", "b" ) | Select-Object -Property @{Name="Field1";Expression={$_}} | 
#       Select-Object -Property Field1,
#       @{Name="Field2";Expression={if($_.Field1 -eq "a" ){ "is_a"; }else{ throw [Exception] "This exc is ignored and instead of throwing up the stack the result of the Expression statement is $null."; } }};
#     $a[0].Field2 -eq "is_a" -and $a[1].Field2 -eq $null;  # this is true
#     $a | ForEach { if( $_.Field2 -eq $null ){ throw [Exception] "Field2 is null"; } } # this does the throw
#     Recommendation: After creation of the list do iterate through it and assert non-null values.
#   - String without comparison as condition:  Assert ( "anystring" ); Assert ( "$false" );
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
#     A child scope does not inherit variables, functions, etc., 
#     but it is allowed to view and even change them by accessing parent scope.
#     However, a child scope is created with a set of items. 
#     Typically, it includes all the aliases and variables that have the AllScope option, 
#     plus some variables that can be used to customize the scope, such as MaximumFunctionCount. 
#   Examples: $global:MyVar = "a1"; $script:MyVar = "a2"; $private:MyVar = "a3"; 
#     function global:MyFunc(){..};  $local.MyVar = "a4"; $MyVar = "a5"; get-variable -scope global;
# - Run a script:
#   - runs script in script scope, variables and functions do not persists in shell after script end:
#       ".\myscript.ps1"
#   - runs script in local scope, variables and functions persists in shell after script end, used to include ps artefacts:
#       . ".\myscript.ps1"
#       . { Write-Host "Test"; }    
#       powershell.exe -command ". .\myscript.ps1" 
#       powershell.exe -file ".\myscript.ps1"
#   - Call operator, runs a script, executable, function or scriptblock, 
#     - Creates a new script scope which is deleted after script end. Changes to global variables are also lost.
#         & "./myscript.ps1" ...arguments... ; & $mycmd ...args... ; & { mycmd1; mycmd2 }
#     - Use quotes when calling non-powershell executables. 
#     - Very important: if an empty argument should be specified then two quotes as '' or "" or $null 
#       or $myEmptyVar do not work (will make the argument not present), 
#       it requires '""' or "`"`"" or `"`" or use a blank as " ". This is really a big fail, it is very bad and dangerous!
#       Why is an empty string not handled similar as a filled string?
#       The best workaround is to use ALWAYS escaped double-quotes for EACH argument: & "myexe.exe" `"$arg1`" `"`" `"$arg3`";
#       But even then it is NOT ALLOWED that content contains a double-quote.
#       There is also no proper solution if quotes instead of double-quotes are used.
#     - Precedence of commands: Alias > Function > Filter > Cmdlet > Application > ExternalScript > Script.
#     - Override precedence of commands by using get-command, ex: Get-Command -commandType Application Ping
#   - Evaluate (string expansion) and run a command given in a string, does not create a new script scope 
#     and so works in local scope. Care for code injection. 
#       Invoke-Expression [-command] string [CommonParameters]
#     Very important: It performs string expansion before running, so it can be a severe problem if the string contains character $.
#     This behaviour is very bad and so avoid using Invoke-Expression and use & or . operators instead.
#     Ex: $cmd1 = "echo `$PSHome"; $cmd2 = "echo $PSHome"; Invoke-Expression $cmd1; Invoke-Expression $cmd2;
#   - Run a script or command remotely. See http://ss64.com/ps/invoke-command.html
#     Invoke-Command 
#     If you use Invoke-Command to run a script or command on a remote computer, 
#     then it will not run elevated even if the local session is. This is because any prompt 
#     for elevation will happen on the remote machine in a non-interactive session and so will fail.
#     Example:  invoke-command -LiteralPath "c:\scripts\test.ps1" -computerName "Server64";  
#       invoke-command -computername "server64" -credential "domain64\user64" -scriptblock {get-culture};
#   - Invoke the (provider-specific) default action on an item (like double click). For example open pdf viewer for a .pdf file.
#       Invoke-Item ./myfile.xls
#   - Start a process waiting for end or not.
#       start-process -FilePath notepad.exe -ArgumentList """Test.txt"""; # no wait for end, opened in foreground
#       [Diagnostics.Process]::Start("notepad.exe","test.txt"); # no wait for end, opened in foreground
#       start-process -FilePath  C:\batch\demo.cmd -verb runas;
#       start-process -FilePath notepad.exe -wait -windowstyle Maximized; # wait for end
#       start-process -FilePath Sort.exe -RedirectStandardInput C:\Demo\Testsort.txt -RedirectStandardOutput C:\Demo\Sorted.txt -RedirectStandardError C:\Demo\SortError.txt
#       $pclass = [wmiclass]'root\cimv2:Win32_Process'; $new_pid = $pclass.Create('notepad.exe', '.', $null).ProcessId; # no wait for end, opened app in background
#     Run powershell with elevated rights: Start-Process -FilePath powershell.exe -Verb runAs
#     Important note: If a program is called which also has as input a commandline then the arguments must be tripple-doublequoted.
#       see https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.arguments
#           https://github.com/PowerShell/PowerShell/issues/5576
#       Start-Process -FilePath powershell.exe -Verb runAs -ArgumentList "-NoExit `"&`" notepad.exe `"`"`"Test WithBlank.txt`"`"`" "
# - Call module with arguments: ex:  Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1" -ArgumentList $myinvocation.mycommand.Path;
# - FsEntries: -LiteralPath means no interpretation of wildcards
# - Extensions and libraries: https://www.powershellgallery.com/  http://ss64.com/links/pslinks.html
# - Important to know:
#   - Alternative for Split-Path has problems: 
#       [System.IO.Path]::GetDirectoryName("c:\") -eq $null; 
#       [System.IO.Path]::GetDirectoryName("\\mymach\myshare\") -eq "\\mymach\myshare\";
#   - Split():
#       [String[]] $a = "".Split(";",[System.StringSplitOptions]::RemoveEmptyEntries); 
#       # returns correctly an empty array and not null: $a.Count -eq 0;
#     Usually Split is used with the option RemoveEmptyEntries.
