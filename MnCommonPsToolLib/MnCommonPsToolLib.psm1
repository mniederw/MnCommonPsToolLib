# MnCommonPsToolLib - Common Powershell Tool Library for PS5 and PS7 and multiplatforms (Windows, Linux and OSX)
# --------------------------------------------------------------------------------------------------------------
# Published at: https://github.com/mniederw/MnCommonPsToolLib
# Licensed under GPL3. This is freeware.
#
# This library encapsulates many common commands for the purpose of supporting compatibility between
# multi platforms, simplifying commands, fixing usual problems, supporting tracing information,
# making behaviour compatible for usage with powershell.exe and powershell_ise.exe and acts as documentation.
# It is splitted in a mulitplatform compatible part and a part which runs only on Windows.
# Some functions depends on that its subtools as git, svn, etc. are available via path variable.
#
# Recommendations and notes about common approaches of this library:
# - Unit-Tests: Many functions are included and they are run either
#   automatically by github workflow (on win, linux and osx) or by manual starts.
# - Indenting format of library functions: The statements are indented in the way that they are easy readable as documentation.
# - Typesafe: Functions and its arguments and return values are always specified with its type
#   to assert type reliablility as far as possible.
# - Avoid null values: Whenever possible null values are generally avoided. For example arrays gets empty instead of null.
# - Win-1252/UTF8: Text file contents are written per default as UTF8-BOM for improving compatibility between multi platforms.
#   They are read in Win-1252(=ANSI) if they have no BOM (byte order mark) or otherwise according to BOM.
# - Create files: On writing or appending files they automatically create its path parts.
# - Notes about tracing information lines:
#   - Progress : Any change of the system will be notified with color Gray. Is enabled as default.
#   - Verbose  : Some io functions will be enriched with Write-Verbose infos. which are written in DarkGray
#     and can be enabled by VerbosePreference.
#   - Debug    : Some minor additional information are enriched with Write-Debug, which can be enabled by DebugPreference.
# - Comparison with null: All such comparing statements have the null constant on the left side ($null -eq $a)
#   because for arrays this is mandatory (throws: @() -eq $null)
# - Null Arrays: All powershell function returning an array should always return an empty array instead of null
#   for avoiding counting null as one element when added to an empty array.
# - More: Powershell useful knowledge and additional documentation see bottom of MnCommonPsToolLib.psm1
#
# Example usages of this module for a .ps1 script:
#      # Simple example for using MnCommonPsToolLib
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
#      Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "Hello world";
#      OutProgress "Working";
#      StdInReadLine "Press enter to exit.";
# More examples see: https://github.com/mniederw/MnCommonPsToolLib/tree/main/Examples
#
# 2013-2023 produced by Marc Niederwieser, Switzerland.



# Do not change the following line, it is a powershell statement and not a comment! Note: if it would be run interactively then it would throw: RuntimeException: Error on creating the pipeline.
#Requires -Version 3.0

# Version: Own version variable because manifest can not be embedded into the module itself only by a separate file which is a lack.
#   Major version changes will reflect breaking changes and minor identifies extensions and third number are for urgent bugfixes.
[String] $global:MnCommonPsToolLibVersion = "7.16"; # more see Releasenotes.txt

# Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).
Set-StrictMode -Version Latest;

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
if( -not [String]  (Get-Variable ModeOutputWithTsPrefix            -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeOutputWithTsPrefix            -value $false; }
                                                                    # if true then it will add before each OutInfo, OutWarning, OutError, OutProgress a timestamp prefix.

# Set some powershell predefined global variables:
$global:ErrorActionPreference         = "Stop"                    ; # abort if a called exe will write to stderr, default is 'Continue'. Can be overridden in each command by [-ErrorAction actionPreference]
$global:ReportErrorShowExceptionClass = $true                     ; # on trap more detail exception info
$global:ReportErrorShowInnerException = $true                     ; # on trap more detail exception info
$global:ReportErrorShowStackTrace     = $true                     ; # on trap more detail exception info
$global:FormatEnumerationLimit        = 999                       ; # used for Format-Table, but seams not to work, default is 4
$global:OutputEncoding                = [Console]::OutputEncoding ; # for pipe to native applications use the same as current console, default is 'System.Text.ASCIIEncoding'
if( $null -ne $Host.PrivateData ){ # if running as job then it is null
  $Host.PrivateData.VerboseForegroundColor = 'DarkGray'; # for verbose messages the default is yellow which is bad because it is flashy and equal to warnings
  $Host.PrivateData.DebugForegroundColor   = 'DarkRed' ; # for debug   messages the default is yellow which is bad because it is flashy and equal to warnings
}

# Leave the following global variables on their default values, is here written just for documentation:
#   $global:InformationPreference   SilentlyContinue   # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $global:VerbosePreference       SilentlyContinue   # Available: Stop, Inquire, Continue(=show verbose and continue), SilentlyContinue(=default=no verbose).
#   $global:DebugPreference         SilentlyContinue   # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $global:ProgressPreference      Continue           # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $global:WarningPreference       Continue           # Available: Stop, Inquire, Continue, SilentlyContinue. Can be overridden in each command by [-WarningAction actionPreference]
#   $global:ConfirmPreference       High               # Available: None, Low, Medium, High.
#   $global:WhatIfPreference        False              # Available: False, True.

# We like english error messages
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US');
  # alternatives: [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US'); Set-Culture en-US;

# Recommended installed modules: Some functions may use the following modules
#   Install-Module PSScriptAnalyzer; # used by testing files for analysing powershell code
#   Install-Module SqlServer       ; # used by SqlPerformFile, SqlPerformCmd.
#   Install-Module ThreadJob       ; # used by GitCloneOrPullUrls

# Import some modules (because it is more performant to do it once than doing this in each function using methods of this module).
# Note: for example on "Windows Server 2008 R2" we currently are missing these modules but we ignore the errors because it its enough if the functions which uses these modules will fail.
#   The specified module 'ScheduledTasks'/'SmbShare' was not loaded because no valid module file was found in any module directory.
if( $null -ne (Import-Module -NoClobber -Name "ScheduledTasks" -ErrorAction Continue *>&1) ){ $error.clear(); Write-Warning "Ignored failing of Import-Module ScheduledTasks because it will fail later if a function is used from it."; }
if( $null -ne (Import-Module -NoClobber -Name "SmbShare"       -ErrorAction Continue *>&1) ){ $error.clear(); Write-Warning "Ignored failing of Import-Module SmbShare       because it will fail later if a function is used from it."; }
# Import-Module "SmbWitness"; # for later usage
# Import-Module "ServerManager"; # Is not always available, requires windows-server-os or at least Win10Prof with installed RSAT. Because seldom used we do not try to load it here.
# Import-Module "SqlServer"; # not always used so we dont load it here.

# types
Add-Type -Name Window -Namespace Console -MemberDefinition '[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);';
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Window { [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect); [DllImport("User32.dll")] public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw); } public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }';
Add-Type -WarningAction SilentlyContinue -TypeDefinition "using System; public class ExcMsg : Exception { public ExcMsg(String s):base(s){} } ";
  # Used for error messages which have a text which will be exact enough so no stackdump is nessessary. Is handled in our StdErrHandleExc.
  # Note: we need to suppress the warning: The generated type defines no public methods or properties

# Set some self defined constant global variables
if( $null -eq (Get-Variable -Scope global -ErrorAction SilentlyContinue -Name ComputerName) -or $null -eq $global:InfoLineColor ){ # check wether last variable already exists because reload safe
  New-Variable -option Constant -scope global -name CurrentMonthAndWeekIsoString -value ([String]((Get-Date -format "yyyy-MM-")+(Get-Date -uformat "W%V")));
  New-Variable -option Constant -scope global -name UserQuickLaunchDir           -value ([String]"$env:APPDATA\Microsoft\Internet Explorer\Quick Launch");
  New-Variable -option Constant -scope global -name UserSendToDir                -value ([String]"$env:APPDATA\Microsoft\Windows\SendTo");
  New-Variable -option Constant -scope global -name UserMenuDir                  -value ([String]"$env:APPDATA\Microsoft\Windows\Start Menu");
  New-Variable -option Constant -scope global -name UserMenuStartupDir           -value ([String]"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup");
  New-Variable -option Constant -scope global -name AllUsersMenuDir              -value ([String]"$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu");
  New-Variable -option Constant -scope global -name InfoLineColor                -Value $(switch($Host.Name -eq "Windows PowerShell ISE Host"){($true){"Gray"}default{"White"}}); # ise is white so we need a contrast color
  New-Variable -option Constant -scope global -name ComputerName                 -value ([String]"$env:computername".ToLower());
}

# Statement extensions
function ForEachParallel {
  # Note: In the statement block no functions or variables of the script where it is embedded can be used. Only from loaded modules.
  #   Only the single variable $_ can be used.
  #   You can also not base on Auto-Load-Module in your script, so generally use Load-Module for each used module.
  # ex: (0..20) | ForEachParallel { Write-Output "Nr: $_"; Start-Sleep -Seconds 1; };
  # ex: (0..5)  | ForEachParallel -MaxThreads 2 { Write-Output "Nr: $_"; Start-Sleep -Seconds 1; };
  # Based on https://powertoe.wordpress.com/2012/05/03/foreach-parallel/
  # In future we may use:  (1..20) | ForEach-Object -Parallel Write-Output "Nr: $_"; Start-Sleep -Seconds 1; } -ThrottleLimit 5
  param( [Parameter(Mandatory=$true,position=0)]              [System.Management.Automation.ScriptBlock] $ScriptBlock,
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [PSObject]                                 $InputObject,
         [Parameter(Mandatory=$false)]                        [Int32]                                    $MaxThreads=8 )
  # Note: for some unknown reason we sometimes get a red line "One or more errors occurred."
  # and maybe "Collection was modified; enumeration operation may not execute." but it continuous successfully.
  # We assume it is because it uses internally autoload module and this is not fully multithreading/parallel safe.
  BEGIN{
    try{
      # if( ($scriptblock.ToString() -replace "`$_","" -replace "`$true","" -replace "`$false","") -match "`$" ){
      #   throw [Exception] "ForEachParallel(`{$scriptblock`}) has a dollar sign in script block and only [`$_,`$true,`$false] are allowed.";
      # }
      $iss = [System.Management.Automation.Runspaces.Initialsessionstate]::CreateDefault();
      # Note: for sharing data we need someting as:
      #   $sharedArray = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new());
      #   $sharedQueue = [System.Collections.Queue]::Synchronized([System.Collections.Queue]::new());
      $pool = [Runspacefactory]::CreateRunspacePool(1,$maxthreads,$iss,$host); $pool.open();
      # alternative: $pool = [Runspacefactory]::CreateRunspacePool($iss); $pool.SetMinRunspaces(1) | Out-Null; $pool.SetMaxRunspaces($maxthreads) | Out-Null;
      # has no effect: $pool.ApartmentState = "MTA";
      $threads = @();
      $scriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("param(`$_)$([Environment]::NewLine)"+$scriptblock.ToString());
    }catch{ $Host.UI.WriteErrorLine("ForEachParallel-BEGIN: $($_)"); }
  }PROCESS{
    try{
      # alternative:
      #   [System.Management.Automation.PSDataCollection[PSObject]] $pipelineInputs = New-Object System.Management.Automation.PSDataCollection[PSObject];
      #   [System.Management.Automation.PSDataCollection[PSObject]] $pipelineOutput = New-Object System.Management.Automation.PSDataCollection[PSObject];
      $powershell = [powershell]::Create().addscript($scriptblock).addargument($InputObject);
      $powershell.runspacepool = $pool;
      $threads += @{ instance = $powershell; handle = $powershell.BeginInvoke(); }; # $pipelineInputs,$pipelineOutput
    }catch{ $Host.UI.WriteErrorLine("ForEachParallel-PROCESS: $($_)"); }
    [gc]::Collect();
  }END{
    try{
      [Boolean] $notdone = $true; while( $notdone ){ $notdone = $false;
        [System.Threading.Thread]::Sleep(250); # polling interval in msec
        for( [Int32] $i = 0; $i -lt $threads.count; $i++ ){
          if( $null -ne $threads[$i].handle ){
            if( $threads[$i].handle.iscompleted ){
              try{
                # Note: Internally we sometimes get the following progress text for which we don't know why and on which statement this happens:
                #   "parent = -1 id = 0 act = Module werden für erstmalige Verwendung vorbereitet. stat =   cur =  pct = -1 sec = -1 type = Processing/Completed "
                #   Because that we write this to verbose and not to progress because for progress a popup window would occurre which does not disappear.
                $threads[$i].instance.EndInvoke($threads[$i].handle);
              }catch{
                [String] $msg = $_; $error.clear();
                # msg example: Exception calling "EndInvoke" with "1" argument(s): "Der ausgeführte Befehl wurde beendet, da die
                #              Einstellungsvariable "ErrorActionPreference" oder ein allgemeiner Parameter auf "Stop" festgelegt ist:
                #              Es ist ein allgemeiner Fehler aufgetreten, für den kein spezifischerer Fehlercode verfügbar ist.."
                Write-Host -ForegroundColor Gray "ForEachParallel-endinvoke: Ignoring $msg";
              }
              [String] $outEr = $threads[$i].instance.Streams.Error      ; if( $outEr -ne "" ){ Write-Error       "Error: $outEr"; }
              [String] $outWa = $threads[$i].instance.Streams.Warning    ; if( $outWa -ne "" ){ Write-Warning     "Warning: $outWa"; }
              [String] $outIn = $threads[$i].instance.Streams.Information; if( $outIn -ne "" ){ Write-Information "Info: $outIn"; }
              [String] $outPr = $threads[$i].instance.Streams.Progress   ; if( $outPr -ne "" ){ Write-Verbose     "Progress: $outPr"; } # we write to verbose not progress
              [String] $outVe = $threads[$i].instance.Streams.Verbose    ; if( $outVe -ne "" ){ Write-Verbose     "Verbose: $outVe"; }
              [String] $outDe = $threads[$i].instance.Streams.Debug      ; if( $outDe -ne "" ){ Write-Debug       "Debug: $outDe"; }
              $threads[$i].instance.dispose();
              $threads[$i].handle = $null;
              [gc]::Collect();
            }else{ $notdone = $true; }
          }
        }
      }
    }catch{
      # ex: 2018-07: Exception calling "EndInvoke" with "1" argument(s) "Der ausgeführte Befehl wurde beendet, da die
      #              Einstellungsvariable "ErrorActionPreference" oder ein allgemeiner Parameter auf "Stop" festgelegt ist:
      #              Es ist ein allgemeiner Fehler aufgetreten, für den kein spezifischerer Fehlercode verfügbar ist.."
      $Host.UI.WriteErrorLine("ForEachParallel-END: $($_)");
    }
    $error.clear();
    [gc]::Collect();
  }
}

# ----- exported tools and types -----

function GlobalSetModeVerboseEnable           ( [Boolean] $val = $true ){ $global:VerbosePreference = $(switch($val){($true){"Continue"}default{"SilentlyContinue"}}); }
function GlobalSetModeHideOutProgress         ( [Boolean] $val = $true ){ $global:ModeHideOutProgress      = $val; }
function GlobalSetModeDisallowInteractions    ( [Boolean] $val = $true ){ $global:ModeDisallowInteractions = $val; }
function GlobalSetModeNoWaitForEnterAtEnd     ( [Boolean] $val = $true ){ $global:ModeNoWaitForEnterAtEnd  = $val; }
function GlobalSetModeEnableAutoLoadingPref   ( [Boolean] $val = $true ){ $global:PSModuleAutoLoadingPreference = $(switch($val){($true){$null}default{"none"}}); } # enable or disable autoloading modules, available internal values: All (=default), ModuleQualified, None.
function GlobalSetModeOutputWithTsPrefix      ( [Boolean] $val = $true ){ $global:ModeOutputWithTsPrefix   = $val; }

function StringIsNullOrEmpty                  ( [String] $s ){ return [Boolean] [String]::IsNullOrEmpty($s); }
function StringIsNotEmpty                     ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrEmpty($s)); }
function StringIsFilled                       ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrWhiteSpace($s)); }
function StringIsInt32                        ( [String] $s ){ [String] $tmp = ""; return [Int32]::TryParse($s,[ref]$tmp); }
function StringIsInt64                        ( [String] $s ){ [String] $tmp = ""; return [Int64]::TryParse($s,[ref]$tmp); }
function StringAsInt32                        ( [String] $s ){ if( ! (StringIsInt32 $s) ){ throw [Exception] "Is not an Int32: $s"; } return ($s -as [Int32]); }
function StringAsInt64                        ( [String] $s ){ if( ! (StringIsInt64 $s) ){ throw [Exception] "Is not an Int64: $s"; } return ($s -as [Int64]); }
function StringLeft                           ( [String] $s, [Int32] $len ){ return [String] $s.Substring(0,(Int32Clip $len 0 $s.Length)); }
function StringRight                          ( [String] $s, [Int32] $len ){ return [String] $s.Substring($s.Length-(Int32Clip $len 0 $s.Length)); }
function StringRemoveRightNr                  ( [String] $s, [Int32] $len ){ return [String] (StringLeft $s ($s.Length-$len)); }
function StringPadRight                       ( [String] $s, [Int32] $len, [Boolean] $doQuote = $false, [Char] $c = " "){
                                                [String] $r = $s; if( $doQuote ){ $r = '"'+$r+'"'; } return [String] $r.PadRight($len,$c); }
function StringSplitIntoLines                 ( [String] $s ){ return [String[]] (($s -replace "`r`n", "`n") -split "`n"); } # for empty string it returns an array with one item.
function StringReplaceNewlines                ( [String] $s, [String] $repl = " " ){ return [String] ($s -replace "`r`n", "`n" -replace "`r", "" -replace "`n", $repl); }
function StringSplitToArray                   ( [String] $sep, [String] $s, [Boolean] $removeEmptyEntries = $true ){
                                                return [String[]] $s.Split($sep,$(switch($removeEmptyEntries){($true){[System.StringSplitOptions]::RemoveEmptyEntries}default{[System.StringSplitOptions]::None}})); }
function StringReplaceEmptyByTwoQuotes        ( [String] $str ){ return [String] $(switch((StringIsNullOrEmpty $str)){($true){"`"`""}default{$str}}); }
function StringRemoveLeft                     ( [String] $str, [String] $strLeft , [Boolean] $ignoreCase = $true ){ [String] $s = StringLeft  $str $strLeft.Length ;
                                                return [String] $(switch(($ignoreCase -and $s -eq $strLeft ) -or $s -ceq $strLeft ){ ($true){$str.Substring($strLeft.Length,$str.Length-$strLeft.Length)} default{$str} }); }
function StringRemoveRight                    ( [String] $str, [String] $strRight, [Boolean] $ignoreCase = $true ){ [String] $s = StringRight $str $strRight.Length;
                                                return [String] $(switch(($ignoreCase -and $s -eq $strRight) -or $s -ceq $strRight){ ($true){StringRemoveRightNr $str $strRight.Length} default{$str} }); }
function StringRemoveOptEnclosingDblQuotes    ( [String] $s ){ if( $s.Length -ge 2 -and $s.StartsWith("`"") -and $s.EndsWith("`"") ){
                                                return [String] $s.Substring(1,$s.Length-2); } return [String] $s; }
function StringMakeNonNull                    ( [String] $s ){ if( $null -eq $s ){ return ""; }else{ return $s; } }
function StringArrayInsertIndent              ( [String[]] $lines, [Int32] $nrOfBlanks ){
                                                return [String[]] (@()+($lines | Where-Object{$null -ne $_} | ForEach-Object{ ((" "*$nrOfBlanks)+$_); })); }
function StringArrayDistinct                  ( [String[]] $lines ){ return [String[]] (@()+($lines | Where-Object{$null -ne $_} | Select-Object -Unique)); }
function StringArrayConcat                    ( [String[]] $lines, [String] $sep = [Environment]::NewLine ){ return [String] ($lines -join $sep); }
function StringArrayContains                  ( [String[]] $a, [String] $itemCaseSensitive ){ return [Boolean] ($a.Contains($itemCaseSensitive)); }
function StringArrayIsEqual                   ( [String[]] $a, [String[]] $b, [Boolean] $ignoreOrder = $false, [Boolean] $ignoreCase = $false ){
                                                if( $null -eq $a ){ return [Boolean] ($null -eq $b -or $b.Count -eq 0); }
                                                if( $null -eq $b ){ return [Boolean] ($null -eq $a -or $a.Count -eq 0); }
                                                if( $a.Count -ne $b.Count ){ return [Boolean] $false; }
                                                if( $ignoreOrder ){
                                                  [Object[]] $r = (Compare-Object -caseSensitive:(-not $ignoreCase) -ReferenceObject $a -DifferenceObject $b) + @();
                                                  return [Boolean] ($r.Count -eq 0); }
                                                for( [Int32] $i = 0; $i -lt $a.Count; $i++ ){
                                                  if( ($ignoreCase -and $a[$i] -ne $b[$i]) -or (-not $ignoreCase -and $a[$i] -cne $b[$i]) ){ return [Boolean] $false; }
                                                } return [Boolean] $true; }
function StringArrayDblQuoteItems             ( [String[]] $a ){ # surround each item by double quotes
                                                return [String[]] (@()+($a | Where-Object{$null -ne $_} | ForEach-Object { "`"$_`"" })); }
function StringFromException                  ( [Exception] $ex ){
                                                # Return full info of string which can contain newlines. Use this if $_.Exception.Message is not enough.
                                                # example: "ArgumentOutOfRangeException: Specified argument was out of the range of valid values. Parameter name: times  at ..."
                                                # note: .Data is never null.
                                                [String] $nl = [Environment]::NewLine;
                                                [String] $typeName = switch($ex.GetType().Name -eq "ExcMsg" ){($true){"Error"}default{$ex.GetType().Name;}};
                                                [String] $excMsg   = StringReplaceNewlines $ex.Message;
                                                [String] $excData  = ""; foreach($key in $ex.Data.Keys){ $excData += "$nl  $key=`"$($ex.Data[$key])`"."; }
                                                [String] $stackTr  = switch($null -eq $ex.StackTrace){($true){""}default{"$nl  StackTrace:$nl $($ex.StackTrace -replace `"$nl`",`"$nl `")"}};
                                                return [String] "$($typeName): $excMsg$excData$stackTr"; }
function StringFromErrorRecord                ( [System.Management.Automation.ErrorRecord] $er ){
                                                 [String] $msg = (StringFromException $er.Exception);
                                                [String] $nl = [Environment]::NewLine;
                                                 $msg += "$nl  ScriptStackTrace: $nl    $($er.ScriptStackTrace -replace `"$nl`",`"$nl    `")"; # ex: at <ScriptBlock>, C:\myfile.psm1: line 800 at MyFunc
                                                 $msg += "$nl  InvocationInfo:$nl    $($er.InvocationInfo.PositionMessage -replace `"$nl`",`"$nl    `")"; # At D:\myfile.psm1:800 char:83 \n   + ...   +   ~~~
                                                 $msg += "$nl  Ts=$(DateTimeNowAsStringIso) User=$($env:username) mach=$($env:COMPUTERNAME) ";
                                                 # $msg += "$nl  InvocationInfoLine: $($er.InvocationInfo.Line -replace `"$nl`",`" `" -replace `"\s+`",`" `" )";
                                                 # $msg += "$nl  InvocationInfoMyCommand: $($er.InvocationInfo.MyCommand)"; # ex: ForEach-Object
                                                 # $msg += "$nl  InvocationInfoInvocationName: $($er.InvocationInfo.InvocationName)"; # ex: ForEach-Object
                                                 # $msg += "$nl  InvocationInfoPSScriptRoot: $($er.InvocationInfo.PSScriptRoot)"; # ex: D:\MyModuleDir
                                                 # $msg += "$nl  InvocationInfoPSCommandPath: $($er.InvocationInfo.PSCommandPath)"; # ex: D:\MyToolModule.psm1
                                                 # $msg += "$nl  FullyQualifiedErrorId: $($er.FullyQualifiedErrorId)"; # ex: "System.ArgumentOutOfRangeException,Microsoft.PowerShell.Commands.ForEachObjectCommand"
                                                 # $msg += "$nl  ErrorRecord: $($er.ToString() -replace `"$nl`",`" `")"; # ex: "Specified argument was out of the range of valid values. Parametername: times"
                                                 # $msg += "$nl  CategoryInfo: $(switch($null -ne $er.CategoryInfo){($true){$er.CategoryInfo.ToString()}default{''}})"; # https://msdn.microsoft.com/en-us/library/system.management.automation.errorcategory(v=vs.85).aspx
                                                 # $msg += "$nl  PipelineIterationInfo: $($er.PipelineIterationInfo|Where-Object{$null -ne $_}|ForEach-Object{'$_, '})";
                                                 # $msg += "$nl  TargetObject: $($er.TargetObject)"; # can be null
                                                 # $msg += "$nl  ErrorDetails: $(switch($null -ne $er.ErrorDetails){($true){$er.ErrorDetails.ToString()}default{''}})";
                                                 # $msg += "$nl  PSMessageDetails: $($er.PSMessageDetails)";
                                                 return [String] $msg; }
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
                                                      [Int32] $q = $line.IndexOf('"',$i + 1);
                                                      if( $q -lt 0 ){ throw [Exception] "Missing closing doublequote after pos=$i in cmdline='$line'"; }
                                                      $s += $line.Substring($i + 1,$q - ($i + 1));
                                                      $i = $q+1;
                                                      if( $i -ge $line.Length -or $line[$i] -eq ' ' -or $line[$i] -eq [Char]9 ){ break; }
                                                      if( $line[$i] -eq '"' ){ $s += '"'; }
                                                      else{ throw [Exception] "Expected blank or tab char or end of string but got char='$($line[$i])' after doublequote at pos=$i in cmdline='$line'"; }
                                                    }
                                                    $result += $s;
                                                  }else{
                                                    [Int32] $w = $line.IndexOf(' ',$i + 1);
                                                    if( $w -lt 0 ){ $w = $line.IndexOf([Char]9,$i + 1); }
                                                    if( $w -lt 0 ){ $w = $line.Length; }
                                                    $s += $line.Substring($i,$w - $i);
                                                    if( $s.Contains('"') ){ throw [Exception] "Expected no doublequote in word='$s' after pos=$i in cmdline='$line'"; }
                                                    $i = $w;
                                                    $result += $s;
                                                  }
                                                  while( $i -lt $line.Length -and ($line[$i] -eq ' ' -or $line[$i] -eq [Char]9) ){ $i++; }
                                                }
                                                return [String[]] $result; }
function StringNormalizeAsVersion             ( [String] $versionString ){
                                                # For comparison the first 4 dot separated parts are cared and the rest after a blank is ignored.
                                                # Each component which begins with a digit is filled with leading zeros to a length of 5
                                                # A leading "V" or "v" is optional and will be removed.
                                                # Ex: "12.3.40" => "00012.00003.00040"; "12.20" => "00012.00002"; "12.3.beta.40.5 descrtext" => "00012.00003.beta.00040";
                                                #     "V12.3" => "00012.00003"; "v12.3" => "00012.00003"; "" => ""; "a" => "a"; " b" => "";
                                                return [String] ( ( (StringSplitToArray "." (@()+(StringSplitToArray " " (StringRemoveLeft $versionString "V") $false))[0]) |
                                                  Select-Object -First 4 |
                                                  ForEach-Object{ if( $_ -match "^[0-9].*$" ){ $_.PadLeft(5,'0') }else{ $_ } }) -join "."); }
function StringCompareVersionIsMinimum        ( [String] $version, [String] $minVersion ){
                                                # Return true if version is equal of higher than a given minimum version (also see StringNormalizeAsVersion).
                                                return [Boolean] ((StringNormalizeAsVersion $version) -ge (StringNormalizeAsVersion $minVersion)); }
function Int32Clip                            ( [Int32] $i, [Int32] $lo, [Int32] $hi ){ if( $i -lt $lo ){
                                                return [Int32] $lo; } elseif( $i -gt $hi ){ return [Int32] $hi; }else{ return [Int32] $i; } }
function DateTimeAsStringIso                  ( [DateTime] $ts, [String] $fmt = "yyyy-MM-dd HH:mm:ss" ){
                                                return [String] $ts.ToString($fmt); }
