# MnCommonPsToolLib - Common Powershell Tool Library for PS5 and PS7 and multiplatforms (Windows, Linux and OSX)
# --------------------------------------------------------------------------------------------------------------
# Published at: https://github.com/mniederw/MnCommonPsToolLib
# Licensed under GPL3. This is freeware.
# 2013-2024 produced by Marc Niederwieser, Switzerland.

[String] $global:MnCommonPsToolLibVersion = "7.48";
  # Own version variable because manifest can not be embedded into the module itself only by a separate file which is a lack.
  # Major version changes will reflect breaking changes and minor identifies extensions and third number are for urgent bugfixes.
  # more see Releasenotes.txt

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
# - Encoding in PS is not consistent (different in PS5/PS7, Win/Linux)
#   So for improving compatibility between multi platforms
#   we are writing text file contents per default as UTF8 with BOM (byte order mark).
#   For reading if they have no BOM then they are read with "Default",
#   which is Win-1252(=ANSI) on windows and UTF8 on other platforms.
#   Note: On PS5 there is no encoding as UTF8NoBOM, so for UTF8 it generally writes a BOM.
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
# Recommendations for windows environment:
# - Use UTF-8 not Win1252 as standard, for example we use the following line in a startup script file:
#   ToolAddLineToConfigFile $Profile "`$Global:OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [Text.UTF8Encoding]::UTF8; # AUTOCREATED LINE BY StartupOnLogon, set pipelining to utf8.";
# - As alternative use in each relevant ps script file the following statement:
#   $Global:OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [Text.UTF8Encoding]::UTF8;
# - As further alternative switch your windows (intl.cpl):
#   Region->Administrative->Change-System-Locale:Beta-Use-Unicode-utf-8-for-worldwide-lang-support: enable.
#
# Example usages of this module for a .ps1 script:
#      # Simple example for using MnCommonPsToolLib
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
#      Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; } $ErrorActionPreference = "Stop";
#      OutInfo "Hello world";
#      OutProgress "Working";
#      StdInReadLine "Press Enter to exit.";
# More examples see: https://github.com/mniederw/MnCommonPsToolLib/tree/main/Examples



# Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).
Set-StrictMode -Version Latest;

# Check last-exit-code status
if( ((test-path "variable:LASTEXITCODE") -and $null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) ){
  Write-Host "Note: `"$PSCommandPath`" was imported by environment with LastExitCode=$LASTEXITCODE LastStatement=`"$^ ... $$`", so reset LastExitCode.";
  $global:LASTEXITCODE = 0; $error.clear();
}

# Assert that the following executed statements from here to the end of this script are not ignored.
# The functions which are later called by a caller of this script are not affected by this trap statement.
# Trap statement are not cared if a catch block is used!
# It is strongly recommended that callers of this script perform after the import-module statement the following set and trap statements for unhandled exceptions:
#   Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
# It is also strongy recommended for client code when it wants to handle exceptions that it uses catch blocks!
trap [Exception] { $Host.UI.WriteErrorLine($_); break; }

# Define global variables if they are not yet defined; caller of this script can anytime set or change these variables to control the specified behaviour.
function GlobalVariablesInit(){
  Write-Verbose "GlobalVariablesInit begin.";
  if( -not [Boolean] (Get-Variable ModeHideOutProgress               -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeHideOutProgress               -value $false; }
                                                                      # If true then OutProgress does nothing.
  if( -not [Boolean] (Get-Variable ModeDisallowInteractions          -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeDisallowInteractions          -value $false; }
                                                                      # If true then any call to a known read-from-input function will throw. For example
                                                                      # it will not restart script for entering elevated admin mode which must be acknowledged by the user
                                                                      # and after any unhandled exception it does not wait for a key (uses a delay of 1 sec instead).
                                                                      # So it can be more assured that a script works unattended.
                                                                      # The effect is comparable to that if the stdin pipe would be closed.
  if( -not [String[]](Get-Variable ArgsForRestartInElevatedAdminMode -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ArgsForRestartInElevatedAdminMode -value @()   ; }
                                                                      # if restarted for entering elevated admin mode then it additionally adds these parameters.
  if( -not [String]  (Get-Variable ModeOutputWithTsPrefix            -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeOutputWithTsPrefix            -value $false; }
                                                                      # if true then it will add before each OutInfo, OutWarning, OutError, OutProgress a timestamp prefix.
  if( -not [String]  (Get-Variable PSModuleAutoLoadingPreference     -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name PSModuleAutoLoadingPreference     -value "All"; }
                                                                      # if true then it will add before each OutInfo, OutWarning, OutError, OutProgress a timestamp prefix.
  # Set some powershell predefined global variables, also in scope of caller of this module:
  $global:ErrorActionPreference         = "Stop"                    ; # abort if a called exe will write to stderr, default is 'Continue'. Can be overridden in each command by [-ErrorAction actionPreference]
  $global:ReportErrorShowExceptionClass = $true                     ; # on trap more detail exception info
  $global:ReportErrorShowInnerException = $true                     ; # on trap more detail exception info
  $global:ReportErrorShowStackTrace     = $true                     ; # on trap more detail exception info
  $global:FormatEnumerationLimit        = 999                       ; # used for Format-Table, but seams not to work, default is 4
  $global:OutputEncoding                = [Console]::OutputEncoding ; # for pipe to native applications use the same as current console, on ps5 the default is 'System.Text.ASCIIEncoding' on ps7 it is utf-8
  if( $null -ne $Host.PrivateData ){ # if running as job then it is null
    $Host.PrivateData.VerboseForegroundColor = 'DarkGray'; # for verbose messages the default is yellow which is bad because it is flashy and equal to warnings
    $Host.PrivateData.DebugForegroundColor   = 'DarkRed' ; # for debug   messages the default is yellow which is bad because it is flashy and equal to warnings
  }
  # avoid Script Analyzer warning for PSUseDeclaredVarsMoreThanAssignments
  if( $global:ReportErrorShowExceptionClass     ){;}
  if( $global:ReportErrorShowInnerException     ){;}
  if( $global:ReportErrorShowStackTrace         ){;}

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
  Write-Verbose "GlobalVariablesInit end.";
}
GlobalVariablesInit;

# Recommended installed modules: Some functions may use the following modules
#   Import-Module  PowerShellGet   ; # Provides: Set-PSRepository, Install-Module
#   Install-Module PowerShellGet   ; # Provides: Set-PSRepository, Install-Module
#   Install-Module PSScriptAnalyzer; # used by testing files for analysing powershell code
#   Install-Module ThreadJob       ; # used by GitCloneOrPullUrls
#   Install-Module SqlServer       ; # used by SqlPerformFile, SqlPerformCmd.
# Import-Module "SqlServer"; # not always used so we dont load it here.

# Import type and function definitions
Add-Type -Name Window -Namespace Console -MemberDefinition '[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);';
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Window { [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect); [DllImport("User32.dll")] public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw); } public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }';
Add-Type -WarningAction SilentlyContinue -TypeDefinition "using System; public class ExcMsg : Exception { public ExcMsg(String s):base(s){} } ";
  # Used for error messages which have a text which will be exact enough so no additionally information as stackdump or data are nessessary. Is handled in our StdErrHandleExc.
  # Note: we need to suppress the warning: The generated type defines no public methods or properties

# Set some self defined constant global variables
if( $null -eq (Get-Variable -Scope global -ErrorAction SilentlyContinue -Name ComputerName) -or $null -eq $global:InfoLineColor ){ # check wether last variable already exists because reload safe
  New-Variable -option Constant -scope global -name CurrentMonthAndWeekIsoString -value ([String]((Get-Date -format "yyyy-MM-")+(Get-Date -uformat "W%V")));
  New-Variable -option Constant -scope global -name InfoLineColor                -Value $(switch($Host.Name -eq "Windows PowerShell ISE Host"){($true){"Gray"}default{"White"}}); # ise is white so we need a contrast color
  New-Variable -option Constant -scope global -name ComputerName                 -value ([String]"$env:computername".ToLower()); # set $ComputerName with unified lowercase $env:ComputerName
}

# Statement extensions
function ForEachParallel {
  # Works compatible for PS5 and PS7.
  # Note about statement blocks:
  #   You can call functions only from the loaded modules but all global variables are then undefined!
  #   You cannot use any functions or variables from the current script where it is embedded!
  #   Only the single variable $_ can be used, so you need to create a [System.Tuple] for passing multiple values as a single object.
  #   You can also not base on Auto-Load-Module in your script, so generally use Load-Module for each used module.
  # Example: (0..9) | ForEachParallel { Write-Output "Nr: $_"; Start-Sleep -Seconds 1; };
  # Example: (0..9) | ForEachParallel -MaxThreads 2 { Write-Output "Nr: $_"; Start-Sleep -Seconds 1; };
  # Example: $x = "abc"; (0..9) | ForEach-Object{ [System.Tuple]::Create($_,$x) } | ForEachParallel{ "$($_.Item1) $($_.Item2)" };
  Param( [Parameter(Mandatory=$true,position=0)]              [System.Management.Automation.ScriptBlock] $ScriptBlock,
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [PSObject]                                 $InputObject,
            # PSScriptAnalyzer: On PS7 we get "PSUseProcessBlockForPipelineCommand warning: Command accepts pipeline input but has not defined a process block."
            #   There is an unknown reason why we need to declare the parameter $InputObject, but we do not use it. Maybe later try to remove it.
         [Parameter(Mandatory=$false)]                        [Int32]                                    $MaxThreads=8 )
  if( $PSVersionTable.PSVersion.Major -gt 5 ){
    # Avoid PSScriptAnalyzer: On PS7 we get PSReviewUnusedParameter The parameter 'InputObject' has been declared but not used.
      $InputObject.GetType() | Out-Null;
    $input | ForEach-Object -ThrottleLimit $MaxThreads -Parallel $ScriptBlock;
  }else{
    $input | ForEachParallelPS5 -MaxThreads $MaxThreads $ScriptBlock;
  }
  # For future use: 0..9 | ForEach-Object -Parallel { Write-Output $_ } -AsJob;
}

function ForEachParallelPS5 {
  # Based on https://powertoe.wordpress.com/2012/05/03/foreach-parallel/
  Param( [Parameter(Mandatory=$true,position=0)]              [System.Management.Automation.ScriptBlock] $ScriptBlock,
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [PSObject]                                 $InputObject,
         [Parameter(Mandatory=$false)]                        [Int32]                                    $MaxThreads=8 )
  # Note: for some unknown reason we sometimes get a red line "One or more errors occurred."
  # and maybe "Collection was modified; enumeration operation may not execute." but it continuous successfully.
  # We assume it is because it uses internally autoload module and this is not fully multithreading/parallel safe.
  BEGIN{ # runs only once per pipeline
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
      $scriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("Param(`$_)$([Environment]::NewLine)"+$scriptblock.ToString());
    }catch{ $Host.UI.WriteErrorLine("ForEachParallel-BEGIN: $($_.Exception.Message)"); }
  }PROCESS{ # runs once per input object
    try{
      # alternative:
      #   [System.Management.Automation.PSDataCollection[PSObject]] $pipelineInputs = New-Object System.Management.Automation.PSDataCollection[PSObject];
      #   [System.Management.Automation.PSDataCollection[PSObject]] $pipelineOutput = New-Object System.Management.Automation.PSDataCollection[PSObject];
      $powershell = [powershell]::Create().addscript($scriptblock).addargument($InputObject);
      $powershell.runspacepool = $pool;
      $threads += @{ instance = $powershell; handle = $powershell.BeginInvoke(); }; # $pipelineInputs,$pipelineOutput
    }catch{ $Host.UI.WriteErrorLine("ForEachParallel-PROCESS: $($_.Exception.Message)"); }
    [gc]::Collect();
  }END{ # runs only once per pipeline
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
                [String] $msg = $_.Exception.Message; $error.clear();
                # 2023-07 msg example: Exception calling "EndInvoke" with "1" argument(s):
                #   "Der Befehl "MountPointCreate" wurde im Modul "MnCommonPsToolLib" gefunden, das Modul konnte aber nicht geladen werden.
                #   Wenn Sie weitere Informationen wünschen, führen Sie "Import-Module MnCommonPsToolLib" aus."
                # 2023-07 msg example: Exception calling "EndInvoke" with "1" argument(s):
                #   "Der ausgeführte Befehl wurde beendet, da die Einstellungsvariable "ErrorActionPreference" oder ein allgemeiner Parameter
                #   auf "Stop" festgelegt ist: Es ist ein allgemeiner Fehler aufgetreten, für den kein spezifischerer Fehlercode verfügbar ist.."
                Write-Verbose "ForEachParallel-endinvoke: Ignoring $msg";
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
      # Example: 2018-07: Exception calling "EndInvoke" with "1" argument(s) "Der ausgeführte Befehl wurde beendet, da die
      #                   Einstellungsvariable "ErrorActionPreference" oder ein allgemeiner Parameter auf "Stop" festgelegt ist:
      #                   Es ist ein allgemeiner Fehler aufgetreten, für den kein spezifischerer Fehlercode verfügbar ist.."
      $Host.UI.WriteErrorLine("ForEachParallel-END: $($_.Exception.Message)");
    }
    $error.clear();
    [gc]::Collect();
  }
}

# ----- Exported tools and types -----

function GlobalSetModeVerboseEnable           ( [Boolean] $val = $true ){ $global:VerbosePreference             = $(switch($val){($true){"Continue"}default{"SilentlyContinue"}}); }
function GlobalSetModeEnableAutoLoadingPref   ( [Boolean] $val = $true ){ $global:PSModuleAutoLoadingPreference = $(switch($val){($true){$null}default{"none"}}); } # enable or disable autoloading modules, available internal values: All (=default), ModuleQualified, None.
function GlobalSetModeHideOutProgress         ( [Boolean] $val = $true ){ $global:ModeHideOutProgress           = $val; if( $global:ModeHideOutProgress      ){;} } # avoid Script Analyzer warning for PSUseDeclaredVarsMoreThanAssignments
function GlobalSetModeDisallowInteractions    ( [Boolean] $val = $true ){ $global:ModeDisallowInteractions      = $val; if( $global:ModeDisallowInteractions ){;} } # avoid Script Analyzer warning for PSUseDeclaredVarsMoreThanAssignments
function GlobalSetModeOutputWithTsPrefix      ( [Boolean] $val = $true ){ $global:ModeOutputWithTsPrefix        = $val; if( $global:ModeOutputWithTsPrefix   ){;} } # avoid Script Analyzer warning for PSUseDeclaredVarsMoreThanAssignments

function StringIsNullOrEmpty                  ( [String] $s ){ return [Boolean] [String]::IsNullOrEmpty($s); }
function StringIsNotEmpty                     ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrEmpty($s)); }
function StringIsFilled                       ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrWhiteSpace($s)); }
function StringIsInt32                        ( [String] $s ){ [String] $tmp = ""; return [Int32]::TryParse($s,[ref]$tmp); }
function StringIsInt64                        ( [String] $s ){ [String] $tmp = ""; return [Int64]::TryParse($s,[ref]$tmp); }
function StringAsInt32                        ( [String] $s ){ if( -not (StringIsInt32 $s) ){ throw [Exception] "Is not an Int32: $s"; } return ($s -as [Int32]); }
function StringAsInt64                        ( [String] $s ){ if( -not (StringIsInt64 $s) ){ throw [Exception] "Is not an Int64: $s"; } return ($s -as [Int64]); }
function StringLeft                           ( [String] $s, [Int32] $len ){ return [String] $s.Substring(0,(Int32Clip $len 0 $s.Length)); }
function StringRight                          ( [String] $s, [Int32] $len ){ return [String] $s.Substring($s.Length-(Int32Clip $len 0 $s.Length)); }
function StringRemoveRightNr                  ( [String] $s, [Int32] $len ){ return [String] (StringLeft $s ($s.Length-$len)); }
function StringRemoveLeftNr                   ( [String] $s, [Int32] $len ){ return [String] (StringRight $s ($s.Length-$len)); }
function StringPadRight                       ( [String] $s, [Int32] $len, [Boolean] $doQuote = $false, [Char] $c = " "){
                                                [String] $r = $s; if( $doQuote ){ $r = '"'+$r+'"'; } return [String] $r.PadRight($len,$c); }
function StringSplitIntoLines                 ( [String] $s ){ return [String[]] ($s.Replace("`r`n","`n").Replace("`r","`n") -split "`n"); } # for empty string it returns an array with one item.
function StringReplaceNewlines                ( [String] $s, [String] $repl = " " ){ return [String] $s.Replace("`r`n","`n").Replace("`r","`n").Replace("`n",$repl); }
function StringSplitToArray                   ( [String] $sep, [String] $s, [Boolean] $removeEmptyEntries = $true ){ # works case sensitive
                                                # this would not work correctly on PS5: return [String[]] $s.Split($sep,$(switch($removeEmptyEntries){($true){[System.StringSplitOptions]::RemoveEmptyEntries}default{[System.StringSplitOptions]::None}})); }
                                                [String[]] $res = ($s -csplit $sep,0,"SimpleMatch");
                                                $res = ($res | Where-Object{ (-not $removeEmptyEntries) -or $_ -ne "" });
                                                return [String[]] (@()+$res); }