function DateTimeGetBeginOf                   ( [String] $beginOf, [DateTime] $ts = (Get-Date) ){
                                                if( $beginOf -eq "Year"     ){ return [DateTime] (New-Object DateTime ($ts.Year),1,1); }
                                                if( $beginOf -eq "Semester" ){ return [DateTime] (New-Object DateTime ($ts.Year),(1+6*[Math]::Floor((($ts.Month)-1)/6)),1); }
                                                if( $beginOf -eq "Quarter"  ){ return [DateTime] (New-Object DateTime ($ts.Year),(1+4*[Math]::Floor((($ts.Month)-1)/4)),1); }
                                                if( $beginOf -eq "TwoMonth" ){ return [DateTime] (New-Object DateTime ($ts.Year),(1+2*[Math]::Floor((($ts.Month)-1)/2)),1); }
                                                if( $beginOf -eq "Month"    ){ return [DateTime] (New-Object DateTime ($ts.Year),($ts.Month),1); }
                                                if( $beginOf -eq "Week"     ){ return [DateTime] $ts.Date.AddDays(-[Int32]$ts.DayOfWeek+[Int32][DayOfWeek]::Monday); }
                                                if( $beginOf -eq "Hour"     ){ return [DateTime] (New-Object DateTime ($ts.Year),($ts.Month),($ts.Day),($ts.Hour),0,0); }
                                                if( $beginOf -eq "Minute"   ){ return [DateTime] (New-Object DateTime ($ts.Year),($ts.Month),($ts.Day),($ts.Hour),($ts.Minute),0); }
                                                throw [Exception] "Unknown beginOf=`"$beginOf`", expected one of: [Year,Semester,Quarter,TwoMonth,Month,Week,Hour,Minute]."; }
function DateTimeNowAsStringIso               ( [String] $fmt = "yyyy-MM-dd HH:mm:ss" ){ return [String] (Get-Date -format $fmt); }
function DateTimeNowAsStringIsoDate           (){ return [String] (Get-Date -format "yyyy-MM-dd"); }
function DateTimeNowAsStringIsoMonth          (){ return [String] (Get-Date -format "yyyy-MM"); }
function DateTimeNowAsStringIsoYear           (){ return [String] (Get-Date -format "yyyy"); }
function DateTimeNowAsStringIsoInMinutes      (){ return [String] (Get-Date -format "yyyy-MM-dd HH:mm"); }
function DateTimeFromStringIso                ( [String] $s ){ # "yyyy-MM-dd HH:mm:ss.fff" or "yyyy-MM-ddTHH:mm:ss.fff".
                                                [String] $fmt = "yyyy-MM-dd HH:mm:ss.fff";
                                                if( $s.Length -le 10 ){ $fmt = "yyyy-MM-dd"; }
                                                elseif( $s.Length -le 16 ){ $fmt = "yyyy-MM-dd HH:mm"; }
                                                elseif( $s.Length -le 19 ){ $fmt = "yyyy-MM-dd HH:mm:ss"; }
                                                elseif( $s.Length -le 20 ){ $fmt = "yyyy-MM-dd HH:mm:ss."; }
                                                elseif( $s.Length -le 21 ){ $fmt = "yyyy-MM-dd HH:mm:ss.f"; }
                                                elseif( $s.Length -le 22 ){ $fmt = "yyyy-MM-dd HH:mm:ss.ff"; }
                                                if( $s.Length -gt 10 -and $s[10] -ceq 'T' ){ $fmt = $fmt.remove(10,1).insert(10,'T'); }
                                                try{ return [DateTime] [datetime]::ParseExact($s,$fmt,$null);
                                                }catch{ <# ex: Ausnahme beim Aufrufen von "ParseExact" mit 3 Argument(en): Die Zeichenfolge wurde nicht als gültiges DateTime erkannt. #>
                                                  throw [Exception] "DateTimeFromStringIso(`"$s`") is not a valid datetime in format `"$fmt`""; } }
function ByteArraysAreEqual                   ( [Byte[]] $a1, [Byte[]] $a2 ){ if( $a1.LongLength -ne $a2.LongLength ){ return [Boolean] $false; }
                                                for( [Int64] $i = 0; $i -lt $a1.LongLength; $i++ ){ if( $a1[$i] -ne $a2[$i] ){ return [Boolean] $false; } } return [Boolean] $true; }
function ArrayIsNullOrEmpty                   ( [Object[]] $a ){ return [Boolean] ($null -eq $a -or $a.Count -eq 0); }
function ConsoleHide                          (){ [Object] $p = [Console.Window]::GetConsoleWindow(); [Object] $dummy = [Console.Window]::ShowWindow($p,0); } #0 hide (also by PowerShell.exe -WindowStyle Hidden)
function ConsoleShow                          (){ [Object] $p = [Console.Window]::GetConsoleWindow(); [Object] $dummy = [Console.Window]::ShowWindow($p,5); } #5 nohide
function ConsoleRestore                       (){ [Object] $p = [Console.Window]::GetConsoleWindow(); [Object] $dummy = [Console.Window]::ShowWindow($p,1); } #1 show
function ConsoleMinimize                      (){ [Object] $p = [Console.Window]::GetConsoleWindow(); [Object] $dummy = [Console.Window]::ShowWindow($p,6); } #6 minimize
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
                                                [Object] $w = $Host.ui.RawUI;
                                                $w.windowtitle = "$PSCommandPath $(switch(ProcessIsRunningInElevatedAdminMode){($true){'- Elevated Admin Mode'}default{'';}})";
                                                $w.foregroundcolor = "Gray";
                                                $w.backgroundcolor = switch(ProcessIsRunningInElevatedAdminMode){($true){"DarkMagenta"}default{"DarkBlue";}};
                                                # for future use: $ = $host.PrivateData; $.VerboseForegroundColor = "White"; $.VerboseBackgroundColor = "Blue";
                                                #   $.WarningForegroundColor = "Yellow"; $.WarningBackgroundColor = "DarkGreen"; $.ErrorForegroundColor = "White"; $.ErrorBackgroundColor = "Red";
                                                # Set buffer sizes before setting window sizes otherwise PSArgumentOutOfRangeException: Window cannot be wider than the screen buffer.
                                                # On ise or jobs calling [System.Console]::WindowWidth would throw (System.IO.IOException: Das Handle ist ungültig) so we avoid accessing it.
                                                $w = $Host.ui.RawUI; # refresh values, maybe meanwhile windows was resized
                                                [Object] $buf = $w.buffersize;
                                                $buf.Height = 9999;
                                                if( $null -ne $Host.ui.RawUI.WindowSize ){
                                                  $buf.Width = [math]::max(300,[Int32]$Host.ui.RawUI.WindowSize.Width);
                                                }
                                                try{
                                                  $w.buffersize = $buf;
                                                }catch{ # seldom we got: PSArgumentOutOfRangeException: Cannot set the buffer size because the size specified is too large or too small.
                                                  OutWarning "Warning: Ignore setting buffersize failed because $($_.Exception.Message)";
                                                }
                                                $w = $Host.ui.RawUI; # refresh values, maybe meanwhile windows was resized
                                                if( $null -ne $w.WindowSize ){ # is null in case of powershell-ISE
                                                  [Object] $m = $w.windowsize; $m.Height = 48; $m.Width = 150;
                                                  # avoid: PSArgumentOutOfRangeException: Window cannot be wider than 147. Parameter name: value.Width Actual value was 150.
                                                  #        PSArgumentOutOfRangeException: Window cannot be taller than 47. Parameter name: value.Height Actual value was 48.
                                                  $m.Width  = [math]::min($m.Width ,$Host.ui.RawUI.BufferSize.Width);
                                                  $m.Width  = [math]::min($m.Width ,$w.MaxWindowSize.Width);
                                                  $m.Width  = [math]::min($m.Width ,$w.MaxPhysicalWindowSize.Width);
                                                  $m.Height = [math]::min($m.Height,$host.ui.RawUI.BufferSize.Height);
                                                  $m.Height = [math]::min($m.Height,$w.MaxWindowSize.Height);
                                                  $m.Height = [math]::min($m.Height,$w.MaxPhysicalWindowSize.Height);
                                                  $w.windowsize = $m;
                                                  ConsoleSetPos 40 40; # little indended from top and left
                                                }
                                                $script:consoleSetGuiProperties_DoneOnce = $true; }
function OutGetTsPrefix                       ( [Boolean] $forceTsPrefix = $false ){
                                                return [String] $(switch($forceTsPrefix -or $global:ModeOutputWithTsPrefix){($true){"$(DateTimeNowAsStringIso) "}default{""}}); }
function OutStringInColor                     ( [String] $color, [String] $line, [Boolean] $noNewLine = $true ){
                                                # NoNewline is used because on multi threading usage, line text and newline can be interrupted between.
                                                Write-Host -ForegroundColor $color -NoNewline:$noNewLine $line; }
function OutInfo                              ( [String] $line ){ OutStringInColor $global:InfoLineColor "$(OutGetTsPrefix)$line$([Environment]::NewLine)"; }
function OutSuccess                           ( [String] $line ){ OutStringInColor Green "$(OutGetTsPrefix)$line$([Environment]::NewLine)"; }
function OutWarning                           ( [String] $line, [Int32] $indentLevel = 1 ){
                                                OutStringInColor Yellow "$(OutGetTsPrefix)$("  "*$indentLevel)$line$([Environment]::NewLine)"; }
function OutError                             ( [String] $line ){
                                                $Host.UI.WriteErrorLine("$(OutGetTsPrefix)$line"); } # Writes a stderr line in red.
function OutProgress                          ( [String] $line, [Int32] $indentLevel = 1 ){
                                                # Used for tracing changing actions, otherwise use OutVerbose.
                                                if( $global:ModeHideOutProgress ){ return; }
                                                OutStringInColor Gray "$(OutGetTsPrefix)$("  "*$indentLevel)$line$([Environment]::NewLine)"; }
function OutProgressText                      ( [String] $str ){
                                                if( $global:ModeHideOutProgress ){ return; }
                                                OutStringInColor Gray "$(OutGetTsPrefix)$str"; }
function OutVerbose                           ( [String] $line ){
                                                # Output depends on $VerbosePreference, used in general for tracing some important arguments or command results mainly of IO-operations.
                                                Write-Verbose -Message "$(DateTimeNowAsStringIso) $line"; }
function OutDebug                             ( [String] $line ){
                                                # Output depends on $DebugPreference, used in general for tracing internal states which can produce a lot of lines.
                                                Write-Debug   -Message "$(DateTimeNowAsStringIso) $line"; }
function OutClear                             (){ Clear-Host; }
function OutStartTranscriptInTempDir          ( [String] $name = "MnCommonPsToolLib", [Boolean] $useHHMMSS = $false ){
                                                 # append everything from console to logfile, return full path name of logfile. Optionally use precision by seconds for file name.
                                                if( $name -eq "" ){ $name = "MnCommonPsToolLib"; }
                                                [String] $pattern = "yyyy yyyy-MM yyyy-MM-dd";
                                                if( $useHHMMSS ){ $pattern += "_HH'h'mm'm'SS's'"; }
                                                [String] $f = "$env:TEMP/tmp/$name/$((DateTimeNowAsStringIso $pattern).Replace(" ","/")).$name.txt"; # works for windows and linux
                                                Start-Transcript -Path $f -Append -IncludeInvocationHeader | Out-Null;
                                                return [String] $f; }
function OutStopTranscript                    (){ Stop-Transcript; }
function StdInAssertAllowInteractions         (){ if( $global:ModeDisallowInteractions ){
                                                throw [Exception] "Cannot read for input because all interactions are disallowed, either caller should make sure variable ModeDisallowInteractions is false or he should not call an input method."; } }
function StdInReadLine                        ( [String] $line ){ OutStringInColor "Cyan" $line; StdInAssertAllowInteractions; return [String] (Read-Host); }
function StdInReadLinePw                      ( [String] $line ){ OutStringInColor "Cyan" $line; StdInAssertAllowInteractions; return [System.Security.SecureString] (Read-Host -AsSecureString); }
function StdInAskForEnter                     (){ [String] $dummyLine = StdInReadLine "Press Enter to Exit"; }
function StdInAskForBoolean                   ( [String] $msg = "Enter Yes or No (y/n)?", [String] $strForYes = "y", [String] $strForNo = "n" ){
                                                 while($true){ OutStringInColor "Magenta" $msg;
                                                 [String] $answer = StdInReadLine ""; if( $answer -eq $strForYes ){ return [Boolean] $true ; }
                                                 if( $answer -eq $strForNo  ){ return [Boolean] $false; } } }
function StdInWaitForAKey                     (){ StdInAssertAllowInteractions; $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null; } # does not work in powershell-ise, so in general do not use it, use StdInReadLine()
function StdOutLine                           ( [String] $line ){ $Host.UI.WriteLine($line); } # Writes an stdout line in default color, normally not used, rather use OutInfo because it classifies kind of output.
function StdOutRedLineAndPerformExit          ( [String] $line, [Int32] $delayInSec = 1 ){ #
                                                OutError $line; if( $global:ModeDisallowInteractions ){ ProcessSleepSec $delayInSec; }else{ StdInReadLine "Press Enter to Exit"; }; Exit 1; }