function StringReplaceEmptyByTwoQuotes        ( [String] $str ){ return [String] $(switch((StringIsNullOrEmpty $str)){($true){"`"`""}default{$str}}); }
function StringRemoveLeft                     ( [String] $str, [String] $strLeft , [Boolean] $ignoreCase = $true ){ [String] $s = (StringLeft $str $strLeft.Length);
                                                return [String] $(switch(($ignoreCase -and $s -eq $strLeft ) -or $s -ceq $strLeft ){ ($true){$str.Substring($strLeft.Length,$str.Length-$strLeft.Length)} default{$str} }); }
function StringRemoveRight                    ( [String] $str, [String] $strRight, [Boolean] $ignoreCase = $true ){ [String] $s = (StringRight $str $strRight.Length);
                                                return [String] $(switch(($ignoreCase -and $s -eq $strRight) -or $s -ceq $strRight){ ($true){StringRemoveRightNr $str $strRight.Length} default{$str} }); }
function StringRemoveOptEnclosingDblQuotes    ( [String] $s ){ if( $s.Length -ge 2 -and $s.StartsWith("`"") -and $s.EndsWith("`"") ){
                                                return [String] $s.Substring(1,$s.Length-2); } return [String] $s; }
function StringMakeNonNull                    ( [String] $s ){ if( $null -eq $s ){ return ""; }else{ return $s; } }
function StringExistsInStringArray            ( [String] $itemCaseSensitive, [String[]] $a ){ return [Boolean] (StringArrayContains $a $itemCaseSensitive); }
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
                                                function StringNormalizeAsVersion             ( [String] $versionString ){
                                                  # For comparison the first 4 dot separated parts are cared and the rest after a blank is ignored.
                                                  # Each component which begins with a digit is filled with leading zeros to a length of 5
                                                  # A leading "V" or "v" is optional and will be removed.
                                                  # Example: "12.3.40" => "00012.00003.00040"; "12.20" => "00012.00002"; "12.3.beta.40.5 descrtext" => "00012.00003.beta.00040";
                                                  #     "V12.3" => "00012.00003"; "v12.3" => "00012.00003"; "" => ""; "a" => "a"; " b" => "";
                                                  return [String] ( ( (StringSplitToArray "." (@()+(StringSplitToArray " " (StringRemoveLeft $versionString "V") $false))[0]) |
                                                    Select-Object -First 4 |
                                                    ForEach-Object{ if( $_ -match "^[0-9].*$" ){ $_.PadLeft(5,'0') }else{ $_ } }) -join "."); }
  function StringCompareVersionIsMinimum        ( [String] $version, [String] $minVersion ){
                                                  # Return true if version is equal of higher than a given minimum version (also see StringNormalizeAsVersion).
                                                  return [Boolean] ((StringNormalizeAsVersion $version) -ge (StringNormalizeAsVersion $minVersion)); }
  function StringFromException                  ( [Exception] $exc ){
                                                # Return full info of exception inclusive data and stacktrace, it can contain newlines.
                                                # Use this if $_ which is equal to $_.Exception.Message is not enough.
                                                # Usage: in catch block call it with $_.Exception
                                                # Example: "ArgumentOutOfRangeException: Specified argument was out of the range of valid values. Parameter name: times  at ..."
                                                [String] $nl = [Environment]::NewLine;
                                                [String] $typeName = switch($exc.GetType().Name -eq "ExcMsg" ){($true){"Error"}default{$exc.GetType().Name;}};
                                                [String] $excMsg   = StringReplaceNewlines $exc.Message;
                                                [String] $excData  = ""; foreach($key in $exc.Data.Keys){ $excData += "$nl  $key=`"$($exc.Data[$key])`"."; } # note: .Data is never null.
                                                [String] $stackTr  = switch($null -eq $exc.StackTrace){($true){""}default{("$nl  StackTrace:$nl "+$exc.StackTrace.Replace("$nl","$nl "))}};
                                                return [String] "$($typeName): $excMsg$excData$stackTr"; }
function StringFromErrorRecord                ( [System.Management.Automation.ErrorRecord] $er ){ # In powershell in a catch block always this type is used for $_ .
                                                [String] $msg = (StringFromException $er.Exception);
                                                [String] $nl = [Environment]::NewLine;
                                                 $msg += "$nl  ScriptStackTrace: $nl    "+$er.ScriptStackTrace.Replace("$nl","$nl    "); # Example: at <ScriptBlock>, C:\myfile.psm1: line 800 at MyFunc
                                                 $msg += "$nl  InvocationInfo:$nl    "+$er.InvocationInfo.PositionMessage.Replace("$nl","$nl    "); # At D:\myfile.psm1:800 char:83 \n   + ...   +   ~~~
                                                 $msg += "$nl  Ts=$(DateTimeNowAsStringIso) User=$($env:username) mach=$($ComputerName) ";
                                                 # $msg += "$nl  InvocationInfoLine: "+($er.InvocationInfo.Line.Replace("$nl"," ") -replace "\s+"," ");
                                                 # $msg += "$nl  InvocationInfoMyCommand: $($er.InvocationInfo.MyCommand)"; # Example: ForEach-Object
                                                 # $msg += "$nl  InvocationInfoInvocationName: $($er.InvocationInfo.InvocationName)"; # Example: ForEach-Object
                                                 # $msg += "$nl  InvocationInfoPSScriptRoot: $($er.InvocationInfo.PSScriptRoot)"; # Example: D:\MyModuleDir
                                                 # $msg += "$nl  InvocationInfoPSCommandPath: $($er.InvocationInfo.PSCommandPath)"; # Example: D:\MyToolModule.psm1
                                                 # $msg += "$nl  FullyQualifiedErrorId: $($er.FullyQualifiedErrorId)"; # Example: "System.ArgumentOutOfRangeException,Microsoft.PowerShell.Commands.ForEachObjectCommand"
                                                 # $msg += "$nl  ErrorRecord: "+$er.ToString().Replace("$nl"," "); # Example: "Specified argument was out of the range of valid values. Parametername: times"
                                                 # $msg += "$nl  CategoryInfo: $(switch($null -ne $er.CategoryInfo){($true){$er.CategoryInfo.ToString()}default{''}})"; # https://msdn.microsoft.com/en-us/library/system.management.automation.errorcategory(v=vs.85).aspx
                                                 # $msg += "$nl  PipelineIterationInfo: $($er.PipelineIterationInfo|Where-Object{$null -ne $_}|ForEach-Object{'$_, '})";
                                                 # $msg += "$nl  TargetObject: $($er.TargetObject)"; # can be null
                                                 # $msg += "$nl  ErrorDetails: $(switch($null -ne $er.ErrorDetails){($true){$er.ErrorDetails.ToString()}default{''}})";
                                                 # $msg += "$nl  PSMessageDetails: $($er.PSMessageDetails)";
                                                 return [String] $msg; }
function StringCommandLineToArray             ( [String] $commandLine ){
                                                # Care spaces or tabs separated args and doublequoted args which can contain double doublequotes for escaping single doublequotes.
                                                # Example: "my cmd.exe" arg1 "ar g2" "arg""3""" "arg4"""""  Example: StringCommandLineToArray "`"my cmd.exe`" arg1 `"ar g2`" `"arg`"`"3`"`"`" `"arg4`"`"`"`"`""
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
function DateTimeNowAsStringIsoMinutes        (){ return [String] (Get-Date -format "yyyy-MM-dd HH:mm"); }
function DateTimeNowAsStringIsoDate           (){ return [String] (Get-Date -format "yyyy-MM-dd"); }
function DateTimeNowAsStringIsoMonth          (){ return [String] (Get-Date -format "yyyy-MM"); }
function DateTimeNowAsStringIsoYear           (){ return [String] (Get-Date -format "yyyy"); }
function DateTimeFromStringIso                ( [String] $s ){ # "yyyy-MM-dd HH:mm:ss.fff" or "yyyy-MM-ddTHH:mm:ss.fff" or "yyyy-MM-ddTHH:mm:ss.fffzzz".
                                                [String] $fmt = "yyyy-MM-dd HH:mm:ss.fff";
                                                [Int32] $l = $s.Length;
                                                [Boolean] $hasZoneOffset = $l -gt 10 -and (StringRight $s 5) -match "^[-+]\d\d\d\d$";
                                                if( $hasZoneOffset ){ $l = $s.Length - 5; }
                                                if    ( $l -le 10 ){ $fmt = "yyyy-MM-dd"; }
                                                elseif( $l -le 16 ){ $fmt = "yyyy-MM-dd HH:mm"; }
                                                elseif( $l -le 19 ){ $fmt = "yyyy-MM-dd HH:mm:ss"; }
                                                elseif( $l -le 20 ){ $fmt = "yyyy-MM-dd HH:mm:ss."; }
                                                elseif( $l -le 21 ){ $fmt = "yyyy-MM-dd HH:mm:ss.f"; }
                                                elseif( $l -le 22 ){ $fmt = "yyyy-MM-dd HH:mm:ss.ff"; }
                                                elseif( $l -le 23 ){ $fmt = "yyyy-MM-dd HH:mm:ss.fff"; }
                                                if( $hasZoneOffset ){ $fmt += "zzz"; }
                                                if( $l -gt 10 -and $s[10] -ceq 'T' ){ $fmt = $fmt.remove(10,1).insert(10,'T'); }
                                                try{ return [DateTime] [DateTime]::ParseExact($s,$fmt,[System.Globalization.CultureInfo]::InvariantCulture);
                                                }catch{ # exc: Ausnahme beim Aufrufen von "ParseExact" mit 3 Argument(en): Die Zeichenfolge wurde nicht als gültiges DateTime erkannt.
                                                  throw [Exception] "DateTimeFromStringIso(`"$s`") is not a valid datetime in format `"$fmt`""; } }
function DateTimeFromStringOrDateTimeValue    ( [Object] $v ){ # Used for example after ConvertFrom-Json for unifying a value to type DateTime because PS7 sets for example type=DateTime and PS5 the type=String.
                                                # example input: "2023-06-30T23:59:59.123+0000"
                                                # On PS5 with json data from github we got "2023-11-14T08:39:42Z", which we convert to "2023-11-14T08:39:42+0000"
                                                return [DateTime] $(switch($v.GetType().FullName){
                                                  "System.DateTime" { $v; }
                                                  "System.String"   { if( $v.EndsWith("Z") ){ $v = (StringRemoveRightNr $v 1)+"+0000"; } DateTimeFromStringIso $v; }
                                                  default           { throw [Exception] "Expected type String or DateTime instead of $($v.GetType().FullName) for value: $v"; }
                                                }); }
function ByteArraysAreEqual                   ( [Byte[]] $a1, [Byte[]] $a2 ){ if( $a1.LongLength -ne $a2.LongLength ){ return [Boolean] $false; }
                                                for( [Int64] $i = 0; $i -lt $a1.LongLength; $i++ ){ if( $a1[$i] -ne $a2[$i] ){ return [Boolean] $false; } } return [Boolean] $true; }
function ArrayIsNullOrEmpty                   ( [Object[]] $a ){ return [Boolean] ($null -eq $a -or $a.Count -eq 0); }
function ConsoleHide                          (){ if( (Get-Process -ID $PID).MainWindowHandle -ne 0 ){ [Object] $p = [Console.Window]::GetConsoleWindow(); [Console.Window]::ShowWindow($p,0) | Out-Null; } } # 0=hide; Alternative: pwsh -WindowStyle Hidden {;}
function ConsoleShow                          (){ if( (Get-Process -ID $PID).MainWindowHandle -ne 0 ){ [Object] $p = [Console.Window]::GetConsoleWindow(); [Console.Window]::ShowWindow($p,5) | Out-Null; } } # 5=nohide
function ConsoleRestore                       (){ if( (Get-Process -ID $PID).MainWindowHandle -ne 0 ){ [Object] $p = [Console.Window]::GetConsoleWindow(); [Console.Window]::ShowWindow($p,1) | Out-Null; } } # 1=show
function ConsoleMinimize                      (){ if( (Get-Process -ID $PID).MainWindowHandle -ne 0 ){ [Object] $p = [Console.Window]::GetConsoleWindow(); [Console.Window]::ShowWindow($p,6) | Out-Null; } } # 6=minimize
Function ConsoleSetPos                        ( [Int32] $x, [Int32] $y ){ # if console is in a window then move to specified location
                                                [RECT] $r = New-Object RECT; [Object] $hd = (Get-Process -ID $PID).MainWindowHandle;
                                                if( $hd -ne 0 ){ # is 0 for ubuntu-consoles
                                                  [Object] $t = [Window]::GetWindowRect($hd,[ref]$r);
                                                  [Int32] $w = $r.Right - $r.Left; [Int32] $h = $r.Bottom - $r.Top;
                                                  If( $t ){ [Window]::MoveWindow($hd, $x, $y, $w, $h, $true) | Out-Null; }
                                                } }
function ConsoleSetGuiProperties              (){ # set standard sizes which makes sense, display-hight 46 lines for HD with 125% zoom. It is performed only once per shell.
                                                # On Ubuntu setting buffersize is not supported, so a warning is given out to verbose output.
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
                                                }catch{
                                                  if( $_.Exception.Message.Contains("Operation is not supported on this platform.") ){
                                                    # On Ubuntu we get: exc: "Exception setting "buffersize": "Operation is not supported on this platform.""
                                                    OutVerbose "Warning: Ignore setting buffersize failed because $($_.Exception.Message)";
                                                  }else{
                                                    # seldom we got: PSArgumentOutOfRangeException: Cannot set the buffer size because the size specified is too large or too small.
                                                    OutWarning "Warning: Ignore setting buffersize failed because $($_.Exception.Message)";
                                                  }
                                                }
                                                $w = $Host.ui.RawUI; # refresh values, maybe meanwhile windows was resized
                                                if( $null -ne $w.WindowSize ){ # is null in case of powershell-ISE
                                                  [Object] $m = $w.windowsize;
                                                  $m.Height = 48;
                                                  $m.Width = 150;
                                                  # avoid: PSArgumentOutOfRangeException: Window cannot be wider than 147. Parameter name: value.Width Actual value was 150.
                                                  #        PSArgumentOutOfRangeException: Window cannot be taller than 47. Parameter name: value.Height Actual value was 48.
                                                  $m.Width  = [math]::min($m.Width ,$Host.ui.RawUI.BufferSize.Width);
                                                  $m.Width  = [math]::min($m.Width ,$w.MaxWindowSize.Width);
                                                  $m.Width  = [math]::min($m.Width ,$w.MaxPhysicalWindowSize.Width);
                                                  $m.Height = [math]::min($m.Height,$host.ui.RawUI.BufferSize.Height);
                                                  $m.Height = [math]::min($m.Height,$w.MaxWindowSize.Height);
                                                  $m.Height = [math]::min($m.Height,$w.MaxPhysicalWindowSize.Height);
                                                  try{
                                                    $w.windowsize = $m;
                                                  }catch{
                                                    if( $_.Exception.Message.Contains("Operation is not supported on this platform.") ){
                                                      # On Ubuntu we get: exc: "Exception setting "windowsize": "Operation is not supported on this platform.""
                                                      OutVerbose "Warning: Ignore setting windowsize failed because $($_.Exception.Message)";
                                                    }else{ throw; }
                                                  }
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
                                                if( $useHHMMSS ){ $pattern += "_HH'h'mm'm'ss's'"; }
                                                [String] $f = "$env:TEMP/tmp/$name/$((DateTimeNowAsStringIso $pattern).Replace(" ","/")).$name.txt"; # works for windows and linux
                                                Start-Transcript -Path $f -Append -IncludeInvocationHeader | Out-Null;
                                                return [String] $f; }
function OutStopTranscript                    (){ Stop-Transcript | Out-Null; } # Writes to output: Transcript stopped, output file is C:\Temp\....txt
function StdOutLine                           ( [String] $line ){ $Host.UI.WriteLine($line); } # Writes an stdout line in default color, normally not used, rather use OutInfo because it classifies kind of output.
function StdInAssertAllowInteractions         (){ if( $global:ModeDisallowInteractions ){
                                                throw [Exception] "Cannot read for input because all interactions are disallowed, either caller should make sure variable ModeDisallowInteractions is false or he should not call an input method."; } }
function StdInReadLine                        ( [String] $line ){ OutStringInColor "Cyan" $line; StdInAssertAllowInteractions; return [String] (Read-Host); }
function StdInReadLinePw                      ( [String] $line ){ OutStringInColor "Cyan" $line; StdInAssertAllowInteractions; return [System.Security.SecureString] (Read-Host -AsSecureString); }
function StdInAskForEnter                     ( [String] $msg = "Press Enter to continue" ){ StdInReadLine $msg | Out-Null; }
function StdInAskForBoolean                   ( [String] $msg = "Enter Yes or No (y/n)?", [String] $strForYes = "y", [String] $strForNo = "n" ){
                                                 while($true){ OutStringInColor "Magenta" $msg;
                                                 [String] $answer = StdInReadLine ""; if( $answer -eq $strForYes ){ return [Boolean] $true ; }
                                                 if( $answer -eq $strForNo  ){ return [Boolean] $false; } } }
function StdInWaitForAKey                     (){ StdInAssertAllowInteractions; $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null; } # does not work in powershell-ise, so in general do not use it, use StdInReadLine
function StdOutRedLineAndPerformExit          ( [String] $line, [Int32] $delayInSec = 1 ){ #
                                                OutError $line; if( $global:ModeDisallowInteractions ){ ProcessSleepSec $delayInSec; }else{ StdInReadLine "Press Enter to Exit"; }; Exit 1; }
function StdErrHandleExc                      ( [System.Management.Automation.ErrorRecord] $er, [Int32] $delayInSec = 1 ){
                                                # Output full error information in red lines and then either wait for pressing enter or otherwise
                                                # if interactions are globally disallowed then wait for specified delay.
                                                [String] $msg = "$(StringFromErrorRecord $er)";
                                                OutError $msg;
                                                if( -not $global:ModeDisallowInteractions ){
                                                  OutError "Press Enter to exit.";
                                                  try{
                                                    Read-Host; return;
                                                  }catch{ # exc: PSInvalidOperationException:  Read-Host : Windows PowerShell is in NonInteractive mode. Read and Prompt functionality is not available.
                                                    OutError "Note: Cannot Read-Host because $($_.Exception.Message)";
                                                  }
                                                }
                                                if( $delayInSec -gt 0 ){ StdOutLine "Waiting for $delayInSec seconds."; }
                                                ProcessSleepSec $delayInSec; }
function StdPipelineErrorWriteMsg             ( [String] $msg ){ Write-Error $msg; } # does not work in powershell-ise, so in general do not use it, use throw
function StdInAskForAnswerWhenInInteractMode  ( [String] $line = "Are you sure (y/n)? ", [String] $expectedAnswer = "y" ){
                                                # works case insensitive; is ignored if interactions are suppressed by global var ModeDisallowInteractions; will abort if not expected answer.
                                                if( -not $global:ModeDisallowInteractions ){ [String] $answer = StdInReadLine $line; if( $answer -ne $expectedAnswer ){ StdOutRedLineAndPerformExit "Aborted"; } } }
function StdInAskAndAssertExpectedAnswer      ( [String] $line = "Are you sure (y/n)? ", [String] $expectedAnswer = "y" ){ # works case insensitive
                                                [String] $answer = StdInReadLine $line; if( $answer -ne $expectedAnswer ){ StdOutRedLineAndPerformExit "Aborted"; } }
function Assert                               ( [Boolean] $cond, [String] $failReason = "condition is false." ){
                                                if( -not $cond ){ throw [Exception] "Assertion failed because $failReason"; } }
function AssertIsFalse                        ( [Boolean] $cond, [String] $failReason = "" ){
                                                if( $cond ){ throw [Exception] "Assertion-Is-False failed because $failReason"; } }
function AssertNotEmpty                       ( [String] $s, [String] $varName ){
                                                Assert ($s -ne "") "not allowed empty string for $varName."; }
function AssertRcIsOk                         ( [String[]] $linesToOutProgress = "", [Boolean] $useLinesAsExcMessage = $false,
                                                [String] $logFileToOutProgress = "", [String] $encodingIfNoBom = "Default" ){
                                                # Asserts success status of last statement and wether code of last exit or native command was zero.
                                                # In case it was not ok it optionally outputs given progress information and throws.
                                                # Only nonempty progress lines are given out.
                                                # Argument linesToOutProgress can also be called with a single string;
                                                # if logFileToOutProgress is given than the lines are given out.
                                                [String] $saveLastCmdInfo = "$?,$^ ... $$"; [Int32] $rc = ScriptGetAndClearLastRc;
                                                [Boolean] $lastCmdIsSucc = ($saveLastCmdInfo -split ",",2)[0] -eq "True";
                                                if( $lastCmdIsSucc -and $rc -eq 0 ){ return; }
                                                if( -not $useLinesAsExcMessage ){ $linesToOutProgress | Where-Object{ StringIsFilled $_ } | ForEach-Object{ OutProgress $_ }; }
                                                [String] $msg = $(switch($lastCmdIsSucc){($true){"Last statement `"$(($saveLastCmdInfo -split ",",2)[1])`" failed. "}})+
                                                  $(switch($rc -ne 0){($true){"Last operation failed [ExitCode=$rc]. "}})+
                                                  "For the reason see the previous output. ";
                                                $msg = $(switch( $useLinesAsExcMessage -and $linesToOutProgress -ne "" ){($true){""}default{$msg}}) + ([String]$linesToOutProgress).Trim();
                                                if( $logFileToOutProgress -ne "" ){
                                                  try{
                                                    OutProgress "Dump of logfile=$($logFileToOutProgress): ";
                                                    Get-Content -Encoding $encodingIfNoBom -LiteralPath $logFileToOutProgress |
                                                      Where-Object{$null -ne $_} | ForEach-Object{ OutProgress "  $_"; }
                                                  }catch{
                                                    OutVerbose "Ignoring problems on reading $logFileToOutProgress failed because $($_.Exception.Message)";
                                                  }
                                                }
                                                throw [Exception] $msg; }
function HelpHelp                             (){ Get-Help     | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllVariables               (){ Get-Variable | Sort-Object Name | ForEach-Object{ OutInfo "$($_.Name.PadRight(32)) $($_.Value)"; } } # Select-Object Name, Value | StreamToListString
function HelpListOfAllAliases                 (){ Get-Alias    | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllCommands                (){ Get-Command  | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object{ OutInfo $_; } }
function HelpListOfAllModules                 (){ Get-Module -ListAvailable | Sort-Object Name | Select-Object Name, ModuleType, Version, ExportedCommands; } # depends on $env:PSModulePath
function HelpListOfAllExportedCommands        (){ (Get-Module -ListAvailable).ExportedCommands.Values | Sort-Object Name | Select-Object Name, ModuleName; }
function HelpGetType                          ( [Object] $obj ){ return [String] $obj.GetType(); }
function ScriptImportModuleIfNotDone          ( [String] $moduleName ){ if( -not (Get-Module $moduleName) ){
                                                OutProgress "Import module $moduleName (can take some seconds on first call)";
                                                Import-Module -NoClobber $moduleName -DisableNameChecking; } }
function ScriptGetCurrentFunc                 (){ return [String] ((Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name); }
function ScriptGetCurrentFuncName             (){ return [String] ((Get-PSCallStack)[2].Position); }
function ScriptGetAndClearLastRc              ( [Int32] $rcForLastStmtFailure = 255 ){
                                                #    return lastExitCode         when last exit or native call was not zero
                                                # or return rcForLastStmtFailure when lastExitCode was zero but last statement failed
                                                # or return zero                 when all was ok.
                                                [Int32] $rc = $(switch($?){($true){0}($false){$rcForLastStmtFailure}});
                                                # if no native or exit command was done then $LASTEXITCODE is null.
                                                if( (test-path "variable:LASTEXITCODE") -and $null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0 ){ $rc = $LASTEXITCODE; ScriptResetRc; }
                                                return [Int32] $rc; }
function ScriptResetRc                        (){ $global:LASTEXITCODE = 0; $error.clear(); } # reset last-exit-code to zero.
function ScriptNrOfScopes                     (){ [Int32] $i = 1; while($true){
                                                try{ Get-Variable null -Scope $i -ValueOnly -ErrorAction SilentlyContinue | Out-Null; $i++;
                                                }catch{ # exc: System.Management.Automation.PSArgumentOutOfRangeException
                                                  return [Int32] ($i-1); } } }
function ScriptGetProcessCommandLine          (){ return [String] ([Environment]::commandline); } # Example: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "& \"C:\myscript.ps1\"";  or  "C:\Program Files\PowerShell\7\pwsh.dll" -nologo
function ScriptGetDirOfLibModule              (){ return [String] $PSScriptRoot ; } # Get dir       of this script file of this function or empty if not from a script; alternative: (Split-Path -Parent -Path ($script:MyInvocation.MyCommand.Path))
function ScriptGetFileOfLibModule             (){ return [String] $PSCommandPath; } # Get full path of this script file of this function or empty if not from a script. alternative1: try{ return [String] (Get-Variable MyInvocation -Scope 1 -ValueOnly).MyCommand.Path; }catch{ return [String] ""; }  alternative2: $script:MyInvocation.MyCommand.Path
function ScriptGetCallerOfLibModule           (){ return [String] $MyInvocation.PSCommandPath; } # Result can be empty or implicit module if called interactive. alternative for dir: $MyInvocation.PSScriptRoot.
function ScriptGetTopCaller                   (){ # return the command line with correct doublequotes.
                                                # Result can be empty or implicit module if called interactive.
                                                # usage Example: "&'$env:TEMP/tmp/A.ps1'" or '&"$env:TEMP/tmp/A.ps1"' or on ISE '"$env:TEMP/tmp/A.ps1"'
                                                [String] $f = $global:MyInvocation.MyCommand.Definition.Trim();
                                                if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return [String] ""; }
                                                if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
                                                if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
                                                return [String] $f; }
function ScriptIsProbablyInteractive          (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim();
                                                # Result can be empty or implicit module if called interactive.
                                                # usage Example: "&'$env:TEMP/tmp/A.ps1'" or '&"$env:TEMP/tmp/A.ps1"' or on ISE '"$env:TEMP/tmp/A.ps1"'
                                                return [Boolean] $f -eq "" -or $f -eq "ScriptGetTopCaller" -or -not $f.StartsWith("&"); }
function StreamAllProperties                  (){ $input | Select-Object *; }
function StreamAllPropertyTypes               (){ $input | Get-Member -Type Property; }
function StreamFilterWhitespaceLines          (){ $input | Where-Object{ StringIsFilled $_ }; }
function StreamToNull                         (){ $input | Out-Null; }
function StreamToString                       (){ $input | Out-String -Width 999999999; }
function StreamToStringDelEmptyLeadAndTrLines (){ $input | Out-String -Width 999999999 | ForEach-Object{ $_ -replace "[ \f\t\v]]+\r\n","\r\n" -replace "^(\r\n)+","" -replace "(\r\n)+$","" }; }
function StreamToGridView                     (){ $input | Out-GridView -Title "TableData"; }
function StreamToCsvStrings                   (){ $input | ConvertTo-Csv -NoTypeInformation; }
                                                # Note: For a simple string array as example  @("one","two")|StreamToCsvStrings  it results with 3 lines "Length","3","3".
function StreamToJsonString                   (){ $input | ConvertTo-Json -Depth 100; }
function StreamToJsonCompressedString         (){ $input | ConvertTo-Json -Depth 100 -Compress; }
function StreamToXmlString                    (){ $input | ConvertTo-Xml -Depth 999999999 -As String -NoTypeInformation; }
function StreamToHtmlTableStrings             (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As Table; }
function StreamToHtmlListStrings              (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As List; }
function StreamToListString                   (){ $input | Format-List -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToFirstPropMultiColumnString   (){ $input | Format-Wide -AutoSize -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToStringIndented               ( [Int32] $nrOfChars = 4 ){ StringSplitIntoLines ($input | StreamToStringDelEmptyLeadAndTrLines) | ForEach-Object{ "$(" "*$nrOfChars)$_" }; }
function StreamToDataRowsString               ( [String[]] $propertyNames = @() ){ # no header, only rows.
                                                if( $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); }
                                                $input | Format-Table -Wrap -Force -autosize -HideTableHeaders $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToTableString                  ( [String[]] $propertyNames = @() ){
                                                # Note: For a simple string array as example  @("one","two")|StreamToTableString  it results with 4 lines "Length","------","     3","     3".
                                                if( $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); }
                                                $input | Format-Table -Wrap -Force -autosize $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function StreamFromCsvStrings                 ( [Char] $delimiter = ',' ){ $input | ConvertFrom-Csv -Delimiter $delimiter; }
function StreamToCsvFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8BOM" ){
                                                # If overwrite is false then nothing done if target already exists.
                                                if( (ProcessIsLesserEqualPs5) -and $encoding -eq "UTF8BOM" ){ $encoding = "UTF8"; }
                                                $input | Export-Csv -Force:$overwrite -NoClobber:$(-not $overwrite) -NoTypeInformation -Encoding $encoding -Path (FsEntryEsc $file); }
function StreamToXmlFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8BOM" ){
                                                # If overwrite is false then nothing done if target already exists.
                                                if( (ProcessIsLesserEqualPs5) -and $encoding -eq "UTF8BOM" ){ $encoding = "UTF8"; }
                                                $input | Export-Clixml -Force:$overwrite -NoClobber:$(-not $overwrite) -Depth 999999999 -Encoding $encoding -Path (FsEntryEsc $file); }
function StreamToFile                         ( [String] $file, [Boolean] $overwrite = $true, [String] $encoding = "UTF8BOM" ){
                                                # Will create path of file. overwrite does ignore readonly attribute.
                                                OutProgress "WriteFile $file"; FsEntryCreateParentDir $file;
                                                if( (ProcessIsLesserEqualPs5) -and $encoding -eq "UTF8BOM" ){ $encoding = "UTF8"; }
                                                $input | Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -LiteralPath $file; }
function OsPsVersion                          (){ return [String] (""+$Host.Version.Major+"."+$Host.Version.Minor); } # alternative: $PSVersionTable.PSVersion.Major
function OsIsWindows                          (){ return [Boolean] ([System.Environment]::OSVersion.Platform -eq "Win32NT"); }
                                                # Example: Win10Pro: Version="10.0.19044.0"
                                                # Alternative: "$($env:WINDIR)" -ne ""; In PS6 and up you can use: $IsMacOS, $IsLinux, $IsWindows.
                                                # for future: function OsIsLinux(){ return [Boolean] ([System.Environment]::OSVersion.Platform -eq "Unix"); } # example: Ubuntu22: Version="5.15.0.41"
function OsIsWinVistaOrHigher                 (){ return [Boolean] ((OsIsWindows) -and [Environment]::OSVersion.Version -ge (new-object "Version" 6,0)); }
function OsIsWin7OrHigher                     (){ return [Boolean] ((OsIsWindows) -and [Environment]::OSVersion.Version -ge (new-object "Version" 6,1)); }
function OsPathSeparator                      (){ return [String] $(switch(OsIsWindows){$true{";"}default{":"}}); } # separator for PATH environment variable
function OsPsModulePathList                   (){ # return content of $env:PSModulePath as string-array with os dependent dir separators.
                                                # Usual entries: On Windows, PS5/PS7, scope MACHINE:
                                                #   C:\Windows\system32\WindowsPowerShell\v1.0\Modules\   (strongly recommended as long as ps7 not contains all of ps5)
                                                #   C:\Program Files\WindowsPowerShell\Modules\
                                                #   D:\MyDevelopDir\mniederw\MnCommonPsToolLib#trunk\
                                                # Usual additonal entries: On Windows PS5, scope PROCESS:
                                                #   $HOME\Documents\WindowsPowerShell\Modules\
                                                # Usual additonal entries: On Windows PS7, scope PROCESS:
                                                #   $HOME\Documents\PowerShell\Modules\
                                                #   C:\Program Files\PowerShell\Modules\
                                                #   c:\program files\powershell\7\Modules\
                                                # Note: If a single backslash is part of the PSModulePath then autocompletion is very slow (2017-08).
                                                return [String[]] (@()+(([Environment]::GetEnvironmentVariable("PSModulePath","Machine").
                                                  Split((OsPathSeparator),[System.StringSplitOptions]::RemoveEmptyEntries)) | Where-Object{$null -ne $_} |
                                                  ForEach-Object{ FsEntryMakeTrailingDirSep $_ })); }
function OsPsModulePathContains               ( [String] $dir ){ # Example: "D:\MyGitRoot\MyGitAccount\MyPsLibRepoName"
                                                [String[]] $a = OsPsModulePathList;
                                                return [Boolean] ($a -contains (FsEntryMakeTrailingDirSep $dir)); }
function OsPsModulePathAdd                    ( [String] $dir ){ $dir = FsEntryMakeTrailingDirSep $dir; if( (OsPsModulePathContains $dir) ){ return; }
                                                OsPsModulePathSet ((OsPsModulePathList)+@($dir)); }
function OsPsModulePathDel                    ( [String] $dir ){ $dir = FsEntryMakeTrailingDirSep $dir; OsPsModulePathSet (@()+(OsPsModulePathList |
                                                Where-Object{$null -ne $_} | Where-Object{ -not (FsEntryPathIsEqual $_ $dir) })); }
function OsPsModulePathSet                    ( [String[]] $pathList ){ [String] $s = ((@()+($pathList | Where-Object{$null -ne $_} |
                                                  ForEach-Object{ FsEntryRemoveTrailingDirSep $_ })) -join (OsPathSeparator))+(OsPathSeparator);
                                                [Environment]::SetEnvironmentVariable("PSModulePath",$s,"Machine"); }
function PrivAclRegRightsToString             ( [System.Security.AccessControl.RegistryRights] $rule ){
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
function ProcessIsLesserEqualPs5              (){ return [Boolean] ($PSVersionTable.PSVersion.Major -le 5); }
function ProcessPsExecutable                  (){ return [String] $(switch((ProcessIsLesserEqualPs5)){ $true{"powershell.exe"} default{"pwsh"}}); }
function ProcessIsRunningInElevatedAdminMode  (){ if( (OsIsWindows) ){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
                                                  return [Boolean] ("$env:SUDO_USER" -ne ""); }
function ProcessAssertInElevatedAdminMode     (){ Assert (ProcessIsRunningInElevatedAdminMode) "requires to be in elevated admin mode"; }
function ProcessRestartInElevatedAdminMode    (){ if( (ProcessIsRunningInElevatedAdminMode) ){ return; }
                                                # Example: "C:\myscr.ps1" or if interactive then statement name example "ProcessRestartInElevatedAdminMode"
                                                [String] $cmd = @( (ScriptGetTopCaller) ) + $global:ArgsForRestartInElevatedAdminMode;
                                                if( $global:ModeDisallowInteractions ){
                                                  [String] $msg = "Script `"$cmd`" is currently not in elevated admin mode and function ProcessRestartInElevatedAdminMode was called ";
                                                  $msg += "but currently the mode ModeDisallowInteractions=$($global:ModeDisallowInteractions), ";
                                                  $msg += "and so restart will not be performed. Now it will continue but it probably will fail.";
                                                  OutWarning "Warning: $msg";
                                                }else{
                                                  $cmd = $cmd.Replace("`"","`"`"`""); # see https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.arguments
                                                  $cmd = $(switch((ProcessIsLesserEqualPs5)){ $true{"& `"$cmd`""} default{"-Command `"$cmd`""}});
                                                  $cmd = $(switch(ScriptIsProbablyInteractive){ ($true){"-NoExit -NoLogo "} default{""} }) + $cmd;
                                                  OutProgress "Not running in elevated administrator mode so elevate current script and exit:";
                                                  if( (OsIsWindows) ){
                                                    OutProgress "  Start-Process -Verb RunAs -FilePath $(ProcessPsExecutable) -ArgumentList $cmd";
                                                    Start-Process -Verb "RunAs" -FilePath (ProcessPsExecutable) -ArgumentList $cmd;
                                                    # Example exc: InvalidOperationException: This command cannot be run due to the error: Der Vorgang wurde durch den Benutzer abgebrochen.
                                                    OutProgress "Exiting in 10 seconds";
                                                    ProcessSleepSec 10;
                                                  }else{
                                                    # 2023-12: Start-Process: The parameter '-Verb' is not supported for the cmdlet 'Start-Process' on this edition of PowerShell.
                                                    $cmd = "$(ProcessPsExecutable) $cmd"; # maybe we have to use: -CommandWithArgs cmdString
                                                    OutProgress "  sudo $(StringCommandLineToArray $cmd)";
                                                    & sudo (StringCommandLineToArray $cmd);
                                                  }
                                                  [Environment]::Exit("0"); # Note: 'Exit 0;' would only leave the last '. mycommand' statement.
                                                  throw [Exception] "Exit done, but it did not work, so it throws now an exception.";
                                                } }
function ProcessFindExecutableInPath          ( [String] $exec ){
                                                # Return full path or empty if not found. Note:
                                                # if an alias with the same name is defined then it Get-Command returns the alias.
                                                if( $exec -eq "" ){ return [String] ""; }
                                                [Object] $p = (Get-Command $exec -ErrorAction SilentlyContinue);
                                                if( $null -eq $p ){ return [String] ""; } return [String] $p.Source; }
function ProcessGetCurrentThreadId            (){ return [Int32] [Threading.Thread]::CurrentThread.ManagedThreadId; }
function ProcessListRunnings                  (){ return [Object[]] (@()+(Get-Process * | Where-Object{$null -ne $_} |
                                                    Where-Object{ $_.Id -ne 0 } | Sort-Object ProcessName)); }
function ProcessListRunningsFormatted         (){ return [Object[]] (@()+( ProcessListRunnings | Select-Object Name, Id,
                                                    @{Name="CpuMSec";Expression={[Decimal]::Floor($_.TotalProcessorTime.TotalMilliseconds).ToString().PadLeft(7,' ')}},
                                                    StartTime, @{Name="Prio";Expression={($_.BasePriority)}}, @{Name="WorkSet";Expression={($_.WorkingSet64)}}, Path |
                                                    StreamToTableString )); }
function ProcessListRunningsAsStringArray     (){ return [String[]] (StringSplitIntoLines (@()+(ProcessListRunnings |
                                                    Where-Object{$null -ne $_} |
                                                    Format-Table -auto -HideTableHeaders " ",ProcessName,ProductVersion,Company |
                                                    StreamToStringDelEmptyLeadAndTrLines))); }
function ProcessIsRunning                     ( [String] $processName ){ return [Boolean] ($null -ne (Get-Process -ErrorAction SilentlyContinue ($processName.Replace(".exe","")))); }
function ProcessCloseMainWindow               ( [String] $processName ){ # enter name without exe extension.
                                                while( (ProcessIsRunning $processName) ){
                                                  Get-Process $processName | ForEach-Object {
                                                    OutProgress "CloseMainWindows `"$processName`"";
                                                    $_.CloseMainWindow() | Out-Null;
                                                    ProcessSleepSec 1; }; } }
function ProcessKill                          ( [String] $processName ){ # kill all with the specified name, note if processes are not from owner then it requires to previously call ProcessRestartInElevatedAdminMode
                                                [System.Diagnostics.Process[]] $p = Get-Process $processName.Replace(".exe","") -ErrorAction SilentlyContinue;
                                                if( $null -ne $p ){ OutProgress "ProcessKill $processName"; $p.Kill(); } }
function ProcessSleepSec                      ( [Int32] $sec ){ Start-Sleep -Seconds $sec; }
function ProcessListInstalledAppx             (){ if( -not (OsIsWindows) ){ return [String[]] @(); }
                                                  if( -not (ProcessIsLesserEqualPs5) ){
                                                    # 2023-03: Problems using Get-AppxPackage in PS7, see end of: https://github.com/PowerShell/PowerShell/issues/13138
                                                    Import-Module -Name Appx -UseWindowsPowerShell 3> $null;
                                                      # We suppress the output: WARNING: Module Appx is loaded in Windows PowerShell using WinPSCompatSession remoting session;
                                                      #   please note that all input and output of commands from this module will be deserialized objects.
                                                      #   If you want to load this module into PowerShell please use 'Import-Module -SkipEditionCheck' syntax.
                                                  }
                                                  return [String[]] (@()+(Get-AppxPackage | Where-Object{$null -ne $_} |
                                                    ForEach-Object{ "$($_.PackageFullName)" } | Sort-Object)); }
function ProcessGetCommandInEnvPathOrAltPaths ( [String] $commandNameOptionalWithExtension, [String[]] $alternativePaths = @(), [String] $downloadHintMsg = ""){
                                                [System.Management.Automation.CommandInfo] $cmd = Get-Command -CommandType Application -Name $commandNameOptionalWithExtension -ErrorAction SilentlyContinue | Select-Object -First 1;
                                                if( $null -ne $cmd ){ return [String] $cmd.Source; }
                                                foreach( $d in $alternativePaths ){
                                                  [String] $f = (Join-Path $d $commandNameOptionalWithExtension);
                                                  if( (FileExists $f) ){ return [String] $f; } }
                                                throw [Exception] "$(ScriptGetCurrentFunc): commandName=`"$commandNameOptionalWithExtension`" was wether found in env-path=`"$env:PATH`" nor in alternativePaths=`"$alternativePaths`". $downloadHintMsg"; }
function ProcessStart                         ( [String] $cmd, [String[]] $cmdArgs = @(), [Boolean] $careStdErrAsOut = $false, [Boolean] $traceCmd = $false ){
                                                # Start any gui or console command including ps scripts in path and provide arguments in an array, waits for output
                                                # and returns output as a single string. You can use StringSplitIntoLines on output to get it as lines.
                                                # Console input is disabled.
                                                # The advantages in contrast of using the call operator (&) are:
                                                # - You do not have to call AssertRcIsOk afterwards, in case of an error it throws.
                                                # - Empty-string parameters can be passed to the calling program.
                                                # - It has no side effects if the parameters contains special characters as quotes, double-quotes or $-characters.
                                                # - as tracing the calling command can easy be written to output.
                                                # The only known disadvantage currently is, it is not optimized for line oriented output because it returns a single string.
                                                # As working directory the current dir is taken which makes it compatible to call operator.
                                                # If careStdErrAsOut is true then output on stderr will not lead to an error, instead it will be appended to stdout.
                                                # If exitCode is not 0 or stderr is not empty then it throws.
                                                # But if ErrorActionPreference is Continue then stderr is appended to output and no error is produced.
                                                # In case an error is throwed then it will first OutProgress the non empty stdout lines.
                                                # Internally the stdout and stderr are stored to variables and not to temporary files to avoid file system IO.
                                                # Important Note: The original Process.Start(ProcessStartInfo) cannot run a ps1 file
                                                #   even if $env:PATHEXT contains the PS1 because it does not precede it with (powershell.exe -File) or (pwsh -File).
                                                #   Our solution will do this by automatically preceed the ps1 file by
                                                #   pwsh -NoLogo -File  or  powershell.exe -NoLogo -File
                                                #   and it surrounds the arguments correctly by double-quotes to support blanks in any argument.
                                                #
                                                # Generally for each call of an executable the commandline is handled by some special rules which are descripted in
                                                # "Parsing C++ command-line arguments" https://docs.microsoft.com/en-us/cpp/cpp/main-function-command-line-args
                                                # As follow:
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
                                                [String] $exec = (Get-Command $cmd).Source;
                                                [Boolean] $isPs = $exec.EndsWith(".ps1");
                                                [String] $traceInfo = "`"$cmd`" $(StringArrayDblQuoteItems $cmdArgs)";
                                                if( $isPs ){
                                                  $cmdArgs = @() + ($cmdArgs | Where-Object { $null -ne $_ } | ForEach-Object {
                                                      $_.Replace("\\","\").Replace("\`"","`""); });
                                                  $traceInfo = "$((ProcessPsExecutable)) -File `"$cmd`" $(StringArrayDblQuoteItems $cmdArgs)";
                                                  $cmdArgs = @( "-NoLogo", "-NonInteractive", "-File", "`"$exec`"" ) + $cmdArgs;
                                                  # Note: maybe for future we require: pwsh -NoProfileLoadTime
                                                  $exec = (Get-Command (ProcessPsExecutable)).Source;
                                                }else{
                                                  $cmdArgs = @() + ($cmdArgs | Where-Object { $null -ne $_ } | ForEach-Object {
                                                    ($_ + $(switch($_.EndsWith("\")){($true){"\"}($false){""}})) });
                                                  $cmdArgs = @() + (StringArrayDblQuoteItems $cmdArgs);
                                                }
                                                if( $traceCmd ){ OutProgress $traceInfo; }
                                                [Int32] $i = 1;
                                                [String] $verboseText = "`"$exec`" " + ($cmdArgs | Where-Object { $null -ne $_ } | ForEach-Object { "Arg[$i]=$_"; $i += 1; } );
                                                OutVerbose "ProcessStart $verboseText";
                                                $prInfo = New-Object System.Diagnostics.ProcessStartInfo;
                                                $prInfo.FileName = $exec;
                                                $prInfo.Arguments = $cmdArgs;
                                                $prInfo.CreateNoWindow = $true;
                                                $prInfo.WindowStyle = "Normal";
                                                $prInfo.UseShellExecute = $false; # UseShellExecute must be false when redirect io
                                                $prInfo.RedirectStandardError = $true;
                                                $prInfo.RedirectStandardOutput = $true;
                                                $prInfo.RedirectStandardInput = $false; # parent and child have same standard-input and no additional pipe created.
                                                # for future use: $prInfo.StandardOutputEncoding = Encoding.UTF8;
                                                # for future use: $prInfo.StandardErrorEncoding  = Encoding.UTF8;
                                                # for future use: $prInfo.StandardInputEncoding  = Encoding.UTF8;
                                                $prInfo.WorkingDirectory = (Get-Location);
                                                $pr = New-Object System.Diagnostics.Process;
                                                $pr.StartInfo = $prInfo;
                                                $pr.EnableRaisingEvents = $false; # default is false; we not need it because we wait for end
                                                # Note: We can not simply call WaitForExit() and after that read stdout and stderr streams because it could hang endless.
                                                # The reason is the called program can produce child processes which can inherit redirect handles which can be still open
                                                # while a subprocess exited and so WaitForExit which does wait for EOFs can block forever.
                                                # See https://stackoverflow.com/questions/26713373/process-waitforexit-doesnt-return-even-though-process-hasexited-is-true
                                                # Uses async read of stdout and stderr to avoid deadlocks.
                                                [System.Text.StringBuilder] $bufStdOut = New-Object System.Text.StringBuilder;
                                                [System.Text.StringBuilder] $bufStdErr = New-Object System.Text.StringBuilder;
                                                $actionReadStdOut = { if( (StringIsFilled $Event.SourceEventArgs.Data) ){ [void]$Event.MessageData.AppendLine($Event.SourceEventArgs.Data); } };
                                                $actionReadStdErr = { if( (StringIsFilled $Event.SourceEventArgs.Data) ){ [void]$Event.MessageData.AppendLine($Event.SourceEventArgs.Data); } };
                                                #[String] $thid = "$([System.Threading.Thread]::CurrentThread.ManagedThreadId)";
                                                [Object] $eventStdOut = Register-ObjectEvent -InputObject $pr -EventName "OutputDataReceived" -Action $actionReadStdOut -MessageData $bufStdOut;
                                                [Object] $eventStdErr = Register-ObjectEvent -InputObject $pr -EventName "ErrorDataReceived"  -Action $actionReadStdErr -MessageData $bufStdErr;
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
                                                if( $ErrorActionPreference -ne "Continue" -and $doThrow ){
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
function ProcessEnvVarSet                     ( [String] $name, [String] $val, [System.EnvironmentVariableTarget] $scope = [System.EnvironmentVariableTarget]::Process, [Boolean] $traceCmd = $true ){
                                                # Scope: MACHINE, USER, PROCESS. Use empty string to delete a value
                                                if( $traceCmd ){ OutProgress "SetEnvironmentVariable scope=$scope $name=`"$val`""; }
                                                [Environment]::SetEnvironmentVariable($name,$val,$scope); }
function ProcessEnvVarPathAdd                 ( [String] $dir = "", [String] $scope = "User" ){ # add dir to path if it not yet contains it
                                                if( $dir -eq "" ){ return; }
                                                $dir = FsEntryMakeTrailingDirSep $dir;
                                                [String[]] $pathUser =  (@()+((ProcessEnvVarGet "PATH" $scope).Split((OsPathSeparator),[System.StringSplitOptions]::RemoveEmptyEntries)) |
                                                  Where-Object{$null -ne $_} | ForEach-Object{ FsEntryMakeTrailingDirSep $_ });
                                                if( (@()+($pathUser | Where-Object{$null -ne $_} | Where-Object{ FsEntryPathIsEqual $_ $dir })).Count -gt 0 ){ return; }
                                                OutProgress "ProcessEnvVarPathAdd-User `"$dir`" ";
                                                $pathUser += $dir;
                                                ProcessEnvVarSet "PATH" ($pathUser -join (OsPathSeparator)) "User" -traceCmd:$false; }
function ProcessEnvVarList                    (){
                                                [Hashtable] $envVarProc = [Hashtable]::new([System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process),[StringComparer]::InvariantCultureIgnoreCase);
                                                [Hashtable] $envVarUser = [Hashtable]::new([System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User   ),[StringComparer]::InvariantCultureIgnoreCase);
                                                [Hashtable] $envVarMach = [Hashtable]::new([System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine),[StringComparer]::InvariantCultureIgnoreCase);
                                                OutInfo "List all environment variables with scopes process, user and machine:";
                                                OutProgress "`"Scope  `",`"$("Name".PadRight(32))`",`"Value`"";
                                                $envVarProc.Keys | Sort-Object | ForEach-Object{ OutProgress "`"PROCESS`",`"$($_.PadRight(32))`",`"$($envVarProc[$_])`""; }
                                                $envVarUser.Keys | Sort-Object | ForEach-Object{ OutProgress "`"USER   `",`"$($_.PadRight(32))`",`"$($envVarUser[$_])`""; }
                                                $envVarMach.Keys | Sort-Object | ForEach-Object{ OutProgress "`"MACHINE`",`"$($_.PadRight(32))`",`"$($envVarMach[$_])`""; } }
function ProcessPathVarStringToUnifiedArray   ( [String] $pathVarString ){
                                                return [String[]] (@()+(StringSplitToArray (OsPathSeparator) $pathVarString $true |
                                                  Where-Object{$null -ne $_} | ForEach-Object{ FsEntryMakeTrailingDirSep $_ })); }
function ProcessRefreshEnvVars                ( [Boolean] $traceCmd = $true ){ # Use this after an installer did change environment variables for example by extending the PATH.
                                                if( $traceCmd ){ OutProgress "ProcessRefreshEnvVars"; }
                                                [Hashtable] $envVarUser = [Hashtable]::new([System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User   ),[StringComparer]::InvariantCultureIgnoreCase);
                                                [Hashtable] $envVarMach = [Hashtable]::new([System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine),[StringComparer]::InvariantCultureIgnoreCase);
                                                [Hashtable] $envVarProc = [Hashtable]::new([System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process),[StringComparer]::InvariantCultureIgnoreCase);
                                                [Hashtable] $envVarNewP = [Hashtable]::new(@{},[StringComparer]::InvariantCultureIgnoreCase);
                                                # On a default Windows 10 the path variable has the name "Path" but on linux and osx it has the name "PATH".
                                                # Note: On Windows ps5/7 does automatically append ".CPL" to PATHEXT env var in process scope.
                                                if( (OsIsWindows) -and -not $envVarMach["PATHEXT"].Contains(".CPL") ){ $envVarMach["PATHEXT"] = "$($envVarMach["PATHEXT"]);.CPL"; }
                                                $envVarMach.Keys | ForEach-Object{ $envVarNewP[$_] = $envVarMach[$_]; }
                                                $envVarUser.Keys | ForEach-Object{ $envVarNewP[$_] = $envVarUser[$_]; }
                                                $envVarNewP["PATH"        ] = $envVarProc["PATH"        ];
                                                $envVarNewP["PSModulePath"] = $envVarProc["PSModulePath"];
                                                # Note: For PATH we do not touch current order of process scope but append new ones.
                                                [String] $sep = OsPathSeparator;
                                                [String[]] $p = ProcessPathVarStringToUnifiedArray $envVarProc["PATH"];
                                                [String[]] $mAndU = ProcessPathVarStringToUnifiedArray ($envVarMach["PATH"] + $sep + $envVarUser["PATH"]);
                                                $mAndU | ForEach-Object{
                                                  if( "" -ne "$_" -and $p -notcontains $_ ){ $p += $_;
                                                    OutProgress "Extended PATH of scope process by: `"$_`"";
                                                    $envVarNewP["PATH"] = $envVarNewP["PATH"] + $(switch("$($envVarNewP["PATH"])".EndsWith($sep)){($true){""}($false){$sep}}) + $_; # append
                                                  }
                                                };
                                                # Note: Powershell preceeds the PSModulePath env var on Windows of process scope with
                                                #   "$HOME\Documents\PowerShell\Modules;C:\Program Files\PowerShell\Modules;c:\program files\powershell\7\Modules;"
                                                #   and so we only check for new parts of user and machine scope and do not touch current order of process scope but append new ones.
                                                [String[]] $p = ProcessPathVarStringToUnifiedArray $envVarProc["PSModulePath"];
                                                [String[]] $mAndU = ProcessPathVarStringToUnifiedArray ($envVarMach["PSModulePath"] + $sep + $envVarUser["PSModulePath"]);
                                                $mAndU | ForEach-Object{
                                                  if( "" -ne "$_" -and $p -notcontains $_ ){ $p += $_;
                                                    OutProgress "Extended PSModulePath of scope process by: `"$_`"";
                                                    $envVarNewP["PSModulePath"] = $envVarNewP["PSModulePath"] + $(switch("$($envVarNewP["PSModulePath"])".EndsWith($sep)){($true){""}($false){$sep}}) + $_; # append
                                                  }
                                                };
                                                $envVarNewP.Keys | ForEach-Object{ [String] $val = $envVarNewP[$_];
                                                  if( $_ -ne "USERNAME" -and # we not set USERNAME because from machine scope we got SYSTEM.
                                                    "$($envVarProc[$_])" -ne "$val" ){
                                                    ProcessEnvVarSet $_ $val -traceCmd:$traceCmd;
                                                  }else{ OutVerbose "ProcessRefreshEnvVars AreEqual $_ $val"; }
                                                } }
function ProcessRemoveAllAlias                ( [String[]] $excludeAliasNames = @(), [Boolean] $doTrace = $false ){
                                                # remove all existing aliases on any levels (local, script, private, and global).
                                                # We recommend to exclude the followings: @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir").
                                                # In powershell v5 (also v7) on windows there are a predefined list of about 180 aliases in each session which cannot be avoided.
                                                # This is very bad because there are also aliases defined as curl->Invoke-WebRequest or wget->Invoke-WebRequest which are incompatible to their known tools.
                                                # On linux there are 108 aliases and fortunately the curl and wget are not part of it.
                                                # 2024-02 update: On windows ps7.4 the curl and wget alias seams to be finally gone!
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
function FsEntryEsc                           ( [String] $fsentry ){ AssertNotEmpty $fsentry "file-system-entry"; # Escaping is not nessessary if a command supports -LiteralPath.
                                                return [String] [Management.Automation.WildcardPattern]::Escape($fsentry); } # Important for chars as [,], etc.
function FsEntryUnifyDirSep                   ( [String] $fsEntry ){ return [String] ($fsEntry -replace "[\\/]",(DirSep)); }
function FsEntryGetAbsolutePath               ( [String] $fsEntry ){ # works without IO, so no check to file system; does not remove a trailing dir-separator. Return empty for empty input.
                                                # Convert dir-separators slashes or backslashes to correct os dependent dir separators.
                                                # Note: We cannot use (Resolve-Path -LiteralPath $fsEntry) because it will throw if path not exists,
                                                # see http://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist
                                                if( $fsEntry -eq "" ){ return [String] ""; }
                                                if( (OsIsWindows) -and $fsEntry.StartsWith("//") ){ $fsEntry = $fsEntry.Replace("/","\"); }
                                                try{ return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
                                                catch [System.Management.Automation.DriveNotFoundException] {
                                                  # Example: DriveNotFoundException: Cannot find drive. A drive with the name 'Z' does not exist.
                                                  try{ return [String] [IO.Path]::GetFullPath($fsEntry);
                                                  }catch{
                                                    # maybe this is not working for psdrives. Solve this if it occurrs.
                                                    throw [Exception] "[IO.Path]::GetFullPath(`"$fsEntry`") failed because $($_.Exception.Message)";
                                                  } } }
function FsEntryGetUncShare                   ( [String] $fsEntry ){ # return "\\host\sharename\" of a given unc path, return empty string if fs entry is not an unc path
                                                try{ [System.Uri] $u = (New-Object System.Uri -ArgumentList $fsEntry);
                                                  if( $u.IsUnc -and $u.Segments.Count -ge 2 -and $u.Segments[0] -eq "/" ){
                                                    return [String] (FsEntryGetAbsolutePath "//$($u.Host)/$(StringRemoveRight $u.Segments[1] '/')/");
                                                  }
                                                }catch{ $error.clear(); } # Example: "Ungültiger URI: Das URI-Format konnte nicht bestimmt werden.", "Ungültiger URI: Der URI ist leer."
                                                return [String] ""; }
function FsEntryMakeValidFileName             ( [String] $str ){
                                                [System.IO.Path]::GetInvalidFileNameChars() |
                                                  ForEach-Object{ $str = $str.Replace($_,"_") };
                                                return [String] $str; }
function FsEntryMakeRelative                  ( [String] $fsEntry, [String] $belowDir, [Boolean] $prefixWithDotDir = $false ){
                                                # Works without IO to file system; if $fsEntry is not equal or below dir then it throws;
                                                # if fs-entry is equal the below-dir then it returns the dot dir "./";
                                                # a trailing dir separator of the fs entry is not changed;
                                                # trailing dir separators for belowDir are not nessessary.
                                                # Example on linux: "Dir1/Dir/" -eq (FsEntryMakeRelative "$HOME/Dir1/Dir/" "$HOME");
                                                # Example on linux: "Dir1/File" -eq (FsEntryMakeRelative "$HOME/Dir1/File" "$HOME");
                                                AssertNotEmpty $belowDir "belowDir";
                                                $belowDir = FsEntryMakeTrailingDirSep $belowDir;
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                if( (FsEntryMakeTrailingDirSep $fsEntry) -eq $belowDir ){ $fsEntry += ".$(DirSep)"; }
                                                Assert ($fsEntry.StartsWith($belowDir,"CurrentCultureIgnoreCase")) "expected `"$fsEntry`" is below `"$belowDir`"";
                                                return [String] ($(switch($prefixWithDotDir){($true){".$(DirSep)"}default{""}})+$fsEntry.Substring($belowDir.Length)); }
function FsEntryHasTrailingDirSep             ( [String] $fsEntry ){ return [Boolean] ($fsEntry.EndsWith("\") -or $fsEntry.EndsWith("/")); }
function FsEntryAssertHasTrailingDirSep       ( [String] $fsEntry ){ if( $fsEntry -eq "" -or (FsEntryHasTrailingDirSep $fsEntry) ){ return; }
                                                OutWarning "Warning: For specifying a dir it expects a trailing dir separator for: `"$fsEntry`". NOTE: In MnCommonPsToolLib V7.x this is only a warning, but in next version this will throw! "; return;
                                                throw [Exception] "For specifying a dir it expects a trailing dir separator for: `"$fsEntry`""; }
function FsEntryRemoveTrailingDirSep          ( [String] $fsEntry ){ [String] $r = $fsEntry;
                                                if( $r -ne "" ){ while( FsEntryHasTrailingDirSep $r ){ $r = $r.Remove($r.Length-1); }
                                                if( $r -eq "" ){ $r = $fsEntry; } } return [String] (FsEntryGetAbsolutePath $r); }
function FsEntryMakeTrailingDirSep            ( [String] $fsEntry ){
                                                [String] $result = $fsEntry;
                                                if( $result -ne "" -and -not (FsEntryHasTrailingDirSep $result) ){ $result += "/"; }
                                                return [String] (FsEntryGetAbsolutePath $result); }
function FsEntryJoinRelativePatterns          ( [String] $rootDir, [String[]] $relativeFsEntriesPatternsSemicolonSeparated ){
                                                # Create an array Example: @( "c:\myroot\bin\", "c:\myroot\obj\", "c:\myroot\*.tmp", ... )
                                                #   from input as @( "bin\;obj\;", ";*.tmp;*.suo", ".\dir\d1?\", ".\dir\file*.txt");
                                                # If an fs entry specifies a dir patterns then it must be specified by a trailing directory delimiter.
                                                [String[]] $a = @(); $relativeFsEntriesPatternsSemicolonSeparated |
                                                  Where-Object{$null -ne $_} |
                                                  ForEach-Object{ $a += (StringSplitToArray ";" $_); };
                                                return [String[]] (@()+($a | ForEach-Object{ FsEntryGetAbsolutePath "$rootDir/$_"; })); }
function FsEntryPathIsEqual                   ( [String] $fs1, [String] $fs2 ){ # compare independent on trailing dir separators. Case sensitivity depends on OS.
                                                $fs1 = FsEntryRemoveTrailingDirSep $fs1;
                                                $fs2 = FsEntryRemoveTrailingDirSep $fs2;
                                                return [Boolean] $(switch((OsIsWindows)){($true){$fs1 -eq $fs2} ($false){$fs1 -ceq $fs2}}); }
function FsEntryGetFileNameWithoutExt         ( [String] $fsEntry ){
                                                return [String] [System.IO.Path]::GetFileNameWithoutExtension((FsEntryRemoveTrailingDirSep $fsEntry)); }
function FsEntryGetFileName                   ( [String] $fsEntry ){
                                                return [String] [System.IO.Path]::GetFileName((FsEntryRemoveTrailingDirSep $fsEntry)); }
function FsEntryGetFileExtension              ( [String] $fsEntry ){
                                                return [String] [System.IO.Path]::GetExtension((FsEntryRemoveTrailingDirSep $fsEntry)); }
function FsEntryGetDrive                      ( [String] $fsEntry ){ # Example: "C:"
                                                return [String] (Split-Path -Qualifier (FsEntryGetAbsolutePath $fsEntry)); }
function FsEntryIsDir                         ( [String] $fsEntry ){ return [Boolean] (Get-Item -Force -LiteralPath $fsEntry).PSIsContainer; } # empty string not allowed
function FsEntryGetParentDir                  ( [String] $fsEntry ){ # Returned path contains trailing backslash; for c:\ or \\mach\share it returns empty string;
                                                return [String] (FsEntryMakeTrailingDirSep (Split-Path -LiteralPath (FsEntryGetAbsolutePath $fsEntry))); }
function FsEntryExists                        ( [String] $fsEntry ){ return [Boolean] (Test-Path -LiteralPath $fsEntry); }
function FsEntryNotExists                     ( [String] $fsEntry ){
                                                return [Boolean] -not (FsEntryExists $fsEntry); }
function FsEntryAssertExists                  ( [String] $fsEntry, [String] $text = "Assertion failed" ){
                                                if( -not (FsEntryExists $fsEntry) ){ throw [Exception] "$text because fs entry not exists: `"$fsEntry`""; } }
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
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                OutProgress "FsFileSetAttributeReadOnly `"$fsEntry`" $val";
                                                Set-ItemProperty (FsEntryEsc $fsEntry) -name IsReadOnly -value $val; }
function FsEntryFindFlatSingleByPattern       ( [String] $fsEntryPattern, [Boolean] $allowNotFound = $false ){
                                                # it throws if file not found or more than one file exists. if allowNotFound is true then if return empty if not found.
                                                [System.IO.FileSystemInfo[]] $r = @()+(Get-ChildItem -Force -ErrorAction SilentlyContinue -Path $fsEntryPattern | Where-Object{$null -ne $_});
                                                if( $r.Count -eq 0 ){ if( $allowNotFound ){ return [String] ""; } throw [Exception] "No file exists: `"$fsEntryPattern`""; }
                                                if( $r.Count -gt 1 ){ throw [Exception] "More than one file exists: `"$fsEntryPattern`""; }
                                                return [String] $r[0].FullName; }
function FsEntryFsInfoFullNameDirWithBackSlash( [System.IO.FileSystemInfo] $fsInfo ){ # TODO later rename this function
                                                return [String] ($fsInfo.FullName+$(switch($fsInfo.PSIsContainer){($true){$(DirSep)}default{""}})); }
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
function FsEntryDelete                        ( [String] $fsEntry ){ # depends strongly on trailing dir separator
                                                if( (FsEntryHasTrailingDirSep $fsEntry) ){ DirDelete $fsEntry; }else{ FileDelete $fsEntry; } }
function FsEntryDeleteToRecycleBin            ( [String] $fsEntry ){
                                                Add-Type -AssemblyName Microsoft.VisualBasic;
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                OutProgress "FsEntryDeleteToRecycleBin `"$fsEntry`"";
                                                FsEntryAssertExists $fsEntry "Not exists: `"$fsEntry`"";
                                                if( FsEntryIsDir $fsEntry ){ [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($fsEntry,"OnlyErrorDialogs","SendToRecycleBin");
                                                }else{                       [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($fsEntry,"OnlyErrorDialogs","SendToRecycleBin"); } }
function FsEntryRename                        ( [String] $fsEntryFrom, [String] $fsEntryTo ){
                                                # for files or dirs, relative or absolute, origin must exists, directory parts must be identic.
                                                $fsEntryFrom = FsEntryGetAbsolutePath $fsEntryFrom;
                                                $fsEntryTo   = FsEntryGetAbsolutePath $fsEntryTo;
                                                OutProgress "FsEntryRename `"$fsEntryFrom`" `"$fsEntryTo`"";
                                                FsEntryAssertExists $fsEntryFrom; FsEntryAssertNotExists $fsEntryTo;
                                                [String] $fs1 = FsEntryRemoveTrailingDirSep $fsEntryFrom;
                                                [String] $fs2 = FsEntryRemoveTrailingDirSep $fsEntryTo;
                                                Rename-Item -Path $fs1 -newName $fs2 -force; }
function FsEntryCreateSymLink                 ( [String] $newSymLink, [String] $fsEntryOrigin ){
                                                # (junctions (=~symlinksToDirs) do not) (https://superuser.com/questions/104845/permission-to-make-symbolic-links-in-windows-7/105381).
                                                New-Item -ItemType SymbolicLink -Name (FsEntryEsc $newSymLink) -Value (FsEntryEsc $fsEntryOrigin); }
function FsEntryCreateHardLink                ( [String] $newHardLink, [String] $fsEntryOrigin ){
                                                # for files or dirs, origin must exists, it requires elevated rights.
                                                New-Item -ItemType HardLink -Name (FsEntryEsc $newHardLink) -Value (FsEntryEsc $fsEntryOrigin); }
function FsEntryCreateDirSymLink              ( [String] $symLinkDir, [String] $symLinkOriginDir ){
                                                # Create symlinks to dirs. On windows creates junctions which are symlinks to dirs with some slightly other behaviour around privileges and local/remote usage.
                                                FsEntryAssertHasTrailingDirSep $symLinkDir;
                                                FsEntryAssertHasTrailingDirSep $symLinkOriginDir;
                                                if( -not (DirExists $symLinkOriginDir) ){
                                                  throw [Exception] "Cannot create dir sym link because original directory not exists: `"$symLinkOriginDir`""; }
                                                FsEntryAssertNotExists $symLinkDir "Cannot create dir sym link";
                                                [String] $cd = Get-Location;
                                                Set-Location (FsEntryGetParentDir $symLinkDir);
                                                [String] $symLinkName = FsEntryGetFileName $symLinkDir;
                                                if( (OsIsWindows) ){ & "cmd.exe" "/c" ('mklink /J "'+$symLinkName+'" "'+$symLinkOriginDir+'"'); AssertRcIsOk; }
                                                else{ & "ln" "--symbolic" $symLinkOriginDir $symLinkName; AssertRcIsOk; }
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
                                                $targetDir = FsEntryGetAbsolutePath $targetDir;
                                                OutProgress "FsEntryMoveByPatternToDir `"$fsEntryPattern`" to `"$targetDir`""; DirAssertExists $targetDir;
                                                FsEntryListAsStringArray $fsEntryPattern $false |
                                                  Where-Object{$null -ne $_} | Sort-Object |
                                                  ForEach-Object{
                                                    if( $showProgress ){ OutProgress "Source: $_"; };
                                                    Move-Item -Force -Path $_ -Destination (FsEntryEsc $targetDir);
                                                  }; }
function FsEntryCopyByPatternByOverwrite      ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $continueOnErr = $false ){
                                                $targetDir = FsEntryGetAbsolutePath $targetDir;
                                                OutProgress "FsEntryCopyByPatternByOverwrite `"$fsEntryPattern`" to `"$targetDir`" continueOnErr=$continueOnErr";
                                                FsEntryAssertHasTrailingDirSep $targetDir;
                                                DirCreate $targetDir;
                                                Copy-Item -ErrorAction SilentlyContinue -Recurse -Force -Path $fsEntryPattern -Destination (FsEntryEsc $targetDir);
                                                if( -not $? ){
                                                  [String] $trace = "CopyFiles `"$fsEntryPattern`" to `"$targetDir`" failed.";
                                                  if( -not $continueOnErr ){ throw [Exception] "$trace"; } else{ OutWarning "Warning: $trace, will continue."; } } }
function FsEntryFindNotExistingVersionedName  ( [String] $fsEntry, [String] $ext = ".bck", [Int32] $maxNr = 9999 ){ # Example return: "C:\Dir\MyName.001.bck"
                                                $fsEntry = FsEntryRemoveTrailingDirSep $fsEntry;
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
                                                $targetDir = FsEntryGetAbsolutePath $targetDir;
                                                OutProgress "FsEntryAclRuleWrite $modeSetAddOrDel `"$fsEntry`" `"$(PrivFsRuleAsString $rule)`"";
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry;
                                                if    ( $modeSetAddOrDel -eq "Set" ){ $acl.SetAccessRule($rule); }
                                                elseif( $modeSetAddOrDel -eq "Add" ){ $acl.AddAccessRule($rule); }
                                                elseif( $modeSetAddOrDel -eq "Del" ){ $acl.RemoveAccessRule($rule); }
                                                else{ throw [Exception] "For modeSetAddOrDel expected 'Set', 'Add' or 'Del' but got `"$modeSetAddOrDel`""; }
                                                Set-Acl -Path (FsEntryEsc $fsEntry) -AclObject $acl; # Set-Acl does set or add
                                                if( $recursive -and (FsEntryIsDir $fsEntry) ){
                                                  FsEntryListAsStringArray "$fsEntry/*" $false | Where-Object{$null -ne $_} |
                                                    ForEach-Object{ FsEntryAclRuleWrite $modeSetAddOrDel $_ $rule $true };
                                                } }
function FsEntryTrySetOwner                   ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){
                                                # usually account is (PrivGetGroupAdministrators); if the entry itself cannot be set then it tries to set on its parent the fullcontrol for admins.
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                ProcessRestartInElevatedAdminMode;
                                                PrivEnableTokenPrivilege SeTakeOwnershipPrivilege;
                                                PrivEnableTokenPrivilege SeRestorePrivilege;
                                                PrivEnableTokenPrivilege SeBackupPrivilege;
                                                [System.Security.AccessControl.FileSystemSecurity] $acl = FsEntryAclGet $fsEntry;
                                                try{
                                                  [System.IO.FileSystemInfo] $fs = Get-Item -Force -LiteralPath $fsEntry;
                                                  if( $acl.Owner -ne $account ){
                                                    OutProgress "FsEntryTrySetOwner `"$fsEntry`" `"$($account.ToString())`" recursive=$recursive ";
                                                    if( $fs.PSIsContainer ){
                                                      try{
                                                        $fs.SetAccessControl((PrivDirSecurityCreateOwner $account));
                                                      }catch{
                                                        OutProgress "taking ownership of dir `"$($fs.FullName)`" failed so setting fullControl for administrators of its parent `"$($fs.Parent.FullName)`"";
                                                        $fs.Parent.SetAccessControl((PrivDirSecurityCreateFullControl (PrivGetGroupAdministrators)));
                                                        $fs.SetAccessControl((PrivDirSecurityCreateOwner $account));
                                                      }
                                                    }else{ # is a file
                                                      try{
                                                        $fs.SetAccessControl((PrivFileSecurityCreateOwner $account));
                                                      }catch{
                                                        OutProgress "taking ownership of file `"$($fs.FullName)`" failed so setting fullControl for administrators of its dir `"$($fs.Directory.FullName)`"";
                                                        $fs.Directory.SetAccessControl((PrivDirSecurityCreateFullControl (PrivGetGroupAdministrators)));
                                                        $fs.SetAccessControl((PrivFileSecurityCreateOwner $account));
                                                      }
                                                    } }
                                                  if( $recursive -and $fs.PSIsContainer ){
                                                    FsEntryListAsStringArray "$fs/*" $false | Where-Object{$null -ne $_} |
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
                                                    FsEntryListAsStringArray "$fsEntry/*" $false | Where-Object{$null -ne $_} |
                                                      ForEach-Object{ FsEntryTrySetOwnerAndAclsIfNotSet $_ $account $true };
                                                  }
                                                }catch{
                                                  OutWarning "Warning: FsEntryTrySetOwnerAndAclsIfNotSet `"$fsEntry`" $account $recursive : Failed because $($_.Exception.Message)";
                                                } }
function FsEntryTryForceRenaming              ( [String] $fsEntry, [String] $extension ){
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                if( (FsEntryExists $fsEntry) ){
                                                  ProcessRestartInElevatedAdminMode; # because rename os files and change acls
                                                  [String] $newFileName = (FsEntryFindNotExistingVersionedName $fsEntry $extension);
                                                  try{
                                                    FsEntryRename $fsEntry $newFileName;
                                                  }catch{
                                                    # exc: System.UnauthorizedAccessException: Der Zugriff auf den Pfad wurde verweigert. bei System.IO.__Error.WinIOError(Int32 errorCode, String maybeFullPath) bei System.IO.FileInfo.MoveTo(String destFileName)
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
                                                $fsEntry = FsEntryGetAbsolutePath $fsEntry;
                                                OutProgress "FsEntrySetTs `"$fsEntry`" recursive=$recursive ts=$(DateTimeAsStringIso $ts)";
                                                FsEntryAssertExists $fsEntry; [Boolean] $inclDirs = $true;
                                                if( -not (FsEntryIsDir $fsEntry) ){ $recursive = $false; $inclDirs = $false; }
                                                FsEntryListAsFileSystemInfo $fsEntry $recursive $true $true $true | Where-Object{$null -ne $_} | ForEach-Object{
                                                  [String] $f = $(FsEntryFsInfoFullNameDirWithBackSlash $_);
                                                  OutProgress "Set $(DateTimeAsStringIso $ts) of $(DateTimeAsStringIso $_.LastWriteTime) $f";
                                                  try{ $_.LastWriteTime = $ts; $_.CreationTime = $ts; $_.LastAccessTime = $ts;
                                                  }catch{
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
                                                  [String] $e = FsEntryGetAbsolutePath "$p/$searchFsEntryName";
                                                  if( FsEntryExists $e ){ return [String] $e; }
                                                  $d = $p;
                                                } return [String] ""; # not found
                                                }
function FsEntryGetSize                       ( [String] $fsEntry ){ # Must exists, works recursive.
                                                if( FsEntryNotExists $fsEntry ){ throw [Exception] "File system entry not exists: `"$fsEntry`""; }
                                                [Microsoft.PowerShell.Commands.GenericMeasureInfo] $size = Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse -LiteralPath $fsEntry |
                                                  Where-Object{$null -ne $_} | Measure-Object -Property length -sum;
                                                if( $null -eq $size ){ return [Int64] 0; }
                                                return [Int64] $size.sum; }
function DriveFreeSpace                       ( [String] $drive ){
                                                FsEntryAssertHasTrailingDirSep $drive;
                                                return [Int64] (Get-PSDrive $drive | Select-Object -ExpandProperty Free); }
function DirSep                               (){ return [Char] [IO.Path]::DirectorySeparatorChar; }
function DirExists                            ( [String] $dir ){
                                                FsEntryAssertHasTrailingDirSep $dir;
                                                try{ return [Boolean] (Test-Path -PathType Container -LiteralPath $dir); }catch{ throw [Exception] "$(ScriptGetCurrentFunc)($dir) failed because $($_.Exception.Message)"; } }
function DirNotExists                         ( [String] $dir ){ FsEntryAssertHasTrailingDirSep $dir; return [Boolean] -not (DirExists $dir); }
function DirAssertExists                      ( [String] $dir, [String] $text = "Assertion" ){
                                                FsEntryAssertHasTrailingDirSep $dir;
                                                if( -not (DirExists $dir) ){ throw [Exception] "$text failed because dir not exists: `"$dir`"."; } }
function DirCreate                            ( [String] $dir ){ # create dir if it not yet exists; we do not call OutProgress because is not an important change.
                                                FsEntryAssertHasTrailingDirSep $dir;
                                                New-Item -type directory -Force (FsEntryEsc $dir) | Out-Null; }
function DirCreateTemp                        ( [String] $prefix = "" ){ while($true){
                                                [String] $d = FsEntryMakeTrailingDirSep "$([System.IO.Path]::GetTempPath())/$prefix.$(StringLeft ([System.IO.Path]::GetRandomFileName().Replace('.','')) 6)"; # 6 alphachars has 2G possibilities
                                                if( FsEntryNotExists $d ){ DirCreate $d; return [String] $d; } } }
function DirDelete                            ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                # Remove dir recursively if it exists, be careful when using this.
                                                $dir = FsEntryGetAbsolutePath $dir;
                                                FsEntryAssertHasTrailingDirSep $dir;
                                                if( (DirExists $dir) ){
                                                  try{ OutProgress "DirDelete$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) `"$dir`"";
                                                    Remove-Item -Force:$ignoreReadonly -Recurse -LiteralPath $dir;
                                                  }catch{ # Example: Für das Ausführen des Vorgangs sind keine ausreichenden Berechtigungen vorhanden.
                                                    throw [Exception] "$(ScriptGetCurrentFunc)$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}})(`"$dir`") failed because $($_.Exception.Message) (maybe locked or readonly files exists)"; } } }
function DirDeleteContent                     ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                # remove dir content if it exists, be careful when using this.
                                                $dir = FsEntryGetAbsolutePath $dir;
                                                FsEntryAssertHasTrailingDirSep $dir;
                                                if( (DirExists $dir) -and (@()+(Get-ChildItem -Force -Directory -LiteralPath $dir)).Count -gt 0 ){
                                                  try{ OutProgress "DirDeleteContent$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) `"$dir`"";
                                                    Remove-Item -Force:$ignoreReadonly -Recurse "$(FsEntryEsc $dir)/*";
                                                  }catch{ # exc: Für das Ausführen des Vorgangs sind keine ausreichenden Berechtigungen vorhanden.
                                                    throw [Exception] "$(ScriptGetCurrentFunc)$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}})(`"$dir`") failed because $($_.Exception.Message) (maybe locked or readonly files exists)"; } } }
function DirDeleteIfIsEmpty                   ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                FsEntryAssertHasTrailingDirSep $dir;
                                                if( (DirExists $dir) -and (@()+(Get-ChildItem -Force -LiteralPath $dir)).Count -eq 0 ){ DirDelete $dir; } }
function DirCopyToParentDirByAddAndOverwrite  ( [String] $srcDir, [String] $tarParentDir ){
                                                FsEntryAssertHasTrailingDirSep $srcDir;
                                                FsEntryAssertHasTrailingDirSep $tarParentDir;
                                                $srcDir       = FsEntryGetAbsolutePath $srcDir;
                                                $tarParentDir = FsEntryGetAbsolutePath $tarParentDir;
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
                                                if( (FsEntryHasTrailingDirSep $file) ){ throw [Exception] "File has not allowed trailing dir sep: `"$file`"."; }; if( (FileNotExists $file) ){ throw [Exception] "File not exists: `"$file`"."; } }
function FileExistsAndIsNewer                 ( [String] $ftar, [String] $fsrc ){
                                                FileAssertExists $fsrc; return [Boolean] ((FileExists $ftar) -and ((FsEntryGetLastModified $ftar) -ge (FsEntryGetLastModified $fsrc))); }
function FileNotExistsOrIsOlder               ( [String] $ftar, [String] $fsrc ){
                                                return [Boolean] -not (FileExistsAndIsNewer $ftar $fsrc); }
function FileReadContentAsString              ( [String] $file, [String] $encodingIfNoBom = "Default" ){
                                                # Encoding Default is ANSI on windows and UTF8 on other platforms.
                                                return [String] (FileReadContentAsLines $file $encodingIfNoBom | Out-String -Width ([Int32]::MaxValue)); }
function FileReadContentAsLines               ( [String] $file, [String] $encodingIfNoBom = "Default" ){
                                                # Encoding Default is ANSI on windows and UTF8 on other platforms.
                                                OutVerbose "FileRead $file";
                                                return [String[]] (@()+(Get-Content -Encoding $encodingIfNoBom -LiteralPath $file)); }
function FileReadJsonAsObject                 ( [String] $jsonFile ){
                                                try{ Get-Content -Raw -Path $jsonFile | ConvertFrom-Json; }catch{ throw [Exception] "FileReadJsonAsObject(`"$jsonFile`") failed because $($_.Exception.Message)"; } }
function FileWriteFromString                  ( [String] $file, [String] $content, [Boolean] $overwrite = $true, [String] $encoding = "UTF8BOM" ){
                                                # Will create path of file. overwrite does ignore readonly attribute.
                                                $file = FsEntryGetAbsolutePath $file;
                                                OutProgress "WriteFile $file"; FsEntryCreateParentDir $file;
                                                if( (ProcessIsLesserEqualPs5) -and $encoding -eq "UTF8BOM" ){ $encoding = "UTF8"; }
                                                Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -Inputobject $content -LiteralPath $file; }
                                                # alternative: Set-Content -Encoding $encoding -Path (FsEntryEsc $file) -Value $content; but this would lock file,
                                                # more see http://stackoverflow.com/questions/10655788/powershell-set-content-and-out-file-what-is-the-difference
function FileWriteFromLines                   ( [String] $file, [String[]] $lines, [Boolean] $overwrite = $false, [String] $encoding = "UTF8BOM" ){
                                                $file = FsEntryGetAbsolutePath $file;
                                                OutProgress "WriteFile $file";
                                                if( (ProcessIsLesserEqualPs5) -and $encoding -eq "UTF8BOM" ){ $encoding = "UTF8"; }
                                                FsEntryCreateParentDir $file;
                                                $lines | Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -LiteralPath $file; }
function FileCreateEmpty                      ( [String] $file, [Boolean] $overwrite = $false, [Boolean] $quiet = $false, [String] $encoding = "UTF8BOM" ){
                                                $file = FsEntryGetAbsolutePath $file;
                                                if( (ProcessIsLesserEqualPs5) -and $encoding -eq "UTF8BOM" ){ $encoding = "UTF8"; }
                                                if( -not $quiet -and $overwrite ){ OutProgress "FileCreateEmpty-ByOverwrite $file"; }
                                                FsEntryCreateParentDir $file;
                                                Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -LiteralPath $file; }
function FileAppendLineWithTs                 ( [String] $file, [String] $line ){ FileAppendLine $file $line $true; }
function FileAppendLine                       ( [String] $file, [String] $line, [Boolean] $tsPrefix = $false, [String] $encoding = "UTF8BOM" ){
                                                if( (ProcessIsLesserEqualPs5) -and $encoding -eq "UTF8BOM" ){ $encoding = "UTF8"; }
                                                FsEntryCreateParentDir $file;
                                                Out-File -Encoding $encoding -Append -LiteralPath $file -InputObject ($(switch($tsPrefix){($true){"$(DateTimeNowAsStringIso) "}default{""}})+$line); }
function FileAppendLines                      ( [String] $file, [String[]] $lines, [String] $encoding = "UTF8BOM" ){
                                                if( (ProcessIsLesserEqualPs5) -and $encoding -eq "UTF8BOM" ){ $encoding = "UTF8"; }
                                                FsEntryCreateParentDir $file;
                                                $lines | Out-File -Encoding $encoding -Append -LiteralPath $file; }
function FileGetTempFile                      (){ return [String] [System.IO.Path]::GetTempFileName(); } # Example on linux: "/tmp/tmpFN3Gnz.tmp"; on windows: C:\Windows\Temp\tmpE3B6.tmp
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
                                                else                                                                                                { return [String] "Default"          ; } } # codepage on windows 1252=ANSI and otherwise UTF8.
function FileTouch                            ( [String] $file ){
                                                $file = FsEntryGetAbsolutePath $file;
                                                OutProgress "Touch: `"$file`"";
                                                if( FileExists $file ){ (Get-Item -Force -LiteralPath $file).LastWriteTime = (Get-Date); }
                                                else{ FileCreateEmpty $file $false $false "ASCII"; } }
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
                                                if( $fi1.Length -ne $fi2.Length ){ return [Boolean] $false; }
                                                # Alternative: use: sha256sum file1 file2;
                                                if( $true ){ # Much more performant (20 sec for 5 GB file).
                                                  if( (OsIsWindows) ){ & "fc.exe" "/b" ($fi1.FullName) ($fi2.FullName) > $null; }
                                                  else{                & "cmp" "-s"    ($fi1.FullName) ($fi2.FullName) | Out-Null; }
                                                  [Boolean] $result = $?;
                                                  ScriptResetRc;
                                                  return [Boolean] $result;
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
                                                $file = FsEntryGetAbsolutePath $file;
                                                if( (FileExists $file) ){ OutProgress "FileDelete$(switch($ignoreReadonly){($true){''}default{'CareReadonly'}}) `"$file`""; }
                                                [Int32] $nrOfTries = 0; while($true){ $nrOfTries++;
                                                  try{
                                                    Remove-Item -Force:$ignoreReadonly -LiteralPath $file;
                                                    return;
                                                  }catch [System.Management.Automation.ItemNotFoundException] { # Example: ItemNotFoundException: Cannot find path '$HOME/myfile.lnk' because it does not exist.
                                                    return; #
                                                  }catch [System.UnauthorizedAccessException] { # Example: Access to the path '$HOME/Desktop/desktop.ini' is denied.
                                                    if( -not $ignoreAccessDenied ){ throw; }
                                                    OutWarning "Warning: Ignoring UnauthorizedAccessException for Remove-Item -Force:$ignoreReadonly -LiteralPath `"$file`""; return;
                                                  }catch{ # exc: IOException: The process cannot access the file '$HOME\myprog.lnk' because it is being used by another process.
                                                    [Boolean] $isUsedByAnotherProc = $_.Exception -is [System.IO.IOException] -and $_.Exception.Message.Contains("The process cannot access the file ") -and $_.Exception.Message.Contains(" because it is being used by another process.");
                                                    if( -not $isUsedByAnotherProc ){ throw; }
                                                    if( $nrOfTries -ge 5 ){ throw; }
                                                    Start-Sleep -Milliseconds $(switch($nrOfTries){1{50}2{100}3{200}4{400}default{800}}); } } }
function FileCopy                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){
                                                $srcFile = FsEntryGetAbsolutePath $srcFile;
                                                $tarFile = FsEntryGetAbsolutePath $tarFile;
                                                OutProgress "FileCopy(Overwrite=$overwrite) `"$srcFile`" to `"$tarFile`" $(switch($(FileExists $(FsEntryEsc $tarFile))){($true){'(Target exists)'}default{''}})";
                                                FsEntryCreateParentDir $tarFile;
                                                Copy-Item -Force:$overwrite (FsEntryEsc $srcFile) (FsEntryEsc $tarFile); }
function FileMove                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){
                                                $srcFile = FsEntryGetAbsolutePath $srcFile;
                                                $tarFile = FsEntryGetAbsolutePath $tarFile;
                                                OutProgress "FileMove(Overwrite=$overwrite) `"$srcFile`" to `"$tarFile`"$(switch($(FileExists $(FsEntryEsc $tarFile))){($true){'(Target exists)'}default{''}})";
                                                FsEntryCreateParentDir $tarFile;
                                                Move-Item -Force:$overwrite -LiteralPath $srcFile -Destination $tarFile; }
function FileGetHexStringOfHash128BitsMd5     ( [String] $srcFile ){ [String] $md = "MD5"; return [String] (get-filehash -Algorithm $md $srcFile).Hash; } # 2008: is broken. Because PSScriptAnalyzer.PSAvoidUsingBrokenHashAlgorithms we put name into a variable.
function FileGetHexStringOfHash256BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA256" $srcFile).Hash; } # 2017-11 ps standard is SHA256, available are: SHA1;SHA256;SHA384;SHA512;MACTripleDES;MD5;RIPEMD160
function FileGetHexStringOfHash512BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA512" $srcFile).Hash; } # 2017-12: this is our standard for ps
function FileUpdateItsHashSha2FileIfNessessary( [String] $srcFile ){
                                                $srcFile = FsEntryGetAbsolutePath $srcFile;
                                                [String] $hashTarFile = "$srcFile.sha2";
                                                [String] $hashSrc = FileGetHexStringOfHash512BitsSha2 $srcFile;
                                                [String] $hashTar = $(switch((FileNotExists $hashTarFile) -or (FileGetSize $hashTarFile) -gt 8200){
                                                  ($true){""}
                                                  default{(FileReadContentAsString $hashTarFile "Default").TrimEnd()}
                                                });
                                                if( $hashSrc -eq $hashTar ){
                                                  OutProgress "File is up to date, nothing done with `"$hashTarFile`".";
                                                }else{
                                                  Out-File -Encoding "UTF8" -LiteralPath $hashTarFile -Inputobject $hashSrc;
                                                  OutProgress "Created `"$hashTarFile`".";
                                                } }
function PsDriveListAll                       (){
                                                OutVerbose "List PsDrives";
                                                return [Object[]] (@()+(Get-PSDrive -PSProvider FileSystem |
                                                  Where-Object{$null -ne $_} |
                                                  Select-Object Name,@{Name="ShareName";Expression={$_.DisplayRoot+""}},Description,CurrentLocation,Free,Used |
                                                  Sort-Object Name)); }
                                                # Not used: Root, Provider. PSDrive: Note are only for current session, even if persist.
function PsDriveCreate                        ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null ){
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
                                                $mountPoint = FsEntryGetAbsolutePath $mountPoint;
                                                MountPointRemove $drive $mountPoint;
                                                [String] $us = CredentialGetUsername $cred $true;
                                                OutProgress "PsDriveCreate drive=$drive mountPoint=$mountPoint username=$us";
                                                try{
                                                  New-PSDrive -Name $drive.Replace(":","") -Root $mountPoint -PSProvider "FileSystem" -Scope Global -Persist -Description "$mountPoint($drive)" -Credential $cred | Out-Null;
                                                }catch{
                                                  # exc: System.ComponentModel.Win32Exception (0x80004005): Der lokale Gerätename wird bereits verwendet
                                                  # exc: System.Exception: Mehrfache Verbindungen zu einem Server oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig.
                                                  #      Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut
                                                  # exc: System.Exception: New-PSDrive(Z,\\mycomp\Transfer,) failed because Das angegebene Netzwerkkennwort ist falsch
                                                  throw [Exception] "New-PSDrive($drive,$mountPoint,$us) failed because $($_.Exception.Message)";
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
                                                return [String] (ConvertFrom-SecureString $code); } # Example return: "ea32f9d30de3d3dc7fcd86a6a8f587ed9"
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
                                                $secureCredentialFile = FsEntryGetAbsolutePath $secureCredentialFile;
                                                OutProgress "CredentialRemoveFile `"$secureCredentialFile`"";
                                                FileDelete $secureCredentialFile; }
function CredentialReadFromFile               ( [String] $secureCredentialFile ){
                                                [String[]] $s = (@()+(StringSplitIntoLines (FileReadContentAsString $secureCredentialFile "Default")));
                                                try{ [String] $us = $s[0]; [System.Security.SecureString] $pwSecure = CredentialGetSecureStrFromHexString $s[1];
                                                  # alternative: New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content -Encoding "Default" -LiteralPath $secureCredentialFile | ConvertTo-SecureString)
                                                  return [System.Management.Automation.PSCredential] (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure));
                                                }catch{ throw [Exception] "Credential file `"$secureCredentialFile`" has not expected format for decoding credentials, maybe you changed password of current user or current machine id, in that case you may remove it and retry"; } }
function CredentialCreate                     ( [String] $username = "", [String] $password = "", [String] $accessShortDescription = "" ){
                                                [String] $us = $username;
                                                [String] $descr = switch($accessShortDescription -eq ""){($true){""}default{(" for $accessShortDescription")}};
                                                while( $us -eq "" ){ $us = StdInReadLine "Enter username$($descr): "; }
                                                if( $username -eq "" ){ $descr = ""; } # display descr only once
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
function NetPingHostIsConnectable             ( [String] $hostName, [Boolean] $doRetryWithFlushDns = $false ){
                                                if( (Test-Connection -ComputerName $hostName -BufferSize 16 -Count 1 -ErrorAction SilentlyContinue -quiet) ){ return [Boolean] $true; } # later in ps V6 use -TimeoutSeconds 3 default is 5 sec
                                                if( -not $doRetryWithFlushDns ){ return [Boolean] $false; }
                                                OutVerbose "Host $hostName not reachable, so flush dns, nslookup and retry";
                                                if( OsIsWindows ){ & "ipconfig.exe" "/flushdns"  | Out-Null; AssertRcIsOk; }
                                                else{              & "resolvectl" "flush-caches" | Out-Null; AssertRcIsOk; }
                                                try{ [System.Net.Dns]::GetHostByName($hostName); }catch{ OutVerbose "Ignoring GetHostByName($hostName) failed because $($_.Exception.Message)"; }
                                                # nslookup $hostName -ErrorAction SilentlyContinue | out-null;
                                                return [Boolean] (Test-Connection -ComputerName $hostName -BufferSize 16 -Count 1 -ErrorAction SilentlyContinue -quiet); }
# Type: ServerCertificateValidationCallback
Add-Type -TypeDefinition "using System;using System.Net;using System.Net.Security;using System.Security.Cryptography.X509Certificates; public class ServerCertificateValidationCallback { public static void Ignore() { ServicePointManager.ServerCertificateValidationCallback += delegate( Object obj, X509Certificate certificate, X509Chain chain, SslPolicyErrors errors ){ return true; }; } } ";
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
                                                # Maybe later: OAuth. Example: https://docs.github.com/en/free-pro-team@latest/rest/overview/other-authentication-methods
                                                # Alternative on PS5 and PS7: Invoke-RestMethod -Uri "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/main/MnCommonPsToolLib/MnCommonPsToolLib.psm1" -OutFile "$env:TEMP/tmp/p.tmp";
                                                $tarFile = FsEntryGetAbsolutePath $tarFile;
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
                                                  [Boolean] $useWebclient = $false; # we currently use Invoke-WebRequest because its more comfortable than WebClient.DownloadFile
                                                  if( $useWebclient ){
                                                    OutVerbose "WebClient.DownloadFile(url=$url,us=$us,tar=`"$tarFile`")";
                                                    $webclient = new-object System.Net.WebClient;
                                                    # Defaults: AllowAutoRedirect is true.
                                                    $webclient.Headers.Add("User-Agent",$userAgent);
                                                    # For future use: $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded");
                                                    # not relevant because getting byte array: $webclient.Encoding = "Default" or "UTF8";
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
                                                      OutVerbose "Invoke-WebRequest -Uri `"$url`" -OutFile `"$tarFile`" -MaximumRedirection 2 -TimeoutSec 70 -UserAgent `"$userAgent`"; ";
                                                      Invoke-WebRequest -Uri $url -OutFile $tarFile -MaximumRedirection 2 -TimeoutSec 70 -UserAgent $userAgent;
                                                    }
                                                  }
                                                  [String] $stateMsg = "  Ok, downloaded $(FileGetSize $tarFile) bytes.";
                                                  OutProgress $stateMsg;
                                                }catch{
                                                  # exc: The request was aborted: Could not create SSL/TLS secure channel.
                                                  # exc: Ausnahme beim Aufrufen von "DownloadFile" mit 2 Argument(en):  "The server committed a protocol violation. Section=ResponseStatusLine"
                                                  # exc: System.Net.WebException: Der Remoteserver hat einen Fehler zurückgegeben: (404) Nicht gefunden.
                                                  # for future use: $fileNotExists = $_.Exception -is [System.Net.WebException] -and (([System.Net.WebException]($_.Exception)).Response.StatusCode.value__) -eq 404;
                                                  [String] $msg = $_.Exception.Message;
                                                  if( $msg.Contains("Section=ResponseStatusLine") ){ $msg = "Server returned not a valid HTTP response. "+$msg; }
                                                  $msg = "  NetDownloadFile(url=$url ,us=$us,tar=$tarFile) failed because $msg";
                                                  if( -not $errorAsWarning ){ throw [ExcMsg] $msg; } OutWarning "Warning: $msg";
                                                } }
function NetDownloadFileByCurl                ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false,
                                                [Boolean] $onlyIfNewer = $false, [Boolean] $errorAsWarning = $false ){
                                                # Download a single file by overwrite it (as NetDownloadFile).
                                                # It requires and uses curl executable in path and it ignores any curl alias as you would find it in PS5 because this would references not a curl program.
                                                # Redirections are followed, timestamps are also fetched, logging info is stored in a global logfile,
                                                # for user agent info a mozilla firefox is set,
                                                # if file curl-ca-bundle.crt exists next to curl executable then this is taken.
                                                # Supported protocols: DICT, FILE, FTP, FTPS, Gopher, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS,
                                                #                      POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMB, SMTP, SMTPS, Telnet and TFTP.
                                                # Supported features:  SSL certificates, HTTP POST, HTTP PUT, FTP uploading, HTTP form based upload,
                                                #                      proxies, HTTP/2, cookies, user+password authentication (Basic, Plain, Digest,
                                                #                      CRAM-MD5, NTLM, Negotiate and Kerberos), file transfer resume, proxy tunneling and more.
                                                # Example: curl --show-error --output $tarFile --silent --create-dirs --connect-timeout 70 --retry 2 --retry-delay 5 --remote-time --stderr - --user "$($us):$pw" $url;
                                                $tarFile = FsEntryGetAbsolutePath $tarFile;
                                                AssertNotEmpty $url "NetDownloadFileByCurl.url";
                                                if( $us -ne "" ){ AssertNotEmpty $pw "password for username=$us"; }
                                                [String[]] $opt = @( # see https://curl.haxx.se/docs/manpage.html
                                                   "--show-error"                            # Show error. With -s, make curl show errors when they occur
                                                  ,"--fail"                                  # if http response code is 4xx or 5xx then fail, but 3XX (redirects) are ok.
                                                  ,"--output", $tarFile                      # Write to FILE instead of stdout
                                                  ,"--silent"                                # Silent mode (don't output anything), no progress meter
                                                  ,"--create-dirs"                           # create the necessary local directory hierarchy as needed of --output file
                                                  ,"--connect-timeout", "70"                 # in sec
                                                  ,"--retry","2"                             # Retry request NUM times if transient problems occur
                                                  ,"--retry-delay","5"                       # Wait SECONDS between retries
                                                  ,"--tlsv1.2"                               # Use TLSv1.2 (SSL)
                                                  ,"--remote-time"                           # Set the remote file's time on the local output
                                                  ,"--location"                              # Follow redirects (H)
                                                  ,"--max-redirs","50"                       # Maximum number of redirects allowed, default is 50, 0 means error on redir (H)
                                                  ,"--stderr","-"                            # Where to redirect stderr (use "-" for stdout)
                                                  # ,"--limit-rate","$limitRateBytesPerSec"  #
                                                  # ,"--progress-bar"                        # Display transfer progress as a progress bar
                                                  # ,"--remote-name"                         # Write output to a file named as the remote file example: "http://a.be/c.ext"
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
                                                  ,"--user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0"  # Send User-Agent STRING to server (H), we take latest ESR
                                                );
                                                if( $us -ne "" ){ $opt += @( "--user", "$($us):$pw" ); }
                                                if( $ignoreSslCheck ){ $opt += "--insecure"; }
                                                if( $onlyIfNewer -and (FileExists $tarFile) ){ $opt += @( "--time-cond", $tarFile); }
                                                [String] $curlExe = ProcessGetCommandInEnvPathOrAltPaths "curl" @() "Please download it from http://curl.haxx.se/download.html and install it and add dir to path env var.";
                                                [String] $curlCaCert = Join-Path (FsEntryGetParentDir $curlExe) "curl-ca-bundle.crt";
                                                # 2021-10: Because windows has its own curl executable in windows-system32 folder and it does not care the search rule
                                                #   for the curl-ca-bundle.crt file as it is descripted in https://curl.se/docs/sslcerts.html
                                                #   we needed a solution for this. So, when the current curl executable is that from system32 folder
                                                #   then the first found curl-ca-bundle.crt file in path var is used for cacert option.
                                                if( (FsEntryPathIsEqual $curlExe "$env:SystemRoot/System32/curl.exe") ){
                                                  [String] $s = StringMakeNonNull (Get-Command -CommandType Application -Name curl-ca-bundle.crt -ErrorAction SilentlyContinue |
                                                    Select-Object -First 1 | Foreach-Object { $_.Source });
                                                  if( $s -ne "" ){ $curlCaCert = $s; }
                                                }
                                                if( (FileExists $curlCaCert) ){ $opt += @( "--cacert", $curlCaCert); }
                                                $opt += @( "--url", $url );
                                                [String] $optForTrace = StringArrayDblQuoteItems $opt.Replace("--user $($us):$pw","--user $($us):***");
                                                OutProgress "NetDownloadFileByCurl $url";
                                                OutProgress "  to `"$tarFile`"";
                                                [String] $tarDir = FsEntryGetParentDir $tarFile;
                                                DirCreate $tarDir;
                                                OutVerbose "`"$curlExe`" $optForTrace";
                                                try{
                                                  [String] $out = (ProcessStart $curlExe $opt);
                                                  # curl error codes:
                                                  #   23: "write data chunk to output failed." Write error. Curl could not write data chunk to a output.
                                                  #   60: "SSL certificate problem as expired or domain name not matches, alternatively use option to ignore ssl check."
                                                  #       SSL certificate problem: unable to get local issuer certificate. More details here: http://curl.haxx.se/docs/sslcerts.html
                                                  #       Curl performs SSL certificate verification by default, using a "bundle" of Certificate Authority (CA) public keys (CA certs).
                                                  #       If the default bundle file isn't adequate, you can specify an alternate file using the --cacert option.
                                                  #       If this HTTPS server uses a certificate signed by a CA represented in the bundle, the certificate verification probably failed
                                                  #       due to a problem with the certificate (it might be expired, or the name might not match the domain name in the URL).
                                                  #       If you'd like to turn off curl's verification of the certificate, use the -k (or --insecure) option.
                                                  #    6: "host not found." Could not resolve host: github.com
                                                  #   22: "file not found." The requested URL returned error: 404 Not Found
                                                  #   77: "SEC_E_UNTRUSTED_ROOT certificate chain not trustworthy (alternatively use insecure option or add server to curl-ca-bundle.crt next to curl.exe)."
                                                  #       schannel: next InitializeSecurityContext failed: SEC_E_UNTRUSTED_ROOT (0x80090325) - Die Zertifikatkette wurde von einer nicht vertrauenswürdigen Zertifizierungsstelle ausgestellt.
                                                  OutVerbose $out;
                                                  OutProgress "  Ok, downloaded $(FileGetSize $tarFile) bytes.";
                                                }catch{
                                                  [String] $msg = "  ($curlExe $optForTrace) failed because $($_.Exception.Message)";
                                                  if( -not $errorAsWarning ){ throw [ExcMsg] $msg; } OutWarning "Warning: $msg";
                                                } }
function NetDownloadToString                  ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false,
                                                  [Boolean] $onlyIfNewer = $false, [String] $encodingIfNoBom = "UTF8" ){
                                                [String] $tmp = (FileGetTempFile);
                                                NetDownloadFile $url $tmp $us $pw $ignoreSslCheck $onlyIfNewer;
                                                [String] $result = (FileReadContentAsString $tmp $encodingIfNoBom);
                                                FileDelTempFile $tmp; return [String] $result; }
function NetDownloadToStringByCurl            ( [String] $url, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false,
                                                  [Boolean] $onlyIfNewer = $false, [String] $encodingIfNoBom = "UTF8" ){
                                                [String] $tmp = (FileGetTempFile);
                                                NetDownloadFileByCurl $url $tmp $us $pw $ignoreSslCheck $onlyIfNewer;
                                                [String] $result = (FileReadContentAsString $tmp $encodingIfNoBom);
                                                FileDelTempFile $tmp; return [String] $result; }
function NetDownloadIsSuccessful              ( [String] $url ){ # test wether an url is downloadable or not;
                                                [Boolean] $res = $false;
                                                try{ [Boolean] $ignoreSslCheck = $true;
                                                  NetDownloadToString $url "" "" $ignoreSslCheck *>&1 | Out-Null; $res = $true;
                                                }catch{ OutVerbose "NetDownloadIsSuccessful: Ignoring expected behaviour that NetDownloadToString $url failed because $($_.Exception.Message)"; }
                                                return [Boolean] $res; }
function NetDownloadSite                      ( [String] $url, [String] $tarDir, [Int32] $level = 999,
                                                  [Int32] $maxBytes = 0, [String] $us = "", [String] $pw = "", [Boolean] $ignoreSslCheck = $false,
                                                  [Int32] $limitRateBytesPerSec = ([Int32]::MaxValue), [Boolean] $alsoRetrieveToParentOfUrl = $false ){
                                                # Mirror site to dir; wget: HTTP, HTTPS, FTP. Logfile is written into target dir. Password is not logged.
                                                # If wget2 (multithreaded) is in path then use wget2, otherwise wget.
                                                $tarDir = FsEntryGetAbsolutePath $tarDir;
                                                OutProgress "NetDownloadSite $url ";
                                                FsEntryAssertHasTrailingDirSep $tarDir;
                                                [String] $logf  = "$tarDir/.Download.$(DateTimeNowAsStringIsoMonth).detail.log";
                                                [String] $links = "$tarDir/.Download.$(DateTimeNowAsStringIsoMonth).links.log";
                                                [String] $logf2 = "$tarDir/.Download.$(DateTimeNowAsStringIsoMonth).log";
                                                [String] $caCert = ""; # default seams to be on windows: C:/ProgramData/ssl/ca-bundle.pem"; Maybe for future: "wget2-ca-bundle.crt";
                                                OutProgress "  (only newer files) to `"$tarDir`"";
                                                OutProgress "  Logfile: `"$logf`"";
                                                [String[]] $opt = @(
                                                   "--directory-prefix=."         # Note: On wget1 we could specify $tarDir but on wget2 we would have to replace all '\' to '/' and the "D:\" is replaced to "D%3A". So we need to set current dir.
                                                  ,$(switch($alsoRetrieveToParentOfUrl){ ($true){""} default{"--parent=off"}})  # Ascend above parent directory. (default: on)
                                                 #,"--verbose=off"                # default is on
                                                 #,"--debug=on"                   # default is off
                                                 #,"--quiet=off"                  # default is off
                                                  ,"--recursive"                  # Recursive download. (default: off)
                                                  ,"--level=$level"               # alternatives: --level=inf
                                                 #,"--no-remove-listing"          # leave .listing files for ftp (we not use this anymore because option not exists in wget2)
                                                  ,"--page-requisites"            # download all files as images to display .html
                                                  ,"--adjust-extension"           # make sure .html or .css for such types of files
                                                  ,"--backup-converted"           # When converting a file, back up the original version with a .orig suffix. optimizes incremental runs.
                                                  ,"--tries=2"                    # default is 20
                                                  ,"--waitretry=5"                # Wait up to number of seconds after error per thread. (default: 10)
                                                 #,"--execute=robots=off"         # We used this for wget1
                                                 #,"--robots=off"                 # Respect robots.txt standard for recursive downloads. (default: on)
                                                  ,"--user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0'" # take latest ESR
                                                  ,"--quota=$maxBytes"            # Download quota, 0 = no quota. (default: 0)
                                                  ,"--limit-rate=$limitRateBytesPerSec" # Limit rate of download per second, 0 = no limit. (default: 0)
                                                  ,"--wait=1"                     # Wait number of seconds between downloads per thread. (default: 0)
                                                 #,"--waitretry=10"               # Wait up to number of seconds after error per thread. (default: 10)
                                                  ,"--random-wait=1"              # Wait 0.5 up to 1.5*<--wait> seconds between downloads per thread. (default: off)
                                                 #,"--timestamping"               # Just retrieve younger files than the local ones. (default: off)
                                                  ,$(switch($ignoreSslCheck){ ($true){"--check-certificate=off"} default{""}})  # .
                                                    # Otherwise: ERROR: cannot verify ...'s certificate, issued by 'CN=...,C=US': Unable to locally verify the issuer's authority. To connect to ... insecurely, use `--no-check-certificate'.
                                                 #,"--convert-links"              # Convert non-relative links locally    deactivated because:  Both --no-clobber and --convert-links were specified, only --convert-links will be used.
                                                 #,"--force-html"                 # When input is read from a file, force it to be treated as an HTML file. This enables you to retrieve relative links from existing HTML files on your local disk, by adding <base href="url"> to HTML, or using the --base command-line option.
                                                 #,"--input-file=$fileslist"      # File where URLs are read from, - for STDIN.
                                                  ,"--clobber=off"                # Enable file clobbering. (default: on) skip downloads to existing files, either noclobber or timestamping
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
                                                 #,"--hsts=on"                     # Use HTTP Strict Transport Security (HSTS). (default: on)
                                                  ,"--host-directories=off"        # Create host directories when retrieving recursively. (default: on). Off: no dir $tardir\domainname
                                                  ,"--local-encoding=UTF-8"        # required if link urls contains utf8 which must be mapped to filesystem names (note: others as ISO-8859-1, windows-1251 does not work).
                                                  ,"--user=$us"                    # we take this as last option because following pw
                                                  ,"--append-output=$logf"         # .
                                                  ,"--ca-certificate=$caCert"      # WGET2 option: File with the bundle of CAs to verify the peers. Must be in PEM format. Otherwise CAs are searched at system-specified locations,
                                                                                   #   chosen at OpenSSL installation time. Default seams to be 'C:\ProgramData/ssl/ca-bundle.pem'.
                                                                                   #   2023-12/MN: If not specified it outputs an error msg that 'C:\ProgramData/ssl/ca-bundle.pem' was not found, but nevertheless it has 160 CAs.
                                                                                   #     It also outputs an error msg if an empty string is specified.
                                                 #,"--ca-directory=directory"      # WGET2 option: Containing CA certs in PEM format. Each file contains one CA cert, file name is based on a hash value derived from the cert.
                                                                                   #   Otherwise CA certs searched at system-specified locations, chosen at OpenSSL installation time.
                                                 #,"--restrict-file-names=windows" # WGET2 option: One of: unix, windows, nocontrol, ascii, lowercase, uppercase, none; Does Percent-Escaping illegal characters (on windows: "\\<>:\"|?*").
                                                 #,"--use-server-timestamps=off"   # Set local file's timestamp to server's timestamp. (default: on) 2023-12/MN: seams not to work.
                                                 #,"--force-directories"           # Create hierarchy of directories when not retrieving recursively. (default: off)
                                                 #,"--protocol-directories"        # Force creating protocol directories. (default: off)
                                                  ,"--connect-timeout=60"          # Connect timeout in seconds. Default is none so it depends on system libraries.
                                                  ,"--dns-timeout=60"              # DNS lookup timeout in seconds. Default is none so it depends on system libraries.
                                                 #,"--read-timeout"                # Read and write timeout in seconds. default is 900 sec.
                                                 #,"--timeout"                     # General network timeout in seconds. Same as all together: connect-timeout, dns-timeout, read-timeout
                                                  ,"--referer=$url"                # Include Referer: url in HTTP request. (default: off)
                                                );
                                                # more about logon forms: http://wget.addictivecode.org/FrequentlyAskedQuestions
                                                # backup without file conversions: wget -mirror --page-requisites --directory-prefix=c:\wget_files\example2 ftp://username:password@ftp.yourdomain.com
                                                # download:                        wget                           --directory-prefix=c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                # download resume:                 wget --continue                --directory-prefix=c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                # maybe we should also: $url/sitemap.xml
                                                DirCreate $tarDir;
                                                Push-Location $tarDir;
                                                [String] $stateBefore = FsEntryReportMeasureInfo $tarDir;
                                                # alternative would be for wget: Invoke-WebRequest
                                                [String] $wgetExe  = ProcessGetCommandInEnvPathOrAltPaths "wget" ; # Example: D:\Work\PortableProg\Tool\...
                                                [String] $wgetExe2 = ProcessFindExecutableInPath "wget2"; # Example: D:\Work\PortableProg\Tool\...
                                                if( $wgetExe2 -ne "" ){ $wgetExe = $wgetExe2; }
                                                FileAppendLineWithTs $logf "Push-Location `"$tarDir`"; & `"$wgetExe`" `"$url`" $opt --password=*** ; Pop-Location; ";
                                                #FileAppendLineWithTs $logf "  Note: Ignore the error messages: Failed to parse URI ''; No CAs were found in ''; Cannot resolve URI 'mailto:...'; Nothing to do - goodbye; ";
                                                OutProgress              "  Push-Location `"$tarDir`"; & `"$wgetExe`" `"$url`" ...opt... ";
                                                $opt += "--password=$pw";
                                                [String] $errMsg = & $wgetExe $opt $url *>&1;
                                                [Int32] $rc = ScriptGetAndClearLastRc; if( $rc -ne 0 ){
                                                  [String] $err = switch($rc){ # on multiple errors the prio: 2,..,8,1.
                                                    0 {"OK"}
                                                    1 {"Generic"}
                                                    2 {"CommandLineOption"}
                                                    3 {"FileIo"}
                                                    4 {"Network"}
                                                    5 {"SslVerification"}
                                                    6 {"Authentication"}
                                                    7 {"Protocol"}
                                                    8 {"ServerIssuedSomeResponse(example:404NotFound)"}
                                                    default {"Unknown(rc=$rc)"} };
                                                  if( $errMsg -ne "" ){ FileAppendLineWithTs $logf "  ErrorCategory: $err  ErrorMessage: $errMsg"; }
                                                  OutWarning "  Warning: Ignored one or more occurrences of error category: $err $errMsg. More see logfile=`"$logf`".";
                                                }
                                                Pop-Location;
                                                [String] $state = "  TargetDir: $(FsEntryReportMeasureInfo "$tarDir") (BeforeStart: $stateBefore)";
                                                FileAppendLineWithTs $logf $state;
                                                OutProgress $state; FileAppendLineWithTs $logf "-".PadRight(99,'-');
                                                [String[]] $lnkLines = @()+(FileReadContentAsLines $logf | Where-Object{ $_ -match "^Adding\ URL\:\ .*" } |
                                                  ForEach-Object{ StringRemoveLeft $_ "Adding URL: " $false; } | Sort-Object | Select-Object -Unique );
                                                FileWriteFromLines $links $lnkLines $true;
                                                [String[]] $logLines = @()+(FileReadContentAsLines $logf |
                                                  Where-Object{ $_ -ne "Failed to parse URI ''" } |
                                                  Where-Object{ $_ -ne "No CAs were found in ''" } |
                                                  Where-Object{ $_ -ne "Nothing to do - goodbye" } |
                                                  Where-Object{ $_ -notmatch "^Cannot\ resolve\ URI\ \'mailto\:.*" } |
                                                  Where-Object{ $_ -notmatch "^URL\ \'.*\'\ not\ followed\ \(no\ host-spanning\ requested\)" } |
                                                  Where-Object{ $_ -notmatch "^Saving\ \'.*" } |
                                                  Where-Object{ $_ -notmatch "^URI\ content\ encoding\ \=\ \'.*\'.*" } |
                                                  Where-Object{ $_ -notmatch "^UR[IL]\ \'.*\'\ not\ followed\ \(action\/formaction\ attribute\)" } |
                                                  Where-Object{ $_ -notmatch "^Adding\ URL\:\ .*" } |
                                                  Where-Object{ $_ -notmatch "^File\ \'.*\'\ already\ there\;\ not\ retrieving\." } |
                                                  Where-Object{ $_ -notmatch "^URL\ \'\'\ not\ requested\ \(file\ already\ exists\)" } |
                                                  Where-Object{ $_ -notmatch "^Cannot\ resolve\ URI\ \'.*\'" } |
                                                  Where-Object{ $_ -notmatch "^\[[0-9]+\]\ Downloading\ \'.*" } );
                                                FileWriteFromLines $logf2 $logLines $true;
                                                }
# Script local variable: gitLogFile
[String] $script:gitLogFile = FsEntryGetAbsolutePath "${env:TEMP}/tmp/MnCommonPsToolLibLog/$(DateTimeNowAsStringIsoYear)/$(DateTimeNowAsStringIsoMonth)/Git.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
function GitBuildLocalDirFromUrl              ( [String] $tarRootDir, [String] $urlAndOptionalBranch ){
                                                # Maps a root dir and a repo url with an optional sharp-char separated branch name
                                                # to a target repo dir which contains all url fragments below the hostname.
                                                # Example: (GitBuildLocalDirFromUrl "C:\WorkGit\" "https://github.com/mniederw/MnCommonPsToolLib")          == "C:\WorkGit\mniederw\MnCommonPsToolLib\";
                                                # Example: (GitBuildLocalDirFromUrl "C:\WorkGit\" "https://github.com/mniederw/MnCommonPsToolLib#MyBranch") == "C:\WorkGit\mniederw\MnCommonPsToolLib#MyBranch\";
                                                AssertNotEmpty $tarRootDir "tarRootDir";
                                                FsEntryAssertHasTrailingDirSep $tarRootDir;
                                                return [String] (FsEntryMakeTrailingDirSep (Join-Path $tarRootDir (([System.Uri]$urlAndOptionalBranch).AbsolutePath+([System.Uri]$urlAndOptionalBranch).Fragment))); }
function GitShowUrl                           ( [String] $repoDir ){
                                                # Example: return "https://github.com/mniederw/MnCommonPsToolLib"
                                                AssertNotEmpty $repoDir "repoDir";
                                                FsEntryAssertHasTrailingDirSep $repoDir;
                                                [String] $out = (& "git" "--git-dir=$repoDir/.git" "config" "remote.origin.url"); AssertRcIsOk $out;
                                                return [String] $out; }
function GitShowRemoteName                    ( [String] $repoDir ){
                                                # Example: return "origin"
                                                AssertNotEmpty $repoDir "repoDir";
                                                FsEntryAssertHasTrailingDirSep $repoDir;
                                                [String] $out = (& "git" "--git-dir=$repoDir/.git" "remote"); AssertRcIsOk $out;
                                                return [String] $out; }
function GitShowRepo                          ( [String] $repoDir ){ # return owner and reponame separated with a slash.
                                                # Example: return "mniederw/MnCommonPsToolLib"
                                                AssertNotEmpty $repoDir "repoDir";
                                                FsEntryAssertHasTrailingDirSep $repoDir;
                                                [String] $url = (GitShowUrl $repoDir);
                                                ToolGithubApiAssertValidRepoUrl $url;
                                                [String] $githubUrl = "https://github.com/";
                                                Assert ($url.StartsWith($githubUrl)) "Expected $url starts with $githubUrl";
                                                return [String] (StringRemoveLeft $url $githubUrl); }
function GitShowBranch                        ( [String] $repoDir, [Boolean] $getDefault = $false ){
                                                # return current branch (example: "trunk"). Returns empty if branch is detached.
                                                # If getDefault is specified then it returns in general main or master.
                                                AssertNotEmpty $repoDir "repoDir";
                                                FsEntryAssertHasTrailingDirSep $repoDir;
                                                if( $getDefault ){
                                                  # for future use: [String] $remote = (GitShowRemoteName $repoDir); # Example: "origin"
                                                  # for future use: if( $remote -eq "" ){ throw [ExcMsg] "Cannot get default branch in repodir=`"$repoDir`" because GitShowRemoteName returned empty string."; }
                                                  #[String[]] $out = (StringSplitIntoLines (ProcessStart "git" @("-C", (FsEntryRemoveTrailingDirSep $repoDir), "--git-dir=.git", "branch", "--remotes", "--no-color" ) -traceCmd:$false));
                                                  [String[]] $out = (& "git" "-C" $repoDir "--git-dir=.git" "branch" "--remotes" "--no-color"); AssertRcIsOk;
                                                  [String] $pattern = "  origin/HEAD -> origin/";
                                                  [String[]] $defBranch = @()+($out | Where-Object{ $_.StartsWith($pattern) } | ForEach-Object{ StringRemoveLeft $_ $pattern; });
                                                  if( $defBranch.Count -ne 1 ){ throw [ExcMsg] "GitShowBranch(`"$repoDir`",$getDefault) failed because for (git branch --remotes) we expected a line with leading pattern `"$pattern`" but we got: `"$out`"."; }
                                                  return [String] $defBranch[0];
                                                }
                                                #[String] $out = (ProcessStart "git" @("-C", $repoDir, "--git-dir=.git", "branch", "--no-color", "--show-current" ) -traceCmd:$false);
                                                [String] $out = (& "git" "-C" $repoDir "--git-dir=.git" "branch" "--no-color" "--show-current"); AssertRcIsOk;
                                                # old: [String] $line = "$(StringSplitIntoLines $out | Where-Object { $_.StartsWith("* ") } | Select-Object -First 1)";
                                                # old: Assert ($line.StartsWith("* ") -and $line.Length -ge 3) "GitShowBranch(`"$repoDir`") expected result of git branch begins with `"* `" but got `"$line`" and expected minimum length of 3.";
                                                # old: return [String] (StringRemoveLeft $line "* ").Trim(); }
                                                return [String] $out.Trim(); }
function GitShowChanges                       ( [String] $repoDir ){
                                                # return changed, deleted and new files or dirs. Per entry one line prefixed with a change code.
                                                AssertNotEmpty $repoDir "repoDir";
                                                FsEntryAssertHasTrailingDirSep $repoDir;
                                                [String] $out = (ProcessStart "git" @("-C", $repoDir, "--git-dir=.git", "status", "--short") -traceCmd:$false);
                                                return [String[]] (@()+(StringSplitIntoLines $out |
                                                  Where-Object{$null -ne $_} |
                                                  Where-Object{ StringIsFilled $_; })); }
function GitBranchList                        ( [String] $repoDir, [Boolean] $remotesOnly = $false ){
                                                # return sorted string list of all branches of a local repo dir
                                                # example: @("main","origin/main","origin/trunk");
                                                AssertNotEmpty $repoDir "repoDir";
                                                FsEntryAssertHasTrailingDirSep $repoDir;
                                                [String[]] $opt = @("-C", $repoDir, "branch", "--all" ); if( $remotesOnly ){ $opt += "--remotes"; }
                                                [String[]] $result = (StringSplitIntoLines (ProcessStart "git" $opt)) | ForEach-Object{ StringRemoveLeftNr $_ 2 } |
                                                  ForEach-Object{ if( $_.StartsWith("remotes/") ){ StringRemoveLeftNr $_ "remotes/".Length; }else{ $_; } } |
                                                  Where-Object{ $_ -ne "" -and (-not $_.StartsWith("origin/HEAD ")) } | Sort-Object;
                                                return [String[]] $result; }
function GitCmd                               ( [String] $cmd, [String] $tarRootDir, [String] $urlAndOptionalBranch, [Boolean] $errorAsWarning = $false ){
                                                # For commands:
                                                #   "Clone"       : Creates a full local copy of specified repo. Target dir must not exist.
                                                #                   Branch can be optionally specified, in that case it also will switch to this branch.
                                                #                   Default branch name is where the standard remote HEAD is pointing to, usually "main" or "master".
                                                #   "Fetch"       : Get all changes from specified repo to local repo but without touching current working files. Target dir must exist.
                                                #                   Branch in repo url can be optionally specified and then it is asserted that it matches. No switching branch will be done.
                                                #   "Pull"        : First a Fetch and then it also merges current branch into current working files. Target dir must exist.
                                                #                   Branch in repo url can be optionally specified and then it is asserted that it matches. No switching branch will be done.
                                                #   "CloneOrPull" : if target not exists then Clone otherwise Pull.
                                                #   "CloneOrFetch": if target not exists then Clone otherwise Fetch.
                                                #   "Revert"      : First a fetch, then a reset-hard to loose all local changes except new files and then do a clean to remove untracked files.
                                                #                   Same as delete folder and clone, but faster.
                                                # Target-Dir: see GitBuildLocalDirFromUrl.
                                                # The urlAndOptionalBranch defines a repo url optionally with a sharp-char separated branch name (allowed chars: A-Z,a-z,0-9,.,_,-).
                                                # If the branch name is specified with that form then it is also checked wether
                                                # We assert that no AutoCrLf git attribute option is used.
                                                # Pull-No-Rebase: We generally use no-rebase for pull because commit history should not be modified.
                                                # Example: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib"
                                                # Example: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib#MyBranch"
                                                AssertNotEmpty $tarRootDir "tarRootDir";
                                                FsEntryAssertHasTrailingDirSep $tarRootDir;
                                                $tarRootDir = FsEntryGetAbsolutePath $tarRootDir;
                                                if( @("Clone","Fetch","Pull","CloneOrPull","CloneOrFetch","Revert") -notcontains $cmd ){
                                                  throw [Exception] "Expected one of (Clone,Fetch,Pull,CloneOrPull,CloneOrFetch,Revert) instead of: $cmd"; }
                                                if( ($urlAndOptionalBranch -split "/",0)[-1] -notmatch "^[A-Za-z0-9]+[A-Za-z0-9._-]*(#[A-Za-z0-9]+[A-Za-z0-9._-]*)?`$" ){
                                                  throw [Exception] "Expected only ident-chars as (letter,numbers,.,_,-) for last part of `"$urlAndOptionalBranch`"."; }
                                                [String[]] $urlOpt = @()+(StringSplitToArray "#" $urlAndOptionalBranch); # Example: @( "https://github.com/mniederw/MnCommonPsToolLib", "MyBranch" )
                                                if( $urlOpt.Count -gt 2 ){ throw [Exception] "Unknown third param in sharp-char separated urlAndBranch=`"$urlAndOptionalBranch`". "; }
                                                if( $urlOpt.Count -gt 1 ){ AssertNotEmpty $urlOpt[1] "branch is empty in sharp-char separated urlAndBranch=`"$urlAndOptionalBranch`". "; }
                                                [String] $url = $urlOpt[0]; # repo url without branch. Example: "https://github.com/mniederw/MnCommonPsToolLib"
                                                [String] $branch = switch($urlOpt.Count -gt 1){($true){$urlOpt[1]} default{""}}; # Example: "" or "MyBranch"
                                                [String] $dir = FsEntryMakeTrailingDirSep (GitBuildLocalDirFromUrl $tarRootDir $urlAndOptionalBranch);
                                                GitAssertAutoCrLfIsDisabled;
                                                if( $cmd -eq "CloneOrPull"  ){ if( (DirNotExists $dir) ){ $cmd = "Clone"; }else{ $cmd = "Pull" ; } }
                                                if( $cmd -eq "CloneOrFetch" ){ if( (DirNotExists $dir) ){ $cmd = "Clone"; }else{ $cmd = "Fetch"; } }
                                                if( $branch -ne "" -and ($cmd -eq "Fetch" -or $cmd -eq "Pull") ){
                                                  [String] $currentBranch = (GitShowBranch $dir);
                                                  if( $currentBranch -ne $branch ){ throw [Exception] "$cmd $urlAndOptionalBranch to target `"$dir`" containing branch $currentBranch is denied because expected branch $branch. Before retry perform: GitSwitch `"$dir`" $branch;"; }
                                                }
                                                try{
                                                  [Object] $usedTime = [System.Diagnostics.Stopwatch]::StartNew();
                                                  [String[]] $gitArgs = @();
                                                  if( $cmd -eq "Clone" ){
                                                    # Writes to stderr: Cloning into '$env:TEMP/tmp/test'...
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
                                                  }elseif( $cmd -eq "Revert" ){
                                                    GitCmd "Fetch" $tarRootDir $urlAndOptionalBranch $errorAsWarning;
                                                    $gitArgs = @( "-C", $dir, "--git-dir=.git", "reset", "--hard"); # alternative option: --hard origin/master
                                                    # if( $branch -ne "" ){ $gitArgs += @( $branch ); }
                                                  }else{ throw [Exception] "Unknown git cmd=`"$cmd`""; }
                                                  FileAppendLineWithTs $gitLogFile "GitCmd(`"$tarRootDir`",$urlAndOptionalBranch) git $(StringArrayDblQuoteItems $gitArgs)";
                                                  # Example: "git" "-C" "$env:TEMP/tmp/mniederw/myrepo" "--git-dir=.git" "pull" "--quiet" "--no-stat" "--no-rebase" "https://github.com/mniederw/myrepo"
                                                  # Example: "git" "clone" "--quiet" "--branch" "MyBranch" "--" "https://github.com/mniederw/myrepo" "$env:TEMP/tmp/mniederw/myrepo#MyBranch"
                                                  # TODO middle prio: check env param pull.rebase and think about display and usage
                                                  [String] $out = (ProcessStart "git" $gitArgs -careStdErrAsOut:$true -traceCmd:$true);
                                                  # Skip known unused strings which are written to stderr as:
                                                  # - "Checking out files:  47% (219/463)" or "Checking out files: 100% (463/463), done."
                                                  # - warning: You appear to have cloned an empty repository.
                                                  # - The string "Already up to date." is presumebly suppressed by quiet option.
                                                  if( $cmd -eq "Revert" ){
                                                    if( $out.StartsWith("HEAD is now at ") ){
                                                      OutProgress "  $($out.Trim())"; # HEAD is now at 18956cc0 ...commit-comment...
                                                      $out = "";
                                                    }
                                                    $gitArgs = @( "-C", $dir, "--git-dir=.git", "clean", "-d", "--force");
                                                    $out += (ProcessStart "git" $gitArgs -careStdErrAsOut:$true -traceCmd:$true); $out = $out.Trim();
                                                    if( $out -eq "" ){ $out = "No untracked files to clean"; }
                                                    OutProgress "  $out"; # Removing MyRepo/MyFile.txt
                                                    $out = "";
                                                  }
                                                  StringSplitIntoLines $out | Where-Object{ StringIsFilled $_ } |
                                                    ForEach-Object{ $_.Trim(); } |
                                                    Where-Object{ -not ($_.StartsWith("Checking out files: ") -and ($_.EndsWith(")") -or $_.EndsWith(", done."))) } |
                                                    ForEach-Object{ OutWarning "Warning: For (git $gitArgs) got unexpected output: $_"; };
                                                  [String] $branchInfo = "$((GitShowBranch $dir).PadRight(10)) ($(GitShowRemoteName $dir)-default=$(GitShowBranch $dir $true))";
                                                  OutSuccess "  Ok, usedTimeInSec=$([Int64]($usedTime.Elapsed.TotalSeconds+0.999)) for url: $($url.PadRight(60)) branch: $branchInfo ";
                                                }catch{
                                                  # exc:              fatal: HttpRequestException encountered.
                                                  # exc:              Fehler beim Senden der Anforderung.
                                                  # exc:              fatal: AggregateException encountered.
                                                  # exc:              Logon failed, use ctrl+c to cancel basic credential prompt.  - bash: /dev/tty: No such device or address - error: failed to execute prompt script (exit code 1) - fatal: could not read Username for 'https://github.com': No such file or directory
                                                  # exc: Clone rc=128 remote: Repository not found.\nfatal: repository 'https://github.com/mniederw/UnknownRepo/' not found
                                                  # exc:              fatal: Not a git repository: 'D:\WorkGit\mniederw\UnknownRepo\.git'
                                                  # exc:              error: unknown option `anyUnknownOption'
                                                  # exc: Pull  rc=128 fatal: refusing to merge unrelated histories
                                                  # exc: Pull  rc=128 error: Pulling is not possible because you have unmerged files. - hint: Fix them up in the work tree, and then use 'git add/rm <file>' - fatal: Exiting because of an unresolved conflict. - hint: as appropriate to mark resolution and make a commit.
                                                  # exc: Pull  rc=128 fatal: Exiting because of an unresolved conflict. - error: Pulling is not possible because you have unmerged files. - hint: as appropriate to mark resolution and make a commit. - hint: Fix them up in the work tree, and then use 'git add/rm <file>'
                                                  # exc: Pull  rc=1   fatal: Couldn't find remote ref HEAD    (in case the repo contains no content)
                                                  # exc:              error: Your local changes to the following files would be overwritten by merge:   (Then the lines: "        ...file..." "Aborting" "Please commit your changes or stash them before you merge.")
                                                  # exc:              error: The following untracked working tree files would be overwritten by merge:   (Then the lines: "        ....file..." "Please move or remove them before you merge." "Aborting")
                                                  # exc: Pull  rc=1   Auto-merging dir1/file1  CONFLICT (add/add): Merge conflict in dir1/file1  Automatic merge failed; fix conflicts and then commit the result.\nwarning: Cannot merge binary files: dir1/file1 (HEAD vs. ab654...)
                                                  # exc: Pull  rc=1   fatal: unable to access 'https://github.com/anyUser/anyGitRepo/': Failed to connect to github.com port 443: Timed out
                                                  # exc: Pull  rc=1   fatal: TaskCanceledException encountered. -    Eine Aufgabe wurde abgebrochen. - bash: /dev/tty: No such device or address - error: failed to execute prompt script (exit code 1) - fatal: could not read Username for 'https://github.com': No such file or directory
                                                  $msg = "$(ScriptGetCurrentFunc)($cmd,$tarRootDir,$url) failed because $(StringReplaceNewlines $($_.Exception.Message) ' - ')";
                                                  ScriptResetRc;
                                                  if( $cmd -eq "Pull" -and ( $msg.Contains("error: Your local changes to the following files would be overwritten by merge:") -or
                                                                             $msg.Contains("error: Pulling is not possible because you have unmerged files.") -or
                                                                             $msg.Contains("fatal: Exiting because of an unresolved conflict.") ) ){
                                                    OutProgress "Note: If you would like to ignore and revert all local changes then call:  GitCmd Revert `"$tarRootDir`" $urlAndOptionalBranch ";
                                                  }
                                                  if( $cmd -eq "Pull" -and $msg.Contains("fatal: refusing to merge unrelated histories") ){
                                                    OutProgress "Note: If you would like to ignore and revert all local changes then call:  GitCmd Revert `"$tarRootDir`" $urlAndOptionalBranch; # maybe also try with pull --allow-unrelated-histories ";
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

function GitSwitch                            ( [String] $repoDir, [String] $branch ){
                                                AssertNotEmpty $repoDir "repoDir";
                                                FsEntryAssertHasTrailingDirSep $repoDir;
                                                ProcessStart "git" @("-C", $repoDir, "switch", $branch) -careStdErrAsOut:$true -traceCmd:$true | Out-Null; }
function GitAdd                               ( [String] $fsEntryToAdd ){
                                                AssertNotEmpty $fsEntryToAdd "fsEntryToAdd";
                                                [String] $repoDir = FsEntryGetAbsolutePath "$(FsEntryFindInParents $fsEntryToAdd ".git")/../"; # not trailing slash allowed
                                                ProcessStart "git" @("-C", $repoDir, "add", $fsEntryToAdd) -traceCmd:$true | Out-Null; }
function GitMerge                             ( [String] $repoDir, [String] $branch, [Boolean] $errorAsWarning = $false ){
                                                # merge branch (remotes/origin) into current repodir, no-commit, no-fast-forward
                                                AssertNotEmpty $repoDir "repoDir";
                                                FsEntryAssertHasTrailingDirSep $repoDir;
                                                AssertNotEmpty $branch "branch";
                                                try{
                                                  [String] $out = (ProcessStart "git" @("-C", $repoDir, "--git-dir=.git", "merge", "--no-commit", "--no-ff", "remotes/origin/$branch") -careStdErrAsOut:$true -traceCmd:$false);
                                                  # Example output to console but not to stdout:
                                                  #   Auto-merging MyDir/MyFile.txt
                                                  #   CONFLICT (content): Merge conflict in MyDir/MyFile.txt
                                                  #   CONFLICT (rename/delete): MyDir/MyFile.txt renamed to MyDir2/MyFile.txt in HEAD, but deleted in remotes/origin/mybranch
                                                  #   CONFLICT (modify/delete): MyDir/MyFile.txt deleted in remotes/origin/mybranch and modified in HEAD.  Version HEAD of MyDir/MyFile.txt left in tree.
                                                  #   CONFLICT (file location): MyDir/MyFile.txt added in remotes/origin/mybranch inside a directory that was renamed in HEAD, suggesting it should perhaps be moved to MyDir2/MyFile.txt
                                                  #   Automatic merge failed; fix conflicts and then commit the result.
                                                  OutProgress $out;
                                                }catch{
                                                  if( -not $errorAsWarning ){ throw [Exception] "Merge failed, fix conflicts manually: $($_.Exception.Message)"; }
                                                  OutWarning "Warning: Merge of branch $branch into `"$repoDir`" failed, fix conflicts manually. ";
                                                } }
function GitListCommitComments                ( [String] $tarDir, [String] $localRepoDir, [String] $fileExtension = ".tmp",
                                                  [String] $prefix = "Log.", [Int32] $doOnlyIfOlderThanAgeInDays = 14 ){
                                                # Reads commit messages and changed files info from localRepoDir
                                                # and overwrites it to two target files to target dir.
                                                # For building the filenames it takes the two last dir parts and writes the files with the names:
                                                # - Log.NameOfRepoParent.NameOfRepo.CommittedComments.tmp
                                                # - Log.NameOfRepoParent.NameOfRepo.CommittedChangedFiles.tmp
                                                # It is quite slow about 10 sec per repo, so it can be controlled by $doOnlyIfOlderThanAgeInDays.
                                                # In case of a git error it outputs it as warning.
                                                # Example: GitListCommitComments "C:\WorkGit\_CommitComments" "C:\WorkGit\mniederw\MnCommonPsToolLib"
                                                $tarDir       = FsEntryGetAbsolutePath $tarDir;
                                                $localRepoDir = FsEntryGetAbsolutePath $localRepoDir;
                                                FsEntryAssertHasTrailingDirSep $tarDir;
                                                FsEntryAssertHasTrailingDirSep $localRepoDir;
                                                [String] $repoName =  (Split-Path -Leaf (Split-Path -Parent $localRepoDir)) + "." + (Split-Path -Leaf $localRepoDir);
                                                function GitGetLog ([Boolean] $doSummary, [String] $fout) {
                                                  $fout = FsEntryGetAbsolutePath $fout;
                                                  if( -not (FsEntryNotExistsOrIsOlderThanNrDays $fout $doOnlyIfOlderThanAgeInDays) ){
                                                    OutProgress "Process git log not nessessary because file is newer than $doOnlyIfOlderThanAgeInDays days: $fout";
                                                  }else{
                                                    [String[]] $options = @( "--git-dir=$localRepoDir\.git", "log", "--after=1990-01-01", "--pretty=format:%ci %cn [%ce] %s" );
                                                    if( $doSummary ){ $options += "--summary"; }
                                                    [String] $out = "";
                                                    try{
                                                      $out = (ProcessStart "git" $options -careStdErrAsOut:$true -traceCmd:$true); # git can write warnings to stderr which we not handle as error
                                                    }catch{
                                                      # Example: ProcessStart of ("git" "--git-dir=D:\Workspace\mniederw\MnCommonPsToolLib\.git" "log" "--after=1990-01-01" "--pretty=format:%ci %cn [%ce] %s" "--summary") failed with rc=128\nfatal: your current branch 'master' does not have any commits yet
                                                      if( $_.Exception.Message.Contains("fatal: your current branch '") -and
                                                          $_.Exception.Message.Contains("' does not have any commits yet") ){ # Last operation failed [rc=128]
                                                        $out +=  "$([Environment]::NewLine)" + "Info: your current branch 'master' does not have any commits yet.";
                                                        OutProgress "  Info: Empty branch without commits.";
                                                      }else{
                                                        $out += "$([Environment]::NewLine)" + "Warning: (GitListCommitComments `"$tarDir`" `"$localRepoDir`" `"$fileExtension`" `"$prefix`" `"$doOnlyIfOlderThanAgeInDays`") ";
                                                        $out += "$([Environment]::NewLine)" + "  failed because $($_.Exception.Message)";
                                                        if( $_.Exception.Message.Contains("warning: inexact rename detection was skipped due to too many files.") ){
                                                          $out += "$([Environment]::NewLine)" + "  The reason is that the config value of diff.renamelimit with its default of 100 is too small. ";
                                                          $out += "$([Environment]::NewLine)" + "  Before a next retry you should either add the two lines (`"[diff]`",`"  renamelimit = 999999`") to .git/config file, ";
                                                          $out += "$([Environment]::NewLine)" + "  or run (git `"--git-dir=$localRepoDir\.git`" config diff.renamelimit 999999) ";
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
function GitAssertAutoCrLfIsDisabled          (){
                                                # Always use this before using git in general because the mode core.autocrlf=true
                                                # will lead sometimes to conflicts (mixed eols, shared-files, merges, definition what is a text file).
                                                # On Linux: The problem generally is not present because as default
                                                #   the system settings (default for all users, stored in /etc/gitconfig) are not existing
                                                #   and in the global settings (default for all repos of current user, stored in $HOME/.gitconfig)
                                                #   this option also not exists and for the git command the default value of this mode is false.
                                                # On Windows: The bad thing is that https://git-scm.com (for example in V2.43 from 2023-11-20) does create the file
                                                #   C:\Install-dir-of-Git\etc\gitconfig with the entry "autocrlf = true" and so this is the default
                                                #   for the system settings, which is not the same as on linux!
                                                #   Probably this was done because in earlier days there were some windows text editors,
                                                #   which did automatically silently replace all LF line endings by CRLF.
                                                #   But no major editor is doing this anymore (notepad since 2018) and in contrast todays the editors on windows have options
                                                #   to create text files from the beginning with LF line endings (https://editorconfig.org/) as linux editors always are doing it.
                                                # With the $repo/.gitattributes file stored in the repo there is the possibility to define the usage of LF or CRLF
                                                #   for all contributors of a repo but this is also not reasonable because there is no consistent definition
                                                #   which files are text files and which not.
                                                # Best way: Use .editorconfig file in your repo and or on top of your workspace, ref: https://editorconfig.org/ .
                                                # List current line endings, use:  git ls-files --eol
                                                # More: https://www.aleksandrhovhannisyan.com/blog/crlf-vs-lf-normalizing-line-endings-in-git/
                                                # More: https://git-scm.com/docs/git-config see under option core.safecrlf which depends on core.autocrlf=true
                                                #   it has the description "CRLF conversion bears a slight chance of corrupting data."
                                                # We recommend (strongly on windows) to call GitDisableAutoCrLf after any git installation or update.
                                                [String] $errmsg = "it is strongly recommended never use this because unexpected state and merge behaviours. Please change it by calling GitDisableAutoCrLf and then retry.";
                                                if( (FileExists "$HOME/.gitconfig") ){
                                                  [String] $line1 = (StringMakeNonNull (& "git" "config" "--list" "--global" | Where-Object{ $_ -like "core.autocrlf=true" })); AssertRcIsOk;
                                                  if( $line1 -ne "" ){ throw [ExcMsg] "Git is globally (for all repos of user) configured to use autocrlf conversions, $errmsg"; }
                                                }
                                                if( (OsIsWindows) -or (-not (OsIsWindows) -and (FileExists "/etc/gitconfig")) ){
                                                  [String] $line2 = (StringMakeNonNull (& "git" "config" "--list" "--system" | Where-Object{ $_ -like "core.autocrlf=true" })); AssertRcIsOk;
                                                  if( $line2 -ne "" ){ throw [ExcMsg] "Git is systemwide (for all users on machine) configured to use autocrlf conversions, $errmsg"; }
                                                }
                                                OutVerbose "ok, git-autocrlf is globally and systemwide defined as false or undefined."; }
function GitSetGlobalVar                      ( [String] $var, [String] $val, [Boolean] $useSystemNotGlobal = $false ){
                                                # if val is empty then it will unset the var.
                                                # If option $useSystemNotGlobal is true then system-wide variable are set instead of the global.
                                                # The order of priority for configuration levels is: local, global, system.
                                                AssertNotEmpty $var;
                                                # check if defined
                                                [String] $confScope     = $(switch($useSystemNotGlobal){($true){"--system"      }($false){"--global"        }});
                                                [String] $confFileLinux = $(switch($useSystemNotGlobal){($true){"/etc/gitconfig"}($false){"$HOME/.gitconfig"}});
                                                [String] $a = "";
                                                if( (OsIsWindows) -or (-not (OsIsWindows) -and (FileExists $confFileLinux)) ){
                                                  # if conf file was never created then we would get for example: fatal: unable to read config file '/etc/gitconfig': No such file or directory
                                                  $a = "$(& "git" "config" "--list" $confScope | Where-Object{ $_ -like "$var=*" })"; AssertRcIsOk;
                                                }
                                                # if defined then we can get value; this statement would throw if var would not be defined
                                                if( $a -ne "" ){ $a = (& "git" "config" $confScope $var); AssertRcIsOk; }
                                                if( $a -eq $val ){
                                                  OutDebug "GitSetVar$($confScope): $var=`"$val`" was already done.";
                                                }else{
                                                  if( $val -eq "" ){
                                                    OutProgress "GitSetVar$($confScope): $var=`"$val`" (will unset var)";
                                                    & "git" "config" $confScope --unset $var; AssertRcIsOk;
                                                  }else{
                                                    OutProgress "GitSetVar$($confScope): $var=`"$val`" ";
                                                    & "git" "config" $confScope $var $val; AssertRcIsOk;
                                                  }
                                                } }
function GitDisableAutoCrLf                   (){ # set this as default for global (all repos of user) and system (for all users on mach); no output if nothing done.
                                                [String] $val = $(switch((OsIsWindows)){($true){"false"}($false){""}});
                                                GitSetGlobalVar "core.autocrlf" $val;
                                                GitSetGlobalVar "core.autocrlf" $val $true; }
function GitCloneOrPullUrls                   ( [String[]] $listOfRepoUrls, [String] $tarRootDirOfAllRepos, [Boolean] $errorAsWarning = $false ){
                                                # Works later multithreaded and errors are written out, collected and throwed at the end.
                                                # If you want single threaded then call it with only one item in the list.
                                                $tarRootDirOfAllRepos = FsEntryGetAbsolutePath $tarRootDirOfAllRepos;
                                                FsEntryAssertHasTrailingDirSep $tarRootDirOfAllRepos;
                                                [String[]] $errorLines = @();
                                                function GetOne( [String] $url ){
                                                  try{
                                                    GitCmd "CloneOrPull" $tarRootDirOfAllRepos $url $errorAsWarning;
                                                  }catch{
                                                    [String] $msg = "Error: $($_.Exception.Message)"; OutError $msg; $errorLines += $msg;
                                                  }
                                                }
                                                if( $listOfRepoUrls.Count -eq 1 ){ GetOne $listOfRepoUrls[0]; }
                                                else{
                                                  [String] $tmp = (FileGetTempFile);
                                                  $listOfRepoUrls | ForEach-Object { Start-ThreadJob -ThrottleLimit 8 -StreamingHost $host -ScriptBlock {
                                                    try{
                                                      GitCmd "CloneOrPull" $using:tarRootDirOfAllRepos $using:_ $using:errorAsWarning;
                                                    }catch{
                                                      [String] $msg = "Error: $($_.Exception.Message)"; OutError $msg;
                                                      FileAppendLine $using:tmp $msg;
                                                    }
                                                  } } | Wait-Job | Remove-Job;
                                                  [String] $errMsg = (FileReadContentAsString $tmp); FileDelTempFile $tmp;
                                                  if( $errMsg -ne "" ){ $errorLines += $errMsg; }
                                                }
                                                # alternative not yet works because vars: $listOfRepoUrls | Where-Object{$null -ne $_} | ForEachParallel -MaxThreads 10 { GitCmd "CloneOrPull" $tarRootDirOfAllRepos $_ $errorAsWarning; } }
                                                # old else{ $listOfRepoUrls | Where-Object{$null -ne $_} | ForEach-Object { GetOne $_; } }
                                                # for future use:
                                                #   # Works later multithreaded and errors are written out, collected and throwed at the end.
                                                #   # If you want single threaded then call it with only one item in the list.
                                                #   OutProgress "GitCloneOrPullUrls NrOfUrls=$($listOfRepoUrls.Count) CallLog=`"$gitLogFile`" ";
                                                #   [String[]] $errorLines = @();
                                                #   if( $listOfRepoUrls.Count -eq 0 ){ OutProgress "Ok, GitCloneOrPullUrls was called with no urls so nothing to do."; return; }
                                                #   [Object] $threadSafeDict = [System.Collections.Concurrent.ConcurrentDictionary[string,string]]::new();
                                                #   $listOfRepoUrls | ForEach-Object { [System.Tuple]::Create($tarRootDirOfAllRepos,$_,$errorAsWarning,$threadSafeDict) } |
                                                #   ForEach-Object{ #TODO later: ForEachParallel { GlobalVariablesInit;
                                                #     [String] $tarRootDirOfAllRepos = $_.Item1;
                                                #     [String] $url                  = $_.Item2;
                                                #     [String] $errorAsWarning       = $_.Item3;
                                                #     [Object] $threadSafeDict       = $_.Item4;
                                                #     try{
                                                #       GitCmd "CloneOrPull" $_.Item1 $_.Item2 $_.Item3;
                                                #     }catch{
                                                #       [String] $msg = "Error (GitCmd CloneOrPull $tarRootDirOfAllRepos $url $errorAsWarning): $(StringFromException $_.Exception)";
                                                #       OutError $msg;
                                                #       Assert $threadSafeDict.TryAdd($url,$msg);
                                                #     }
                                                #   };
                                                #   $errorLines += $threadSafeDict.Values;
                                                #   if( $errorLines.Count ){ throw [ExcMsg] (StringArrayConcat $errorLines); } }
                                                if( $errorLines.Count ){ throw [ExcMsg] (StringArrayConcat $errorLines); } }
                                                function GithubPrepareCommand                 (){ # otherwise we would get: "A new release of gh is available: 2.7.0 → v2.31.0\nhttps://github.com/cli/cli/releases/tag/v2.31.0"
                                                ProcessEnvVarSet "GH_NO_UPDATE_NOTIFIER" "1" -traceCmd:$false; }
function GithubAuthStatus                     (){
                                               GithubPrepareCommand;
                                               [String] $out = (ProcessStart "gh" @("auth", "status") -careStdErrAsOut:$true -traceCmd:$true);
                                               # Output:
                                               #   github.com
                                               #     Ô£ô Logged in to github.com as myowner ($HOME\AppData\Roaming\GitHub CLI\hosts.yml)
                                               #     Ô£ô Git operations for github.com configured to use https protocol.
                                               #     Ô£ô Token: *******************
                                               OutProgress $out; }
function GithubGetBranchCommitId             ( [String] $repo, [String] $branch, [String] $repoDirForCred = "", [Boolean] $traceCmd = $false ){
                                                # repo           : has format [HOST/]OWNER/REPO
                                                # branch         : if branch is not uniquely defined it will throw.
                                                # repoDirForCred : Any folder under any git repository, from which the credentials will be taken, use empty for current dir.
                                                # traceCmd       : Output progress messages instead only the result.
                                                # example: GithubGetBranchCommitId "mniederw/MnCommonPsToolLib" "trunk"; # returns "62ea808a029fa645fcb0c62332ca2698d1b783a1"
                                                FsEntryAssertHasTrailingDirSep $repoDirForCred;
                                                if( $traceCmd ){ OutProgress "List github-branch-commit from branch $branch in repo $repo (repoDirForCred=$repoDirForCred)"; }
                                                AssertNotEmpty $repo "repo";
                                                Push-Location $repoDirForCred;
                                                GithubPrepareCommand;
                                                [String] $out = "";
                                                try{
                                                  # example: gh api repos/mniederw/MnCommonPsToolLib/git/refs/heads/trunk --jq '.object.sha'
                                                  $out = (ProcessStart "gh" @("api", "repos/$repo/git/refs/heads/$branch", "--jq", ".object.sha" ) -careStdErrAsOut:$false -traceCmd:$traceCmd).Trim();
                                                }catch{
                                                  # exc: "rc=1  gh: Not Found (HTTP 404)"
                                                  # exc: "rc=1  expected an object but got: array ([{"node_id":"MDM6UmVmMTQ0 ...])""
                                                  if( $_.Exception.Message.Contains("gh: Not Found (HTTP 404)") -or
                                                      $_.Exception.Message.Contains("expected an object but got: array ") ){
                                                    $error.clear();
                                                    throw [ExcMsg] "ToolListBranchCommit: In github repo $repo no branch exists with name `"$branch`".";
                                                  }else{ throw; }
                                                }
                                                Pop-Location;
                                                if( $traceCmd ){ OutProgress $out; }else{ return [String] $out; } }
function GithubListPullRequests               ( [String] $repo, [String] $filterToBranch = "", [String] $filterFromBranch = "", [String] $filterState = "open" ){
                                               # repo has format [HOST/]OWNER/REPO
                                               AssertNotEmpty $repo "repo";
                                               [String] $fields = "number,state,createdAt,title,labels,author,assignees,updatedAt,url,body,closedAt,repository,authorAssociation,commentsCount,isLocked,isPullRequest,id";
                                               GithubPrepareCommand;
                                               [String] $out = (ProcessStart "gh" @("search", "prs", "--repo", $repo, "--state", $filterState, "--base", $filterToBranch, "--head", $filterFromBranch, "--json", $fields) -traceCmd:$true);
                                               return ($out | ConvertFrom-Json); }
function GithubCreatePullRequest              ( [String] $repo, [String] $toBranch, [String] $fromBranch, [String] $title = "", [String] $repoDirForCred = "" ){
                                               # repo           : has format [HOST/]OWNER/REPO .
                                               # title          : default title is "Merge $fromBranch into $toBranch".
                                               # repoDirForCred : Any folder under any git repository, from which the credentials will be taken, use empty for current dir.
                                               # example: GithubCreatePullRequest "mniederw/MnCommonPsToolLib" "trunk" "main" "" $PSScriptRoot;
                                               AssertNotEmpty $repo "repo";
                                               OutProgress "Create a github-pull-request from branch $fromBranch to $toBranch in repo=$repo (repoDirForCred=$repoDirForCred)";
                                               if( $title -eq "" ){ $title = "Merge $fromBranch to $toBranch"; }
                                               [String[]] $prUrls = @()+(GithubListPullRequests $repo $toBranch $fromBranch |
                                                 Where-Object{$null -ne $_} | ForEach-Object{ $_.url });
                                               if( $prUrls.Count -gt 0 ){
                                                 # if we would perform the gh command we would get: rc=1  https://github.com/myowner/myrepo/pull/1234 a pull request for branch "mybranch" into branch "main" already exists:
                                                 OutProgress "A pull request for branch $fromBranch into $toBranch already exists: $($prUrls[0])";
                                                 return;
                                               }
                                               Push-Location $repoDirForCred;
                                               GithubPrepareCommand;
                                               [String] $out = "";
                                               try{
                                                 $out = (ProcessStart "gh" @("pr", "create", "--repo", $repo, "--base", $toBranch, "--head", $fromBranch, "--title", $title, "--body", " ") -careStdErrAsOut:$true -traceCmd:$true);
                                               }catch{
                                                 # example: rc=1  pull request create failed: GraphQL: No commits between main and trunk (createPullRequest)
                                                 if( $_.Exception.Message.Contains("pull request create failed: GraphQL: No commits between ") ){
                                                   $error.clear();
                                                   $out = "No pull request nessessary because no commit between branches `"$toBranch`" and `"$fromBranch`" .";
                                                 }else{ throw; }
                                               }
                                               Pop-Location;
                                               # Possible outputs, one of:
                                               #   Warning: 2 uncommitted changes
                                               #   Creating pull request for myfrombranch into main in myowner/myrepo
                                               #   a pull request for branch "myfrombranch" into branch "main" already exists:
                                               #   https://github.com/myowner/myrepo/pull/1234
                                               OutProgress $out; }
function GithubMergeOpenPr                    ( [String] $prUrl, [String] $repoDirForCred = "" ){
                                               # prUrl          : Url to pr which has no pending merge conflict.
                                               # repoDirForCred : Any folder under any git repository, from which the credentials will be taken, use empty for current dir.
                                               # example: GithubMergeOpenPr "https://github.com/mniederw/MnCommonPsToolLib/pull/123" $PSScriptRoot;
                                               FsEntryAssertHasTrailingDirSep $repoDirForCred;
                                               OutProgress "GithubMergeOpenPr $prUrl (repoDirForCred=$repoDirForCred)";
                                               Push-Location $repoDirForCred;
                                                 GithubPrepareCommand;
                                                 [String] $out = "";
                                                 $out = (ProcessStart "gh" @("pr", "merge", "--repo", $repoDirForCred, "--merge", $prUrl) -traceCmd:$true);
                                               Pop-Location;
                                               OutProgress $out; }
function ToolTailFile                         ( [String] $file ){ OutProgress "Show tail of file until ctrl-c is entered"; Get-Content -Wait $file; }
function ToolAddLineToConfigFile              ( [String] $file, [String] $line, [String] $existingFileEncodingIfNoBom = "Default" ){
                                                # if file not exists or line not found case sensitive in file then the line is appended.
                                                if( FileNotExists $file ){ FileWriteFromLines $file $line; }
                                                elseif( -not (StringArrayContains (FileReadContentAsLines $file $existingFileEncodingIfNoBom) $line) ){ FileAppendLines $file $line; } }
function ToolGithubApiAssertValidRepoUrl      ( [String] $repoUrl ){
                                                # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
                                                [String] $githubUrl = "https://github.com/";
                                                Assert $repoUrl.StartsWith($githubUrl) "expected url begins with $githubUrl but got: $repoUrl";
                                                [String[]] $a = @()+(StringSplitToArray "/" (StringRemoveLeft (StringRemoveRight $repoUrl "/") $githubUrl $false));
                                                Assert ($a.Count -eq 2 -and $a[0].Length -ge 2 -and $a[1].Length -ge 2) "expected url contains user/reponame but got: $repoUrl"; }
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
                                                  # Example: https://api.github.com/orgs/arduino/repos?type=all&sort=id&per_page=100&page=2&affiliation=owner,collaborator,organization_member
                                                  [String] $url = "https://api.github.com/orgs/$org/repos?per_page=100&page=$i";
                                                  [Object] $json = NetDownloadToString $url $us $pw | ConvertFrom-Json;
                                                  [Array] $a = @()+($json | Select-Object @{N='Url';E={$_.html_url}}, archived, private, fork, forks, language,
                                                    @{N='CreatedAt';E={(DateTimeFromStringOrDateTimeValue $_.created_at).ToString("yyyy-MM-dd")}},
                                                    @{N='UpdatedAt';E={(DateTimeFromStringOrDateTimeValue $_.updated_at).ToString("yyyy-MM-dd")}},
                                                    @{N='PermAdm';E={$_.permissions.admin}}, @{N='PermPush';E={$_.permissions.push}}, @{N='PermPull';E={$_.permissions.pull}},
                                                    default_branch, @{N='LicName';E={$_.license.name}},
                                                    @{N='Description';E={(StringLeft $_.description 200)}});
                                                  if( $a.Count -eq 0 ){ break; }
                                                  $result += $a;
                                                } return [Array] $result | Sort-Object archived, Url; }
function ToolGithubApiDownloadLatestReleaseDir( [String] $repoUrl ){
                                                # Creates a unique temp dir, downloads zip, return folder of extracted zip; You should remove dir after usage.
                                                # Latest release is the most recent non-prerelease, non-draft release, sorted by its last commit-date.
                                                # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
                                                ToolGithubApiAssertValidRepoUrl $repoUrl;
                                                [String] $apiUrl = "https://api.github.com/repos/" + (StringRemoveLeft (StringRemoveRight $repoUrl "/") "https://github.com/" $false);
                                                # Example: $apiUrl = "https://api.github.com/repos/mniederw/MnCommonPsToolLib"
                                                [String] $url = "$apiUrl/releases/latest";
                                                OutProgress "Download: $url";
                                                [Object] $apiObj = NetDownloadToString $url | ConvertFrom-Json;
                                                [String] $relName = "$($apiObj.name) [$($apiObj.target_commitish),$((DateTimeFromStringOrDateTimeValue $apiObj.created_at).ToString("yyyy-MM-dd")),$($apiObj.tag_name)]";
                                                OutProgress "Selected: `"$relName`"";
                                                # Example: $apiObj.zipball_url = "https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball/V4.9"
                                                # Example: $relName = "OpenSource-GPL3 MnCommonPsToolLib V4.9 en 2020-02-13 [master,2020-02-13,V4.9]"
                                                [String] $tarDir = DirCreateTemp "MnCoPsToLib_";
                                                [String] $tarZip = "$tarDir/$relName.zip";
                                                # We can download latest release zip by one of:
                                                # - https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball
                                                # - https://api.github.com/repos/mniederw/MnCommonPsToolLib/zipball/V4.9
                                                # - https://github.com/mniederw/MnCommonPsToolLib/archive/V4.9.zip
                                                # - https://codeload.github.com/mniederw/MnCommonPsToolLib/legacy.zip/master
                                                NetDownloadFileByCurl "$apiUrl/zipball" $tarZip;
                                                ToolUnzip $tarZip $tarDir; # Example: ./mniederw-MnCommonPsToolLib-25dbfb0/*
                                                FileDelete $tarZip;
                                                 # list flat dirs, Example: "$env:TEMP/tmp/MnCoPsToLib_catkmrpnfdp/mniederw-MnCommonPsToolLib-25dbfb0/"
                                                [String[]] $dirs = (@()+(FsEntryListAsStringArray $tarDir $false $true $false));
                                                if( $dirs.Count -ne 1 ){ throw [ExcMsg] "Expected one dir in `"$tarDir`" instead of: $dirs"; }
                                                [String] $dir0 = $dirs[0];
                                                FsEntryMoveByPatternToDir "$dir0/*" $tarDir;
                                                DirDelete $dir0;
                                                return [String] $tarDir; }
function ToolEvalVsCodeExec                   (){ [String] $result = (ProcessFindExecutableInPath "code");
                                                  if( $result -eq "" -and (OsIsWindows) ){
                                                    if( (FileExists "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\Code.cmd") ){ # user
                                                      $result =     "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\Code.cmd";
                                                    }elseif( (FileExists "$env:ProgramFiles\Microsoft VS Code\Code.exe") ){ # system
                                                      $result =          "$env:ProgramFiles\Microsoft VS Code\Code.exe";
                                                    }
                                                  }
                                                  if( $result -eq "" ){ throw [ExcMsg] "VS Code executable was not found wether in path nor on windows at common locations for user or system programs."; }
                                                  return [String] $result; }

function GetSetGlobalVar( [String] $var, [String] $val){ OutWarning "GetSetGlobalVar is DEPRECATED, replace it now by GitSetGlobalVar. ";  GitSetGlobalVar $var $val; }
function FsEntryIsEqual ( [String] $fs1, [String] $fs2, [Boolean] $caseSensitive = $false ){ OutWarning "FsEntryIsEqual is DEPRECATED, replace it now by FsEntryPathIsEqual."; return (FsEntryPathIsEqual $fs1 $fs2); }
function StdOutBegMsgCareInteractiveMode ( [String] $mode = "" ){ OutWarning "StdOutBegMsgCareInteractiveMode is DEPRECATED; replace it now by one or more of: StdInAskForAnswerWhenInInteractMode; OutProgress `"Minimize console`"; ConsoleMinimize;"; StdInAskForAnswerWhenInInteractMode; }
function StdOutEndMsgCareInteractiveMode ( [Int32] $delayInSec = 1 ){ OutWarning "StdOutEndMsgCareInteractiveMode is DEPRECATED; replace it now by one or more of: OutSuccess `"Ok, done. Press Enter to Exit / Ending in .. seconds.`", StdInReadLine `"Press Enter to exit.`", ProcessSleepSec!"; StdInReadLine "Press Enter to exit."; }
function ToolGetBranchCommit ( [String] $repo, [String] $branch, [String] $repoDirForCred = "", [Boolean] $traceCmd = $false ){ OutWarning "ToolGetBranchCommit is DEPRECATED; replace it now by GithubGetBranchCommitId."; GithubGetBranchCommitId $repo $branch $repoDirForCred $traceCmd; }

# ----------------------------------------------------------------------------------------------------

if( (OsIsWindows) ){ # running under windows
  OutVerbose "$PSScriptRoot : Running on windows";
  . "$PSScriptRoot/MnCommonPsToolLib_Windows.ps1";
}else{
  OutVerbose "$PSScriptRoot : Running not on windows";
}
AssertRcIsOk;

Export-ModuleMember -function *; # Export all functions from this script which are above this line (types are implicit usable).

# Powershell useful knowledge and additional documentation
# ========================================================
#
# - Enable powershell: Before using any powershell script, the following default modes are predefined:
#     Current mode on PS7       environment: RemoteSigned
#     Current mode on PS5-64bit environment: AllSigned
#     Current mode on PS5-32bit environment: AllSigned
#   so you must enable them on 64bit and on 32bit environment!
#   It requires admin rights so either run a cmd.exe shell with admin mode and call:
#     PS7      :  pwsh                                               -Command Set-ExecutionPolicy -Scope LocalMachine Unrestricted
#     PS5-64bit:  %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe Set-Executionpolicy -Scope LocalMachine Unrestricted
#     PS5-32bit:  %SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe Set-Executionpolicy -Scope LocalMachine Unrestricted
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
# - Parameter attribute declarations (Example: Mandatory, Position): https://msdn.microsoft.com/en-us/library/ms714348(v=vs.85).aspx
# - Parameter validation attributes (Example: ValidateRange): https://social.technet.microsoft.com/wiki/contents/articles/15994.powershell-advanced-function-parameter-attributes.aspx#Parameter_Validation_Attributes
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
#   $LASTEXITCODE : Contains the exit code of the last native executable execution, 0 is ok, is init with $null.
#                   Can be null if not windows command was called. Should not manually set, but if yes then as: $global:LASTEXITCODE = $null;
# - Available colors for console -foregroundcolor and -backgroundcolor:
#   Black DarkBlue DarkGreen DarkCyan DarkRed DarkMagenta DarkYellow Gray DarkGray Blue Green Cyan Red Magenta Yellow White
# - Whenever possible use Write-Output (can be redirected, does always a newline)
#   instead of Write-Host (not redirectable, newline optional, provides color).
#   Colors for Write-Output can be done as following but this is not multithreading safe.
#   [ConsoleColor] $c = $host.UI.RawUI.ForegroundColor; $host.UI.RawUI.ForegroundColor = $color; Write-Output $line; $host.UI.RawUI.ForegroundColor = $c;
# - Manifest .psd1 file can be created with: New-ModuleManifest MnCommonPsToolLib.psd1 -ModuleVersion "1.0" -Author "Marc Niederwieser"
# - Known Bugs or Problems:
#   - Powershell V2 Bug: checking strings for $null is different between if and switch tests:
#     http://stackoverflow.com/questions/12839479/powershell-treats-empty-string-as-equivalent-to-null-in-switch-statements-but-no
#   - Variable or function argument of type String is never $null, if $null is assigned then always empty is stored.
#       [String] $s; $s = $null; Assert ($null -ne $s); Assert ($s -eq "");
#     But if type String is within a struct then it can be null.
#       Add-Type -TypeDefinition "public struct MyStruct {public string MyVar;}"; Assert( $null -eq (New-Object MyStruct).MyVar );
#     And the string variable is null IF IT IS RUNNING IN A SCRIPT in ps5or7, if running interactive then it is not null:
#       [String] $a = @() | Where-Object{ $false }; Write-Output "IsStringNull: $($null -eq $a)";
#   - GetFullPath() works not with the current dir but with the working dir where powershell was started for example when running as administrator.
#     http://stackoverflow.com/questions/4071775/why-is-powershell-resolving-paths-from-home-instead-of-the-current-directory/4072205
#     powershell.exe         ;
#                              Get-Location                                 # Example: $HOME
#                              Write-Output hi > .\a.tmp   ;
#                              [System.IO.Path]::GetFullPath(".\a.tmp")     # is correct "$HOME\a.tmp"
#     powershell.exe as Admin;
#                              Get-Location                                 # Example: C:\WINDOWS\System32
#                              Set-Location $HOME;
#                              [System.IO.Path]::GetFullPath(".\a.tmp")     # is wrong   "C:\WINDOWS\System32\a.tmp"
#                              [System.IO.Directory]::GetCurrentDirectory() # is         "C:\WINDOWS\System32"
#                              (get-location).Path                          # is         "$HOME"
#                              Resolve-Path .\a.tmp                         # is correct "$HOME\a.tmp"
#                              (Get-Item -Path ".\a.tmp" -Verbose).FullName # is correct "$HOME\a.tmp"
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
#   - Good behaviour: DotNet functions as Split() can return empty arrays instead of return $null:
#       [String[]] $a = "".Split(";",[System.StringSplitOptions]::RemoveEmptyEntries); if( $a.Count -eq 0 ){ write-Output "Ok, array-is-empty"; }
#     But the PS5 version has a bug:
#       [String] $s = "abc".Split("cx"); if( $s -eq "abc" ){ Write-Output "Ok, correct."; }else{ Write-Output "Result='$s' is wrong. We know it happens in PS5, Current-PS-Version: $($PSVersionTable.PSVersion.Major)"; }
#   - Exceptions are always catched within Pipeline Expression statement and instead of expecting the throw it returns $null:
#     [Object[]] $a = @( "a", "b" ) | Select-Object -Property @{Name="Field1";Expression={$_}} |
#       Select-Object -Property Field1,
#       @{Name="Field2";Expression={if($_.Field1 -eq "a" ){ "is_a"; }else{ throw [Exception] "This exc is ignored and instead of throwing up the stack the result of the Expression statement is $null."; } }};
#     $a[0].Field2 -eq "is_a" -and $null -eq $a[1].Field2;  # this is true
#     $a | ForEach-Object{ if( $null -eq $_.Field2 ){ throw [Exception] "Field2 is null"; } } # this does the throw
#     Recommendation: After creation of the list do iterate through it and assert non-null values
#       or redo the expression within a ForEach-Object loop to get correct throwed message.
#   - String without comparison as condition:  Assert ( "anystring" ); Assert ( "$false" );
#   - PS 5/7 is poisoning the current scope by its aliases. See also comments on: ProcessRemoveAllAlias.
#     List all aliases by: alias; For example: Alias curl -> Invoke-WebRequest ; Alias wget -> Invoke-WebRequest ; Alias diff -> Compare-Object ;
#     If we really want to call the curl executable than this is a mess.
#     We strongly recommend to add to your ps5 $profile ($HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1) at least the line:
#       Remove-Item -Force "Alias:curl" -ErrorAction SilentlyContinue; Remove-Item -Force "Alias:wget" -ErrorAction SilentlyContinue;
#     If you have to bypass the curl alias you need to do the following:
#     [String] $curlPath = "$(get-command -CommandType Application curl -ErrorAction SilentlyContinue | Select -First 1 | ForEach-Object{ $_.Source })";
#   - Automatically added folders (2023-02):
#     - ps7: %USERPROFILE%\Documents\PowerShell\Modules\         location for current users for any modules
#     - ps5: %USERPROFILE%\Documents\WindowsPowerShell\Modules\  location for current users for any modules
#     - ps7: %ProgramW6432%\PowerShell\Modules\                  location for all     users for any modules (ps7 and up, multiplatform)
#     - ps7: %ProgramW6432%\powershell\7\Modules\                location for all     users for any modules (ps7 only  , multiplatform)
#     - ps5: %ProgramW6432%\WindowsPowerShell\Modules\           location for all     users for any modules (ps5 and up) and             64bit environment (Example: "C:\Program Files")
#     - ps5: %ProgramFiles(x86)%\WindowsPowerShell\Modules\      location for all     users for any modules (ps5 and up) and             32bit environment (Example: "C:\Program Files (x86")
#     - ps5: %ProgramFiles%\WindowsPowerShell\Modules\           location for all     users for any modules (ps5 and up) and current 64/32 bit environment (Example: "C:\Program Files (x86)" or "C:\Program Files")
#   - Not automatically added but currently strongly recommended additional folder:
#     - %SystemRoot%\System32\WindowsPowerShell\v1.0\Modules\    location for windows modules for all users (ps5 and up)
#       In future if ps7 can completely replace ps5 then we can remove this folder.
#   - Type Mismatch: A function returns a string array: If it returns a single element (=string) then it does not return a string array but the string:
#     function ReturnStringArrayWithOneString(){ return [String[]] @("abc"); } Assert (ReturnStringArrayWithOneString)[0] -eq "a";
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
#     - Precedence of commands: Alias > Function > Filter > Cmdlet > Application > ExternalScript > Script.
#     - Override precedence of commands by using get-command, Example: Get-Command -commandType Application Ping
#     - Very important for empty arguments or arguments with blanks:
#       PS5: If an empty argument should be specified then two quotes as '' or "" or $null or $myEmptyVar
#         do not work (will make the argument not present),
#         it requires '""' or "`"`"" or `"`" or use a blank as " ". This is really a big fail, it is very bad and dangerous!
#         Why is an empty string not handled similar as a filled string?
#         The best workaround is to use ALWAYS escaped double-quotes for EACH argument: & "myexe.exe" `"$arg1`" `"`" `"$arg3`";
#         But even then it is NOT ALLOWED that content contains a double-quote.
#         There is also no proper solution if quotes instead of double-quotes are used.
#         Maybe because these problems there is the recommendation of checker-tools
#         to use options instead of positional arguments to specify parameters.
#         Best recommended solution: Use from our library: ProcessStart $exe $opt -traceCmd:$true;
#       PS7: It works as it should, without additional double-double-quotes.
#     - Resulttype is often [Object[]] (Example: (& dir).GetType()) but can also be [String] (Example: (& echo hi).GetType()).
#       so be careful on applying string functions to it, for example do not use:  (& anycmd).Trim()  but use ([String](& anycmd)).Trim()
#   - Evaluate (string expansion) and run a command given in a string, does not create a new script scope
#     and so works in local scope. Care for code injection.
#       Invoke-Expression [-command] string [CommonParameters]
#     Very important: It performs string expansion before running, so it can be a severe problem if the string contains character $.
#     This behaviour is very bad and so avoid using Invoke-Expression and use & or . operators instead.
#     Example: $cmd1 = "Write-Output `$PSHome"; $cmd2 = "Write-Output $PSHome"; Invoke-Expression $cmd1; Invoke-Expression $cmd2;
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
# - Call module with arguments: Example:  Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1" -ArgumentList $myinvocation.mycommand.Path;
# - FsEntries: -LiteralPath means no interpretation of wildcards
# - Extensions and libraries: https://www.powershellgallery.com/  http://ss64.com/links/pslinks.html
# - Write Portable ps hints: https://powershell.org/2019/02/tips-for-writing-cross-platform-powershell-code/
# - Script Calling Parameters: The expression CmdletBinding for param is optional and so it should not be used anymore:
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
# - Encoding problem on PS5: There is no encoding as UTF8NoBOM, so for UTF8 it generally writes a BOM, alternative code would be:
#   [System.IO.File]::WriteAllLines($f,$lines,(New-Object System.Text.UTF8Encoding $false))
# - More on differences of PS5 and PS7 see: https://learn.microsoft.com/en-us/powershell/scripting/whats-new/differences-from-windows-powershell?view=powershell-7.3
#