function StdErrHandleExc                      ( [System.Management.Automation.ErrorRecord] $er, [Int32] $delayInSec = 1 ){
                                                # Output full error information in red lines and then either wait for pressing enter or otherwise
                                                # if interactions are globally disallowed then wait for specified delay.
                                                [String] $msg = "$(StringFromErrorRecord $er)";
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
                                                ScriptResetRc; [String[]] $modes = @()+($mode -split "," |
                                                  Where-Object{$null -ne $_} | ForEach-Object{ $_.Trim() });
                                                [String[]] $availableModes = @( "DoRequestAtBegin", "NoRequestAtBegin", "NoWaitAtEnd", "MinimizeConsole" );
                                                [Boolean] $modesAreValid = ((@()+($modes | Where-Object{$null -ne $_} | Where-Object{ $availableModes -notcontains $_})).Count -eq 0 );
                                                Assert $modesAreValid "StdOutBegMsgCareInteractiveMode was called with unknown mode=`"$mode`", expected one of ($availableModes).";
                                                $global:ModeNoWaitForEnterAtEnd = $modes -contains "NoWaitAtEnd";
                                                if( -not $global:ModeDisallowInteractions -and $modes -notcontains "NoRequestAtBegin" ){ StdInAskForAnswerWhenInInteractMode; }
                                                if( $modes -contains "MinimizeConsole" ){ OutProgress "Minimize console"; ProcessSleepSec 0; ConsoleMinimize; } }
function StdInAskForAnswerWhenInInteractMode  ( [String] $line = "Are you sure (y/n)? ", [String] $expectedAnswer = "y" ){
                                                # works case insensitive; is ignored if interactions are suppressed by global var ModeDisallowInteractions; will abort if not expected answer.
                                                if( -not $global:ModeDisallowInteractions ){ [String] $answer = StdInReadLine $line; if( $answer -ne $expectedAnswer ){ StdOutRedLineAndPerformExit "Aborted"; } } }
function StdInAskAndAssertExpectedAnswer      ( [String] $line = "Are you sure (y/n)? ", [String] $expectedAnswer = "y" ){ # works case insensitive
                                                [String] $answer = StdInReadLine $line; if( $answer -ne $expectedAnswer ){ StdOutRedLineAndPerformExit "Aborted"; } }
function StdOutEndMsgCareInteractiveMode      ( [Int32] $delayInSec = 1 ){
                                                if( $global:ModeDisallowInteractions -or $global:ModeNoWaitForEnterAtEnd ){
                                                  OutSuccess "Ok, done. Ending in $delayInSec second(s)."; ProcessSleepSec $delayInSec;
                                                }else{ OutSuccess "Ok, done. Press Enter to Exit;"; StdInReadLine; } }
function Assert                               ( [Boolean] $cond, [String] $failReason = "condition is false." ){
                                                if( -not $cond ){ throw [Exception] "Assertion failed because $failReason"; } }
function AssertIsFalse                        ( [Boolean] $cond, [String] $failReason = "" ){
                                                if( $cond ){ throw [Exception] "Assertion-Is-False failed because $failReason"; } }
function AssertNotEmpty                       ( [String] $s, [String] $varName ){
                                                Assert ($s -ne "") "not allowed empty string for $varName."; }
function AssertRcIsOk                         ( [String[]] $linesToOutProgress = $null, [Boolean] $useLinesAsExcMessage = $false, [String] $logFileToOutProgressIfFailed = "", [String] $encodingIfNoBom = "Default" ){
                                                # Can also be called with a single string; only nonempty progress lines are given out.
                                                [Int32] $rc = ScriptGetAndClearLastRc;
                                                if( $rc -ne 0 ){
                                                  if( -not $useLinesAsExcMessage ){ $linesToOutProgress | Where-Object{ StringIsFilled $_ } | ForEach-Object{ OutProgress $_ }; }
                                                  [String] $msg = "Last operation failed [rc=$rc]. ";
                                                  if( $useLinesAsExcMessage ){
                                                    $msg = $(switch($rc -eq 1 -and $out -ne ""){($true){""}default{$msg}}) + ([String]$linesToOutProgress).Trim();
                                                  }
                                                  try{
                                                    OutProgress "Dump of logfile=$($logFileToOutProgressIfFailed):";
                                                    Get-Content -Encoding $encodingIfNoBom -LiteralPath $logFileToOutProgressIfFailed |
                                                      Where-Object{$null -ne $_} | ForEach-Object{ OutProgress "  $_"; }
                                                  }catch{
                                                    OutVerbose "Ignoring problems on reading $logFileToOutProgressIfFailed failed because $($_.Exception.Message)";
                                                  }
                                                  throw [Exception] $msg;
                                                } }
function ScriptImportModuleIfNotDone          ( [String] $moduleName ){ if( -not (Get-Module $moduleName) ){
                                                OutProgress "Import module $moduleName (can take some seconds on first call)";
                                                Import-Module -NoClobber $moduleName -DisableNameChecking; } }
function ScriptGetCurrentFunc                 (){ return [String] ((Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name); }
function ScriptGetCurrentFuncName             (){ return [String] ((Get-PSCallStack)[2].Position); }
function ScriptGetAndClearLastRc              (){ [Int32] $rc = 0;
                                                if( ((test-path "variable:LASTEXITCODE") -and $null -ne $LASTEXITCODE <# if no windows command was done then $LASTEXITCODE is null #> -and $LASTEXITCODE -ne 0) -or -not $? ){ $rc = $LASTEXITCODE; ScriptResetRc; }
                                                return [Int32] $rc; }
function ScriptResetRc                        (){ $error.clear(); $global:LASTEXITCODE = 0; $error.clear(); AssertRcIsOk; } # reset $LASTEXITCODE (ERRORLEVEL to 0); non-portable alternative: & "cmd.exe" "/C" "EXIT 0"
function ScriptNrOfScopes                     (){ [Int32] $i = 1; while($true){
                                                try{ Get-Variable null -Scope $i -ValueOnly -ErrorAction SilentlyContinue | Out-Null; $i++;
                                                }catch{ <# ex: System.Management.Automation.PSArgumentOutOfRangeException #> return [Int32] ($i-1); } } }
function ScriptGetProcessCommandLine          (){ return [String] ([Environment]::commandline); } # ex: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "& \"C:\myscript.ps1\"";  or  "C:\Program Files\PowerShell\7\pwsh.dll" -nologo
function ScriptGetDirOfLibModule              (){ return [String] $PSScriptRoot ; } # Get dir       of this script file of this function or empty if not from a script; alternative: (Split-Path -Parent -Path ($script:MyInvocation.MyCommand.Path))
function ScriptGetFileOfLibModule             (){ return [String] $PSCommandPath; } # Get full path of this script file of this function or empty if not from a script. alternative1: try{ return [String] (Get-Variable MyInvocation -Scope 1 -ValueOnly).MyCommand.Path; }catch{ return [String] ""; }  alternative2: $script:MyInvocation.MyCommand.Path
function ScriptGetCallerOfLibModule           (){ return [String] $MyInvocation.PSCommandPath; } # Result can be empty or implicit module if called interactive. alternative for dir: $MyInvocation.PSScriptRoot.
function ScriptGetTopCaller                   (){ # return the command line with correct doublequotes.
                                                # Result can be empty or implicit module if called interactive.
                                                # usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
                                                [String] $f = $global:MyInvocation.MyCommand.Definition.Trim();
                                                if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return [String] ""; }
                                                if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
                                                if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
                                                return [String] $f; }
function ScriptIsProbablyInteractive          (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim();
                                                # Result can be empty or implicit module if called interactive.
                                                # usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
                                                return [Boolean] $f -eq "" -or $f -eq "ScriptGetTopCaller" -or -not $f.StartsWith("&"); }
function StreamAllProperties                  (){ $input | Select-Object *; }
function StreamAllPropertyTypes               (){ $input | Get-Member -Type Property; }
function StreamFilterWhitespaceLines          (){ $input | Where-Object{ StringIsFilled $_ }; }
function StreamToNull                         (){ $input | Out-Null; }
function StreamToString                       (){ $input | Out-String -Width 999999999; }
function StreamToStringDelEmptyLeadAndTrLines (){ $input | Out-String -Width 999999999 | ForEach-Object{ $_ -replace "[ \f\t\v]]+\r\n","\r\n" -replace "^(\r\n)+","" -replace "(\r\n)+$","" }; }
function StreamToGridView                     (){ $input | Out-GridView -Title "TableData"; }
function StreamToCsvStrings                   (){ $input | ConvertTo-Csv -NoTypeInformation; }
                                                # Note: For a simple string array as ex: @("one","two")|StreamToCsvStrings  it results with 3 lines "Length","3","3".
function StreamToJsonString                   (){ $input | ConvertTo-Json -Depth 100; }
function StreamToJsonCompressedString         (){ $input | ConvertTo-Json -Depth 100 -Compress; }
function StreamToXmlString                    (){ $input | ConvertTo-Xml -Depth 999999999 -As String -NoTypeInformation; }
function StreamToHtmlTableStrings             (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As Table; }
function StreamToHtmlListStrings              (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As List; }
function StreamToListString                   (){ $input | Format-List -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToFirstPropMultiColumnString   (){ $input | Format-Wide -AutoSize -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToCsvFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){
                                                # If overwrite is false then nothing done if target already exists.
                                                $input | Export-Csv -Force:$overwrite -NoClobber:$(-not $overwrite) -NoTypeInformation -Encoding $encoding -Path (FsEntryEsc $file); }
function StreamToXmlFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){
                                                # If overwrite is false then nothing done if target already exists.
                                                $input | Export-Clixml -Force:$overwrite -NoClobber:$(-not $overwrite) -Depth 999999999 -Encoding $encoding -Path (FsEntryEsc $file); }
function StreamToDataRowsString               ( [String[]] $propertyNames = @() ){ # no header, only rows.
                                                if( $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); }
                                                $input | Format-Table -Wrap -Force -autosize -HideTableHeaders $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToTableString                  ( [String[]] $propertyNames = @() ){
                                                # Note: For a simple string array as ex: @("one","two")|StreamToTableString  it results with 4 lines "Length","------","     3","     3".
                                                if( $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); }
                                                $input | Format-Table -Wrap -Force -autosize $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToFile                         ( [String] $file, [Boolean] $overwrite = $true, [String] $encoding = "UTF8" ){
                                                # Will create path of file. overwrite does ignore readonly attribute.
                                                OutProgress "WriteFile $file"; FsEntryCreateParentDir $file;
                                                $input | Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -LiteralPath $file; }
function StreamFromCsvStrings                 ( [Char] $delimiter = ',' ){ $input | ConvertFrom-Csv -Delimiter $delimiter; }
function ProcessIsLesserEqualPs5              (){ return [Boolean] ($PSVersionTable.PSVersion.Major -le 5); }
function ProcessPsExecutable                  (){ return [String] $(switch((ProcessIsLesserEqualPs5)){ $true{"powershell.exe"} default{"pwsh"}}); }
function ProcessIsRunningInElevatedAdminMode  (){ if( (OsIsWindows) ){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
                                                  return [Boolean] ("$env:SUDO_USER" -ne ""); }
function ProcessAssertInElevatedAdminMode     (){ Assert (ProcessIsRunningInElevatedAdminMode) "requires to be in elevated admin mode"; }
function ProcessRestartInElevatedAdminMode    (){ if( (ProcessIsRunningInElevatedAdminMode) ){ return; }
                                                # ex: "C:\myscr.ps1" or if interactive then statement name ex: "ProcessRestartInElevatedAdminMode"
                                                [String] $cmd = @( (ScriptGetTopCaller) ) + $global:ArgsForRestartInElevatedAdminMode;
                                                if( $global:ModeDisallowInteractions ){
                                                  [String] $msg = "Script `"$cmd`" is currently not in elevated admin mode and function ProcessRestartInElevatedAdminMode was called ";
                                                  $msg += "but currently the mode ModeDisallowInteractions=$global:ModeDisallowInteractions, ";
                                                  $msg += "and so restart will not be performed. Now it will continue but it probably will fail.";
                                                  OutWarning "Warning: $msg";
                                                }else{
                                                  $cmd = $cmd -replace "`"","`"`"`""; # see https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.arguments
                                                  $cmd = $(switch((ProcessIsLesserEqualPs5)){ $true{"& `"$cmd`""} default{"-Command `"$cmd`""}});
                                                  $cmd = $(switch(ScriptIsProbablyInteractive){ ($true){"-NoExit -NoLogo "} default{""} }) + $cmd;
                                                  OutProgress "Not running in elevated administrator mode so elevate current script and exit:";
                                                  OutProgress "  Start-Process -Verb RunAs -FilePath $(ProcessPsExecutable) -ArgumentList $cmd";
                                                  Start-Process -Verb "RunAs" -FilePath (ProcessPsExecutable) -ArgumentList $cmd;
                                                  # ex: InvalidOperationException: This command cannot be run due to the error: Der Vorgang wurde durch den Benutzer abgebrochen.
                                                  OutProgress "Exiting in 10 seconds";
                                                  ProcessSleepSec 10;
                                                  [Environment]::Exit("0"); # Note: 'Exit 0;' would only leave the last '. mycommand' statement.
                                                  throw [Exception] "Exit done, but it did not work, so it throws now an exception.";
                                                } }
function ProcessFindExecutableInPath          ( [String] $exec ){ # Return full path or empty if not found.
                                                if( $exec -eq "" ){ return [String] ""; }
                                                [Object] $p = (Get-Command $exec -ErrorAction SilentlyContinue);
                                                if( $null -eq $p ){ return [String] ""; } return [String] $p.Source; }
function ProcessGetCurrentThreadId            (){ return [Int32] [Threading.Thread]::CurrentThread.ManagedThreadId; }
function ProcessListRunnings                  (){ return [Object[]] (@()+(Get-Process * | Where-Object{$null -ne $_} |
                                                    Where-Object{ $_.Id -ne 0 } | Sort-Object ProcessName)); }
function ProcessListRunningsFormatted         (){ return [Object[]] (@()+( ProcessListRunnings | Select-Object Name, Id,
                                                    @{Name="CpuMSec";Expression={[Decimal]::Floor($_.TotalProcessorTime.TotalMilliseconds).ToString().PadLeft(7,' ')}},
                                                    StartTime, @{Name="Prio";Expression={($_.BasePriority)}}, @{Name="WorkSet";Expression={($_.WorkingSet64)}}, Path |
                                                    StreamToTableString  )); }
function ProcessListRunningsAsStringArray     (){ return [String[]] (StringSplitIntoLines (@()+(ProcessListRunnings |
                                                    Where-Object{$null -ne $_} |
                                                    Format-Table -auto -HideTableHeaders " ",ProcessName,ProductVersion,Company |
                                                    StreamToStringDelEmptyLeadAndTrLines))); }
function ProcessIsRunning                     ( [String] $processName ){ return [Boolean] ($null -ne (Get-Process -ErrorAction SilentlyContinue ($processName -replace ".exe",""))); }
function ProcessCloseMainWindow               ( [String] $processName ){ # enter name without exe extension.
                                                while( (ProcessIsRunning $processName) ){
                                                  Get-Process $processName | ForEach-Object {
                                                    OutProgress "CloseMainWindows `"$processName`"";
                                                    $_.CloseMainWindow() | Out-Null;
                                                    ProcessSleepSec 1; }; } }
function ProcessKill                          ( [String] $processName ){ # kill all with the specified name, note if processes are not from owner then it requires to previously call ProcessRestartInElevatedAdminMode
                                                [System.Diagnostics.Process[]] $p = Get-Process ($processName -replace ".exe","") -ErrorAction SilentlyContinue;
                                                if( $null -ne $p ){ OutProgress "ProcessKill $processName"; $p.Kill(); } }
function ProcessSleepSec                      ( [Int32] $sec ){ Start-Sleep -Seconds $sec; }
function ProcessListInstalledAppx             (){ if( ! (OsIsWindows) ){ return [String[]] @(); }
                                                  if( ! (ProcessIsLesserEqualPs5) ){
                                                    # 2023-03: Problems using Get-AppxPackage in PS7, see end of: https://github.com/PowerShell/PowerShell/issues/13138
                                                    Import-Module -Name Appx -UseWindowsPowerShell 3> $null;
                                                      # We suppress the output: WARNING: Module Appx is loaded in Windows PowerShell using WinPSCompatSession remoting session; 
                                                      #   please note that all input and output of commands from this module will be deserialized objects. 
                                                      #   If you want to load this module into PowerShell please use 'Import-Module -SkipEditionCheck' syntax.
                                                  }
                                                  return [String[]] (@()+(Get-AppxPackage | Where-Object{$null -ne $_} |
                                                    ForEach-Object{ "$($_.PackageFullName)" } | Sort)); }
function ProcessGetCommandInEnvPathOrAltPaths ( [String] $commandNameOptionalWithExtension, [String[]] $alternativePaths = @(), [String] $downloadHintMsg = ""){
                                                [System.Management.Automation.CommandInfo] $cmd = Get-Command -CommandType Application -Name $commandNameOptionalWithExtension -ErrorAction SilentlyContinue | Select-Object -First 1;
                                                if( $null -ne $cmd ){ return [String] $cmd.Path; }
                                                foreach( $d in $alternativePaths ){
                                                  [String] $f = (Join-Path $d $commandNameOptionalWithExtension);
                                                  if( (FileExists $f) ){ return [String] $f; } }
                                                throw [Exception] "$(ScriptGetCurrentFunc): commandName=`"$commandNameOptionalWithExtension`" was wether found in env-path=`"$env:PATH`" nor in alternativePaths=`"$alternativePaths`". $downloadHintMsg"; }
function ProcessStart                         ( [String] $cmd, [String[]] $cmdArgs = @(), [Boolean] $careStdErrAsOut = $false, [Boolean] $traceCmd = $false ){
                                                # Mainly intended for starting a program with a window,
                                                # but is also used for starting a command in path when arguments are provided in an array.
                                                # The advantages in contrast of using the call operator (&) are:
                                                # - you do not have to call AssertRcIsOk afterwards
                                                # - empty-string parameters can be passed to the calling program
                                                # - it has no side effects if the parameters contains special characters as quotes, double-quotes or $-characters.
                                                # - the calling command can easy be written to output for tracing
                                                # Returns output as a single string.
                                                # As working directory the current dir is taken which makes it compatible to call operator.
                                                # If careStdErrAsOut is true then stderr will be appended to stdout and stderr is set to empty which means this leads not to an error.
                                                # If exitCode is not 0 or stderr is not empty then it throws.
                                                # But if ErrorActionPreference is Continue then stderr is appended to output and not error is produced.
                                                # In case and error is throwed then it will first OutProgress the non empty stdout lines.
                                                # You can use StringSplitIntoLines on output to get it as lines.
                                                # Internally the stdout and stderr are stored to variables and not temporary files to avoid file system IO.
                                                # Important Note: The original Process.Start(ProcessStartInfo) cannot run a ps1 file
                                                #   even if $env:PATHEXT contains the PS1 because it does not precede it with (powershell.exe -File) or (pwsh -File).
                                                #   Our solution will do this by automatically use powershell.exe -NoLogo -File  or  pwsh -NoLogo -File  before the ps1 file
                                                #   and it surrounds the arguments correctly by double-quotes to support blanks in any argument.
                                                # There is a special handling of the commandline as descripted in "Parsing C++ command-line arguments"
                                                # https://docs.microsoft.com/en-us/cpp/cpp/main-function-command-line-args
                                                # - Arguments are delimited by white space, which is either a space or a tab.
                                                # - The first argument (argv[0]) is treated specially. It represents the program name.
                                                #   Because it must be a valid pathname, parts surrounded by double quote marks (") are allowed.
                                                #   The double quote marks aren't included in the argv[0] output.
                                                #   The parts surrounded by double quote marks prevent interpretation of a space or tab character
                                                #   as the end of the argument. The later rules in this list don't apply.
                                                # - A string surrounded by double quote marks is interpreted as a single argument,
                                                #   which may contain white-space characters. A quoted string can be embedded in an argument.
                                                #   The caret (^) isn't recognized as an escape character or delimiter.
                                                #   Within a quoted string, a pair of double quote marks is interpreted as a single escaped double quote mark.
                                                #   If the command line ends before a closing double quote mark is found,
                                                #   then all the characters read so far are output as the last argument.
                                                # - A double quote mark preceded by a backslash (\") is interpreted as a literal double quote mark (").
                                                # - Backslashes are interpreted literally, unless they immediately precede a double quote mark.
                                                # - If an even number of backslashes is followed by a double quote mark,
                                                #   then one backslash (\) is placed in the argv array for every pair of backslashes (\\),
                                                #   and the double quote mark (") is interpreted as a string delimiter.
                                                # - If an odd number of backslashes is followed by a double quote mark,
                                                #   then one backslash (\) is placed in the argv array for every pair of backslashes (\\).
                                                #   The double quote mark is interpreted as an escape sequence by the remaining backslash,
                                                #   causing a literal double quote mark (") to be placed in argv.
                                                AssertRcIsOk;
                                                [String] $exec = (Get-Command $cmd).Path;
                                                [Boolean] $isPs = $exec.EndsWith(".ps1");
                                                [String] $traceInfo = "`"$cmd`" $(StringArrayDblQuoteItems $cmdArgs)";
                                                if( $isPs ){
                                                  $cmdArgs = @() + ($cmdArgs | Where-Object { $null -ne $_ } | ForEach-Object {
                                                      $_.Replace("\\","\").Replace("\`"","`""); });
                                                  $traceInfo = "$((ProcessPsExecutable)) -File `"$cmd`" $(StringArrayDblQuoteItems $cmdArgs)";
                                                  $cmdArgs = @( "-NoLogo", "-File", "`"$exec`"" ) + $cmdArgs;
                                                  $exec = (Get-Command (ProcessPsExecutable)).Path;
                                                }else{
                                                  $cmdArgs = @() + (StringArrayDblQuoteItems $cmdArgs);
                                                }
                                                if( $traceCmd ){ OutProgress $traceInfo; }
                                                [Int32] $i = 1;
                                                [String] $verboseText = "`"$exec`" " + ($cmdArgs | Where-Object { $null -ne $_ } | ForEach-Object { "Arg[$i]=`"$_`""; $i += 1; } );
                                                OutVerbose "ProcessStart $verboseText";
                                                $prInfo = New-Object System.Diagnostics.ProcessStartInfo;
                                                $prInfo.FileName = $exec;
                                                $prInfo.Arguments = $cmdArgs;
                                                $prInfo.CreateNoWindow = $true;
                                                $prInfo.WindowStyle = "Normal";
                                                $prInfo.UseShellExecute = $false; <# UseShellExecute must be false when redirect io #>
                                                $prInfo.RedirectStandardError = $true; $prInfo.RedirectStandardOutput = $true;
                                                $prInfo.RedirectStandardInput = $false;
                                                $prInfo.WorkingDirectory = (Get-Location);
                                                $pr = New-Object System.Diagnostics.Process; $pr.StartInfo = $prInfo;
                                                # Note: We can not simply call WaitForExit() and after that read stdout and stderr streams because it could hang endless.
                                                # The reason is the called program can produce child processes which can inherit redirect handles which can be still open
                                                # while a subprocess exited and so WaitForExit which does wait for EOFs can block forever.
                                                # See https://stackoverflow.com/questions/26713373/process-waitforexit-doesnt-return-even-though-process-hasexited-is-true
                                                # Uses async read of stdout and stderr to avoid deadlocks.
                                                [System.Text.StringBuilder] $bufStdOut = New-Object System.Text.StringBuilder;
                                                [System.Text.StringBuilder] $bufStdErr = New-Object System.Text.StringBuilder;
                                                $actionReadStdOut = { if( StringIsFilled $Event.SourceEventArgs.Data ){ [void]$Event.MessageData.AppendLine($Event.SourceEventArgs.Data); } };
                                                $actionReadStdErr = { if( StringIsFilled $Event.SourceEventArgs.Data ){ [void]$Event.MessageData.AppendLine($Event.SourceEventArgs.Data); } };
                                                [Object] $eventStdOut = Register-ObjectEvent -InputObject $pr -EventName OutputDataReceived -Action $actionReadStdOut -MessageData $bufStdOut;
                                                [Object] $eventStdErr = Register-ObjectEvent -InputObject $pr -EventName ErrorDataReceived  -Action $actionReadStdErr -MessageData $bufStdErr;
                                                [void]$pr.Start();
                                                $pr.BeginOutputReadLine();
                                                $pr.BeginErrorReadLine();
                                                $pr.WaitForExit();
                                                [Int32] $exitCode = $pr.ExitCode;
                                                $pr.Dispose();
                                                Unregister-Event -SourceIdentifier $eventStdOut.Name; $eventStdOut.Dispose();
                                                Unregister-Event -SourceIdentifier $eventStdErr.Name; $eventStdErr.Dispose();
                                                [String] $out = $bufStdOut.ToString();
                                                [String] $err = $bufStdErr.ToString().Trim(); if( $err -ne "" ){ $err = [Environment]::NewLine + $err; }
                                                [Boolean] $doThrow = $exitCode -ne 0 -or ($err -ne "" -and -not $careStdErrAsOut);
                                                if( $global:ErrorActionPreference -ne "Continue" -and $doThrow ){
                                                  if( -not $traceCmd ){ OutProgress $traceInfo; } # in case of an error output command line, if not yet done
                                                  StringSplitIntoLines $out | Where-Object{$null -ne $_} |
                                                    Where-Object{ StringIsFilled $_ } |
                                                    ForEach-Object{ OutProgress "  $_"; };
                                                  [String] $msgPrg = "ProcessStart";
                                                  if( $careStdErrAsOut ){ $msgPrg += "-careStdErrAsOut"; }
                                                  [String] $msg = "$msgPrg($traceInfo) failed with rc=$exitCode $err";
                                                  throw [Exception] $msg;
                                                }
                                                $out += $err;
                                                return [String] $out; }
function ProcessEnvVarGet                     ( [String] $name, [System.EnvironmentVariableTarget] $scope = [System.EnvironmentVariableTarget]::Process ){
                                                return [String] [Environment]::GetEnvironmentVariable($name,$scope); }
function ProcessEnvVarSet                     ( [String] $name, [String] $val, [System.EnvironmentVariableTarget] $scope = [System.EnvironmentVariableTarget]::Process ){
                                                 # Scope: MACHINE, USER, PROCESS.
                                                 OutProgress "SetEnvironmentVariable scope=$scope $name=`"$val`"";
                                                 [Environment]::SetEnvironmentVariable($name,$val,$scope); }
function ProcessRemoveAllAlias                ( [String[]] $excludeAliasNames = @(), [Boolean] $doTrace = $false ){
                                                # remove all existing aliases on any levels (local, script, private, and global).
                                                # We recommend to exclude the followings: @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir").
                                                # In powershell v5 (also v7) there are a predefined list of about 180 aliases in each session which cannot be avoided.
                                                # This is very bad because there are also aliases defined as curl->Invoke-WebRequest or wget->Invoke-WebRequest which are incompatible to their known tools.
                                                # Also the Invoke-ScriptAnalyzer results with a warning as example:
                                                #   PSAvoidUsingCmdletAliases 'cd' is an alias of 'Set-Location'. Alias can introduce possible problems and make scripts hard to maintain.
                                                #   Please consider changing alias to its full content.
                                                # All aliases can be listed by:
                                                #   powershell -NoProfile { Get-Alias | Select-Object Name, Definition, Visibility, Options, Module | StreamToTableString }
                                                # example: ProcessRemoveAllAlias @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir");
                                                # example: ProcessRemoveAllAlias @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir","select","where","foreach");
                                                [String[]] $removedAliasNames = @();
                                                @(1,2,3) | ForEach-Object{ Get-Alias | Select-Object Name | ForEach-Object{ $_.Name } |
                                                  Where-Object { $_ -notin $excludeAliasNames } |
                                                  Where-Object { Test-Path "Alias:$_" } | ForEach-Object{ $removedAliasNames += $_; Remove-Item -Force "Alias:$_"; }; }
                                                $removedAliasNames = $removedAliasNames | Select-Object -Unique | Sort-Object;
                                                if( $doTrace -and $removedAliasNames.Count -gt 0 ){
                                                  OutProgress "Removed all existing $($removedAliasNames.Count) alias except [$excludeAliasNames]."; } }
function HelpHelp                             (){ Get-Help     | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllVariables               (){ Get-Variable | Sort-Object Name | ForEach-Object{ OutInfo "$($_.Name.PadRight(32)) $($_.Value)"; } } # Select-Object Name, Value | StreamToListString
function HelpListOfAllAliases                 (){ Get-Alias    | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllCommands                (){ Get-Command  | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllModules                 (){ Get-Module -ListAvailable | Sort-Object Name | Select-Object Name, ModuleType, Version, ExportedCommands; }
function HelpListOfAllExportedCommands        (){ (Get-Module -ListAvailable).ExportedCommands.Values | Sort-Object Name | Select-Object Name, ModuleName; }
function HelpGetType                          ( [Object] $obj ){ return [String] $obj.GetType(); }
function OsPsVersion                          (){ return [String] (""+$Host.Version.Major+"."+$Host.Version.Minor); } # alternative: $PSVersionTable.PSVersion.Major
function OsIsWindows                          (){ return [Boolean] ([System.Environment]::OSVersion.Platform -eq "Win32NT"); }
                                                # Example: Win10Pro: Version="10.0.19044.0"
                                                # Alternative: "$($env:WINDIR)" -ne ""; In PS6 and up you can use: $IsMacOS, $IsLinux, $IsWindows. 
                                                # for future: function OsIsLinux(){ return [Boolean] ([System.Environment]::OSVersion.Platform -eq "Unix"); } # example: Ubuntu22: Version="5.15.0.41"
function OsPsModulePathList                   (){ return [String[]] ([Environment]::GetEnvironmentVariable("PSModulePath", "Machine").
                                                  Split(";",[System.StringSplitOptions]::RemoveEmptyEntries)); }
function OsPsModulePathContains               ( [String] $dir ){ # ex: "D:\MyGitRoot\MyGitAccount\MyPsLibRepoName"
                                                [String[]] $a = (OsPsModulePathList | ForEach-Object{ FsEntryRemoveTrailingDirSep $_ });
                                                return [Boolean] ($a -contains (FsEntryRemoveTrailingDirSep $dir)); }
function OsPsModulePathAdd                    ( [String] $dir ){ if( OsPsModulePathContains $dir ){ return; }
                                                OsPsModulePathSet ((OsPsModulePathList)+@( (FsEntryRemoveTrailingDirSep $dir) )); }
function OsPsModulePathDel                    ( [String] $dir ){ OsPsModulePathSet (OsPsModulePathList |
                                                Where-Object{ (FsEntryRemoveTrailingDirSep $_) -ne (FsEntryRemoveTrailingDirSep $dir) }); }
function OsPsModulePathSet                    ( [String[]] $pathList ){ [Environment]::SetEnvironmentVariable("PSModulePath", ($pathList -join ";")+";", "Machine"); }
function PrivAclRegRightsToString              ( [System.Security.AccessControl.RegistryRights] $r ){
                                                [String] $result = "";
                                                # Ref: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registryrights?view=netframework-4.8
                                                if(   $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::FullControl         ){ $s += "F,"; } # exert full control over a registry key, and to modify its access rules and audit rules.
                                                else{
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::ReadKey             ){ $s += "R,"; } # query the name/value pairs in a registry key, to request notification of changes, to enumerate its subkeys, and to read its access rules and audit rules.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::WriteKey            ){ $s += "W,"; } # create, delete, and set the name/value pairs in a registry key, to create or delete subkeys, to request notification of changes, to enumerate its subkeys, and to read its access rules and audit rules.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::CreateSubKey        ){ $s += "C,"; } # create subkeys of a registry key.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::Delete              ){ $s += "D,"; } # delete a registry key.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::TakeOwnership       ){ $s += "O,"; } # change the owner of a registry key.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::EnumerateSubKeys    ){ $s += "L,"; } # list the subkeys of a registry key.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::QueryValues         ){ $s += "r,"; } # query the name/value pairs in a registry key.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::SetValue            ){ $s += "w,"; } # create, delete, or set name/value pairs in a registry key.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::ReadPermissions     ){ $s += "p,"; } # open and copy the access rules and audit rules for a registry key.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::ChangePermissions   ){ $s += "c,"; } # change the access rules and audit rules associated with a registry key.
                                                  if( $rule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::Notify              ){ $s += "n,"; } # request notification of changes on a registry key.
                                                  # Not used:  CreateLink=Reserved for system use. ExecuteKey=Same as ReadKey.
                                                } return [String] $result; }
function DirSep                               (){ return [Char] [IO.Path]::DirectorySeparatorChar; }
function FsEntryEsc                           ( [String] $fsentry ){ AssertNotEmpty $fsentry "file-system-entry"; # Escaping is not nessessary if a command supports -LiteralPath.
                                                return [String] [Management.Automation.WildcardPattern]::Escape($fsentry); } # Important for chars as [,], etc.
function FsEntryGetAbsolutePath               ( [String] $fsEntry ){ # works without IO, so no check to file system; does not change a trailing backslash. Return empty for empty input.
                                                # Note: We cannot use (Resolve-Path -LiteralPath $fsEntry) because it will throw if path not exists,
                                                # see http://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist
                                                if( $fsEntry -eq "" ){ return [String] ""; }
                                                try{ return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
                                                catch [System.Management.Automation.DriveNotFoundException] { # ex: DriveNotFoundException: Cannot find drive. A drive with the name 'Z' does not exist.
                                                  try{ return [String] [IO.Path]::GetFullPath($fsEntry); }catch{
                                                    # maybe this is not working for psdrives. Solve this if it occurrs.
                                                    throw [Exception] "[IO.Path]::GetFullPath(`"$fsEntry`") failed because $($_.Exception.Message)";
                                                  } } }
function FsEntryGetUncShare                   ( [String] $fsEntry ){ # return "\\host\sharename\" of a given unc path, return empty string if fs entry is not an unc path
                                                try{ [System.Uri] $u = (New-Object System.Uri -ArgumentList $fsEntry);
                                                  if( $u.IsUnc -and $u.Segments.Count -ge 2 -and $u.Segments[0] -eq "/" ){
                                                    return [String] "$(DirSep)$(DirSep)$($u.Host)$(DirSep)$(StringRemoveRight $u.Segments[1] '/')$(DirSep)";
                                                  }
                                                }catch{ $error.clear(); } # ex: "Ungültiger URI: Das URI-Format konnte nicht bestimmt werden.", "Ungültiger URI: Der URI ist leer."
                                                return [String] ""; }
function FsEntryMakeValidFileName             ( [String] $str ){
                                                [System.IO.Path]::GetInvalidFileNameChars() |
                                                  ForEach-Object{ $str = $str.Replace($_,"_") };
                                                return [String] $str; }
function FsEntryMakeRelative                  ( [String] $fsEntry, [String] $belowDir, [Boolean] $prefixWithDotDir = $false ){
                                                # Works without IO to file system; if $fsEntry is not equal or below dir then it throws;
                                                # if fs-entry is equal the below-dir then it returns a dot;
                                                # a trailing backslash of the fs entry is not changed;
                                                # trailing backslashes for belowDir are not nessessary. ex: "Dir1/Dir2" -eq (FsEntryMakeRelative "$HOME/Dir1/Dir2" "$HOME");
                                                AssertNotEmpty $belowDir "belowDir";
                                                $belowDir = FsEntryMakeTrailingDirSep (FsEntryGetAbsolutePath $belowDir);
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                if( (FsEntryMakeTrailingDirSep $fsEntry) -eq $belowDir ){ $fsEntry += "$(DirSep)."; }
                                                Assert ($fsEntry.StartsWith($belowDir,"CurrentCultureIgnoreCase")) "expected `"$fsEntry`" is below `"$belowDir`"";
                                                return [String] ($(switch($prefixWithDotDir){($true){".$(DirSep)"}default{""}})+$fsEntry.Substring($belowDir.Length)); }
function FsEntryHasTrailingDirSep             ( [String] $fsEntry ){ return [Boolean] ($fsEntry.EndsWith("\") -or $fsEntry.EndsWith("/")); }
function FsEntryRemoveTrailingDirSep          ( [String] $fsEntry ){ [String] $r = $fsEntry;
                                                if( $r -ne "" ){ while( FsEntryHasTrailingDirSep $r ){ $r = $r.Remove($r.Length-1); }
                                                if( $r -eq "" ){ $r = $fsEntry; } } return [String] $r; }
function FsEntryMakeTrailingDirSep            ( [String] $fsEntry ){
                                                [String] $result = $fsEntry;
                                                if( -not (FsEntryHasTrailingDirSep $result) ){ $result += $(DirSep); }
                                                return [String] $result; }
function FsEntryJoinRelativePatterns          ( [String] $rootDir, [String[]] $relativeFsEntriesPatternsSemicolonSeparated ){
                                                # Create an array ex: @( "c:\myroot\bin\", "c:\myroot\obj\", "c:\myroot\*.tmp", ... ) from input as @( "bin\;obj\;", ";*.tmp;*.suo", ".\dir\d1?\", ".\dir\file*.txt");
                                                # If an fs entry specifies a dir patterns then it must be specified by a trailing backslash.
                                                [String[]] $a = @(); $relativeFsEntriesPatternsSemicolonSeparated |
                                                  Where-Object{$null -ne $_} |
                                                  ForEach-Object{ $a += (StringSplitToArray ";" $_); };
                                                return [String[]] (@()+($a | ForEach-Object{ "$rootDir$(DirSep)$_" })); }
function FsEntryGetFileNameWithoutExt         ( [String] $fsEntry ){
                                                return [String] [System.IO.Path]::GetFileNameWithoutExtension((FsEntryRemoveTrailingDirSep $fsEntry)); }
function FsEntryGetFileName                   ( [String] $fsEntry ){
                                                return [String] [System.IO.Path]::GetFileName((FsEntryRemoveTrailingDirSep $fsEntry)); }
function FsEntryGetFileExtension              ( [String] $fsEntry ){
                                                return [String] [System.IO.Path]::GetExtension((FsEntryRemoveTrailingDirSep $fsEntry)); }
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
function FsEntryNotExistsOrIsOlderThanNrDays  ( [String] $fsEntry, [Int32] $maxAgeInDays, [Int32] $maxAgeInHours = 0, [Int32] $maxAgeInMinutes = 0 ){
                                                return [Boolean] ((FsEntryNotExists $fsEntry) -or ((FsEntryGetLastModified $fsEntry).AddDays($maxAgeInDays).AddHours($maxAgeInHours).AddMinutes($maxAgeInMinutes) -lt (Get-Date))); }
function FsEntryNotExistsOrIsOlderThanBeginOf ( [String] $fsEntry, [String] $beginOf ){ # more see: DateTimeGetBeginOf
                                                return [Boolean] ((FsEntryNotExists $fsEntry) -or ((FsEntryGetLastModified $fsEntry) -lt (DateTimeGetBeginOf $beginOf))); }
function FsEntryExistsAndIsNewerThanBeginOf   ( [String] $fsEntry, [String] $beginOf ){ # more see: DateTimeGetBeginOf
                                                return [Boolean] (-not (FsEntryNotExistsOrIsOlderThanBeginOf $fsEntry $beginOf)); }
function FsEntrySetAttributeReadOnly          ( [String] $fsEntry, [Boolean] $val ){ # use false for $val to make file writable
                                                OutProgress "FsFileSetAttributeReadOnly `"$fsEntry`" $val"; Set-ItemProperty (FsEntryEsc $fsEntry) -name IsReadOnly -value $val; }
function FsEntryFindFlatSingleByPattern       ( [String] $fsEntryPattern, [Boolean] $allowNotFound = $false ){
                                                # it throws if file not found or more than one file exists. if allowNotFound is true then if return empty if not found.
                                                [System.IO.FileSystemInfo[]] $r = @()+(Get-ChildItem -Force -ErrorAction SilentlyContinue -Path $fsEntryPattern | Where-Object{$null -ne $_});
                                                if( $r.Count -eq 0 ){ if( $allowNotFound ){ return [String] ""; } throw [Exception] "No file exists: `"$fsEntryPattern`""; }
                                                if( $r.Count -gt 1 ){ throw [Exception] "More than one file exists: `"$fsEntryPattern`""; }
                                                return [String] $r[0].FullName; }
function FsEntryFsInfoFullNameDirWithBackSlash( [System.IO.FileSystemInfo] $fsInfo ){ return [String] ($fsInfo.FullName+$(switch($fsInfo.PSIsContainer){($true){$(DirSep)}default{""}})); }
function FsEntryListAsFileSystemInfo          ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
                                                # List entries specified by a pattern, which applies to files and directories and which can contain wildards (*,?).
                                                # Internally it uses Get-Item and Get-ChildItem.
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
                                                #     second if pattern was not yet found then it searches for it recursively and lists the found entries but even if it is a dir then its content is not listed.
                                                # Trailing backslashes:  Are handled in powershell quite curious:
                                                #   In non-recursive mode they are handled as they are not present, so files are also matched ("*\myfile\").
                                                #   In recursive mode they wrongly match only files and not directories ("*\myfile\") and
                                                #   so parent dir parts (".\*\dir\" or "d1\dir\") would not be found for unknown reasons.
                                                #   Very strange is that (CD "D:\tmp"; CD "C:"; Get-Item "D:";) does not list D:\ but it lists the current directory of that drive.
                                                #   So we interpret a trailing backslash as it would not be present with the exception that
                                                #     If pattern contains a trailing backslash then pattern "\*\" will be replaced by ("\.\").
                                                #   If pattern is a drive as "C:" then a trailing backslash is added to avoid the unexpected listing of current dir of that drive.
                                                AssertNotEmpty $fsEntryPattern "pattern";
                                                [String] $pa = $fsEntryPattern;
                                                [Boolean] $trailingBackslashMode = (FsEntryHasTrailingDirSep $pa);
                                                if( $trailingBackslashMode ){
                                                  $pa = FsEntryRemoveTrailingDirSep $pa;
                                                }
                                                OutVerbose "FsEntryListAsFileSystemInfo `"$pa`" recursive=$recursive includeDirs=$includeDirs includeFiles=$includeFiles";
                                                [System.IO.FileSystemInfo[]] $result = @();
                                                if( $trailingBackslashMode -and ($pa.Contains("\*\") -or $pa.Contains("/*/")) ){
                                                  # enable that ".\*\dir\" can also find dir as top dir
                                                  $pa = $pa.Replace("\*\","\.\").Replace("/*/","/./"); # Otherwise Get-ChildItem would find dirs.
                                                }
                                                if( $pa.Length -eq 2 -and $pa.EndsWith(":") -and $pa -match "[a-z]" ){ $pa += $(DirSep); }
                                                if( $inclTopDir -and $includeDirs -and -not ($pa -eq "*" -or $pa.EndsWith("$(DirSep)*")) ){
                                                  $result += @()+((Get-Item -Force -ErrorAction SilentlyContinue -Path $pa) |
                                                  Where-Object{$null -ne $_} | Where-Object{ $_.PSIsContainer });
                                                }
                                                try{
                                                  $result += (@()+(Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse:$recursive -Path $pa |
                                                    Where-Object{$null -ne $_} |
                                                    Where-Object{ ($includeDirs -and $includeFiles) -or ($includeDirs -and $_.PSIsContainer) -or ($includeFiles -and -not $_.PSIsContainer) }));
                                                }catch [System.UnauthorizedAccessException] { # BUG: why is this not handled by SilentlyContinue?
                                                  OutWarning "Warning: Ignoring UnauthorizedAccessException for Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse:$recursive -Path `"$pa`"";
                                                } return [System.IO.FileSystemInfo[]] $result; }
function FsEntryListAsStringArray             ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
                                                # Output of directories will have a trailing backslash. more see FsEntryListAsFileSystemInfo.
                                                return [String[]] (@()+(FsEntryListAsFileSystemInfo $fsEntryPattern $recursive $includeDirs $includeFiles $inclTopDir | Where-Object{$null -ne $_} |
                                                  ForEach-Object{ FsEntryFsInfoFullNameDirWithBackSlash $_} )); }
function FsEntryDelete                        ( [String] $fsEntry ){
                                                if( (FsEntryHasTrailingDirSep $fsEntry) ){ DirDelete $fsEntry; }else{ FileDelete $fsEntry; } }
function FsEntryDeleteToRecycleBin            ( [String] $fsEntry ){
                                                Add-Type -AssemblyName Microsoft.VisualBasic;
                                                [String] $e = FsEntryGetAbsolutePath $fsEntry;
                                                OutProgress "FsEntryDeleteToRecycleBin `"$e`"";
                                                FsEntryAssertExists $e "Not exists: `"$e`"";
                                                if( FsEntryIsDir $e ){ [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($e,"OnlyErrorDialogs","SendToRecycleBin");
                                                }else{                 [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($e,"OnlyErrorDialogs","SendToRecycleBin"); } }
function FsEntryRename                        ( [String] $fsEntryFrom, [String] $fsEntryTo ){
                                                # for files or dirs, relative or absolute, origin must exists, directory parts must be identic.
                                                OutProgress "FsEntryRename `"$fsEntryFrom`" `"$fsEntryTo`"";
                                                FsEntryAssertExists $fsEntryFrom; FsEntryAssertNotExists $fsEntryTo;
                                                [String] $fs1 = (FsEntryGetAbsolutePath (FsEntryRemoveTrailingDirSep $fsEntryFrom));
                                                [String] $fs2 = (FsEntryGetAbsolutePath (FsEntryRemoveTrailingDirSep $fsEntryTo));
                                                Rename-Item -Path $fs1 -newName $fs2 -force; }
function FsEntryCreateSymLink                 ( [String] $newSymLink, [String] $fsEntryOrigin ){
                                                # (junctions (=~symlinksToDirs) do not) (https://superuser.com/questions/104845/permission-to-make-symbolic-links-in-windows-7/105381).
                                                New-Item -ItemType SymbolicLink -Name (FsEntryEsc $newSymLink) -Value (FsEntryEsc $fsEntryOrigin); }
function FsEntryCreateHardLink                ( [String] $newHardLink, [String] $fsEntryOrigin ){
                                                # for files or dirs, origin must exists, it requires elevated rights.
                                                New-Item -ItemType HardLink -Name (FsEntryEsc $newHardLink) -Value (FsEntryEsc $fsEntryOrigin); }
function FsEntryCreateDirSymLink              ( [String] $symLinkDir, [String] $symLinkOriginDir ){
                                                # Creates junctions which are symlinks to dirs with some slightly other behaviour around privileges and local/remote usage.
                                                if( !(DirExists $symLinkOriginDir)  ){
                                                  throw [Exception] "Cannot create dir sym link because original directory not exists: `"$symLinkOriginDir`""; }
                                                FsEntryAssertNotExists $symLinkDir "Cannot create dir sym link";
                                                [String] $cd = Get-Location;
                                                Set-Location (FsEntryGetParentDir $symLinkDir);
                                                [String] $symLinkName = FsEntryGetFileName $symLinkDir;
                                                & "cmd.exe" "/c" ('mklink /J "'+$symLinkName+'" "'+$symLinkOriginDir+'"'); AssertRcIsOk;
                                                Set-Location $cd; }
function FsEntryIsSymLink                     ( [String] $fsEntry ){ # tested only for dirs; return false if fs-entry not exists.
                                                if( FsEntryNotExists $fsEntry ){ return $false; }
                                                [Object] $f = Get-Item -Force -ErrorAction SilentlyContinue $fsEntry;
                                                return [Boolean] ($f.Attributes -band [IO.FileAttributes]::ReparsePoint); }
function FsEntryReportMeasureInfo             ( [String] $fsEntry ){ # Must exists, works recursive.
                                                if( FsEntryNotExists $fsEntry ){ throw [Exception] "File system entry not exists: `"$fsEntry`""; }
                                                [Microsoft.PowerShell.Commands.GenericMeasureInfo] $size = Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse -LiteralPath $fsEntry |
                                                  Where-Object{$null -ne $_} | Measure-Object -Property length -sum;
                                                if( $null -eq $size ){ return [String] "SizeInBytes=0; NrOfFsEntries=0;"; }
                                                return [String] "SizeInBytes=$($size.sum); NrOfFsEntries=$($size.count);"; }
function FsEntryCreateParentDir               ( [String] $fsEntry ){ [String] $dir = FsEntryGetParentDir $fsEntry; DirCreate $dir; }
function FsEntryMoveByPatternToDir            ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $showProgress = $false ){ # Target dir must exists. pattern is non-recursive scanned.
                                                OutProgress "FsEntryMoveByPatternToDir `"$fsEntryPattern`" to `"$targetDir`""; DirAssertExists $targetDir;
                                                FsEntryListAsStringArray $fsEntryPattern $false |
                                                  Where-Object{$null -ne $_} | Sort-Object |
                                                  ForEach-Object{
                                                    if( $showProgress ){ OutProgress "Source: $_"; };
                                                    Move-Item -Force -Path $_ -Destination (FsEntryEsc $targetDir);
                                                  }; }
function FsEntryCopyByPatternByOverwrite      ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $continueOnErr = $false ){
                                                OutProgress "FsEntryCopyByPatternByOverwrite `"$fsEntryPattern`" to `"$targetDir`" continueOnErr=$continueOnErr";
                                                DirCreate $targetDir;
                                                Copy-Item -ErrorAction SilentlyContinue -Recurse -Force -Path $fsEntryPattern -Destination (FsEntryEsc $targetDir);
                                                if( -not $? ){ if( ! $continueOnErr ){ AssertRcIsOk; }
                                                else{ OutWarning "Warning: CopyFiles `"$fsEntryPattern`" to `"$targetDir`" failed, will continue"; } } }
function FsEntryFindNotExistingVersionedName  ( [String] $fsEntry, [String] $ext = ".bck", [Int32] $maxNr = 9999 ){ # return ex: "C:\Dir\MyName.001.bck"
                                                $fsEntry = (FsEntryRemoveTrailingDirSep (FsEntryGetAbsolutePath $fsEntry));
                                                if( $fsEntry.Length -gt (260-4-$ext.Length) ){
                                                  throw [Exception] "$(ScriptGetCurrentFunc)($fsEntry,$ext) not available because fullpath longer than 260-4-extLength"; }
                                                [Int32] $n = 1; do{
                                                  [String] $newFs = $fsEntry + "." + $n.ToString("D3")+$ext;
                                                  if( (FsEntryNotExists $newFs) ){ return [String] $newFs; }
                                                  $n += 1;
                                                }until( $n -gt $maxNr );
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
                                                OutProgress "FsEntryAclRuleWrite $modeSetAddOrDel `"$fsEntry`" `"$(PrivFsRuleAsString $rule)`"";
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry;
                                                if    ( $modeSetAddOrDel -eq "Set" ){ $acl.SetAccessRule($rule); }
                                                elseif( $modeSetAddOrDel -eq "Add" ){ $acl.AddAccessRule($rule); }
                                                elseif( $modeSetAddOrDel -eq "Del" ){ $acl.RemoveAccessRule($rule); }
                                                else{ throw [Exception] "For modeSetAddOrDel expected 'Set', 'Add' or 'Del' but got `"$modeSetAddOrDel`""; }
                                                Set-Acl -Path (FsEntryEsc $fsEntry) -AclObject $acl; <# Set-Acl does set or add #>
                                                if( $recursive -and (FsEntryIsDir $fsEntry) ){
                                                  FsEntryListAsStringArray "$fsEntry$(DirSep)*" $false | Where-Object{$null -ne $_} |
                                                    ForEach-Object{ FsEntryAclRuleWrite $modeSetAddOrDel $_ $rule $true };
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
                                                    FsEntryListAsStringArray "$fs$(DirSep)*" $false | Where-Object{$null -ne $_} |
                                                      ForEach-Object{ FsEntryTrySetOwner $_ $account $true };
                                                  }
                                                }catch{
                                                  OutWarning "Warning: Ignoring FsEntryTrySetOwner($fsEntry,$account) failed because $($_.Exception.Message)";
                                                } }
function FsEntryTrySetOwnerAndAclsIfNotSet    ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){
                                                # usually account is (PrivGetGroupAdministrators)
                                                try{
                                                  [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry;
                                                  if( $acl.Owner -ne $account ){
                                                    FsEntryTrySetOwner $fsEntry $account $false;
                                                    $acl = FsEntryAclGet $fsEntry;
                                                  }
                                                  [Boolean] $isDir = FsEntryIsDir $fsEntry;
                                                  [System.Security.AccessControl.FileSystemAccessRule] $rule = (PrivFsRuleCreateFullControl $account $isDir);
                                                  if( -not (PrivAclHasFullControl $acl $account $isDir) ){
                                                    FsEntryAclRuleWrite "Set" $fsEntry $rule $false;
                                                  }
                                                  if( $recursive -and $isDir ){
                                                    FsEntryListAsStringArray "$fsEntry$(DirSep)*" $false | Where-Object{$null -ne $_} |
                                                      ForEach-Object{ FsEntryTrySetOwnerAndAclsIfNotSet $_ $account $true };
                                                  }
                                                }catch{
                                                  OutWarning "FsEntryTrySetOwnerAndAclsIfNotSet `"$fsEntry`" $account $recursive : Failed because $($_.Exception.Message)";
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
                                                    [System.Security.AccessControl.FileSystemAccessRule] $rule = (PrivFsRuleCreateFullControl $account (FsEntryIsDir $fsEntry));
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
                                                      OutWarning "Warning: Ignoring FsEntryRename($fsEntry,$newFileName) failed because $($_.Exception.Message)";
                                                    } } } }
function FsEntryResetTs                       ( [String] $fsEntry, [Boolean] $recursive, [String] $tsInIsoFmt = "2000-01-01 00:00" ){
                                                # Overwrite LastWriteTime, CreationTime and LastAccessTime. Drive ts cannot be changed and so are ignored. Used for example to anonymize ts.
                                                [DateTime] $ts = DateTimeFromStringIso $tsInIsoFmt;
                                                OutProgress "FsEntrySetTs `"$fsEntry`" recursive=$recursive ts=$(DateTimeAsStringIso $ts)";
                                                FsEntryAssertExists $fsEntry; [Boolean] $inclDirs = $true;
                                                if( -not (FsEntryIsDir $fsEntry) ){ $recursive = $false; $inclDirs = $false; }
                                                FsEntryListAsFileSystemInfo $fsEntry $recursive $true $true $true | Where-Object{$null -ne $_} | ForEach-Object{
                                                  [String] $f = $(FsEntryFsInfoFullNameDirWithBackSlash $_);
                                                  OutProgress "Set $(DateTimeAsStringIso $ts) of $(DateTimeAsStringIso $_.LastWriteTime) $f";
                                                  try{ $_.LastWriteTime = $ts; $_.CreationTime = $ts; $_.LastAccessTime = $ts; }catch{
                                                    OutWarning "Warning: Ignoring SetTs($f) failed because $($_.Exception.Message)";
                                                  } }; }
function FsEntryFindInParents                 ( [String] $fromFsEntry, [String] $searchFsEntryName ){
                                                # From an fsEntry scan its parent dir upwards to root until a search name has been found.
                                                # Return full path of found fs entry or empty string if not found.
                                                AssertNotEmpty $fromFsEntry "fromFsEntry";
                                                AssertNotEmpty $searchFsEntryName "searchFsEntryName";
                                                [String] $d = $fromFsEntry;
                                                while( $d -ne "" ){
                                                  [String] $p = FsEntryGetParentDir $d;
                                                  [String] $e = "$p$(DirSep)$searchFsEntryName";
                                                  if( FsEntryExists $e ){ return [String] $e; }
                                                  $d = $p;
                                                } return [String] ""; # not found
                                                }
function DriveFreeSpace                       ( [String] $drive ){
                                                return [Int64] (Get-PSDrive $drive | Select-Object -ExpandProperty Free); }
function DirExists                            ( [String] $dir ){
                                                try{ return [Boolean] (Test-Path -PathType Container -LiteralPath $dir); }catch{ throw [Exception] "$(ScriptGetCurrentFunc)($dir) failed because $($_.Exception.Message)"; } }
function DirNotExists                         ( [String] $dir ){ return [Boolean] -not (DirExists $dir); }
function DirAssertExists                      ( [String] $dir, [String] $text = "Assertion" ){
                                                if( -not (DirExists $dir) ){ throw [Exception] "$text failed because dir not exists: `"$dir`"."; } }
function DirCreate                            ( [String] $dir ){
                                                New-Item -type directory -Force (FsEntryEsc $dir) | Out-Null; } # create dir if it not yet exists,;we do not call OutProgress because is not an important change.
function DirCreateTemp                        ( [String] $prefix = "" ){ while($true){
                                                [String] $d = Join-Path ([System.IO.Path]::GetTempPath()) ($prefix + "." + (StringLeft ([System.IO.Path]::GetRandomFileName().Replace(".","")) 6)); # 6 alphachars has 2G possibilities
                                                if( FsEntryNotExists $d ){ DirCreate $d; return [String] $d; } } }
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
                                                    Remove-Item -Force:$ignoreReadonly -Recurse "$(FsEntryEsc $dir)$(DirSep)*";
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
function FileExists                           ( [String] $file ){ AssertNotEmpty $file "$(ScriptGetCurrentFunc):filename";
                                                [String] $f2 = FsEntryGetAbsolutePath $file; if( Test-Path -PathType Leaf -LiteralPath $f2 ){ return [Boolean] $true; }
                                                # Note: Known bug: Test-Path does not work for hidden and system files, so we need an additional check.
                                                # Note2: The following would not works on vista and win7-with-ps2: [String] $d = Split-Path $f2; return [Boolean] ([System.IO.Directory]::EnumerateFiles($d) -contains $f2);
                                                return [Boolean] [System.IO.File]::Exists($f2); }
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
                                                OutVerbose "FileRead $file"; return [String[]] (@()+(Get-Content -Encoding $encodingIfNoBom -LiteralPath $file)); }
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
                                                FsEntryCreateParentDir $file;
                                                $lines | Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -LiteralPath $file; }
function FileCreateEmpty                      ( [String] $file, [Boolean] $overwrite = $false, [Boolean] $quiet = $false ){
                                                if( -not $quiet -and $overwrite ){ OutProgress "FileCreateEmpty-ByOverwrite $file"; }
                                                FsEntryCreateParentDir $file;
                                                Out-File -Force -NoClobber:$(-not $overwrite) -Encoding ASCII -LiteralPath $file; }
function FileAppendLineWithTs                 ( [String] $file, [String] $line ){ FileAppendLine $file $line $true; }
function FileAppendLine                       ( [String] $file, [String] $line, [Boolean] $tsPrefix = $false ){
                                                FsEntryCreateParentDir $file;
                                                Out-File -Encoding Default -Append -LiteralPath $file -InputObject ($(switch($tsPrefix){($true){"$(DateTimeNowAsStringIso) "}default{""}})+$line); }
function FileAppendLines                      ( [String] $file, [String[]] $lines ){
                                                FsEntryCreateParentDir $file;
                                                $lines | Out-File -Encoding Default -Append -LiteralPath $file; }
function FileGetTempFile                      (){ return [String] [System.IO.Path]::GetTempFileName(); }
function FileDelTempFile                      ( [String] $file ){ if( (FileExists $file) ){
                                                OutDebug "FileDelete -Force `"$file`"";
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
function FileTouch                            ( [String] $file ){
                                                OutProgress "Touch: `"$file`"";
                                                if( FileExists $file ){ (Get-Item -Force -LiteralPath $file).LastWriteTime = (Get-Date); }
                                                else{ FileCreateEmpty $file; } }
function FileGetLastLines                     ( [String] $file, [Int32] $nrOfLines ){
                                                Get-content -tail $nrOfLines -LiteralPath $file; }
function FileContentsAreEqual                 ( [String] $f1, [String] $f2, [Boolean] $allowSecondFileNotExists = $true ){ # first file must exist
                                                FileAssertExists $f1; if( $allowSecondFileNotExists -and -not (FileExists $f2) ){ return [Boolean] $false; }
                                                [System.IO.FileInfo] $fi1 = Get-Item -Force -LiteralPath $f1; [System.IO.FileStream] $fs1 = $null;
                                                [System.IO.FileInfo] $fi2 = Get-Item -Force -LiteralPath $f2; [System.IO.FileStream] $fs2 = $null;
                                                [Int64] $BlockSizeInBytes = 32768;
                                                [Int32] $nrOfBlocks = [Math]::Ceiling($fi1.Length/$BlockSizeInBytes);
                                                [Byte[]] $a1 = New-Object byte[] $BlockSizeInBytes;
                                                [Byte[]] $a2 = New-Object byte[] $BlockSizeInBytes;
                                                if( $false ){ # Much more performant (20 sec for 5 GB file).
                                                  if( $fi1.Length -ne $fi2.Length ){ return [Boolean] $false; }
                                                  & "fc.exe" "/b" ($fi1.FullName) ($fi2.FullName) > $null;
                                                  if( $? ){ return [Boolean] $true; }
                                                  ScriptResetRc;
                                                  return [Boolean] $false;
                                                }else{ # Slower but more portable (longer than 5 min).
                                                  try{
                                                    $fs1 = $fi1.OpenRead();
                                                    $fs2 = $fi2.OpenRead();
                                                    [Int64] $dummyNrBytesRead = 0;
                                                    for( [Int32] $b = 0; $b -lt $nrOfBlocks; $b++ ){
                                                      $dummyNrBytesRead = $fs1.Read($a1,0,$BlockSizeInBytes);
                                                      $dummyNrBytesRead = $fs2.Read($a2,0,$BlockSizeInBytes);
                                                      # Note: this is probably too slow, so took it inline: if( -not (ByteArraysAreEqual $a1 $a2) ){ return [Boolean] $false; }
                                                      if( $a1.Length -ne $a2.Length ){ return [Boolean] $false; }
                                                      for( [Int64] $i = 0; $i -lt $a1.Length; $i++ ){
                                                        if( $a1[$i] -ne $a2[$i] ){ return [Boolean] $false; } }
                                                    } return [Boolean] $true;
                                                  }finally{ $fs1.Close(); $fs2.Close(); } }
                                                }
function FileDelete                           ( [String] $file, [Boolean] $ignoreReadonly = $true, [Boolean] $ignoreAccessDenied = $false ){
                                                # for hidden files it is also required to set ignoreReadonly=true.
                                                # In case the file is used by another process it waits some time between a retries.
                                                if( (FileExists $file) ){ OutProgress "FileDelete$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) `"$file`""; }
                                                [Int32] $nrOfTries = 0; while($true){ $nrOfTries++;
                                                  try{
                                                    Remove-Item -Force:$ignoreReadonly -LiteralPath $file;
                                                    return;
                                                  }catch [System.Management.Automation.ItemNotFoundException] { # example: ItemNotFoundException: Cannot find path '$HOME/myfile.lnk' because it does not exist.
                                                    return; #
                                                  }catch [System.UnauthorizedAccessException] { # example: Access to the path '$HOME/Desktop/desktop.ini' is denied.
                                                    if( -not $ignoreAccessDenied ){ throw; }
                                                    OutWarning "Warning: Ignoring UnauthorizedAccessException for Remove-Item -Force:$ignoreReadonly -LiteralPath `"$file`""; return;
                                                  }catch{ # ex: IOException: The process cannot access the file '$HOME\myprog.lnk' because it is being used by another process.
                                                    [Boolean] $isUsedByAnotherProc = $_.Exception -is [System.IO.IOException] -and $_.Exception.Message.Contains("The process cannot access the file ") -and $_.Exception.Message.Contains(" because it is being used by another process.");
                                                    if( -not $isUsedByAnotherProc ){ throw; }
                                                    if( $nrOfTries -ge 5 ){ throw; }
                                                    Start-Sleep -Milliseconds $(switch($nrOfTries){1{50}2{100}3{200}4{400}default{800}}); } } }
function FileCopy                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){
                                                OutProgress "FileCopy(Overwrite=$overwrite) `"$srcFile`" to `"$tarFile`" $(switch($(FileExists $(FsEntryEsc $tarFile))){($true){'(Target exists)'}default{''}})";
                                                FsEntryCreateParentDir $tarFile;
                                                Copy-Item -Force:$overwrite (FsEntryEsc $srcFile) (FsEntryEsc $tarFile); }
function FileMove                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){
                                                OutProgress "FileMove(Overwrite=$overwrite) `"$srcFile`" to `"$tarFile`"$(switch($(FileExists $(FsEntryEsc $tarFile))){($true){'(Target exists)'}default{''}})";
                                                FsEntryCreateParentDir $tarFile;
                                                Move-Item -Force:$overwrite -LiteralPath $srcFile -Destination $tarFile; }
function FileGetHexStringOfHash128BitsMd5     ( [String] $srcFile ){ [String] $m = "MD5"; return [String] (get-filehash -Algorithm $md $srcFile).Hash; } # 2008: is broken. Because PSScriptAnalyzer.PSAvoidUsingBrokenHashAlgorithms we put name into a variable.
function FileGetHexStringOfHash256BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA256" $srcFile).Hash; } # 2017-11 ps standard is SHA256, available are: SHA1;SHA256;SHA384;SHA512;MACTripleDES;MD5;RIPEMD160
function FileGetHexStringOfHash512BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA512" $srcFile).Hash; } # 2017-12: this is our standard for ps
function FileUpdateItsHashSha2FileIfNessessary( [String] $srcFile ){
                                                [String] $hashTarFile = "$srcFile.sha2";
                                                [String] $hashSrc = FileGetHexStringOfHash512BitsSha2 $srcFile;
                                                [String] $hashTar = $(switch((FileNotExists $hashTarFile) -or (FileGetSize $hashTarFile) -gt 8200){
                                                  ($true){""}
                                                  default{(FileReadContentAsString $hashTarFile "Default").TrimEnd()}
                                                });
                                                if( $hashSrc -eq $hashTar ){
                                                  OutProgress "File is up to date, nothing done with `"$hashTarFile`".";
                                                }else{
                                                  Out-File -Encoding UTF8 -LiteralPath $hashTarFile -Inputobject $hashSrc;
                                                  OutProgress "Created `"$hashTarFile`".";
                                                } }
function CredentialStandardizeUserWithDomain  ( [String] $username ){
                                                # Allowed username as input: "", "u0", "u0@domain", "@domain\u0", "domain\u0"   used because for unknown reasons sometimes a username like user@domain does not work, it requires domain\user.
                                                if( $username.Contains("\") -or $username.Contains("/") -or -not $username.Contains("@") ){
                                                  return [String] $username;
                                                }
                                                [String[]] $u = $username -split "@",2;
                                                return [String] ($u[1]+"\"+$u[0]); }
function CredentialGetSecureStrFromHexString  ( [String] $text ){
                                                return [System.Security.SecureString] (ConvertTo-SecureString $text); } # Will throw if it is not an encrypted string.
function CredentialGetSecureStrFromText       ( [String] $text ){ AssertNotEmpty $text "$(ScriptGetCurrentFunc).callingText";
                                                return [System.Security.SecureString] (ConvertTo-SecureString $text -AsPlainText -Force); }
function CredentialGetHexStrFromSecureString  ( [System.Security.SecureString] $code ){
                                                return [String] (ConvertFrom-SecureString $code); } # ex: "ea32f9d30de3d3dc7fcd86a6a8f587ed9"
function CredentialGetTextFromSecureString    ( [System.Security.SecureString] $code ){
                                                [Object] $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($code);
                                                return [String] [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr); }
function CredentialGetUsername                ( [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $onNullCredGetCurrentUserInsteadOfEmpty = $false ){
                                                # if cred is null then take current user.
                                                return [String] $(switch($null -eq $cred){ ($true){$(switch($onNullCredGetCurrentUserInsteadOfEmpty){($true){$env:USERNAME}default{""}})} default{$cred.UserName}}); }
function CredentialGetPassword                ( [System.Management.Automation.PSCredential] $cred = $null ){
                                                # if cred is null then return empty string.
                                                # $cred.GetNetworkCredential().Password is the same as (CredentialGetTextFromSecureString $cred.Password)
                                                return [String] $(switch($null -eq $cred){ ($true){""} default{$cred.GetNetworkCredential().Password}}); }
function CredentialWriteToFile                ( [System.Management.Automation.PSCredential] $cred, [String] $secureCredentialFile ){
                                                FileWriteFromString $secureCredentialFile ($cred.UserName+"$([Environment]::NewLine)"+(CredentialGetHexStrFromSecureString $cred.Password)); }
function CredentialRemoveFile                 ( [String] $secureCredentialFile ){
                                                OutProgress "CredentialRemoveFile `"$secureCredentialFile`""; FileDelete $secureCredentialFile; }
function CredentialReadFromFile               ( [String] $secureCredentialFile ){
                                                [String[]] $s = (@()+(StringSplitIntoLines (FileReadContentAsString $secureCredentialFile "Default")));
                                                try{ [String] $us = $s[0]; [System.Security.SecureString] $pwSecure = CredentialGetSecureStrFromHexString $s[1];
                                                  # alternative: New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content -Encoding Default -LiteralPath $secureCredentialFile | ConvertTo-SecureString)
                                                  return [System.Management.Automation.PSCredential] (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure));
                                                }catch{ throw [Exception] "Credential file `"$secureCredentialFile`" has not expected format for decoding credentials, maybe you changed password of current user or current machine id, in that case you may remove it and retry"; } }
function CredentialCreate                     ( [String] $username = "", [String] $password = "", [String] $accessShortDescription = "" ){
                                                [String] $us = $username;
                                                [String] $descr = switch($accessShortDescription -eq ""){($true){""}default{(" for $accessShortDescription")}};
                                                while( $us -eq "" ){ $us = StdInReadLine "Enter username$($descr): "; }
                                                if( $username -eq "" ){ $descr = ""; <# display descr only once #> }
                                                [System.Security.SecureString] $pwSecure = $null;
                                                if( $password -eq "" ){ $pwSecure = StdInReadLinePw "Enter password for username=$($us)$($descr): "; }
                                                else{ $pwSecure = CredentialGetSecureStrFromText $password; }
                                                return [System.Management.Automation.PSCredential] (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure)); }
function CredentialGetAndStoreIfNotExists     ( [String] $secureCredentialFile, [String] $username = "", [String] $password = "", [String] $accessShortDescription = ""){
                                                # If username or password is empty then they are asked from std input.
                                                # If file exists and non-empty-user matches then it takes credentials from it.
                                                # If file not exists or non-empty-user not matches then it is written by given credentials.
                                                # For access description enter a message hint which is added to request for user as "login host xy", "mountpoint xy", etc.
                                                # For secureCredentialFile usually use: "$env:LOCALAPPDATA\MyNameOrCompany\MyOperation.secureCredentials.txt";
                                                AssertNotEmpty $secureCredentialFile "secureCredentialFile";
                                                [System.Management.Automation.PSCredential] $cred = $null;
                                                if( FileExists $secureCredentialFile ){
                                                  try{
                                                    $cred = CredentialReadFromFile $secureCredentialFile;
                                                  }catch{ [String] $msg = $_.Exception.Message; # ... you changed pw ... may remove it ...
                                                    OutWarning "Warning: $msg";
                                                    if( -not (StdInAskForBoolean "Do you want to remove the credential file and recreate it (y=delete/n=abort)?") ){
                                                      throw [Exception] "Aborted, please fix credential file `"$secureCredentialFile`".";
                                                    }
                                                    FileDelete $secureCredentialFile;
                                                  }
                                                  if( $username -ne "" -and (CredentialGetUsername $cred) -ne (CredentialStandardizeUserWithDomain $username)){ $cred = $null; }
                                                }
                                                if( $null -eq $cred ){
                                                  $cred = CredentialCreate $username $password $accessShortDescription;
                                                }
                                                if( FileNotExists $secureCredentialFile ){
                                                  CredentialWriteToFile $cred $secureCredentialFile;
                                                }
                                                return [System.Management.Automation.PSCredential] $cred; }
function PsDriveListAll                       (){
                                                OutVerbose "List PsDrives";
                                                return [Object[]] (@()+(Get-PSDrive -PSProvider FileSystem |
                                                  Where-Object{$null -ne $_} |
                                                  Select-Object Name,@{Name="ShareName";Expression={$_.DisplayRoot+""}},Description,CurrentLocation,Free,Used |
                                                  Sort-Object Name)); }
                                                # Not used: Root, Provider. PSDrive: Note are only for current session, even if persist.
function PsDriveCreate                        ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null ){
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
                                                MountPointRemove $drive $mountPoint;
                                                [String] $us = CredentialGetUsername $cred $true;
                                                OutProgress "PsDriveCreate drive=$drive mountPoint=$mountPoint username=$us";
                                                try{
                                                  $dummyObj = New-PSDrive -Name ($drive -replace ":","") -Root $mountPoint -PSProvider "FileSystem" -Scope Global -Persist -Description "$mountPoint($drive)" -Credential $cred;
                                                }catch{
                                                  # ex: System.ComponentModel.Win32Exception (0x80004005): Der lokale Gerätename wird bereits verwendet
                                                  # ex: System.Exception: Mehrfache Verbindungen zu einem Server oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig.
                                                  #     Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut
                                                  # ex: System.Exception: New-PSDrive(Z,\\mycomp\Transfer,) failed because Das angegebene Netzwerkkennwort ist falsch
                                                  throw [Exception] "New-PSDrive($drive,$mountPoint,$us) failed because $($_.Exception.Message)";
                                                } }
function NetExtractHostName                   ( [String] $url ){ return [String] ([System.Uri]$url).Host; }
function NetUrlUnescape                       ( [String] $url ){ return [String] [uri]::UnescapeDataString($url); } # convert for example %20 to blank.
function NetAdapterGetConnectionStatusName    ( [Int32] $netConnectionStatusNr ){
                                                return [String] $(switch($netConnectionStatusNr){
                                                  0{"Disconnected"}
                                                  1{"Connecting"}
                                                  2{"Connected"}
                                                  3{"Disconnecting"}
                                                  4{"Hardware not present"}
                                                  5{"Hardware disabled"}
                                                  6{"Hardware malfunction"}
                                                  7{"Media disconnected"}
                                                  8{"Authenticating"}
                                                  9{"Authentication succeeded"}
                                                  10{"Authentication failed"}
                                                  11{"Invalid address"}
                                                  12{"Credentials required"}
                                                  default{"unknownNr=$netConnectionStatusNr"} }); }
<# Type: ServerCertificateValidationCallback #> Add-Type -TypeDefinition "using System;using System.Net;using System.Net.Security;using System.Security.Cryptography.X509Certificates; public class ServerCertificateValidationCallback { public static void Ignore() { ServicePointManager.ServerCertificateValidationCallback += delegate( Object obj, X509Certificate certificate, X509Chain chain, SslPolicyErrors errors ){ return true; }; } } ";
function NetWebRequestLastModifiedFailSafe    ( [String] $url ){ # Requests metadata from a downloadable file. Return DateTime.MaxValue in case of any problem
                                                [net.WebResponse] $resp = $null;
                                                try{
                                                  [net.HttpWebRequest] $webRequest = [net.WebRequest]::Create($url);
                                                  $resp = $webRequest.GetResponse();
                                                  $resp.Close();
                                                  if( $resp.StatusCode -ne [system.net.httpstatuscode]::ok ){
                                                    throw [ExcMsg] "GetResponse($url) failed with statuscode=$($resp.StatusCode)"; }
                                                  if( $resp.LastModified -lt (DateTimeFromStringIso "1970-01-01") ){
                                                    throw [ExcMsg] "GetResponse($url) failed because LastModified=$($resp.LastModified) is unexpected lower than 1970"; }
                                                  return [DateTime] $resp.LastModified;
                                                }catch{ return [DateTime] [DateTime]::MaxValue; }finally{ if( $null -ne $resp ){ $resp.Dispose(); } } }
function NetDownloadFile                      ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [Boolean] $errorAsWarning = $false ){
                                                # Download a single file by overwrite it (as NetDownloadFileByCurl),
                                                #   powershell internal implementation of curl or wget which works for http, https and ftp only.
                                                # Cares http response code 3xx for auto redirections.
                                                # If url not exists then it will throw.
                                                # It seams the internal commands (WebClient and Invoke-WebRequest) cannot work with urls as "https://token@host/path"
                                                #   because they returned 404=not-found, but NetDownloadFileByCurl worked successfully.
                                                # If ignoreSslCheck is true then it will currently ignore all following calls,
                                                #   so this is no good solution (use NetDownloadFileByCurl).
                                                # Maybe later: OAuth. Ex: https://docs.github.com/en/free-pro-team@latest/rest/overview/other-authentication-methods
                                                [String] $authMethod = "Basic"; # Current implemented authMethods: "Basic".
                                                AssertNotEmpty $url "NetDownloadFile.url"; # alternative check: -or $url.EndsWith("/")
                                                if( $us -ne "" ){ AssertNotEmpty $pw "password for username=$us"; }
                                                OutProgress "NetDownloadFile $url";
                                                OutProgress "  (onlyIfNewer=$onlyIfNewer) to `"$tarFile`" ";
                                                # Check minimum secure protocol (avoid Ssl3,Tls,Tls11; require Tls12)
                                                #   On Win10 and GithubWorkflowWindowsLatest: "SystemDefault".
                                                if( [System.Net.ServicePointManager]::SecurityProtocol -notin @("SystemDefault","Tls12") ){
                                                  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
                                                }
                                                if( $ignoreSslCheck ){
                                                  # Note: This alternative is now obsolete (see https://msdn.microsoft.com/en-us/library/system.net.servicepointmanager.certificatepolicy(v=vs.110).aspx):
                                                  #   Add-Type -TypeDefinition "using System.Net; using System.Security.Cryptography.X509Certificates; public class TrustAllCertsPolicy : ICertificatePolicy { public bool CheckValidationResult( ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem){ return true; } } ";
                                                  #   [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy;
                                                  [ServerCertificateValidationCallback]::Ignore();
                                                  # Known Bug: We currently do not restore this option so it will influence all following calls.
                                                  # Maybe later we use: -SkipCertificateCheck for PS7
                                                  # TODO find another solution which does reset and is multithreading safe
                                                }
                                                if( $onlyIfNewer -and (FileExists $tarFile) ){
                                                  [DateTime] $srcTs = (NetWebRequestLastModifiedFailSafe $url);
                                                  [DateTime] $fileTs = (FsEntryGetLastModified $tarFile);
                                                  if( $srcTs -le $fileTs ){
                                                    OutProgress "  Ok, download not nessessary because timestamp of src $(DateTimeAsStringIso $srcTs) is older than target $(DateTimeAsStringIso $fileTs).";
                                                    return;
                                                  }
                                                }
                                                [String] $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0"; # some servers as api.github.com requires at least a string as "Mozilla/5.0", we take latest ESR
                                                [String] $tarDir = FsEntryGetParentDir $tarFile;
                                                DirCreate $tarDir;
                                                [System.Management.Automation.PSCredential] $cred = $(switch($us -eq ""){ ($true){$null} default{(CredentialCreate $us $pw)} });
                                                try{
                                                  [Boolean] $useWebclient = $false; # we currently use Invoke-WebRequest because its more comfortable
                                                  if( $useWebclient ){
                                                    OutVerbose "WebClient.DownloadFile(url=$url,us=$us,tar=`"$tarFile`")";
                                                    $webclient = new-object System.Net.WebClient;
                                                    # Defaults: AllowAutoRedirect is true.
                                                    $webclient.Headers.Add("User-Agent",$userAgent);
                                                    # For future use: $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded");
                                                    # not relevant because getting byte array: $webclient.Encoding = "Default"; "UTF8";
                                                    if( $us -ne "" ){
                                                      $webclient.Credentials = $cred;
                                                    }
                                                    $webclient.DownloadFile($url,$tarFile); # use DotNet function WebClient.downloadFile (maybe we also would have to implement basic header for example when using api.github.com)
                                                  }else{
                                                    # For future use: -UseDefaultCredentials, -Method, -Body, -ContentType, -TransferEncoding, -InFile
                                                    if( $us -ne "" ){
                                                      If( $authMethod -cne "Basic" ){ throw [Exception] "Currently authMethod Basic is only implemented, unknown: `"$authMethod`""; }
                                                      # https://www.ietf.org/rfc/rfc2617.txt
                                                      [String] $base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${us}:$pw"));
                                                      [Hashtable] $headers = @{ Authorization = "Basic $base64" };
                                                      # Note: on api.github.com the -Credential option is ignored
                                                      #   (see https://docs.github.com/en/free-pro-team@latest/rest/overview/other-authentication-methods ),
                                                      # so it requires the basic auth in header, but we also add $cred maybe for other servers. By the way curl -u works.
                                                      OutVerbose "Invoke-WebRequest -Uri `"$url`" -OutFile `"$tarFile`" -MaximumRedirection 2 -TimeoutSec 70 -UserAgent `"$userAgent`" -Headers `"$headers`" (Credential-User=`"$us`",authMethod=$authMethod);";
                                                      Invoke-WebRequest -Uri $url -OutFile $tarFile -MaximumRedirection 2 -TimeoutSec 70 -UserAgent $userAgent -Headers $headers -Credential $cred;
                                                    }else{
                                                      OutVerbose "Invoke-WebRequest -Uri `"$url`" -OutFile `"$tarFile`" -MaximumRedirection 2 -TimeoutSec 70 -UserAgent `"$userAgent`";";
                                                      Invoke-WebRequest -Uri $url -OutFile $tarFile -MaximumRedirection 2 -TimeoutSec 70 -UserAgent $userAgent;
                                                    }
                                                  }
                                                  [String] $stateMsg = "  Ok, downloaded $(FileGetSize $tarFile) bytes.";
                                                  OutVerbose $stateMsg;
                                                  OutProgress $stateMsg;
                                                }catch{
                                                  # ex: The request was aborted: Could not create SSL/TLS secure channel.
                                                  # ex: Ausnahme beim Aufrufen von "DownloadFile" mit 2 Argument(en):  "The server committed a protocol violation. Section=ResponseStatusLine"
                                                  # ex: System.Net.WebException: Der Remoteserver hat einen Fehler zurückgegeben: (404) Nicht gefunden.
                                                  # for future use: $fileNotExists = $_.Exception -is [System.Net.WebException] -and (([System.Net.WebException]($_.Exception)).Response.StatusCode.value__) -eq 404;
                                                  [String] $msg = $_.Exception.Message;
                                                  if( $msg.Contains("Section=ResponseStatusLine") ){ $msg = "Server returned not a valid HTTP response. "+$msg; }
                                                  $msg = "  NetDownloadFile(url=$url ,us=$us,tar=$tarFile) failed because $msg";
                                                  if( -not $errorAsWarning ){ throw [ExcMsg] $msg; } OutWarning "Warning: $msg";
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
                                                AssertNotEmpty $url "NetDownloadFileByCurl.url"; # alternative check: -or $url.EndsWith("/")
                                                if( $us -ne "" ){ AssertNotEmpty $pw "password for username=$us"; }
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
                                                  ,"--tlsv1.2"                               # Use TLSv1.2 (SSL)
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
                                                  ,"--user-agent", "`"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0`""  # Send User-Agent STRING to server (H), we take latest ESR
                                                );
                                                if( $us -ne "" ){ $opt += @( "--user", "$($us):$pw" ); }
                                                if( $ignoreSslCheck ){ $opt += "--insecure"; }
                                                if( $onlyIfNewer -and (FileExists $tarFile) ){ $opt += @( "--time-cond", $tarFile); }
                                                [String] $curlExe = ProcessGetCommandInEnvPathOrAltPaths "curl.exe" @() "Please download it from http://curl.haxx.se/download.html and install it and add dir to path env var.";
                                                [String] $curlCaCert = "$(FsEntryGetParentDir $curlExe)$(DirSep)curl-ca-bundle.crt";
                                                # 2021-10: Because windows has its own curl.exe and windows-system32 folder is one of the first folders in path var
                                                #   and does not care a file curl-ca-bundle.crt next to the exe as it is descripted in https://curl.se/docs/sslcerts.html we need a solution for it.
                                                #   So if the current curl.exe is that from system32 folder then we self are looking for crt file in path var and use it for https requests.
                                                if( $curlExe -eq "$env:SystemRoot/System32/curl.exe" ){
                                                  Get-Command -CommandType Application -Name curl-ca-bundle.crt -ErrorAction SilentlyContinue |
                                                    Select-Object -First 1 | Foreach-Object {
                                                      $curlCaCert = $_.Path; # note: the script analyser tells us that this variable is assigned but not used, why? Do we have a problem here?
                                                    };
                                                }
                                                if( -not $url.StartsWith("http:") -and (FileExists $curlCaCert) ){
                                                  $opt += @( "--cacert", $curlCaCert); }
                                                $opt += @( "--url", $url );
                                                [String] $optForTrace = $opt.Replace("--user $($us):$pw","--user $($us):***");
                                                OutProgress "NetDownloadFileByCurl $url";
                                                OutProgress "  to `"$tarFile`"";
                                                [String] $tarDir = FsEntryGetParentDir $tarFile;
                                                DirCreate $tarDir;
                                                OutVerbose "$curlExe $optForTrace";
                                                try{
                                                  [String[]] $out = @()+(& $curlExe $opt); # TODO check wether use: Int32] $rc = ScriptGetAndClearLastRc; if( $rc -ne 0 ){ [String] $err = switch($rc){ 0 {"OK"} 1 {"err"} default {"Unknown(rc=$rc)"} };
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
                                                  }elseif( $LASTEXITCODE -eq 77 ){
                                                    # curl: (77) schannel: next InitializeSecurityContext failed: SEC_E_UNTRUSTED_ROOT (0x80090325) - Die Zertifikatkette wurde von einer nicht vertrauenswürdigen Zertifizierungsstelle ausgestellt.
                                                    throw [Exception] "SEC_E_UNTRUSTED_ROOT certificate chain not trustworthy (alternatively use insecure option or add server to curl-ca-bundle.crt next to curl.exe).";
                                                  }elseif( $LASTEXITCODE -ne 0 ){
                                                    throw [Exception] "LastExitCode=$LASTEXITCODE.";
                                                  }
                                                  AssertRcIsOk $out $true;
                                                  OutVerbose (StringArrayInsertIndent $out 2); # ex: Warning: Transient problem: timeout Will retry in 5 seconds. 2 retries left.
                                                  OutProgress "  Ok, downloaded $(FileGetSize $tarFile) bytes.";
                                                }catch{
                                                  [String] $msg = "  ($curlExe $optForTrace) failed because $($_.Exception.Message)";
                                                  if( -not $errorAsWarning ){ throw [ExcMsg] $msg; } OutWarning "Warning: $msg";
                                                } }
function NetDownloadToString                  ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [String] $encodingIfNoBom = "UTF8" ){
                                                [String] $tmp = (FileGetTempFile);
                                                NetDownloadFile $url $tmp $us $pw $ignoreSslCheck $onlyIfNewer;
                                                [String] $result = (FileReadContentAsString $tmp $encodingIfNoBom);
                                                FileDelTempFile $tmp; return [String] $result; }
function NetDownloadToStringByCurl            ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Boolean] $onlyIfNewer = $false, [String] $encodingIfNoBom = "UTF8" ){
                                                [String] $tmp = (FileGetTempFile);
                                                NetDownloadFileByCurl $url $tmp $us $pw $ignoreSslCheck $onlyIfNewer;
                                                [String] $result = (FileReadContentAsString $tmp $encodingIfNoBom); FileDelTempFile $tmp; return [String] $result; }
function NetDownloadIsSuccessful              ( [String] $url ){ # test wether an url is downloadable or not
                                                [Boolean] $res = $false;
                                                try{ GlobalSetModeHideOutProgress $true; [Boolean] $ignoreSslCheck = $true;
                                                  [String] $dummyStr = NetDownloadToString $url "" "" $ignoreSslCheck; $res = $true;
                                                }catch{ OutVerbose "Ignoring problems on NetDownloadToString $url failed because $($_.Exception.Message)"; }
                                                GlobalSetModeHideOutProgress $false; return [Boolean] $res; }
function NetDownloadSite                      ( [String] $url, [String] $tarDir, [Int32] $level = 999, [Int32] $maxBytes = 0, [String] $us = "",
                                                  [String] $pw = "", [Boolean] $ignoreSslCheck = $false, [Int32] $limitRateBytesPerSec = ([Int32]::MaxValue),
                                                  [Boolean] $alsoRetrieveToParentOfUrl = $false ){
                                                # Mirror site to dir; wget: HTTP, HTTPS, FTP. Logfile is written into target dir. Password is not logged.
                                                [String] $logf = "$tarDir$(DirSep).Download.$(DateTimeNowAsStringIsoMonth).log";
                                                OutProgress "NetDownloadSite $url ";
                                                OutProgress "  (only newer files) to `"$tarDir`"";
                                                OutProgress "  Logfile: `"$logf`"";
                                                [String[]] $opt = @(
                                                   "--directory-prefix=$tarDir"
                                                  ,$(switch($alsoRetrieveToParentOfUrl){ ($true){""} default{"--no-parent"}})
                                                  ,"--no-verbose"
                                                  ,"--recursive"
                                                  ,"--level=$level" # alternatives: --level=inf
                                                  ,"--no-remove-listing" # leave .listing files for ftp
                                                  ,"--page-requisites" # download all files as images to display .html
                                                  ,"--adjust-extension" # make sure .html or .css for such types of files
                                                  ,"--backup-converted" # When converting a file, back up the original version with a .orig suffix. optimizes incremental runs.
                                                  ,"--tries=2"
                                                  ,"--waitretry=5"
                                                  ,"--referer=$url"
                                                  ,"--execute=robots=off"
                                                  ,"--user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0'" # take latest ESR
                                                  ,"--quota=$maxBytes"
                                                  ,"--limit-rate=$limitRateBytesPerSec"
                                                 #,"--wait=0.02"
                                                 #,"--timestamping"
                                                  ,$(switch($ignoreSslCheck){ ($true){"--no-check-certificate"} default{""}})
                                                    # Otherwise: ERROR: cannot verify ...'s certificate, issued by 'CN=...,C=US': Unable to locally verify the issuer's authority. To connect to ... insecurely, use `--no-check-certificate'.
                                                 #,"--convert-links"            # Convert non-relative links locally    deactivated because:  Both --no-clobber and --convert-links were specified, only --convert-links will be used.
                                                 #,"--force-html"               # When input is read from a file, force it to be treated as an HTML file. This enables you to retrieve relative links from existing HTML files on your local disk, by adding <base href="url"> to HTML, or using the --base command-line option.
                                                 #,"--input-file=$fileslist"    #
                                                 #,"--ca-certificate file.crt"  # (more see http://users.ugent.be/~bpuype/wget/#download)
                                                  ,"--no-clobber"               # skip downloads to existing files, either noclobber or timestamping ,"--timestamping"
                                                      # If a file is downloaded more than once in the same directory, Wgets behavior depends on a few options, including --no-clobber.
                                                      # In certain cases, the local file will be clobb  ered, or overwritten, upon repeated download.
                                                      # In other cases it will be preserved.
                                                      # When running Wget without --timestamping, --no-clobber, --recursive or --page-requisites downloading the same file
                                                      # in the same directory will result in the original copy of file being preserved and the second copy being named file.1.
                                                      # If that file is downloaded yet again, the third copy will be named file.2, and so on.
                                                      # This is also the behavior with -nd, even if --recursive or --page-requisites are in effect.
                                                      # When --no-clobber is specified, this behavior is suppressed, and Wget will refuse to download newer copies of file.
                                                      # Therefore, "no-clobber" is actually a misnomer in this modeits not clobbering thats prevented (as the numeric
                                                      # suffixes were already preventing clobbering), but rather the multiple version saving thats prevented.
                                                      # When running Wget with --recursive or --page-requisites, but without --timestamping, --no-directories, or --no-clobber, re-downloading
                                                      # a file will result in the new copy simply overwriting the old. Adding --no-clobber will prevent this behavior, instead
                                                      # causing the original version to be preserved and any newer copies on the server to be ignored.
                                                      # When running Wget with --timestamping, with or without --recursive or --page-requisites, the decision as to whether
                                                      # or not to download a newer copy of a file depends on the local and remote timestamp and size of the file (see Time-Stamping).
                                                      # --no-clobber may not be specified at the same time as --timestamping.
                                                      # Note that when --no-clobber is specified, files with the suffixes .html or .htm will be loaded from the local disk
                                                      # and parsed as if they had been retrieved from the Web.
                                                  ,"--no-hsts"
                                                  ,"--no-host-directories"  # no dir $tardir\domainname
                                                  ,"--local-encoding=UTF-8" # required if link urls contains utf8 which must be mapped to filesystem names (note: others as ISO-8859-1, windows-1251 do not work).
                                                  ,"--user=$us" # we take this as last option because following pw
                                                  # more about logon forms: http://wget.addictivecode.org/FrequentlyAskedQuestions
                                                  # backup without file conversions: wget -mirror --page-requisites --directory-prefix=c:\wget_files\example2 ftp://username:password@ftp.yourdomain.com
                                                  # download:                        Wget                           --directory-prefix=c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                  # download resume:                 Wget --continue                --directory-prefix=c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                  # is default: --force-directories
                                                );
                                                # maybe we should also: $url/sitemap.xml
                                                DirCreate $tarDir;
                                                [String] $stateBefore = FsEntryReportMeasureInfo $tarDir;
                                                # alternative would be for wget: Invoke-WebRequest
                                                [String] $wgetExe = ProcessGetCommandInEnvPathOrAltPaths "wget"; # ex: D:\Work\PortableProg\Tool\...
                                                FileAppendLineWithTs $logf "& `"$wgetExe`" `"$url`" $opt --password=*** ";
                                                OutProgress              "  & `"$wgetExe`" `"$url`"";
                                                & $wgetExe $url $opt "--password=$pw" "--append-output=$logf";
                                                [Int32] $rc = ScriptGetAndClearLastRc; if( $rc -ne 0 ){
                                                  [String] $err = switch($rc){
                                                    0 {"OK"}
                                                    1 {"Generic"}
                                                    2 {"CommandLineOption"}
                                                    3 {"FileIo"}
                                                    4 {"Network"}
                                                    5 {"SslVerification"}
                                                    6 {"Authentication"}
                                                    7 {"Protocol"}
                                                    8 {"ServerIssuedSomeResponse(ex:404NotFound)"}
                                                    default {"Unknown(rc=$rc)"} };
                                                  OutWarning "  Warning: Ignored one or more occurrences of error category: $err. More see logfile=`"$logf`".";
                                                }
                                                [String] $state = "  TargetDir: $(FsEntryReportMeasureInfo "$tarDir") (BeforeStart: $stateBefore)";
                                                FileAppendLineWithTs $logf $state;
                                                OutProgress $state; }
<# Script local variable: gitLogFile #>       [String] $script:gitLogFile = "${env:TEMP}/MnCommonPsToolLibLog/Git.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
function GitBuildLocalDirFromUrl              ( [String] $tarRootDir, [String] $urlAndOptionalBranch ){
                                                # Maps a root dir and a repo url with an optional sharp-char separated branch name
                                                # to a target repo dir which contains all url fragments below the hostname.
                                                # ex: (GitBuildLocalDirFromUrl "C:\WorkGit\" "https://github.com/mniederw/MnCommonPsToolLib")          == "C:\WorkGit\mniederw\MnCommonPsToolLib";
                                                # ex: (GitBuildLocalDirFromUrl "C:\WorkGit\" "https://github.com/mniederw/MnCommonPsToolLib#MyBranch") == "C:\WorkGit\mniederw\MnCommonPsToolLib#MyBranch";
                                                return [String] (FsEntryGetAbsolutePath (Join-Path $tarRootDir (([System.Uri]$urlAndOptionalBranch).AbsolutePath+([System.Uri]$urlAndOptionalBranch).Fragment).Replace("\",$(DirSep)).Replace("/",$(DirSep)))); }
function GitCmd                               ( [String] $cmd, [String] $tarRootDir, [String] $urlAndOptionalBranch, [Boolean] $errorAsWarning = $false ){
                                                # For commands:
                                                #   "Clone"       : Creates a full local copy of specified repo. Target dir must not exist.
                                                #                   Branch can be optionally specified, in that case it also will switch to this branch.
                                                #                   Default branch name is where the standard remote HEAD is pointing to, usually "master".
                                                #   "Fetch"       : Get all changes from specified repo to local repo but without touching current working files.
                                                #                   Target dir must exist. Branch in repo url can be optionally specified but no switching will be done.
                                                #   "Pull"        : First a Fetch and then it also merges current branch into current working files.
                                                #                   Target dir must exist. Branch in repo url can be optionally specified but no switching will be done.
                                                #   "CloneOrPull" : if target not exists then Clone otherwise Pull.
                                                #   "CloneOrFetch": if target not exists then Clone otherwise Fetch.
                                                #   "Reset"       : Reset-hard, loose all local changes. Same as delete folder and clone, but faster.
                                                #                   Target dir must exist. If branch is specified then it will switch to it, otherwise will switch to main (or master).
                                                # Target-Dir: see GitBuildLocalDirFromUrl.
                                                # The urlAndOptionalBranch defines a repo url optionally with a sharp-char separated branch name (allowed chars: A-Z,a-z,0-9,.,_,-).
                                                # We assert the no AutoCrLf is used.
                                                # Pull-No-Rebase: We generally use no-rebase for pull because commit history should not be modified.
                                                # ex: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib"
                                                # ex: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib#MyBranch"
                                                if( @("Clone","Fetch","Pull","CloneOrPull","Reset") -notcontains $cmd ){
                                                  throw [Exception] "Expected one of (Clone,Fetch,Pull,CloneOrPull,Reset) instead of: $cmd"; }
                                                if( ($urlAndOptionalBranch -split "/")[-1] -notmatch "^[A-Za-z0-9]+[A-Za-z0-9._-]*(#[A-Za-z0-9]+[A-Za-z0-9._-]*)?$" ){
                                                  throw [Exception] "Expected only ident-chars as (letter,numbers,.,_,-) for last part of `"$urlAndOptionalBranch`"."; }
                                                [String[]] $urlOpt = @()+(StringSplitToArray "#" $urlAndOptionalBranch);
                                                [String] $url = $urlOpt[0]; # repo url without branch.
                                                [String] $branch = "";
                                                if( $urlOpt.Count -gt 1 ){ $branch = $urlOpt[1]; AssertNotEmpty $branch "branch in urlAndBranch=`"$urlAndOptionalBranch`". "; }
                                                if( $urlOpt.Count -gt 2 ){ throw [Exception] "Unknown third param in urlAndBranch=`"$urlAndOptionalBranch`". "; }
                                                [String] $dir = FsEntryRemoveTrailingDirSep (GitBuildLocalDirFromUrl $tarRootDir $urlAndOptionalBranch);
                                                GitAssertAutoCrLfIsDisabled;
                                                if( $cmd -eq "CloneOrPull"  ){ if( (DirNotExists $dir) ){ $cmd = "Clone"; }else{ $cmd = "Pull" ; }}
                                                if( $cmd -eq "CloneOrFetch" ){ if( (DirNotExists $dir) ){ $cmd = "Clone"; }else{ $cmd = "Fetch"; }}
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
                                                    # Defaults: "origin";
                                                    $gitArgs = @( "-C", $dir, "--git-dir=.git", "pull", "--quiet", "--no-stat", "--no-rebase", $url);
                                                    if( $branch -ne "" ){ $gitArgs += @( $branch ); }
                                                  }elseif( $cmd -eq "Reset" ){
                                                    GitCmd "Fetch" $tarRootDir $urlAndOptionalBranch $errorAsWarning;
                                                    $gitArgs = @( "-C", $dir, "--git-dir=.git", "reset", "--hard", <# "--quiet", #> $url);
                                                    # if( $branch -ne "" ){ $gitArgs += @( $branch ); }
                                                    # alternative option: --hard origin/master
                                                  }else{ throw [Exception] "Unknown git cmd=`"$cmd`""; }
                                                  FileAppendLineWithTs $gitLogFile "GitCmd(`"$tarRootDir`",$urlAndOptionalBranch) git $(StringArrayDblQuoteItems $gitArgs)";
                                                  # ex: "git" "-C" "C:\Temp\mniederw\myrepo" "--git-dir=.git" "pull" "--quiet" "--no-stat" "--no-rebase" "https://github.com/mniederw/myrepo"
                                                  # ex: "git" "clone" "--quiet" "--branch" "MyBranch" "--" "https://github.com/mniederw/myrepo" "C:\Temp\mniederw\myrepo#MyBranch"
                                                  # TODO low prio: if (cmd is Fetch or Pull) and branch is not empty and current branch does not match specified branch then output progress message about it.
                                                  # TODO middle prio: check env param pull.rebase and think about display and usage
                                                  [String] $out = (ProcessStart "git" $gitArgs -careStdErrAsOut:$true -traceCmd:$true);
                                                  # Skip known unused strings which are written to stderr as:
                                                  # - "Checking out files:  47% (219/463)" or "Checking out files: 100% (463/463), done."
                                                  # - warning: You appear to have cloned an empty repository.
                                                  # - The string "Already up to date." is presumebly suppressed by quiet option.
                                                  StringSplitIntoLines $out | Where-Object{$null -ne $_} | Where-Object{ StringIsFilled $_ } |
                                                    ForEach-Object{ $_.Trim() } |
                                                    Where-Object{ -not ($_.StartsWith("Checking out files: ") -and ($_.EndsWith(")") -or $_.EndsWith(", done."))) } |
                                                    ForEach-Object{ OutProgress $_; }
                                                  OutSuccess "  Ok, usedTimeInSec=$([Int64]($usedTime.Elapsed.TotalSeconds+0.999)) for url: $url";
                                                }catch{
                                                  # ex:              fatal: HttpRequestException encountered.
                                                  # ex:              Fehler beim Senden der Anforderung.
                                                  # ex:              fatal: AggregateException encountered.
                                                  # ex:              Logon failed, use ctrl+c to cancel basic credential prompt.  - bash: /dev/tty: No such device or address - error: failed to execute prompt script (exit code 1) - fatal: could not read Username for 'https://github.com': No such file or directory
                                                  # ex: Clone rc=128 remote: Repository not found.\nfatal: repository 'https://github.com/mniederw/UnknownRepo/' not found
                                                  # ex:              fatal: Not a git repository: 'D:\WorkGit\mniederw\UnknownRepo\.git'
                                                  # ex:              error: unknown option `anyUnknownOption'
                                                  # ex: Pull  rc=128 fatal: refusing to merge unrelated histories
                                                  # ex: Pull  rc=128 error: Pulling is not possible because you have unmerged files. - hint: Fix them up in the work tree, and then use 'git add/rm <file>' - fatal: Exiting because of an unresolved conflict. - hint: as appropriate to mark resolution and make a commit.
                                                  # ex: Pull  rc=128 fatal: Exiting because of an unresolved conflict. - error: Pulling is not possible because you have unmerged files. - hint: as appropriate to mark resolution and make a commit. - hint: Fix them up in the work tree, and then use 'git add/rm <file>'
                                                  # ex: Pull  rc=1   fatal: Couldn't find remote ref HEAD    (in case the repo contains no content)
                                                  # ex:              error: Your local changes to the following files would be overwritten by merge:   (Then the lines: "        ...file..." "Aborting" "Please commit your changes or stash them before you merge.")
                                                  # ex:              error: The following untracked working tree files would be overwritten by merge:   (Then the lines: "        ....file..." "Please move or remove them before you merge." "Aborting")
                                                  # ex: Pull  rc=1   Auto-merging dir1/file1  CONFLICT (add/add): Merge conflict in dir1/file1  Automatic merge failed; fix conflicts and then commit the result.\nwarning: Cannot merge binary files: dir1/file1 (HEAD vs. ab654...)
                                                  # ex: Pull  rc=1   fatal: unable to access 'https://github.com/anyUser/anyGitRepo/': Failed to connect to github.com port 443: Timed out
                                                  # ex: Pull  rc=1   fatal: TaskCanceledException encountered. -    Eine Aufgabe wurde abgebrochen. - bash: /dev/tty: No such device or address - error: failed to execute prompt script (exit code 1) - fatal: could not read Username for 'https://github.com': No such file or directory
                                                  $msg = "$(ScriptGetCurrentFunc)($cmd,$tarRootDir,$url) failed because $(StringReplaceNewlines $_.Exception.Message ' - ')";
                                                  ScriptResetRc;
                                                  if( $cmd -eq "Pull" -and ( $msg.Contains("error: Your local changes to the following files would be overwritten by merge:") -or
                                                                             $msg.Contains("error: Pulling is not possible because you have unmerged files.") -or
                                                                             $msg.Contains("fatal: Exiting because of an unresolved conflict.") ) ){
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
                                                  if( -not $errorAsWarning ){ throw [ExcMsg] $msg; }
                                                  OutWarning "Warning: $msg";
                                                } }
function GitShowUrl                           ( [String] $repoDir ){
                                                # Example: "https://github.com/mniederw/MnCommonPsToolLib"
                                                [String] $out = (& "git" "--git-dir=$repoDir/.git" "config" "remote.origin.url"); AssertRcIsOk $out;
                                                return [String] $out; }
function GitShowRepo                          ( [String] $repoDir ){
                                                # Example: "mniederw/MnCommonPsToolLib"
                                                [String] $url = (GitShowUrl $repoDir);
                                                ToolGithubApiAssertValidRepoUrl $url;
                                                [String] $githubUrl = "https://github.com/";
                                                Assert ($url.StartsWith($githubUrl)) "Expected $url starts with $githubUrl";
                                                return [String] (StringRemoveLeft $url $githubUrl); }
function GitShowBranch                        ( [String] $repoDir ){
                                                # return current branch (example: "master").
                                                [String] $out = (ProcessStart "git" @("-C", (FsEntryRemoveTrailingDirSep $repoDir), "--git-dir=.git", "branch") -traceCmd:$false);
                                                [String] $firstLine = StringSplitIntoLines $out | Select-Object -First 1;
                                                # in future when newer version of git is common then we can use new option for get current-branch.
                                                Assert ($firstLine.StartsWith("* ")) "expected result of git branch command begins with `"* `" but got `"$firstLine`"";
                                                return [String] (StringRemoveLeft $firstLine "* ").Trim(); }
function GitShowChanges                       ( [String] $repoDir ){
                                                # return changed, deleted and new files or dirs. Per entry one line prefixed with a change code.
                                                [String] $out = (ProcessStart "git" @("-C", (FsEntryRemoveTrailingDirSep $repoDir), "--git-dir=.git", "status", "--short") -traceCmd:$false);
                                                return [String[]] (@()+(StringSplitIntoLines $out |
                                                  Where-Object{$null -ne $_} |
                                                  Where-Object{ StringIsFilled $_; })); }
function GitSwitch                            ( [String] $repoDir, [String] $branch ){
                                                [String] $dummy = (ProcessStart "git" @("-C", (FsEntryRemoveTrailingDirSep $repoDir), "switch", $branch) -careStdErrAsOut:$true -traceCmd:$true); }
function GitAdd                               ( [String] $fsEntryToAdd ){
                                                [String] $repoDir = FsEntryGetAbsolutePath "$(FsEntryFindInParents $fsEntryToAdd ".git")/.."; # not trailing slash allowed
                                                [String] $dummy = (ProcessStart "git" @("-C", $repoDir, "add", $fsEntryToAdd) -traceCmd:$true); }
function GitMerge                             ( [String] $repoDir, [String] $branch, [Boolean] $errorAsWarning = $false ){
                                                # merge branch (remotes/origin) into current repodir, no-commit, no-fast-forward
                                                Assert ($branch.Length -gt 0) "branch name is empty";
                                                try{
                                                  [String] $out = (ProcessStart "git" @("-C", (FsEntryRemoveTrailingDirSep $repoDir), "--git-dir=.git", "merge", "--no-commit", "--no-ff", "remotes/origin/$branch") -careStdErrAsOut:$true -traceCmd:$false);
                                                  # Example output to console but not to stdout:
                                                  #   Auto-merging MyDir/MyFile.txt
                                                  #   CONFLICT (content): Merge conflict in MyDir/MyFile.txt
                                                  #   CONFLICT (rename/delete): MyDir/MyFile.txt renamed to MyDir2/MyFile.txt in HEAD, but deleted in remotes/origin/mybranch
                                                  #   CONFLICT (modify/delete): MyDir/MyFile.txt deleted in remotes/origin/mybranch and modified in HEAD.  Version HEAD of MyDir/MyFile.txt left in tree.
                                                  #   CONFLICT (file location): MyDir/MyFile.txt added in remotes/origin/mybranch inside a directory that was renamed in HEAD, suggesting it should perhaps be moved to MyDir2/MyFile.txt
                                                  #   Automatic merge failed; fix conflicts and then commit the result.
                                                  OutProgress $out;
                                                }catch{
                                                  if( -not $errorAsWarning ){ throw [Exception] "Merge failed, fix conflicts manually: $_.Exception.Message"; }
                                                  OutWarning "Merge of branch $branch into `"$repoDir`" failed, fix conflicts manually. ";
                                                } }
function GithubAuthStatus                     (){
                                                [String] $out = (ProcessStart "gh" @("auth", "status") -careStdErrAsOut:$true -traceCmd:$true);
                                                # Output:
                                                #   github.com
                                                #     Ô£ô Logged in to github.com as myowner (C:\Users\myuser\AppData\Roaming\GitHub CLI\hosts.yml)
                                                #     Ô£ô Git operations for github.com configured to use https protocol.
                                                #     Ô£ô Token: *******************
                                                OutProgress $out; }
function GithubListPullRequests               ( [String] $repo, [String] $filterToBranch = "", [String] $filterFromBranch = "", [String] $filterState = "open" ){
                                                # repo has format [HOST/]OWNER/REPO
                                                [String] $fields = "number,state,createdAt,title,labels,author,assignees,updatedAt,url,body,closedAt,repository,authorAssociation,commentsCount,isLocked,isPullRequest,id";
                                                [String] $out = (ProcessStart "gh" @("search", "prs", "--repo", $repo, "--state", $filterState, "--base", $filterToBranch, "--head", $filterFromBranch, "--json", $fields) -traceCmd:$true);
                                                return ($out | ConvertFrom-Json); }
function GithubCreatePullRequest              ( [String] $repo, [String] $toBranch, [String] $fromBranch, [String] $title = "", [String] $repoDirForCred = "" ){
                                                # repoDirForCred : Any folder under any git repository, from which the credentials will be taken, use empty for current dir.
                                                # default title is "Merge $fromBranch into $toBranch"
                                                # repo has format [HOST/]OWNER/REPO
                                                OutProgress "Create a github-pull-request from $fromBranch to $toBranch in repo: $repo";
                                                if( $title -eq "" ){ $title = "Merge $fromBranch to $toBranch"; }
                                                [String[]] $prUrls = @()+(GithubListPullRequests $repo $toBranch $fromBranch |
                                                  Where-Object{$null -ne $_} | ForEach-Object{ $_.url });
                                                if( $prUrls.Count -gt 0 ){
                                                  OutProgress "A pull request for branch $fromBranch into $toBranch already exists: $($prUrls[0])";
                                                  return;
                                                }
                                                Push-Location $repoDirForCred;
                                                [String] $out = "";
                                                try{
                                                  $out = (ProcessStart "gh" @("pr", "create", "--repo", $repo, "--base", $toBranch, "--head", $fromBranch, "--title", $title, "--body", " ") -careStdErrAsOut:$true -traceCmd:$true);
                                                }catch{
                                                  if( $_.Exception.Message.Contains("pull request create failed: GraphQL: No commits between ") ){
                                                    $error.clear();
                                                    OutInfo "No pull request nessessary because no commit between $toBranch and $fromBranch .";
                                                  }else{ throw; }
                                                }
                                                Pop-Location;
                                                # Output:
                                                #   Warning: 2 uncommitted changes
                                                #   Creating pull request for myfrombranch into main in myowner/myrepo
                                                #   a pull request for branch "myfrombranch" into branch "main" already exists:
                                                #   https://github.com/myowner/myrepo/pull/1234
                                                # Possible errors:
                                                #   rc=1  https://github.com/myowner/myrepo/pull/1234 a pull request for branch "mybranch" into branch "main" already exists:
                                                #   rc=1  pull request create failed: GraphQL: No commits between QA and Develop (createPullRequest)
                                                OutProgress $out; }
function GitTortoiseCommit                    ( [String] $workDir, [String] $commitMessage = "" ){
                                                [String] $tortoiseExe = (RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseGit" "ProcPath"); # ex: "C:\Program Files\TortoiseGit\bin\TortoiseGitProc.exe"
                                                Start-Process -NoNewWindow -Wait -FilePath "$tortoiseExe" -ArgumentList @("/command:commit","/path:`"$workDir`"", "/logmsg:$commitMessage"); AssertRcIsOk; }
function GitListCommitComments                ( [String] $tarDir, [String] $localRepoDir, [String] $fileExtension = ".tmp",
                                                  [String] $prefix = "Log.", [Int32] $doOnlyIfOlderThanAgeInDays = 14 ){
                                                # Reads commit messages and changed files info from localRepoDir
                                                # and overwrites it to two target files to target dir.
                                                # For building the filenames it takes the two last dir parts and writes the files with the names:
                                                # - Log.NameOfRepoParent.NameOfRepo.CommittedComments.tmp
                                                # - Log.NameOfRepoParent.NameOfRepo.CommittedChangedFiles.tmp
                                                # It is quite slow about 10 sec per repo, so it can be controlled by $doOnlyIfOlderThanAgeInDays.
                                                # In case of a git error it outputs it as warning.
                                                # ex: GitListCommitComments "C:\WorkGit\_CommitComments" "C:\WorkGit\mniederw\MnCommonPsToolLib"
                                                [String] $dir = FsEntryGetAbsolutePath $localRepoDir;
                                                [String] $repoName =  (Split-Path -Leaf (Split-Path -Parent $dir)) + "." + (Split-Path -Leaf $dir);
                                                function GitGetLog ([Boolean] $doSummary, [String] $fout) {
                                                  $fout = FsEntryGetAbsolutePath $fout;
                                                  if( -not (FsEntryNotExistsOrIsOlderThanNrDays $fout $doOnlyIfOlderThanAgeInDays) ){
                                                    OutProgress "Process git log not nessessary because file is newer than $doOnlyIfOlderThanAgeInDays days: $fout";
                                                  }else{
                                                    [String[]] $options = @( "--git-dir=$dir\.git", "log", "--after=1990-01-01", "--pretty=format:%ci %cn [%ce] %s" );
                                                    if( $doSummary ){ $options += "--summary"; }
                                                    [String] $out = "";
                                                    try{
                                                      $out = (ProcessStart "git" $options -careStdErrAsOut:$true -traceCmd:$true); # git can write warnings to stderr which we not handle as error
                                                    }catch{
                                                      # ex: ProcessStart of ("git" "--git-dir=D:\WorkExternal\SrcGit\mniederw\MnCommonPsToolLib\.git" "log" "--after=1990-01-01" "--pretty=format:%ci %cn [%ce] %s" "--summary") failed with rc=128\nfatal: your current branch 'master' does not have any commits yet
                                                      if( $_.Exception.Message.Contains("fatal: your current branch '") -and $_.Exception.Message.Contains("' does not have any commits yet") ){ # Last operation failed [rc=128]
                                                        $out +=  "$([Environment]::NewLine)" + "Info: your current branch 'master' does not have any commits yet.";
                                                        OutProgress "  Info: Empty branch without commits.";
                                                      }else{
                                                        $out += "$([Environment]::NewLine)" + "Warning: (GitListCommitComments `"$tarDir`" `"$localRepoDir`" `"$fileExtension`" `"$prefix`" `"$doOnlyIfOlderThanAgeInDays`") ";
                                                        $out += "$([Environment]::NewLine)" + "  failed because $($_.Exception.Message)";
                                                        if( $_.Exception.Message.Contains("warning: inexact rename detection was skipped due to too many files.") ){
                                                          $out += "$([Environment]::NewLine)" + "  The reason is that the config value of diff.renamelimit with its default of 100 is too small. ";
                                                          $out += "$([Environment]::NewLine)" + "  Before a next retry you should either add the two lines (`"[diff]`",`"  renamelimit = 999999`") to .git/config file, ";
                                                          $out += "$([Environment]::NewLine)" + "  or run (git `"--git-dir=$dir\.git`" config diff.renamelimit 999999) ";
                                                          $out += "$([Environment]::NewLine)" + "  or run (git config --global diff.renamelimit 999999). Instead of 999999 you can also try a lower value as 200,400, etc. ";
                                                        }else{
                                                          $out += "$([Environment]::NewLine)" + "  Outfile `"$fout`" is probably not correctly filled.";
                                                        }
                                                        OutWarning $out;
                                                      }
                                                      ScriptResetRc;
                                                    }
                                                    FileWriteFromLines $fout $out $true;
                                                  }
                                                }
                                                GitGetLog $false "$tarDir/$prefix$repoName.CommittedComments$fileExtension";
                                                GitGetLog $true  "$tarDir/$prefix$repoName.CommittedChangedFiles$fileExtension"; }
function GitAssertAutoCrLfIsDisabled          (){ # use this before using git; do not use core.autocrlf=true because it will lead sometimes to conflicts;
                                                [String] $line1 = (StringMakeNonNull (& "git" "config" "--list" "--global" | Where-Object{ $_ -like "core.autocrlf=true" })); AssertRcIsOk;
                                                [String] $line2 = (StringMakeNonNull (& "git" "config" "--list" "--system" | Where-Object{ $_ -like "core.autocrlf=true" })); AssertRcIsOk;
                                                if( $line1 -ne "" -or $line2 -ne "" ){
                                                  [String] $errmsg = "it is strongly recommended never use this because unexpected state and merge behaviours. Please change it by calling GitDisableAutoCrLf and then retry.";
                                                  if( $line1 -ne "" ){ throw [ExcMsg] "Git is globally configured to use autocrlf conversions, $errmsg"; }
                                                  if( $line2 -ne "" ){ throw [ExcMsg] "Git is systemwide configured to use autocrlf conversions, $errmsg"; }
                                                }
                                                OutVerbose "ok, git-autocrlf is globally and systemwide defined as false or undefined."; }
function GitSetGlobalVar                      ( [String] $var, [String] $val, [Boolean] $useSystemNotGlobal = $false ){
                                                # if val is empty then it will unset the var.
                                                # If option $useSystemNotGlobal is true then system-wide variable are set instead of the global.
                                                # The order of priority for configuration levels is: local, global, system.
                                                AssertNotEmpty $var;
                                                # check if defined
                                                [String] $globalScope = "--global"; if( $useSystemNotGlobal ){ $globalScope = "--system"; }
                                                [String] $a = "$(& "git" "config" "--list" $globalScope | Where-Object{ $_ -like "$var=*" })"; AssertRcIsOk;
                                                 # if defined then we can get value; this statement would throw if var would not be defined
                                                if( $a -ne "" ){ $a = (& "git" "config" $globalScope $var); AssertRcIsOk; }
                                                if( $a -eq $val ){
                                                  OutDebug "GitSetVar$($globalScope): $var=`"$val`" was already done.";
                                                }else{
                                                  if( $val -eq "" ){
                                                    OutProgress "GitSetVar$($globalScope): $var=`"$val`" (will unset var)";
                                                    & "git" "config" $globalScope --unset $var; AssertRcIsOk;
                                                  }else{
                                                    OutProgress "GitSetVar$($globalScope): $var=`"$val`" ";
                                                    & "git" "config" $globalScope $var $val; AssertRcIsOk;
                                                  }
                                                } }
function GitDisableAutoCrLf                   (){ # no output if nothing done.
                                                GitSetGlobalVar "core.autocrlf" "false"; GitSetGlobalVar "core.autocrlf" "false" $true; }
function GitCloneOrPullUrls                   ( [String[]] $listOfRepoUrls, [String] $tarRootDirOfAllRepos, [Boolean] $errorAsWarning = $false ){
                                                # Works later multithreaded and errors are written out, collected and throwed at the end.
                                                # If you want single threaded then call it with only one item in the list.
                                                [String[]] $errorLines = @();
                                                function GetOne( [String] $url ){
                                                  try{
                                                    GitCmd "CloneOrPull" $tarRootDirOfAllRepos $url $errorAsWarning;
                                                  }catch{
                                                    [String] $msg = $_.Exception.Message; OutError $msg; $errorLines += $msg;
                                                  }
                                                }
                                                if( $listOfRepoUrls.Count -eq 1 ){ GetOne $listOfRepoUrls[0]; }
                                                else{
                                                  [String] $tmp = (FileGetTempFile);
                                                  $listOfRepoUrls | ForEach-Object { Start-ThreadJob -ThrottleLimit 8 -StreamingHost $host -ScriptBlock {
                                                    try{
                                                      GitCmd "CloneOrPull" $using:tarRootDirOfAllRepos $using:_ $using:errorAsWarning;
                                                    }catch{
                                                      [String] $msg = $_.Exception.Message; OutError $msg;
                                                      FileAppendLine $using:tmp $msg;
                                                    }
                                                  } } | Wait-Job | Remove-Job;
                                                  [String] $errMsg = (FileReadContentAsString $tmp); FileDelTempFile $tmp;
                                                  if( $errMsg -ne "" ){ $errorLines += $errMsg; }
                                                }
                                                # alternative not yet works because vars: $listOfRepoUrls | Where-Object{$null -ne $_} | ForEachParallel -MaxThreads 10 { GitCmd "CloneOrPull" $tarRootDirOfAllRepos $_ $errorAsWarning; } }
                                                # old else{ $listOfRepoUrls | Where-Object{$null -ne $_} | ForEach-Object { GetOne $_; } }
                                                if( $errorLines.Count ){ throw [ExcMsg] (StringArrayConcat $errorLines); } }
<# Type: SvnEnvInfo #>                        Add-Type -TypeDefinition "public struct SvnEnvInfo {public string Url; public string Path; public string RealmPattern; public string CachedAuthorizationFile; public string CachedAuthorizationUser; public string Revision; }";
                                                # ex: Url="https://myhost/svn/Work"; Path="D:\Work"; RealmPattern="https://myhost:443";
                                                # CachedAuthorizationFile="$env:APPDATA\Subversion\auth\svn.simple\25ff84926a354d51b4e93754a00064d6"; CachedAuthorizationUser="myuser"; Revision="1234"
function SvnExe                               (){ # Note: if certificate is not accepted then a pem file (for example lets-encrypt-r3.pem) can be added to file "$env:APPDATA\Subversion\servers"
                                                return [String] ((RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "Directory") + ".\bin\svn.exe"); }
<# Script local variable: svnLogFile #>       [String] $script:svnLogFile = "${env:TEMP}/MnCommonPsToolLibLog/Svn.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
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
                                                [String[]] $out = @()+(& (SvnExe) "info" $workDir); AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                [String[]] $out2 = @()+(& (SvnExe) "propget" "svn:ignore" "-R" $workDir); AssertRcIsOk $out2;
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
                                                # Note: If the file is already under version control or shows up as M instead of I, then youll first have to svn delete the file from the repository (make a backup of it somewhere first),
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
                                                [String] $svnCachedAuthorizationDir = "$env:APPDATA$(DirSep)Subversion$(DirSep)auth$(DirSep)svn.simple";
                                                # Care only file names like "25ff84926a354d51b4e93754a00064d6"
                                                [String[]] $files = (@()+(FsEntryListAsStringArray "$svnCachedAuthorizationDir$(DirSep)*" $false $false |
                                                  Where-Object{$null -ne $_} |
                                                  Where-Object{ (FsEntryGetFileName $_) -match "^[0-9a-f]{32}$" } |
                                                  Sort-Object));
                                                [String] $encodingIfNoBom = "Default";
                                                foreach( $f in $files ){
                                                  [String[]] $lines = @()+(FileReadContentAsLines $f $encodingIfNoBom);
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
                                                return [SvnEnvInfo] $result; }
function SvnGetDotSvnDir                      ( $workSubDir ){
                                                # Return absolute .svn dir up from given dir which must exists.
                                                [String] $d = FsEntryGetAbsolutePath $workSubDir;
                                                for( [Int32] $i = 0; $i -lt 200; $i++ ){
                                                  if( DirExists "$d$(DirSep).svn" ){ return [String] "$d$(DirSep).svn"; }
                                                  $d = FsEntryGetAbsolutePath (Join-Path $d "..");
                                                }
                                                throw [Exception] "Missing directory '.svn' within or up from the path `"$workSubDir`""; }
function SvnAuthorizationSave                ( [String] $workDir, [String] $user ){
                                                # If this part fails then you should clear authorization account in svn settings.
                                                OutProgress "SvnAuthorizationSave user=$user";
                                                FileAppendLineWithTs $svnLogFile "SvnAuthorizationSave(`"$workDir`")";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                DirCopyToParentDirByAddAndOverwrite "$env:APPDATA$(DirSep)Subversion$(DirSep)auth$(DirSep)svn.simple" "$dotSvnDir$(DirSep)OwnSvnAuthSimpleSaveUser_$user$(DirSep)"; }
function SvnAuthorizationTryLoadFile          ( [String] $workDir, [String] $user ){
                                                # If work auth dir exists then copy content to svn cache dir.
                                                OutProgress "SvnAuthorizationTryLoadFile - try to reload from an earlier save";
                                                FileAppendLineWithTs $svnLogFile "SvnAuthorizationTryLoadFile(`"$workDir`")";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                [String] $svnWorkAuthDir = "$dotSvnDir$(DirSep)OwnSvnAuthSimpleSaveUser_$user$(DirSep)svn.simple";
                                                [String] $svnAuthDir = "$env:APPDATA$(DirSep)Subversion$(DirSep)auth$(DirSep)";
                                                if( DirExists $svnWorkAuthDir ){
                                                  DirCopyToParentDirByAddAndOverwrite $svnWorkAuthDir $svnAuthDir;
                                                }else{
                                                  OutProgress "Load not done because not found dir: `"$svnWorkAuthDir`"";
                                                } } # For later usage: function SvnAuthorizationClear (){ FileAppendLineWithTs $svnLogFile "SvnAuthorizationClear"; [String] $svnAuthCurr = "$env:APPDATA$(DirSep)Subversion$(DirSep)auth$(DirSep)svn.simple"; DirCopyToParentDirByAddAndOverwrite $svnAuthCurr $svnAuthWork; }
function SvnCleanup                           ( [String] $workDir ){
                                                # Cleanup a previously failed checkout, update or commit operation.
                                                FileAppendLineWithTs $svnLogFile "SvnCleanup(`"$workDir`")";
                                                # For future alternative option: --trust-server-cert-failures unknown-ca,cn-mismatch,expired,not-yet-valid,other
                                                [String[]] $out = @()+(& (SvnExe) "cleanup" --non-interactive $workDir); AssertRcIsOk $out;
                                                # At 2022-01 we got:
                                                #   svn: E155009: Failed to run the WC DB work queue associated with '\\myserver\MyShare\Work', work item 363707 (sync-file-flags 102 MyDir/MyFile.ext)
                                                #   svn: E720002: Can't set file '\\myserver\MyShare\Work\MyDir\MyFile.ext' read-write: Das System kann die angegebene Datei nicht finden.
                                                #   Then manually the missing file had to be put to the required location.
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
                                                [Int32] $nrOfCommitRelevantChanges = ([String[]](@()+($out |
                                                  Where-Object{ $null -ne $_ -and -not $_.StartsWith("!") }))).Count; # ignore lines with leading '!' because these would not occurre in commit dialog
                                                OutProgress "NrOfPendingChanged=$nrOfPendingChanges;  NrOfCommitRelevantChanges=$nrOfCommitRelevantChanges;";
                                                FileAppendLineWithTs $svnLogFile "  NrOfPendingChanges=$nrOfPendingChanges;  NrOfCommitRelevantChanges=$nrOfCommitRelevantChanges;";
                                                [Boolean] $hasAnyChange = $nrOfCommitRelevantChanges -gt 0;
                                                if( $showFiles -and $hasAnyChange ){
                                                  $out | Where-Object{$null -ne $_} | ForEach-Object{ OutProgress $_; }; }
                                                return [Boolean] $hasAnyChange; }
function SvnRevert                            ( [String] $workDir, [String[]] $relativeRevertFsEntries ){
                                                # Undo the specified fs-entries if they have any pending change.
                                                foreach( $f in $relativeRevertFsEntries ){
                                                  FileAppendLineWithTs $svnLogFile "SvnRevert(`"$workDir$(DirSep)$f`")";
                                                  [String[]] $out = @()+(& (SvnExe) "revert" "--recursive" "$workDir$(DirSep)$f"); AssertRcIsOk $out;
                                                  FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                } }
function SvnTortoiseCommit                    ( [String] $workDir ){
                                                FileAppendLineWithTs $svnLogFile "SvnTortoiseCommit(`"$workDir`") call checkin dialog";
                                                [String] $tortoiseExe = (RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "ProcPath"); # ex: "C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe"
                                                Start-Process -NoNewWindow -Wait -FilePath "$tortoiseExe" -ArgumentList @("/closeonend:2","/command:commit","/path:`"$workDir`""); AssertRcIsOk; }
function SvnUpdate                            ( [String] $workDir, [String] $user ){
                                                SvnCheckoutAndUpdate $workDir "" $user $true; }
function SvnCheckoutAndUpdate                 ( [String] $workDir, [String] $url, [String] $user, [Boolean] $doUpdateOnly = $false, [String] $pw = "", [Boolean] $ignoreSslCheck = $false ){
                                                # Init working copy and get (init and update) last changes. If pw is empty then it uses svn-credential-cache.
                                                # If specified update-only then no url is nessessary but if given then it verifies it.
                                                # Note: we do not use svn-update because svn-checkout does the same (the difference is only the use of an url).
                                                # Note: sometimes often after 5-20 GB received there is a network problem which aborts svn-checkout,
                                                #   so if it is recognised as a known exception then it will automatically do a cleanup, wait for 30 sec and retry (max 100 times).
                                                if( $doUpdateOnly ){
                                                  Assert ((DirExists $workDir) -and (SvnGetDotSvnDir $workDir)) "missing work dir or it is not a svn repo: `"$workDir`"";
                                                  [String] $repoUrl = (SvnEnvInfoGet $workDir).Url;
                                                  if( $url -eq "" ){ $url = $repoUrl; }else{ Assert ($url -eq $repoUrl) "given url=$url does not match url in repository: $repoUrl"; }
                                                }
                                                [String] $tmp = (FileGetTempFile);
                                                [Int32] $maxNrOfTries = 100; [Int32] $nrOfTries = 0;
                                                while($true){ $nrOfTries++;
                                                  OutProgress "SvnCheckoutAndUpdate: get all changes from $url to `"$workDir`" $(switch($doUpdateOnly){($true){''}default{'and if it not exists and then init working copy first'}}).";
                                                  FileAppendLineWithTs $svnLogFile "SvnCheckoutAndUpdate(`"$workDir`",$url,$user)";
                                                  # For future alternative option: --trust-server-cert-failures unknown-ca,cn-mismatch,expired,not-yet-valid,other
                                                  # For future alternative option: --quite
                                                  [String[]] $opt = @( "--non-interactive", "--ignore-externals" );
                                                  if( $ignoreSslCheck ){ $opt += "--trust-server-cert"; }
                                                  if( $user -ne "" ){ $opt += @( "--username", $user ); }
                                                  if( $pw -ne "" ){ $opt += @( "--password", $pw, "--no-auth-cache" ); } # is visible in process list.
                                                  # Alternative for checkout: tortoiseExe /closeonend:2 /command:checkout /path:$workDir /url:$url
                                                  if( $doUpdateOnly ){ $opt = @( "update"  ) + $opt + @(       $workDir ); }
                                                  else               { $opt = @( "checkout") + $opt + @( $url, $workDir ); }
                                                  [String] $logline = $opt; $logline = $logline -replace "--password $pw", "--password ...";
                                                  FileAppendLineWithTs $svnLogFile "`"$(SvnExe)`" $logline";
                                                  try{
                                                    & (SvnExe) $opt 2> $tmp | ForEach-Object{ FileAppendLineWithTs $svnLogFile ("  "+$_); OutProgress $_ 2; };
                                                    [String] $encodingIfNoBom = "Default";
                                                    AssertRcIsOk (FileReadContentAsLines $tmp $encodingIfNoBom) $true;
                                                    break;
                                                  }catch{
                                                    # ex: "svn: E230001: Server SSL certificate verification failed: issuer is not trusted"
                                                    # ex: "svn: E205000: Try 'svn help checkout' for more information"
                                                    # Note: if throwed then tmp file is empty.
                                                    [String] $m = $_.Exception.Message;
                                                    if( $m.Contains(" E170013:") ){  # ex: "svn: E170013: Unable to connect to a repository at URL 'https://mycomp/svn/Work/mydir'"
                                                      $m += " Note for E170013: Possibly a second error line with E230001=Server-SSL-certificate-verification-failed is given to output " +
                                                        "but if powershell trapping is enabled then this second error line is not given to exception message, so this information is lost " +
                                                        "and so after third retry it stops. Now you have the following three options in recommended order: " +
                                                        "Use 'svn list $url' to get certification issuer, and then if it is not a self signed " +
                                                        "then you may organize its pem file (for example get https://letsencrypt.org/certs/lets-encrypt-r3.pem) " +
                                                        "and add it to file `"$env:APPDATA/Subversion/servers`" under [global] ssl-authority-files=f1.pem;f2.pem. " +
                                                        "Or you call manually 'svn list $url' and accept permanently the issuer which adds its key to `"$env:APPDATA/Subversion/auth/svn.ssl.server`". " +
                                                        "Or you may use insecure option ignoreSslCheck=true. ";
                                                        # more: https://svnbook.red-bean.com/en/1.4/svn.serverconfig.httpd.html#svn.serverconfig.httpd.authn.sslcerts
                                                      if( $nrOfTries -ge 3 ){ $nrOfTries = $maxNrOfTries; }
                                                    }
                                                    [String] $msg = "$(ScriptGetCurrentFunc)(dir=`"$workDir`",url=$url,user=$user) failed because $m. Logfile=`"$svnLogFile`".";
                                                    FileAppendLineWithTs $svnLogFile $msg;
                                                    [Boolean] $isKnownProblemToSolveWithRetry =
                                                      $m.Contains(" E120106:") -or # ex: "svn: E120106: ra_serf: The server sent a truncated HTTP response body"
                                                      $m.Contains(" E155037:") -or # ex: "svn: E155037: Previous operation has not finished; run 'cleanup' if it was interrupted"
                                                      $m.Contains(" E155004:") -or # ex: "svn: E155004: Run 'svn cleanup' to remove locks (type 'svn help cleanup' for details)"
                                                      $m.Contains(" E175002:") -or # ex: "svn: E175002: REPORT request on '/svn/Work/!svn/me' failed"
                                                      $m.Contains(" E200014:") -or # ex: "svn: E200014: Checksum mismatch for '...file...'"
                                                      $m.Contains(" E200030:") -or # ex: "svn: E200030: sqlite[S10]: disk I/O error, executing statement 'VACUUM '"
                                                      $m.Contains(" E730054:") -or # ex: "svn: E730054: Error running context: Eine vorhandene Verbindung wurde vom Remotehost geschlossen."
                                                      $m.Contains(" E170013:")   ; # ex: "svn: E170013: Unable to connect to a repository at URL 'https://mycomp/svn/Work/mydir'"
                                                    if( -not $isKnownProblemToSolveWithRetry -or $nrOfTries -ge $maxNrOfTries ){ throw [ExcMsg] $msg; }
                                                    [String] $msg2 = "Is try nr $nrOfTries of $maxNrOfTries, will do cleanup, wait 30 sec and if not reached max then retry.";
                                                    OutWarning "Warning: $msg $msg2";
                                                    FileAppendLineWithTs $svnLogFile $msg2;
                                                    SvnCleanup $workDir;
                                                    ProcessSleepSec 30;
                                                  }finally{ FileDelTempFile $tmp; } } }
function SvnPreCommitCleanupRevertAndDelFiles ( [String] $workDir, [String[]] $relativeDelFsEntryPatterns, [String[]] $relativeRevertFsEntries ){
                                                OutInfo "SvnPreCommitCleanupRevertAndDelFiles `"$workDir`"";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                [String] $svnRequiresCleanup = "$dotSvnDir$(DirSep)OwnSvnRequiresCleanup.txt";
                                                if( (FileExists $svnRequiresCleanup) ){ # Optimized because it is slow.
                                                  OutProgress "SvnCleanup - Perform cleanup because previous run was not completed";
                                                  SvnCleanup $workDir;
                                                  FileDelete $svnRequiresCleanup;
                                                }
                                                OutProgress "Remove known unused temp, cache and log directories and files";
                                                FsEntryJoinRelativePatterns $workDir $relativeDelFsEntryPatterns |
                                                  Where-Object{$null -ne $_} | ForEach-Object{
                                                    FsEntryListAsStringArray $_ | Where-Object{$null -ne $_} | ForEach-Object{
                                                      FileAppendLines $svnLogFile "  Delete: `"$_`""; FsEntryDelete $_; }; };
                                                OutProgress "SvnRevert - Restore known unwanted changes of directories and files";
                                                SvnRevert $workDir $relativeRevertFsEntries; }
function SvnTortoiseCommitAndUpdate           ( [String] $workDir, [String] $svnUrl, [String] $svnUser, [Boolean] $ignoreIfHostNotReachable, [String] $pw = "" ){
                                                # Check svn dir, do svn cleanup, check svn user by asserting it matches previously used svn user, delete temporary files, svn commit (interactive), svn update.
                                                # If pw is empty then it takes it from svn-credential-cache.
                                                [String] $traceInfo = "SvnTortoiseCommitAndUpdate workdir=`"$workDir`" url=$svnUrl user=$svnUser";
                                                OutInfo $traceInfo;
                                                OutProgress "SvnLogFile: `"$svnLogFile`"";
                                                FileAppendLineWithTs $svnLogFile ("$([Environment]::NewLine)"+("-"*80)+"$([Environment]::NewLine)"+(DateTimeNowAsStringIso "yyyy-MM-dd HH:mm")+" "+$traceInfo);
                                                try{
                                                  [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                  [String] $svnRequiresCleanup = "$dotSvnDir$(DirSep)OwnSvnRequiresCleanup.txt";
                                                  # Check preconditions.
                                                  AssertNotEmpty $svnUrl "SvnUrl";
                                                  AssertNotEmpty $svnUser "SvnUser";
                                                  #
                                                  [SvnEnvInfo] $r = SvnEnvInfoGet $workDir;
                                                  #
                                                  OutProgress "Verify expected SvnUser=$svnUser matches CachedAuthorizationUser=$($r.CachedAuthorizationUser) - if last user was not found then try to load it";
                                                  if( $r.CachedAuthorizationUser -eq "" ){
                                                    SvnAuthorizationTryLoadFile $workDir $svnUser;
                                                    $r = SvnEnvInfoGet $workDir;
                                                  }
                                                  if( $r.CachedAuthorizationUser -eq "" ){
                                                    throw [ExcMsg] "This script asserts that configured SvnUser=$svnUser matches last accessed user because it requires stored credentials, but last user was not saved, please call svn-repo-browser, login, save authentication and then retry."; }
                                                  if( $svnUser -ne $r.CachedAuthorizationUser ){
                                                    throw [ExcMsg] "Configured SvnUser=$svnUser does not match last accessed user=$($r.CachedAuthorizationUser), please call svn-settings, clear cached authentication-data, call svn-repo-browser, login, save authentication and then retry."; }
                                                  #
                                                  [String] $hostname = NetExtractHostName $svnUrl;
                                                  if( $ignoreIfHostNotReachable -and -not (NetPingHostIsConnectable $hostname) ){
                                                    OutWarning "Warning: Host $hostname is not reachable, so ignored.";
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
                                                  FileAppendLineWithTs $svnLogFile (StringReplaceNewlines (StringFromException $_.Exception));
                                                  throw;
                                                } }
# for future use: function SvnList ( [String] $svnUrlAndPath ) # flat list folder; Sometimes: svn: E170013: Unable to connect to a repository at URL '...' svn: E175003: The server at '...' does not support the HTTP/DAV protocol
function TfsExe                               (){ # return tfs executable
                                                [String] $tfExe = "CommonExtensions/Microsoft/TeamFoundation/Team Explorer/TF.exe";
                                                [String[]] $a = @(
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/$tfExe",
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2022/Professional/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2022/Professional/Common7/IDE/$tfExe",
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2022/Community/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2022/Community/Common7/IDE/$tfExe",
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2019/Enterprise/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2019/Enterprise/Common7/IDE/$tfExe",
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2019/Professional/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2019/Professional/Common7/IDE/$tfExe",
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2019/Community/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2019/Community/Common7/IDE/$tfExe",
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2017/Enterprise/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2017/Enterprise/Common7/IDE/$tfExe",
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2017/Professional/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2017/Professional/Common7/IDE/$tfExe",
                                                  "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2017/Community/Common7/IDE/$tfExe",
                                                       "${env:ProgramFiles}/Microsoft Visual Studio/2017/Community/Common7/IDE/$tfExe",
                                                  (FsEntryGetAbsolutePath "$env:VS140COMNTOOLS/../IDE/TF.exe"),
                                                  (FsEntryGetAbsolutePath "$env:VS120COMNTOOLS/../IDE/TF.exe"),
                                                  (FsEntryGetAbsolutePath "$env:VS100COMNTOOLS/../IDE/TF.exe"),
                                                  "$(FsEntryGetAbsolutePath (FsEntryGetParentDir (StringRemoveOptEnclosingDblQuotes (RegistryGetValueAsString "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe"))))\$tfExe"
                                                );
                                                foreach( $i in $a ){ if( FileExists $i ) { return [String] $i; } }
                                                throw [ExcMsg] "Missing one of the files: $a"; }
                                                # for future use: tf.exe checkout /lock:checkout /recursive file
                                                # for future use: tf.exe merge /baseless /recursive /version:C234~C239 branchFrom branchTo
                                                # for future use: tf.exe workfold /workspace:ws /cloak
<# Script local variable: tfsLogFile #>       [String] $script:tfsLogFile = "${env:TEMP}/MnCommonPsToolLibLog/Tfs.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
function TfsHelpWorkspaceInfo                 (){
                                                OutProgress "Help Workspace Info - Command Line Examples";
                                                OutProgress "- Current Tool Path: `"$(TfsExe)`"";
                                                OutProgress "- Help:                                   & tf.exe vc help";
                                                OutProgress "- Help workspace:                         & tf.exe vc help workspace";
                                                OutProgress "- Delete a remote (and local) workspace:  & tf.exe vc workspace  /delete <workspaceName>[;<domain\user>] [/collection:<url>]";
                                                OutProgress "- Delete a local cached workspace:        & tf.exe vc workspaces /remove:<workspaceName>[;<domain\user>] /collection:(*|<url>)";
                                                }
function TfsShowAllWorkspaces                 ( [String] $url, [Boolean] $showPaths = $false, [Boolean] $currentMachineOnly = $false ){
                                                # from all users on all machines; normal output is a table but if showPaths is true then it outputs 12 lines per entry
                                                # ex: url=https://devops.mydomain.ch/MyTfsRoot
                                                OutProgress "Show all tfs workspaces (showPaths=$showPaths,currentMachineOnly=$currentMachineOnly)";
                                                [String] $fmt = "Brief"; if( $showPaths ){ $fmt = "Detailed"; }
                                                [String] $mach = "*"; if( $currentMachineOnly ){ $mach = $env:COMPUTERNAME; }
                                                OutProgress                                    "& `"$(TfsExe)`" vc workspaces /noprompt /format:$fmt /owner:* /computer:$mach /collection:$url";
                                                [String[]] $out = @()+(StringArrayInsertIndent (&    (TfsExe)   vc workspaces /noprompt /format:$fmt /owner:* /computer:$mach /collection:$url) 2); ScriptResetRc;
                                                $out | ForEach-Object{ $_ -replace "--------------------------------------------------", "-" } |
                                                       ForEach-Object{ $_ -replace "==================================================", "=" } |
                                                       ForEach-Object{ OutProgress $_ };
                                                # Example1:
                                                #   Sammlung: https://devops.mydomain.ch/MyTfsRoot
                                                #   Arbeitsbereich Besitzer                                     Computer   Kommentar
                                                #   -------------- -------------------------------------------- ---------- -----------
                                                #   MYCOMPUTER     John Doe                                     MYCOMPUTER
                                                #   ws_1_2         Project Collection Build Service (MyTfsRoot) DEVOPSSV
                                                # Example2 (details):
                                                #    ===================================================
                                                #    Arbeitsbereich : MYCOMPUTER
                                                #    Besitzer       : John Doe
                                                #    Computer       : MYCOMPUTER
                                                #    Kommentar      :
                                                #    Sammlung       : https://devops.mydomain.ch/MyTfsRoot
                                                #    Berechtigungen : Private
                                                #    Speicherort    : Lokal
                                                #    Dateizeitangabe: Aktuell
                                                #
                                                #    Arbeitsordner:
                                                #     $/: D:\Work
                                                #
                                                #    ===================================================
                                                # Example3:
                                                #   Für die Option "collection" ist ein Wert erforderlich.
                                                # Example4:
                                                #   Auf dem Computer "MYCOMPUTER" ist kein entsprechender Arbeitsbereich "*;*" f³r den Azure DevOps Server-Computer "https://devops.mydomain.ch/MyTfsRoot" vorhanden.
                                                # Example5:
                                                #   TF400324: Team Foundation Services sind auf Server "https://devops.mydomain.ch/MyTfsRoot" nicht verfügbar.
                                                #   Technische Informationen (für Administrator):  Die Verbindung mit dem Remoteserver kann nicht hergestellt werden.
                                                #   Ein Verbindungsversuch ist fehlgeschlagen, da die Gegenstelle nach einer bestimmten Zeitspanne nicht richtig reagiert hat,
                                                #     oder die hergestellte Verbindung war fehlerhaft, da der verbundene Host nicht reagiert hat 123.123.123.123:8080
                                                # for future use:
                                                #   https://docs.microsoft.com/en-us/azure/devops/repos/tfvc/workspaces-command?view=azure-devops
                                                #   https://docs.microsoft.com/en-us/azure/devops/repos/tfvc/decide-between-using-local-server-workspace?view=azure-devops
                                                #   https://docs.microsoft.com/en-us/azure/devops/repos/tfvc/workfold-command?view=azure-devops
                                                }
function TfsShowLocalCachedWorkspaces         (){ # works without access an url
                                                OutProgress "Show local cached tfs workspaces";
                                                OutProgress                                    "& `"$(TfsExe)`" vc workspaces /noprompt /format:Brief";
                                                [String[]] $out = @()+(StringArrayInsertIndent (&    (TfsExe)   vc workspaces /noprompt /format:Brief) 2); AssertRcIsOk $out;
                                                $out | ForEach-Object{ $_ -replace "--------------------------------------------------", "-" } |
                                                  ForEach-Object{ OutProgress $_ };
                                                # Format Detailed is only allowed if collection is specified
                                                # Example1:
                                                #   Auf dem Computer "MYCOMPUTER" ist kein entsprechender Arbeitsbereich "*;John Doe" für den Azure DevOps Server-Computer "https://devops.mydomain.ch/MyTfsRoot" vorhanden.
                                                # Example2:
                                                #   Sammlung: https://devops.mydomain.ch/MyTfsRoot
                                                #   Arbeitsbereich Besitzer          Computer Kommentar
                                                #   -------------- ----------------- -------- -----------
                                                #   MYCOMPUTER     John Doe          MYCOMPUTER
                                                # Example3 with option /computer:$env:COMPUTERNAME :
                                                #   Der Quellcodeverwaltungsserver kann nicht bestimmt werden.
                                                }
function TfsHasLocalMachWorkspace             ( [String] $url ){ # we support only workspace name identic to computername
                                                [string] $wsName = $env:COMPUTERNAME;
                                                [string] $mach = $env:COMPUTERNAME;
                                                OutProgress "Check if local tfs workspaces with name identic to computername exists";
                                                OutProgress           "  & `"$(TfsExe)`" vc workspaces /noprompt /format:Brief /owner:* /computer:$mach /collection:$url";
                                                [String[]] $out = @()+(&    (TfsExe)   vc workspaces /noprompt /format:Brief /owner:* /computer:$mach /collection:$url *>&1 |
                                                  Select-Object -Skip 2 | Where-Object{ $_.StartsWith("$wsName ") }); ScriptResetRc;
                                                $out | ForEach-Object{ $_ -replace "--------------------------------------------------", "-" } | ForEach-Object{ OutProgress $_ };
                                                return [Boolean] ($out.Length -gt 0); }
function TfsInitLocalWorkspaceIfNotDone       ( [String] $url, [String] $rootDir ){
                                                # also creates the directory "./$tf/" (or "./$tf1/", etc. ).
                                                [string] $wsName = $env:COMPUTERNAME;
                                                OutProgress "Init local tfs workspaces with name identic to computername if not yet done of $url to `"$rootDir`"";
                                                if( (TfsHasLocalMachWorkspace $url) ){ OutProgress "Init-Workspace not nessessary because has already workspace identic to computername."; return; }
                                                [String] $cd = (Get-Location); Set-Location $rootDir; try{
                                                    OutProgress         "& `"$(TfsExe)`" vc workspace /new /noprompt /location:local /collection:$url $wsName";
                                                    [String] $out = @()+(&    (TfsExe)   vc workspace /new /noprompt /location:local /collection:$url $wsName); AssertRcIsOk $out;
                                                    # The workspace MYCOMPUTER;John Doe already exists on computer MYCOMPUTER.
                                                }finally{ Set-Location $cd; } }
function TfsDeleteLocalMachWorkspace          ( [String] $url ){ # we support only workspace name identic to computername
                                                OutInfo "Delete local tfs workspace with name of current computer";
                                                if( -not (TfsHasLocalMachWorkspace $url) ){ OutProgress "Delete-Workspace not nessessary because has no workspace of name identic to computername."; return; }
                                                [string] $wsName = $env:COMPUTERNAME;
                                                # also deletes the directory "./$tf/".
                                                OutProgress         "& `"$(TfsExe)`" vc workspace /noprompt /delete $wsName /collection:$url";
                                                [String] $out = @()+(&    (TfsExe)   vc workspace /noprompt /delete $wsName /collection:$url); AssertRcIsOk $out;
                                                OutProgress $out;
                                                # Example1:
                                                #   TF14061: The workspace MYCOMPUTER;John Doe does not exist.
                                                # note: this is for cache only:  vc workspaces /remove:$wsName /collection:$url
                                                #   Example3:
                                                #     MYCOMPUTER;John Doe
                                                #   Example4 (stderr):
                                                #     "MYCOMPUTER" entspricht keinem Arbeitsbereich im Cache für den Server "*".
                                                }
function TfsGetNewestNoOverwrite              ( [String] $wsdir, [String] $tfsPath, [String] $url ){ # ex: TfsGetNewestNoOverwrite C:\MyWorkspace\Src $/Src https://devops.mydomain.ch/MyTfsRoot
                                                Assert $tfsPath.StartsWith("`$/") "expected tfsPath=`"$tfsPath`" begins with `$/.";
                                                AssertNotEmpty $wsdir "wsdir";
                                                $wsDir = FsEntryGetAbsolutePath $wsDir;
                                                OutProgress "TfsGetNewestNoOverwrite `"$wsdir`" `"$tfsPath`" $url";
                                                FileAppendLineWithTs $tfsLogFile "TfsGetNewestNoOverwrite(`"$wsdir`",`"$tfsPath`",$url )";
                                                if( ((FsEntryFindInParents $wsdir "`$tf") -eq "") -and ((FsEntryFindInParents $wsdir "`$tf1") -eq "") -and ((FsEntryFindInParents $wsdir "`$tf2") -eq "") ){
                                                  OutProgress "Not found any dir (`"`$tf`",`"`$tf1`",`"`$tf2`") in parents of `"$wsdir`", so calling init workspace.";
                                                  TfsInitLocalWorkspaceIfNotDone $url (FsEntryGetParentDir $wsdir);
                                                }else{
                                                  # If workspace was some months not used then for the get command we got the error:
                                                  # "Der Arbeitsbereich kann nicht bestimmt werden. Dies lässt sich möglicherweise durch Ausführen von "tf workspaces /collection:Teamprojektsammlungs-URL" beheben."
                                                  # After performing this it worked, so we now perform this each time.
                                                  [Boolean] $dummy = (TfsHasLocalMachWorkspace $url);
                                                }
                                                if( FileNotExists $wsdir ){ DirCreate $wsdir; }
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{ # alternative option: /noprompt
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc get /recursive /version:T `"$tfsPath`" ";
                                                  [String[]] $out = @()+(     &    (TfsExe)   vc get /recursive /version:T   $tfsPath); AssertRcIsOk $out;
                                                  # Output: "Alle Dateien sind auf dem neuesten Stand."
                                                  if( $out.Count -gt 0 ){ $out | ForEach-Object{ OutProgress "  $_"; }; }
                                                }finally{ Set-Location $cd; } }
function TfsListOwnLocks                      ( [String] $wsdir, [String] $tfsPath ){
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc status /noprompt /recursive /format:brief `"$tfsPath`" ";
                                                  [String[]] $out = @()+((    &    (TfsExe)   vc status /noprompt /recursive /format:brief   $tfsPath *>&1 ) |
                                                    Select-Object -Skip 2 | Where-Object{ StringIsFilled $_ }); AssertRcIsOk $out;
                                                  # ex:
                                                  #    Dateiname    Ändern     Lokaler Pfad
                                                  #    ------------ ---------- -------------------------------------
                                                  #    $/Src/MyBranch
                                                  #    MyFile.txt   bearbeiten C:\MyWorkspace\Src\MyBranch\MyFile.txt
                                                  #
                                                  #    1 Änderungen
                                                  # ex: Es sind keine ausstehenden Änderungen vorhanden.
                                                  return [String[]] $out;
                                                }finally{ Set-Location $cd; } }
function TfsAssertNoLocksInDir                ( [String] $wsdir, [String] $tfsPath ){ # ex: "C:\MyWorkspace" "$/Src";
                                                [String[]] $allLocks = @()+(TfsListOwnLocks $wsdir $tfsPath);
                                                if( $allLocks.Count -gt 0 ){
                                                  $allLocks | ForEach-Object{ OutProgress "Found Lock: $_"; };
                                                  throw [ExcMsg] "Assertion failed because there exists pending locks under `"$tfsPath`"";
                                                } }
function TfsMergeDir                          ( [String] $wsdir, [String] $tfsPath, [String] $tfsTargetBranch ){
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc merge /noprompt /recursive /format:brief /version:T `"$tfsPath`" `"$tfsTargetBranch`" ";
                                                  [String[]] $dummyOut = @()+(     &    (TfsExe)   vc merge /noprompt /recursive /format:brief /version:T   $tfsPath     $tfsTargetBranch); # later we would like to suppress stderr
                                                  ScriptResetRc;
                                                  # ex:
                                                  #    Konflikt ("mergen, bearbeiten"): $/Src/MyBranch1/MyFile.txt;C123~C129 -> $/Src/MyBranch2/MyFile.txt;C121
                                                  #    3 Konflikte. Geben Sie "/format:detailed" an, um die einzelnen Konflikte in der Zusammenfassung aufzulisten.
                                                  #    mergen, bearbeiten: $/Src/MyBranch1/MyFile2.txt;C123~C129 -> $/Src/MyBranch2/MyFile2.txt;C121
                                                  #    The item $/Src/MyBranch1/MyFile2.txt is locked for check-out by MyDomain\MyUser in workspace MYMACH.
                                                  #
                                                  #    ---- Zusammenfassung: 31 Konflikte, 0 Warnungen, 0 Fehler ----
                                                  # does not work: | Where-Object{ $_ -contains "---- Zusammenfassung:*" }
                                                  #
                                                  #return [String[]] $dummyOut;
                                                #}catch{ ScriptResetRc; OutProgress "Ignoring Error: $($_.Exception)";
                                                }finally{ Set-Location $cd; } }
function TfsResolveMergeConflict              ( [String] $wsdir, [String] $tfsPath, [Boolean] $keepTargetAndNotTakeSource ){
                                                [String] $resolveMode = switch( $keepTargetAndNotTakeSource ){ $true{"TakeTheirs"} $false{"AcceptYours"} };
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc resolve /noprompt /recursive /auto:$resolveMode `"$tfsPath`" ";
                                                  [String[]] $out = @()+(     &    (TfsExe)   vc resolve /noprompt /recursive /auto:$resolveMode   $tfsPath ); AssertRcIsOk $out;
                                                #}catch{ ScriptResetRc; OutProgress "Ignoring Error: $($_.Exception)";
                                                }finally{ Set-Location $cd; } }
function TfsCheckinDirWhenNoConflict          ( [String] $wsdir, [String] $tfsPath, [String] $comment, [Boolean] $handleErrorsAsWarnings ){
                                                # Return true if checkin was successful.
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{
                                                  # Note: sometimes it seem to write this to stderror:
                                                  #  "Es sind keine ausstehenden Änderungen vorhanden, die mit den angegebenen Elementen übereinstimmen.\nEs wurden keine Dateien eingecheckt."
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc checkin /noprompt /recursive /noautoresolve /comment:`"$comment`" `"$tfsPath`" ";
                                                  [String[]] $dummyOut = @()+(     &    (TfsExe)   vc checkin /noprompt /recursive /noautoresolve /comment:"$comment"     $tfsPath);
                                                  ScriptResetRc;
                                                  return [Boolean] $true;
                                                }catch{
                                                  if( -not $handleErrorsAsWarnings ){ throw; }
                                                  OutWarning "Warning: Ignoring checkin problem which requires manually resolving: $($_.Exception.Message)";
                                                  return [Boolean] $false;
                                                }finally{ Set-Location $cd; } }
function TfsUndoAllLocksInDir                 ( [String] $dir ){ # Undo all locks below dir to cleanup a previous failed operation as from merging.
                                                OutProgress           "& `"$(TfsExe)`" vc undo /noprompt /recursive `"$dir`"";
                                                [String[]] $out = @()+(&    (TfsExe)   vc undo /noprompt /recursive   $dir); AssertRcIsOk $out; }
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
                                                else { throw [ExcMsg] "Wether Sql Server 2016, 2014, 2012 nor 2008 is installed, so cannot find sqlcmd.exe"; }
                                                [String] $sqlcmd = (RegistryGetValueAsString $k "Path") + "sqlcmd.EXE"; # "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\sqlcmd.EXE"
                                                return [String] $sqlcmd; }
function SqlRunScriptFile                     ( [String] $sqlserver, [String] $sqlfile, [String] $outFile, [Boolean] $continueOnErr ){ # old style. It is recommended to use: SqlPerformFile
                                                FileAssertExists $sqlfile;
                                                OutProgress "SqlRunScriptFile sqlserver=$sqlserver sqlfile=`"$sqlfile`" out=`"$outfile`" contOnErr=$continueOnErr";
                                                [String] $sqlcmd = SqlGetCmdExe;
                                                FsEntryCreateParentDir $outfile;
                                                & $sqlcmd "-b" "-S" $sqlserver "-i" $sqlfile "-o" $outfile;
                                                if( -not $? ){ if( ! $continueOnErr ){ AssertRcIsOk; }
                                                else{ OutWarning "Warning: Ignore SqlRunScriptFile `"$sqlfile`" on `"$sqlserver`" failed with rc=$(ScriptGetAndClearLastRc), more see outfile, will continue"; } }
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
                                                    ForEach-Object{
                                                      [String] $line = $_;
                                                      if( $_.GetType() -eq [System.Data.DataRow] ){
                                                        $line = "";
                                                        if( $showRows ){ $_.ItemArray | Where-Object{$null -ne $_} | ForEach-Object{ $line += '"'+$_.ToString()+'",'; } } }
                                                      if( $line -ne "" ){ OutProgress $line; }
                                                      if( $logFileToAppend -ne "" ){ FileAppendLineWithTs $logFileToAppend $line; } }
                                                }catch{
                                                  [String] $msg = "$traceInfo failed because $($_.Exception.Message)";
                                                  if( $logFileToAppend -ne "" ){ FileAppendLineWithTs $logFileToAppend $msg; }
                                                  throw [ExcMsg] $msg; } }
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
                                                  [Boolean] $errorAsWarning = $false, [Boolean] $inclIfNotExists = $false,
                                                  [Boolean] $inclDropStmts = $false, [Boolean] $inclDataAsInsertStmts = $false ){
                                                # Create all creation files for a specified sql server database with current user to a specified target directory which must not exists.
                                                # This includes tables (including unique indexes), indexes (non-unique), views, stored procedures, functions, roles, schemas, db-triggers and table-Triggers.
                                                # If a stored procedure, a function or a trigger is encrypted then a single line is put to its sql file indicating encrypted code cannot be dumped.
                                                # It creates file "DbInfo.dbname.out" with some db infos. In case of an error it creates file "DbInfo.dbname.err".
                                                # ex: SqlGenerateFullDbSchemaFiles "MyLogicEnvironment" "MySqlInstance" "MyDbName" "$env:TEMP\DumpFullDbSchemas"
                                                [String] $currentUser = "$env:USERDOMAIN\$env:USERNAME";
                                                [String] $traceInfo = "SqlGenerateFullDbSchemaFiles(logicalEnv=$logicalEnv,dbInstanceServerName=$dbInstanceServerName,dbname=$dbName,targetRootDir=$targetRootDir,currentUser=$currentUser)";
                                                OutInfo $traceInfo;
                                                [String] $tarDir = "$targetRootDir$(DirSep)$(Get-Date -Format yyyy-MM-dd)$(DirSep)$logicalEnv$(DirSep)$dbName";
                                                if( DirExists $tarDir ){
                                                  [String] $msg = "Nothing done because target dir already exists: `"$tarDir`"";
                                                  if( $errorAsWarning ){ OutWarning "Warning: $msg"; return; }
                                                  throw [ExcMsg] $msg;
                                                }
                                                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null;
                                                [System.Reflection.Assembly]::LoadWithPartialName("System.Data") | Out-Null;
                                                [Microsoft.SqlServer.Management.Smo.Server] $srv = new-object "Microsoft.SqlServer.Management.SMO.Server" $dbInstanceServerName;
                                                # ex: $srv.Name = "MySqlInstance"; $srv.State = "Existing"; $srv.ConnectionContext = "Data Source=MySqlInstance;Integrated Security=True;MultipleActiveResultSets=False;Encrypt=False;TrustServerCertificate=False;Application Name=`"SQL Management`""
                                                try{
                                                   # can throw: MethodInvocationException: Exception calling "SetDefaultInitFields" with "2" argument(s): "Failed to connect to server MySqlInstance."
                                                  try{ $srv.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject");
                                                  }catch{ throw [Exception] "SetDefaultInitFields($dbInstanceServerName) failed because $($_.Exception.Message)"; }
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
                                                  if( $null -eq $db ){ throw [Exception] "Not found database with current user."; }
                                                  [String] $fileDbInfo = "$tarDir$(DirSep)DbInfo.$dbName.out";
                                                  #try{
                                                  #  [String] $dummy = $db.Parent; # check for read access
                                                  #}catch{
                                                  #  # ex: ExtendedTypeSystemException: The following exception occurred while trying to enumerate the collection: "An exception occurred while executing a Transact-SQL statement or batch.".
                                                  #  throw [Exception] "Accessing database $dbName failed because $_";
                                                  #}
                                                  [Array] $tables              = @()+($db.Tables               | Where-Object{$null -ne $_} | Where-Object{$_.IsSystemObject -eq $false}); # including unique indexes
                                                  [Array] $views               = @()+($db.Views                | Where-Object{$null -ne $_} | Where-Object{$_.IsSystemObject -eq $false});
                                                  [Array] $storedProcedures    = @()+($db.StoredProcedures     | Where-Object{$null -ne $_} | Where-Object{$_.IsSystemObject -eq $false});
                                                  [Array] $userDefFunctions    = @()+($db.UserDefinedFunctions | Where-Object{$null -ne $_} | Where-Object{$_.IsSystemObject -eq $false});
                                                  [Array] $dbSchemas           = @()+($db.Schemas              | Where-Object{$null -ne $_} | Where-Object{$_.IsSystemObject -eq $false});
                                                  [Array] $dbTriggers          = @()+($db.Triggers             | Where-Object{$null -ne $_} | Where-Object{$_.IsSystemObject -eq $false});
                                                  [Array] $dbRoles             = @()+($db.Roles                | Where-Object{$null -ne $_});
                                                  [Array] $tableTriggers       = @()+($tables                  | Where-Object{$null -ne $_} | ForEach-Object{$_.triggers } | Where-Object{$null -ne $_});
                                                  [Array] $indexesNonUnique    = @()+($tables                  | Where-Object{$null -ne $_} | ForEach-Object{$_.indexes  } | Where-Object{$null -ne $_} | Where-Object{-not $_.IsUnique});
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
                                                  OutProgress "  Process: ";
                                                  OutProgress "Schemas ";
                                                  foreach( $i in $dbSchemas ){
                                                    [String] $name = FsEntryMakeValidFileName $i.Name;
                                                    $options.FileName = "$tarDir$(DirSep)Schema.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgress "Roles ";
                                                  foreach( $i in $dbRoles ){
                                                    [String] $name = FsEntryMakeValidFileName $i.Name;
                                                    $options.FileName = "$tarDir$(DirSep)Role.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgress "DbTriggers ";
                                                  foreach( $i in $dbTriggers ){
                                                    [String] $name = FsEntryMakeValidFileName $i.Name;
                                                    $options.FileName = "$tarDir$(DirSep)DbTrigger.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    if( $i.IsEncrypted ){
                                                      FileAppendLine $options.FileName "Note: DbTrigger $name is encrypted, so cannot be dumped.";
                                                    }else{
                                                      $scr.Script($i);
                                                    }
                                                  }
                                                  OutProgress "Tables "; # inclusive unique indexes
                                                  foreach( $i in $tables ){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir$(DirSep)Table.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $smoObjects = New-Object Microsoft.SqlServer.Management.Smo.UrnCollection;
                                                    $smoObjects.Add($i.Urn);
                                                    $i.indexes | Where-Object{$null -ne $_ -and $_.IsUnique} | ForEach-Object{ $smoObjects.Add($_.Urn); };
                                                    $scr.Script($smoObjects);
                                                  }
                                                  OutProgress "Views ";
                                                  foreach( $i in $views ){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir$(DirSep)View.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgress "StoredProcedures";
                                                  foreach( $i in $storedProcedures ){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir$(DirSep)StoredProcedure.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    if( $i.IsEncrypted ){
                                                      FileAppendLine $options.FileName "Note: StoredProcedure $name is encrypted, so cannot be dumped.";
                                                    }else{
                                                      $scr.Script($i);
                                                    }
                                                  }
                                                  OutProgress "UserDefinedFunctions ";
                                                  foreach( $i in $userDefFunctions ){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir$(DirSep)UserDefinedFunction.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    if( $i.IsEncrypted ){
                                                      FileAppendLine $options.FileName "Note: UserDefinedFunction $name is encrypted, so cannot be dumped.";
                                                    }else{
                                                      $scr.Script($i);
                                                    }
                                                  }
                                                  OutProgress "TableTriggers ";
                                                  foreach( $i in $tableTriggers ){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Parent.Schema).$($i.Parent.Name).$($i.Name)";
                                                    $options.FileName = "$tarDir$(DirSep)TableTrigger.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    if( $i.IsEncrypted ){
                                                      FileAppendLine $options.FileName "Note: TableTrigger $name is encrypted, so cannot be dumped.";
                                                    }else{
                                                      $scr.Script($i);
                                                    }
                                                  }
                                                  OutProgress "IndexesNonUnique ";
                                                  foreach( $i in $indexesNonUnique ){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Parent.Schema).$($i.Parent.Name).$($i.Name)";
                                                    $options.FileName = "$tarDir$(DirSep)IndexesNonUnique.$name.sql";
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
                                                  FileWriteFromLines "$tarDir$(DirSep)DbInfo.$dbName.err" $msg;
                                                  if( -not $errorAsWarning ){ throw [ExcMsg] $msg; }
                                                  OutWarning "Warning: Ignore failing of $msg `nCreated `"$tarDir$(DirSep)DbInfo.$dbName.err`".";
                                                }
                                              }
function ToolTailFile                         ( [String] $file ){ OutProgress "Show tail of file until ctrl-c is entered"; Get-Content -Wait $file; }
function ToolAddLineToConfigFile              ( [String] $file, [String] $line, [String] $encoding = "UTF8" ){ # if file not exists or line not found case sensitive in file then the line is appended
                                                if( FileNotExists $file ){ FileWriteFromLines $file $line; }
                                                elseif( -not (StringArrayContains (FileReadContentAsLines $file $encoding) $line) ){ FileAppendLines $file $line; } }
function ToolGithubApiListOrgRepos            ( [String] $org, [System.Management.Automation.PSCredential] $cred = $null ){
                                                # List all repos (ordered by archived and url) from an org on github.
                                                # If user and its Personal-Access-Token PAT instead of password is specified then not only public
                                                # but also private repos are listed.
                                                [String] $us = CredentialGetUsername $cred;
                                                [String] $pw = CredentialGetPassword $cred;
                                                OutProgress "List all github repos from $org with user=`"$us`"";
                                                [Array] $result = @();
                                                for( [Int32] $i = 1; $i -lt 100; $i++ ){
                                                  # REST API doc: https://developer.github.com/v3/repos/
                                                  # maximum 100 items per page
                                                  # ex: https://api.github.com/orgs/arduino/repos?type=all&sort=id&per_page=100&page=2&affiliation=owner,collaborator,organization_member
                                                  [String] $url = "https://api.github.com/orgs/$org/repos?per_page=100&page=$i";
                                                  [Object] $json = NetDownloadToString $url $us $pw | ConvertFrom-Json;
                                                  [Array] $a = @()+($json | Select-Object @{N='Url';E={$_.html_url}}, archived, private, fork, forks, language,
                                                    @{N='CreatedAt';E={$_.created_at.SubString(0,10)}}, @{N='UpdatedAt';E={$_.updated_at.SubString(0,10)}},
                                                    @{N='PermAdm';E={$_.permissions.admin}}, @{N='PermPush';E={$_.permissions.push}}, @{N='PermPull';E={$_.permissions.pull}},
                                                    default_branch, @{N='LicName';E={$_.license.name}},
                                                    @{N='Description';E={$_.description.SubString(0,200)}});
                                                  if( $a.Count -eq 0 ){ break; }
                                                  $result += $a;
                                                } return [Array] $result | Sort-Object archived, Url; }
function ToolGithubApiAssertValidRepoUrl      ( [String] $repoUrl ){
                                                # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
                                                [String] $githubUrl = "https://github.com/";
                                                Assert $repoUrl.StartsWith($githubUrl) "expected url begins with $githubUrl but got: $repoUrl";
                                                [String[]] $a = @()+(StringSplitToArray "/" (StringRemoveLeft (StringRemoveRight $repoUrl "/") $githubUrl $false));
                                                Assert ($a.Count -eq 2 -and $a[0].Length -ge 2 -and $a[1].Length -ge 2) "expected url contains user/reponame but got: $repoUrl"; }
function ToolGithubApiDownloadLatestReleaseDir( [String] $repoUrl ){
                                                # Creates a unique temp dir, downloads zip, return folder of extracted zip; You should remove dir after usage.
                                                # Latest release is the most recent non-prerelease, non-draft release, sorted by its last commit-date.
                                                # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
                                                ToolGithubApiAssertValidRepoUrl $repoUrl;
                                                [String] $apiUrl = "https://api.github.com/repos/" + (StringRemoveLeft (StringRemoveRight $repoUrl "/") "https://github.com/" $false);
                                                # ex: $apiUrl = "https://api.github.com/repos/mniederw/MnCommonPsToolLib"
                                                [String] $url = "$apiUrl/releases/latest";
                                                OutProgress "Download: $url";
                                                [Object] $apiObj = (& "curl.exe" -s $url) | ConvertFrom-Json; AssertRcIsOk;
                                                [String] $relName = "$($apiObj.name) [$($apiObj.target_commitish),$($apiObj.created_at.Substring(0,10)),$($apiObj.tag_name)]";
                                                OutProgress "Selected: `"$relName`"";
                                                # ex: $apiObj.zipball_url = "https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball/V4.9"
                                                # ex: $relName = "OpenSource-GPL3 MnCommonPsToolLib V4.9 en 2020-02-13 [master,2020-02-13,V4.9]"
                                                [String] $tarDir = DirCreateTemp "MnCoPsToLib_";
                                                [String] $tarZip = "$tarDir$(DirSep)$relName.zip";
                                                # We can download latest release zip by one of:
                                                # - https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball
                                                # - https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball/V4.9
                                                # - https://github.com/mniederw/MnCommonPsToolLib/archive/V4.9.zip
                                                # - https://codeload.github.com/mniederw/MnCommonPsToolLib/legacy.zip/master
                                                NetDownloadFileByCurl "$apiUrl/zipball" $tarZip;
                                                ToolUnzip $tarZip $tarDir; # Ex: ./mniederw-MnCommonPsToolLib-25dbfb0/*
                                                FileDelete $tarZip;
                                                 # list flat dirs, ex: "C:\Temp\MnCoPsToLib_catkmrpnfdp\mniederw-MnCommonPsToolLib-25dbfb0\"
                                                [String[]] $dirs = (@()+(FsEntryListAsStringArray $tarDir $false $true $false));
                                                if( $dirs.Count -ne 1 ){ throw [ExcMsg] "Expected one dir in `"$tarDir`" instead of: $dirs"; }
                                                [String] $dir0 = $dirs[0];
                                                FsEntryMoveByPatternToDir "$dir0$(DirSep)*" $tarDir;
                                                DirDelete $dir0;
                                                return [String] $tarDir; }


function GetSetGlobalVar( [String] $var, [String] $val){ OutProgress "GetSetGlobalVar is OBSOLETE, replace it now by GitSetGlobalVar.";  GitSetGlobalVar $var $val; }

# ----------------------------------------------------------------------------------------------------

if( (OsIsWindows) ){ # running under windows
  OutVerbose "$PSScriptRoot : Running on windows";
  . "$PSScriptRoot/MnCommonPsToolLib_Windows.ps1";
}else{
  OutVerbose "$PSScriptRoot : Running not on windows";
}

Export-ModuleMember -function *; # Export all functions from this script which are above this line (types are implicit usable).

# Powershell useful knowledge and additional documentation
# ========================================================
#
# - Enable powershell: Before using any powershell script you must enable on 64bit and on 32bit environment!
#   It requires admin rights so either run a cmd.exe shell with admin mode and call:
#     PS7  :  pwsh -Command Set-ExecutionPolicy -Scope LocalMachine Unrestricted
#     64bit:  %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe Set-Executionpolicy -Scope LocalMachine Unrestricted
#     32bit:  %SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe Set-Executionpolicy -Scope LocalMachine Unrestricted
#   or start each powershell and run:  Set-Executionpolicy Unrestricted
#   or run: reg.exe add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /f /t REG_SZ /v "ExecutionPolicy" /d "Unrestricted"
#   or run any ps1 even when in restricted mode with:  PowerShell.exe -ExecutionPolicy Unrestricted -NoProfile -File "myfile.ps1"
#   Default is: powershell.exe Set-Executionpolicy Restricted
#   More: get-help about_signing
#   For being able to doubleclick a ps1 file or run a shortcut for a ps1 file, do in Systemcontrol->Standardprograms you can associate .ps1
#     with       "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
#     or better  "C:\Program Files\PowerShell\7\pwsh.EXE"
# - Common parameters used enable stdandard options:
#   [-Verbose] [-Debug] [-ErrorAction <ActionPreference>] [-WarningAction <ActionPreference>] [-ErrorVariable <String>] [-WarningVariable <String>] [-OutVariable <String>] [-OutBuffer <Int32>]
# - Parameter attribute declarations (ex: Mandatory, Position): https://msdn.microsoft.com/en-us/library/ms714348(v=vs.85).aspx
# - Parameter validation attributes (ex: ValidateRange): https://social.technet.microsoft.com/wiki/contents/articles/15994.powershell-advanced-function-parameter-attributes.aspx#Parameter_Validation_Attributes
# - Do Not Use: Avoid using $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") or Write-Error because different behaviour of powershell.exe and powershell_ise.exe
# - Extensions: download and install PowerShell Community Extensions (PSCX) https://github.com/Pscx/Pscx for ntfs-junctions and symlinks.
# - Special predefined variables which are not yet used in this script (use by $global:anyprefefinedvar; names are case insensitive):
#   https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables
#   $null, $true, $false  - some constants
#   $args                 - Contains an array of the parameters passed to a function.
#   $error                - Contains objects for which an error occurred while being processed in a cmdlet.
#   $HOME                 - Specifies the users home directory. ($env:USERPROFILE)
#   $PsHome               - The directory where the Windows PowerShell is installed. (C:\Windows\SysWOW64\WindowsPowerShell\v1.0)
#   $PROFILE              - $HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#   $PS...                - some variables
#   $MaximumAliasCount, $MaximumDriveCount, $MaximumErrorCount, $MaximumFunctionCount, $MaximumHistoryCount, $MaximumVariableCount  - some maximum values
#   $StackTrace, $ConsoleFileName, $ErrorView, $ExecutionContext, $Host, $input, $NestedPromptLevel, $PID, $PWD, $ShellId           - some environment values
#   $PSScriptRoot         - folder of current running script
# - Comparison operators; -eq, -ne, -lt, -le, -gt, -ge, "abcde" -like "aB?d*", -notlike,
#   @( "a1", "a2" ) -contains "a2", -notcontains, "abcdef" -match "b[CD]", -notmatch, "abcdef" -cmatch "b[cd]", -notcmatch, -not
# - Automatic variables see: http://technet.microsoft.com/en-us/library/dd347675.aspx
#   $?            : Contains True if last operation succeeded and False otherwise.
#   $LASTEXITCODE : Contains the exit code of the last Win32 executable execution, 0 is ok.
#                   Can be null if not windows command was called. Should not manually set, but if yes then as: $global:LASTEXITCODE = $null;
# - Available colors for console -foregroundcolor and -backgroundcolor:
#   Black DarkBlue DarkGreen DarkCyan DarkRed DarkMagenta DarkYellow Gray DarkGray Blue Green Cyan Red Magenta Yellow White
# - Do not use write-host, use write-output. See http://www.jsnover.com/blog/2013/12/07/write-host-considered-harmful/
#   But then you have to switch  $host.ui.RawUI.ForegroundColor for colors
# - Manifest .psd1 file can be created with: New-ModuleManifest MnCommonPsToolLib.psd1 -ModuleVersion "1.0" -Author "Marc Niederwieser"
# - Known Bugs or Problems:
#   - Powershell V2 Bug: checking strings for $null is different between if and switch tests:
#     http://stackoverflow.com/questions/12839479/powershell-treats-empty-string-as-equivalent-to-null-in-switch-statements-but-no
#   - Variable or function argument of type String is never $null, if $null is assigned then always empty is stored.
#       [String] $s; $s = $null; Assert ($null -ne $s); Assert ($s -eq "");
#     But if type String is within a struct then it can be null.
#       Add-Type -TypeDefinition "public struct MyStruct {public string MyVar;}"; Assert( $null -eq (New-Object MyStruct).MyVar );
#     And the string variable is null IF IT IS RUNNING IN A SCRIPT in ps5or7, if running interactive then it is not null:
#       [String] $a = @() | Where-Object{ $false }; echo "IsStringNull: $($null -eq $a)";
#   - GetFullPath() works not with the current dir but with the working dir where powershell was started (ex. when running as administrator).
#     http://stackoverflow.com/questions/4071775/why-is-powershell-resolving-paths-from-home-instead-of-the-current-directory/4072205
#     powershell.exe         ;
#                              Get-Location                                 <# ex: $HOME     #>;
#                              Write-Output hi > .\a.tmp   ;
#                              [System.IO.Path]::GetFullPath(".\a.tmp")     <# is correct "$HOME\a.tmp"     #>;
#     powershell.exe as Admin;
#                              Get-Location                                 <# ex: C:\WINDOWS\System32 #>;
#                              Set-Location $HOME;
#                              [System.IO.Path]::GetFullPath(".\a.tmp")     <# is wrong   "C:\WINDOWS\System32\a.tmp" #>;
#                              [System.IO.Directory]::GetCurrentDirectory() <# is         "C:\WINDOWS\System32"       #>;
#                              (get-location).Path                          <# is         "$HOME"                     #>;
#                              Resolve-Path .\a.tmp                         <# is correct "$HOME\a.tmp"               #>;
#                              (Get-Item -Path ".\a.tmp" -Verbose).FullName <# is correct "$HOME\a.tmp"               #>;
#     Possible reasons: PS can have a regkey as current location. GetFullPath works with [System.IO.Directory]::GetCurrentDirectory().
#     Recommendation: do not use [System.IO.Path]::GetFullPath, use Resolve-Path.
#   - ForEach-Object iterates at lease once with $null in pipeline:
#     see http://stackoverflow.com/questions/4356758/how-to-handle-null-in-the-pipeline
#     $null | ForEach-Object{ write-Output "ok reached, at least one iteration in pipeline with $null has been done." }
#     But:  @() | ForEach-Object{ write-Output "NOT OK, reached this unexpected." }
#     Workaround if array variable can be null, then use:
#       $null | Where-Object{$null -ne $_} | ForEach-Object{ write-Output "NOT OK, reached this unexpected." }
#     Alternative:
#       $null | ForEach-Object -Begin{if($null -eq $_){continue}} -Process {do your stuff here}
#     Recommendation: Pipelines which use only Select-Object, ForEach-Object and Sort-Object to produce a output for console or logfiles are ignorable
#       but for others you should avoid side effects in pipelines by always using: |Where-Object{$null -ne $_}
#   - Compare empty array with $null:
#     [String[]] $a = @(); if( $a -is [String[]] ){ write-Output "ok reached, var of expected type." };
#     if( $a.count -eq 0 ){ write-Output "ok reached, count can be used."; }
#     if(      ($a -eq $null) ){ write-Output "NOT OK, reached this unexpected."; }
#     if(      ($a -ne $null) ){ write-Output "NOT OK, reached this unexpected."; }
#     if( -not ($a -eq $null) ){ write-Output "ok reached, compare not-null array wether it is null or not null is always false"; }
#     if( -not ($a -ne $null) ){ write-Output "ok reached, compare not-null array wether it is null or not null is always false"; }
#     if( -not ($null -eq $a) ){ write-Output "ok reached, compare array with null must be done by preceeding null."; }
#     if(      ($null -ne $a) ){ write-Output "ok reached, compare array with null must be done by preceeding null."; }
#     [Boolean] $r = @() -eq $null; # this throws!
#     Recommendation: When comparing array with null then always put null on the left side.
#       More simple when comparing any value with null then always put null on the left side.
#   - A powershell function returning and empty array is compatible with returning $null.
#     But nevertheless it is essential wether it returns an empty array or null because
#     when adding the result of the call to an empty array then it results in count =0 or =1.
#     see https://stackoverflow.com/questions/18476634/powershell-doesnt-return-an-empty-array-as-an-array
#       function ReturnEmptyArray(){ return [String[]] @(); }
#       function ReturnNullArray(){ return [String[]] $null; }
#       if( $null -eq (ReturnEmptyArray) ){ write-Output "ok reached, function return empty array which is equal to null"; }
#       if( $null -eq (ReturnNullArray)  ){ write-Output "ok reached, function return null  array which is equal to null"; }
#       if( (@()+(ReturnEmptyArray                          )).Count -eq 0 ){ write-Output "ok reached, function return empty array which counts as 0"; }
#       if( (@()+(ReturnNullArray                           )).Count -eq 1 ){ write-Output "ok reached, function return null array which counts as one element"; }
#       if( (@()+(ReturnNullArray|Where-Object{$null -ne $_})).Count -eq 0 ){ write-Output "ok reached, function return null but converted to empty array"; }
#     Recommendation: After a call of a function which returns an array then add an empty array.
#       If its possible that a function can returns null instead of an empty array then also use (|Where-Object{$null -ne $_})
#   - Empty array in pipeline is converted to $null:
#       [String[]] $a = (([String[]]@()) | Where-Object{$null -ne $_});
#       if( $null -eq $a ){ write-Output "ok reached, var is null." };
#     Recommendation: After pipelining add an empty array.
#       [String[]] $a = (@()+(@()|Where-Object{$null -ne $_})); Assert ($null -ne $a);
#   - Variable name conflict: ... | ForEach-Object{ [String[]] $a = $_; ... }; [Array] $a = ...;
#     Can result in:  SessionStateUnauthorizedAccessException: Cannot overwrite variable a because the variable has been optimized.
#       Try using the New-Variable or Set-Variable cmdlet (without any aliases),
#       or dot-source the command that you are using to set the variable.
#     Recommendation: Rename one of the variables.
#   - DotNet functions as Split() can return empty arrays:
#       [String[]] $a = "".Split(";",[System.StringSplitOptions]::RemoveEmptyEntries); if( $a.Count -eq 0 ){ write-Output "ok reached"; }
#   - Exceptions are always catched within Pipeline Expression statement and instead of expecting the throw it returns $null:
#     [Object[]] $a = @( "a", "b" ) | Select-Object -Property @{Name="Field1";Expression={$_}} |
#       Select-Object -Property Field1,
#       @{Name="Field2";Expression={if($_.Field1 -eq "a" ){ "is_a"; }else{ throw [Exception] "This exc is ignored and instead of throwing up the stack the result of the Expression statement is $null."; } }};
#     $a[0].Field2 -eq "is_a" -and $null -eq $a[1].Field2;  # this is true
#     $a | ForEach-Object{ if( $null -eq $_.Field2 ){ throw [Exception] "Field2 is null"; } } # this does the throw
#     Recommendation: After creation of the list do iterate through it and assert non-null values
#       or redo the expression within a ForEach-Object loop to get correct throwed message.
#   - String without comparison as condition:  Assert ( "anystring" ); Assert ( "$false" );
#   - PS is poisoning the current scope by its aliases. List all aliases by: alias; For example: Alias curl -> Invoke-WebRequest ; Alias wget -> Invoke-WebRequest ; Alias diff -> Compare-Object ;
#   - Automatically added folders (2023-02):
#     - ps7: %USERPROFILE%\Documents\PowerShell\Modules\         location for current users for any modules
#     - ps5: %USERPROFILE%\Documents\WindowsPowerShell\Modules\  location for current users for any modules
#     - ps7: %ProgramW6432%\PowerShell\Modules\                  location for all     users for any modules (ps7 and up, multiplatform)
#     - ps7: %ProgramW6432%\powershell\7\Modules\                location for all     users for any modules (ps7 only  , multiplatform)
#     - ps5: %ProgramW6432%\WindowsPowerShell\Modules\           location for all     users for any modules (ps5 and up) and             64bit environment (ex: "C:\Program Files")
#     - ps5: %ProgramFiles(x86)%\WindowsPowerShell\Modules\      location for all     users for any modules (ps5 and up) and             32bit environment (ex: "C:\Program Files (x86")
#     - ps5: %ProgramFiles%\WindowsPowerShell\Modules\           location for all     users for any modules (ps5 and up) and current 64/32 bit environment (ex: "C:\Program Files (x86)" or "C:\Program Files")
#   - Not automatically added but currently strongly recommended additional folder:
#     - %SystemRoot%\System32\WindowsPowerShell\v1.0\Modules\    location for windows modules for all users (ps5 and up)
#       In future if ps7 can completely replace ps5 then we can remove this folder.
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
#   - Dot Sourcing Operator (.) runs script in local scope, variables and functions persists in shell after script end,
#     used to include ps artefacts:
#       . ".\myscript.ps1"
#       . { write-Output "Test"; }
#       powershell.exe -command ". .\myscript.ps1"
#       powershell.exe -file      ".\myscript.ps1"
#     Use this only if the two files belong together, otherwise use the call operator.
#   - Call operator (&), runs a script, executable, function or scriptblock,
#     - Creates a new script scope which is deleted after script end, so it is side effect safe. Changes to global variables are also lost.
#         & "./myscript.ps1" ...arguments... ; & $mycmd ...args... ; & { mycmd1; mycmd2 } AssertRcIsOk;
#     - Very important: if an empty argument should be specified then two quotes as '' or "" or $null or $myEmptyVar
#       do not work (will make the argument not present),
#       it requires '""' or "`"`"" or `"`" or use a blank as " ". This is really a big fail, it is very bad and dangerous!
#       Why is an empty string not handled similar as a filled string?
#       The best workaround is to use ALWAYS escaped double-quotes for EACH argument: & "myexe.exe" `"$arg1`" `"`" `"$arg3`";
#       But even then it is NOT ALLOWED that content contains a double-quote.
#       There is also no proper solution if quotes instead of double-quotes are used.
#       Maybe because these problems there is the recommendation of checker-tools to use options instead of positional arguments to specify parameters.
#     - Precedence of commands: Alias > Function > Filter > Cmdlet > Application > ExternalScript > Script.
#     - Override precedence of commands by using get-command, ex: Get-Command -commandType Application Ping
#   - Evaluate (string expansion) and run a command given in a string, does not create a new script scope
#     and so works in local scope. Care for code injection.
#       Invoke-Expression [-command] string [CommonParameters]
#     Very important: It performs string expansion before running, so it can be a severe problem if the string contains character $.
#     This behaviour is very bad and so avoid using Invoke-Expression and use & or . operators instead.
#     Ex: $cmd1 = "Write-Output `$PSHome"; $cmd2 = "Write-Output $PSHome"; Invoke-Expression $cmd1; Invoke-Expression $cmd2;
#   - Run a script or command remotely. See http://ss64.com/ps/invoke-command.html
#     Invoke-Command
#     If you use Invoke-Command to run a script or command on a remote computer,
#     then it will not run elevated even if the local session is. This is because any prompt
#     for elevation will happen on the remote machine in a non-interactive session and so will fail.
#     Example:  invoke-command -LiteralPath "c:\scripts\test.ps1" -computerName "Server64";
#       invoke-command -computername "server64" -credential "domain64\user64" -scriptblock {get-culture};
#   - Invoke the (provider-specific) default action on an item (like double click). For example open pdf viewer for a .pdf file.
#       Invoke-Item ./myfile.xls
#   - Start a process (intended for opening a window) waiting for end or not.
#       start-process -FilePath notepad.exe -ArgumentList """Test.txt"""; # no wait for end, opened in foreground
#       [Diagnostics.Process]::Start("notepad.exe","test.txt"); # no wait for end, opened in foreground
#       start-process -FilePath  C:\batch\demo.cmd -verb runas;
#       start-process -FilePath notepad.exe -wait -windowstyle Maximized; # wait for end
#       start-process -FilePath Sort.exe -RedirectStandardInput C:\Demo\Testsort.txt -RedirectStandardOutput C:\Demo\Sorted.txt -RedirectStandardError C:\Demo\SortError.txt
#       $pclass = [wmiclass]"root\cimv2:Win32_Process"; $new_pid = $pclass.Create("notepad.exe", ".", $null).ProcessId; # no wait for end, opened app in background
#     Run powershell with elevated rights: Start-Process -FilePath powershell.exe -Verb runAs
#     Important note: If a program is called which also has as input a commandline then the arguments must be tripple-doublequoted.
#       see https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.arguments
#           https://github.com/PowerShell/PowerShell/issues/5576
#       Start-Process -FilePath powershell.exe -Verb runAs -ArgumentList "-NoExit `"&`" notepad.exe `"`"`"Test WithBlank.txt`"`"`" "
# - Call module with arguments: ex:  Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1" -ArgumentList $myinvocation.mycommand.Path;
# - FsEntries: -LiteralPath means no interpretation of wildcards
# - Extensions and libraries: https://www.powershellgallery.com/  http://ss64.com/links/pslinks.html
# - Write Portable ps hints: https://powershell.org/2019/02/tips-for-writing-cross-platform-powershell-code/
# - Script Calling Parameters: The expression CmdletBinding for param is optional:
#   Example: [CmdletBinding()] Param( [parameter(Mandatory=$true)] [String] $p1, [parameter(Mandatory=$true)] [String] $p2 ); OutInfo "Parameters: p1=$p1 p2=$p2";
# - A starter for any tool can be created by the following code:
#     #!/usr/bin/env pwsh
#     $intput | & "mytool.exe" $args ; Exit $LASTEXITCODE ; # alternative: if( $MyInvocation.ExpectingInput ){ # has something in $input variable
#   Important note: this works well from powershell/pwsh but if such a starter is called from cmd.exe or a bat file,
#   then all arguments are not passed!!!  In that case you need to perform the following statement:  pwsh -Command MyPsScript.ps1 anyParam...
# - param ( [Parameter()] [ValidateSet("Yes", "No", "Maybe")] [String] $opt )
# - Use  Set-PSDebug -trace 1; Set-PSDebug -trace 2;  to trace each line or use  Set-PSDebug -step  for singlestep mode until  Set-PSDebug -Off;
# - Note: WMI commands should be replaced by CIM counterparts for portability,
#   see https://devblogs.microsoft.com/powershell/introduction-to-cim-cmdlets/


# - After calling a powershell function returning an array you should always preceed it with
#   an empty array (@()+(f)) to avoid null values or alternatively use append operator ($a = @(); $a += f).
