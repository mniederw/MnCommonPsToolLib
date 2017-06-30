# Common powershell tool library
#
# 2013-2017 produced by Marc Niederwieser, Switzerland. This is freeware.
#
# 2017-06-25  V1.0  published as open source to github
#
# This library encapsulates many common commands for the purpose of:
#   Making behaviour compatible for usage with powershell.exe and powershell_ise.exe,
#   fixing problems, supporting tracing information and simplifying commands for documentation.
#
# Notes about common approaches:
# - Typesafe: Functions and its arguments and return values are always specified with its type to assert type reliablility.
# - ANSI/UTF8: Text file contents are written as default as UTF8-BOM. 
#   They are read in ANSI if they have no BOM (byte order mark) or otherwise according to BOM.
#   The reason for this is compatibility to other platforms besides Windows.
# - Indenting format of this file: The statements of the functions below are indented in this way because funtion names should be easy readable as documentation.
# - Notes about tracing information lines:
#   - Progress : Any change of the system will be notified with (Write-Host -ForegroundColor DarkGray). Is enabled as default.
#   - Verbose  : Some read io will be notified with (Write-Verbose) which can be enabled by VerbosePreference.
#   - Debug    : Some minor additional information are notified with (Write-Debug) which can be enabled by DebugPreference.
#
#
# Example usages of this module for a .ps1 script:
#      # my script
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
#      Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "hello world";
#      OutProgress "working";
#      StdInReadLine "Press enter to exit.";
# or
#      # my script
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
#      Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "hello world";
#      StdOutBegMsgCareInteractiveMode; # will ask: if you are sure (y/n)
#      OutProgress "changing anything";
#      StdOutEndMsgCareInteractiveMode; # will write: Ok, done. Press Enter to Exit
# or
#      # my script
#      Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1";
#      Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }
#      OutInfo "hello world";
#      StdOutBegMsgCareInteractiveMode "NoRequestAtBegin, NoWaitAtEnd"; # will nothing write
#      OutProgress "changing anything";
#      StdOutEndMsgCareInteractiveMode; # will write: "Ok, done. Ending in 1 second(s)."



# Do not change the following line, it is a powershell statement and not a comment! Note: if it would be run interactively then it would throw: RuntimeException: Error on creating the pipeline.
#Requires -Version 3.0

Set-StrictMode -Version Latest; # Prohibits: refs to uninit vars, including uninit vars in strings; refs to non-existent properties of an object; function calls that use the syntax for calling methods; variable without a name (${}).
trap [Exception] { $Host.UI.WriteErrorLine($_); break; } # ensure really no exc can continue! Is not called if a catch block is used! It is recommended for client code to use catch blocks for handling exceptions.

# define global variables if they are not yet defined; caller of this script can anytime set or change these variables to control the specified behaviour.
if( -not [Boolean](Get-Variable ModeHideOutProgress      -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeHideOutProgress      -value $false; }
if( -not [Boolean](Get-Variable ModeDisallowInteractions -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeDisallowInteractions -value $false; }
if( -not [Boolean](Get-Variable ModeDisallowElevation    -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeDisallowElevation    -value $false; }
if( -not [String] (Get-Variable ModeNoWaitForEnterAtEnd  -Scope Global -ErrorAction SilentlyContinue) ){ $error.clear(); New-Variable -scope global -name ModeNoWaitForEnterAtEnd  -value $false; }

# set some powershell predefined global variables:
$Global:ErrorActionPreference         = "Stop"                    ; # abort if a called exe will write to stderr, default is 'Continue'.
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
#   $Global:WarningPreference       Continue           # Available: Stop, Inquire, Continue, SilentlyContinue.
#   $Global:ConfirmPreference       High               # Available: None, Low, Medium, High.
#   $Global:WhatIfPreference        False              # Available: False, True.

# we like english error messages
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US');
  # alternatives: [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US'); Set-Culture en-US;

# import some modules
Import-Module -NoClobber -Name "ScheduledTasks";
# for later usage: Import-Module -NoClobber -Name "SmbShare"; Import-Module -NoClobber -Name "SmbWitness";
Add-Type -Name Window -Namespace Console -MemberDefinition '[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);';

# set some self defined constant global variables
if( (Get-Variable -Scope global -ErrorAction SilentlyContinue -Name ComputerName) -eq $null ){ # check wether last variable already exists because reload safe
  New-Variable -option Constant -scope global -name CurrentMonthIsoString   -value ([String](Get-Date -format yyyy-MM)); # alternative: yyyy-MM-dd_HH_mm
  New-Variable -option Constant -scope global -name CurrentWeekIsoString    -value ([String](Get-Date -uformat "YYYY-W%V"));
  New-Variable -option Constant -scope global -name UserQuickLaunchDir      -value ([String]"$env:APPDATA\Microsoft\Internet Explorer\Quick Launch");
  New-Variable -option Constant -scope global -name UserSendToDir           -value ([String]"$env:APPDATA\Microsoft\Windows\SendTo");
  New-Variable -option Constant -scope global -name UserMenuDir             -value ([String]"$env:APPDATA\Microsoft\Windows\Start Menu");
  New-Variable -option Constant -scope global -name UserMenuStartupDir      -value ([String]"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup");
  New-Variable -option Constant -scope global -name AllUsersMenuDir         -value ([String]"$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu");
  New-Variable -option Constant -scope global -name InfoLineColor           -Value $(switch($Host.Name -eq "Windows PowerShell ISE Host"){$true{"Gray"}default{"White"}}); # ise is white so we need a contrast color
  New-Variable -option Constant -scope global -name ComputerName            -value ([String]"$env:computername".ToLower());
}
# ----- exported tools and types -----

function GlobalSetModeVerboseEnable           ( [Boolean] $val = $true ){ $Global:VerbosePreference = $(switch($val){$true{"Continue"}$false{"SilentlyContinue"}}); }
function GlobalSetModeHideOutProgress         ( [Boolean] $val = $true ){ $Global:ModeHideOutProgress      = $val; } # if true then OutProgress does nothing
function GlobalSetModeDisallowInteractions    ( [Boolean] $val = $true ){ $Global:ModeDisallowInteractions = $val; } # if true then any call to read from input will throw, it will not restart script for entering elevated admin mode and after any unhandled exception it does not wait for a key
function GlobalSetModeDisallowElevation       ( [Boolean] $val = $true ){ $Global:ModeDisallowElevation    = $val; } # if true then it will not restart script for entering elevated admin mode
function GlobalSetModeNoWaitForEnterAtEnd     ( [Boolean] $val = $true ){ $Global:ModeNoWaitForEnterAtEnd  = $val; } # if true then it will not wait for enter in StdOutBegMsgCareInteractiveMode

function StringIsNullOrEmpty                  ( [String] $s ){ return [Boolean] [String]::IsNullOrEmpty($s); }
function StringIsNotEmpty                     ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrEmpty($s)); }
function StringIsNullOrWhiteSpace             ( [String] $s ){ return [Boolean] (-not [String]::IsNullOrWhiteSpace($s)); }
function StringSplitIntoLines                 ( [String] $s ){ return [String[]] (($s -replace "`r`n", "`n") -split "`n"); } # for empty string it returns an array with one item.
function StringArrayAddIndent                 ( [String[]] $lines, [Int32] $nrOfBlanks ){ if( $lines -eq $null ){ return [String[]] $null; } return [String[]] ($lines | %{ ((" "*$nrOfBlanks)+$_); }); }
function StringArrayDistinct                  ( [String[]] $lines ){ return [String[]] ($lines | Select-Object -Unique); }
function StringPadRight                       ( [String] $s, [Int32] $len, [Boolean] $doQuote = $false  ){ [String] $r = $s; if( $doQuote ){ $r = '"'+$r+'"'; } return [String] $r.PadRight($len); }
function StringReplaceEmptyByTwoQuotes        ( [String] $str ){ return [String] $(switch((StringIsNullOrEmpty $str)){$true{"`"`""}default{$str}}); }
function StringFromException                  ( [Exception] $ex ){ return [String] "$($ex.GetType().Name): $($ex.Message -replace `"`r`n`",`" `") $($ex.Data|ForEach-Object{`"`r`n Data: $($_.Values)]`"})`r`n StackTrace:`r`n$($ex.StackTrace)"; } # note: .Data is never null.
function DateTimeAsStringForFileName          (){ return [String] (Get-Date -format yyyy-MM-dd_HH_mm); }
function DateTimeAsStringIso                  ( [String] $fmt = "yyyy-MM-dd HH:mm" ){ return [String] (Get-Date -format $fmt); }
function DateTimeAsStringIsoDate              (){ return [String] (DateTimeAsStringIso "yyyy-MM-dd"); }
function DateTimeFromStringAsFormat           ( [String] $s ){ [String] $fmt = "yyyy-MM-dd"; if( $s.Length -gt 16 ){ $fmt = "yyyy-MM-dd_HH_mm_ss"; }elseif( $s.Length -gt 10 ){ $fmt = "yyyy-MM-dd_HH_mm"; } return [DateTime] [datetime]::ParseExact($s,$fmt,$null); }
function ConsoleHide                          (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,0); } #0 hide (also by PowerShell.exe -WindowStyle Hidden)
function ConsoleShow                          (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,5); } #5 nohide
function ConsoleRestore                       (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,1); } #1 show
function ConsoleMinimize                      (){ [Object] $p = [Console.Window]::GetConsoleWindow(); $b = [Console.Window]::ShowWindow($p,6); } #6 minimize
function StdInAssertAllowInteractions         (){ if( $global:ModeDisallowInteractions ){ throw [Exception] "Cannot read for input because all interactions are disallowed, either caller should make sure variable ModeDisallowInteractions is false or he should not call an input method."; } }
function StdInReadLine                        ( [String] $line ){ Write-Host -ForegroundColor Cyan -nonewline $line; StdInAssertAllowInteractions; return [String] (Read-Host); }
function StdInReadLinePw                      ( [String] $line ){ Write-Host -ForegroundColor Cyan -nonewline $line; StdInAssertAllowInteractions; return [System.Security.SecureString] (Read-Host -AsSecureString); }
function StdInAskForEnter                     (){ [String] $line = StdInReadLine "Press Enter to Exit"; }
function StdInWaitForAKey                     (){ StdInAssertAllowInteractions; $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null; } # does not work in powershell-ise, so in general do not use it, use StdInReadLine()
function StdOutLine                           ( [String] $line ){ $Host.UI.WriteLine($line); } # writes an stdout line in default color, normally not used, rather use OutInfo because it gives more information what to output
function StdOutRedLine                        ( [String] $line ){ $Host.UI.WriteErrorLine($line); } # writes an stderr line in red
function StdOutRedLineAndPerformExit          ( [String] $line, [Int32] $delayInSec = 1 ){ StdOutRedLine $line; if( $global:ModeDisallowInteractions ){ ProcessSleepSec $delayInSec; }else{ StdInReadLine "Press Enter to Exit"; }; Exit 1; }
function StdErrHandleExc                      ( [System.Management.Automation.ErrorRecord] $er, [Int32] $delayInSec = 1 ){
                                                [String] $msg = "$(StringFromException $er.Exception)"; # ex: "ArgumentOutOfRangeException: Specified argument was out of the range of valid values. Parameter name: times  at ..."
                                                $msg += "`r`n ScriptStackTrace: `r`n   $($er.ScriptStackTrace -replace `"`r`n`",`"`r`n`   `")"; # ex: at <ScriptBlock>, C:\myfile.psm1: line 800 at MyFunc
                                                $msg += "`r`n InvocationInfo:`r`n   $($er.InvocationInfo.PositionMessage-replace `"`r`n`",`"`r`n`   `" )"; # At D:\myfile.psm1:800 char:83 \n   + ...         } | ForEach-Object {"    ,`@(0,`"-`",`"T`",`"$($_.Name        ... \n   +                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~; 
                                                $msg += "`r`n InvocationInfoLine: $($er.InvocationInfo.Line -replace `"`r`n`",`" `" -replace `"\s+`",`" `" )";
                                                $msg += "`r`n InvocationInfoMyCommand: $($er.InvocationInfo.MyCommand)"; # ex: ForEach-Object
                                                $msg += "`r`n InvocationInfoInvocationName: $($er.InvocationInfo.InvocationName)"; # ex: ForEach-Object
                                                $msg += "`r`n InvocationInfoPSScriptRoot: $($er.InvocationInfo.PSScriptRoot)"; # ex: D:\MyModuleDir
                                                $msg += "`r`n InvocationInfoPSCommandPath: $($er.InvocationInfo.PSCommandPath)"; # ex: D:\Work\PrgCfg\LocalUtility\Modules\AdminCheckAndUpdateSystem.PartManageExecs.psm1
                                                $msg += "`r`n FullyQualifiedErrorId: $($er.FullyQualifiedErrorId)"; # ex: "System.ArgumentOutOfRangeException,Microsoft.PowerShell.Commands.ForEachObjectCommand"
                                                $msg += "`r`n ErrorRecord: $($er.ToString() -replace `"`r`n`",`" `")"; # ex: "Specified argument was out of the range of valid values. Parametername: times"
                                                $msg += "`r`n CategoryInfo: $(switch($er.CategoryInfo -ne $null){$true{$er.CategoryInfo.ToString()}default{''}})"; # https://msdn.microsoft.com/en-us/library/system.management.automation.errorcategory(v=vs.85).aspx
                                                $msg += "`r`n PipelineIterationInfo: $($er.PipelineIterationInfo|ForEach-Object{'$_, '})";
                                                $msg += "`r`n TargetObject: $($er.TargetObject)"; # can be null
                                                $msg += "`r`n ErrorDetails: $(switch($er.ErrorDetails -ne $null){$true{$er.ErrorDetails.ToString()}default{''}})";
                                                $msg += "`r`n PSMessageDetails: $($er.PSMessageDetails)";
                                                StdOutRedLine $msg;
                                                if( $global:ModeDisallowInteractions ){ if( $delayInSec -gt 0 ){ StdOutLine "Waiting for $delayInSec seconds."; } ProcessSleepSec $delayInSec; }else{ StdOutRedLine "Press enter to exit"; Read-Host; } }
function StdPipelineErrorWriteMsg             ( [String] $msg ){ Write-Error $msg; } # does not work in powershell-ise, so in general do not use it, use throw
function StdOutBegMsgCareInteractiveMode      ( [String] $mode = "" ){ # available mode: "NoRequestAtBegin", "NoWaitAtEnd", "MinimizeConsole". Usually this is the first statement in a script after an info line.
                                                ScriptResetRc; [String[]] $modes = @()+($mode -split "," | ForEach-Object { $_.Trim() });
                                                Assert ((@()+($modes | Where-Object { $_ -ne "" -and $_ -ne "NoRequestAtBegin" -and $_ -ne "NoWaitAtEnd" -and $_ -ne "MinimizeConsole"})).Count -eq 0 ) "StdOutBegMsgCareInteractiveMode was called with unknown mode='$mode'";
                                                GlobalSetModeNoWaitForEnterAtEnd ($modes -contains "NoWaitAtEnd");
                                                if( -not $global:ModeDisallowInteractions -and $modes -notcontains "NoRequestAtBegin" ){ StdInAskForAnswerWhenInInteractMode "Are you sure (y/-)? "; }
                                                if( $modes -contains "MinimizeConsole" ){ OutProgress "Minimize console"; ProcessSleepSec 0; ConsoleMinimize; } }
function StdInAskForAnswerWhenInInteractMode  ( [String] $line, [String] $expectedAnswer = "y" ){
                                                if( -not $global:ModeDisallowInteractions ){ [String] $answer = StdInReadLine $line; if( $answer.ToLower() -ne $expectedAnswer ){ StdOutRedLineAndPerformExit "Aborted"; } } }
function StdOutEndMsgCareInteractiveMode      ( [Int32] $delayInSec = 1 ){ if( $global:ModeDisallowInteractions -or $global:ModeNoWaitForEnterAtEnd ){ 
                                                OutSuccess "Ok, done. Ending in $delayInSec second(s)."; ProcessSleepSec $delayInSec; }else{ OutSuccess "Ok, done. Press Enter to Exit;"; StdInReadLine; } }
function Assert                               ( [Boolean] $cond, [String] $msg = "" ){ if( -not $cond ){ throw [Exception] "Assertion failed $msg"; } }
function AssertRcIsOk                         ( [String[]] $linesToOutProgress = $null ){
                                                # can also be called with a single string; only nonempty progress lines are given out
                                                if( ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) -or -not $?) { # if no windows command was done then $LASTEXITCODE is null
                                                  [String] $msg = "Last operation failed [rc=$LASTEXITCODE].";
                                                  $linesToOutProgress | Where-Object { -not [String]::IsNullOrWhiteSpace($_) } | ForEach-Object { OutProgress $_ };
                                                  throw [Exception] $msg; } }
function ScriptGetProcessCommandLine          (){ return [String] ([environment]::commandline); } # ex: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "& \"C:\myscript.ps1\"";
function ScriptResetRc                        (){ $error.clear(); & "cmd.exe" "/C" "EXIT 0"; $error.clear(); AssertRcIsOk; } # reset ERRORLEVEL to 0
function ScriptNrOfScopes                     (){ [Int32] $i = 1; while($true){ 
                                                try{ Get-Variable null -Scope $i -ValueOnly -ErrorAction SilentlyContinue | Out-Null; $i++; 
                                                }catch{ <# ex: System.Management.Automation.PSArgumentOutOfRangeException #> return [Int32] ($i-1); } } }
function ScriptGetDirOfLibModule              (){ return [String] $PSScriptRoot ; } # get dir       of the script file of this function or empty if not from a script; alternative: [String] $f = ScriptGetFileOfLibModule; if( $f -eq "" ){ return [String] ""; } return [String] (FsEntryGetParentDir $f);
function ScriptGetFileOfLibModule             (){ return [String] $PSCommandPath; } # get full path of the script file of this function or empty if not from a script. alternative1: try{ return [String] (Get-Variable MyInvocation -Scope 1 -ValueOnly).MyCommand.Path; }catch{ return [String] ""; }  alternative2: $script:MyInvocation.MyCommand.Path
function ScriptGetCallerOfLibModule           (){ return [String] $MyInvocation.PSCommandPath; } # return empty if called interactive. alternative for dir: $MyInvocation.PSScriptRoot
function ScriptGetTopCaller                   (){ [String] $f = $global:MyInvocation.MyCommand.Definition.Trim(); # return empty if called interactive. usage ex: "&'C:\Temp\A.ps1'" or '&"C:\Temp\A.ps1"' or on ISE '"C:\Temp\A.ps1"'
                                                if( $f -eq "" -or $f -eq "ScriptGetTopCaller" ){ return ""; }
                                                if( $f.StartsWith("&") ){ $f = $f.Substring(1,$f.Length-1).Trim(); }
                                                if( ($f -match "^\'.+\'$") -or ($f -match "^\`".+\`"$") ){ $f = $f.Substring(1,$f.Length-2); }
                                                return [String] $f; }
function StreamAllProperties                  (){ $input | Select-Object *; }
function StreamAllPropertyTypes               (){ $input | Get-Member -Type Property; }
function StreamFilterWhitespaceLines          (){ $input | Where-Object { -not [String]::IsNullOrWhiteSpace($_) }; }
function StreamToNull                         (){ $input | Out-Null; }
function StreamToString                       (){ $input | Out-String -Width 999999999; }
function StreamToStringDelEmptyLeadAndTrLines (){ $input | Out-String -Width 999999999 | ForEach-Object { $_ -replace "[ \f\t\v]]+\r\n","\r\n" -replace "^(\r\n)+","" -replace "(\r\n)+$","" }; }
function StreamToGridView                     (){ $input | Out-GridView -Title "TableData"; }
function StreamToCsvStrings                   (){ $input | ConvertTo-Csv -NoTypeInformation; }
function StreamToJsonString                   (){ $input | ConvertTo-Json -Depth 999999999; }
function StreamToJsonCompressedString         (){ $input | ConvertTo-Json -Depth 999999999 -Compress; }
function StreamToXmlString                    (){ $input | ConvertTo-Xml -Depth 999999999 -As String -NoTypeInformation; }
function StreamToHtmlTableStrings             (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As Table; }
function StreamToHtmlListStrings              (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As List; }
function StreamToListString                   (){ $input | Format-List -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToFirstPropMultiColumnString   (){ $input | Format-Wide -AutoSize -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToCsvFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){
                                                $input | Export-Csv -Force:$overwrite -NoClobber:$(-not $overwrite) -NoTypeInformation -Encoding $encoding -Path (FsEntryEsc $file); }
function StreamToXmlFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){
                                                $input | Export-Clixml -Force:$overwrite -NoClobber:$(-not $overwrite) -Depth 999999999 -Encoding $encoding -Path (FsEntryEsc $file);}
function StreamToDataRowsString               ( [String[]] $propertyNames ){ if( $propertyNames -eq $null -or $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); } 
                                                $input | Format-Table -Wrap -Force -autosize -HideTableHeaders $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function StreamToTableString                  ( [String[]] $propertyNames ){ if( $propertyNames -eq $null -or $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); } 
                                                $input | Format-Table -Wrap -Force -autosize $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
function OutInfo                              ( [String] $line ){ Write-Host -ForegroundColor $InfoLineColor $line; }
function OutWarning                           ( [String] $line, [Int32] $indentLevel = 1 ){ Write-Host -ForegroundColor Yellow (("  "*$indentLevel)+$line); }
function OutSuccess                           ( [String] $line ){ Write-Host -ForegroundColor Green    $line; }
function OutProgress                          ( [String] $line, [Int32] $indentLevel = 1 ){ if( $Global:ModeHideOutProgress ){ return; } Write-Host -ForegroundColor DarkGray (("  "*$indentLevel) +$line); } # used for tracing changing actions, otherwise use OutVerbose
function OutProgressText                      ( [String] $str  ){ if( $Global:ModeHideOutProgress ){ return; } Write-Host -ForegroundColor DarkGray -nonewline $str; }
function OutVerbose                           ( [String] $line ){ Write-Verbose -Message $line; } # output depends on $VerbosePreference, used tracing read or network operations
function OutDebug                             ( [String] $line ){ Write-Debug -Message $line; } # output depends on $DebugPreference, used tracing read or network operations
function OutWarnIfRcNotOkAndResetRc           ( [String] $msg ){ if( ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) -or -not $?) { OutWarning "Last operation failed [rc=$LASTEXITCODE]. $msg"; ScriptResetRc; } }
function OutClear                             (){ Clear-Host; }
function ProcessIsRunningInElevatedAdminMode  (){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
function ProcessAssertInElevatedAdminMode     (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){ throw [Exception] "Assertion failed because requires to be in elevated admin mode"; } }
function ProcessRestartInElevatedAdminMode    (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){
                                                [String[]] $topCallerArguments = @(); # currently it supports no arguments because we do not know how to access them (something like $global:args would be nice)
                                                [String[]] $cmd = @( (ScriptGetTopCaller) ) + $topCallerArguments;
                                                if( $Global:ModeDisallowInteractions -or $Global:ModeDisallowElevation ){ 
                                                  [String] $msg = "Script is currently not in elevated admin mode but the proceeding statements would require it. "
                                                  $msg += "The calling script=`"$cmd`" has the modes ModeDisallowInteractions=$Global:ModeDisallowInteractions and ModeDisallowElevation=$Global:ModeDisallowElevation, ";
                                                  $msg += "if both of them would be reset then it would try to restart script here to enter the elevated admin mode. ";
                                                  $msg += "Now it will continue but it will probably fail."; 
                                                  OutWarning $msg;
                                                }else{
                                                  OutProgress "Not running in elevated administrator mode so elevate current script and exit: $cmd"; 
                                                  Start-Process -Verb "RunAs" -FilePath "powershell.exe" -ArgumentList "& `"$cmd`" "; # ex: InvalidOperationException: This command cannot be run due to the error: Der Vorgang wurde durch den Benutzer abgebrochen.
                                                  # AssertRcIsOk; seams not to be nessessary
                                                  [Environment]::Exit("0"); # note: 'Exit 0;' would only leave the last '. mycommand' statement.
                                                  throw [Exception] "Exit done, but it did not work, so it throws now an exception.";
                                                } } }
function ProcessListRunnings                  (){ return (Get-Process * | Where-Object {$_.Id -ne 0} | Sort-Object ProcessName); }
function ProcessListRunningsAsStringArray     (){ return (ProcessListRunnings | Format-Table -auto -HideTableHeaders " ",ProcessName,ProductVersion,Company | StreamToStringDelEmptyLeadAndTrLines); }
function ProcessIsRunning                     ( [String] $processName ){ return [Boolean] ((Get-Process -ErrorAction SilentlyContinue $processName) -ne $null); }
function ProcessKill                          ( [String] $processName ){ [Object] $p = Get-Process ($processName -replace ".exe","") -ErrorAction SilentlyContinue; 
                                                if( $p -ne $null ){ OutProgress "ProcessKill $processName"; ProcessRestartInElevatedAdminMode; $p.Kill(); } }
function ProcessSleepSec                      ( [Int32] $sec ){ Start-Sleep -s $sec; }
function ProcessListInstalledAppx             (){ return [String[]] (Get-AppxPackage | Select-Object PackageFullName | Sort PackageFullName); }
function ProcessGetCommandInEnvPathOrAltPaths ( [String] $commandNameOptionalWithExtension, [String[]] $alternativePaths = @() ){
                                                [System.Management.Automation.CommandInfo] $cmd = Get-Command -CommandType Application -Name $commandNameOptionalWithExtension -ErrorAction SilentlyContinue;
                                                if( $cmd -ne $null ){ return [String] $cmd.Path; }
                                                foreach( $d in $alternativePaths ){ [String] $f = (Join-Path $d $commandNameOptionalWithExtension); if( (FileExists $f) ){ return $f; } }
                                                throw [Exception] "ProcessGetCommandInEnvPathOrDirs: commandName='$commandNameOptionalWithExtension' was wether found in env-path='$env:PATH' nor in alternativePaths='$alternativePaths'"; }
function HelpHelp                             (){ Get-Help     | ForEach-Object { OutInfo $_; } }
function HelpListOfAllVariables               (){ Get-Variable | Sort-Object Name | ForEach-Object { OutInfo "$($_.Name.PadRight(32)) $($_.Value)"; } } # Select-Object Name, Value | StreamToListString
function HelpListOfAllAliases                 (){ Get-Alias    | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object { OutInfo $_; } }
function HelpListOfAllCommands                (){ Get-Command  | Select-Object CommandType, Name, Version, Source | StreamToTableString | ForEach-Object { OutInfo $_; } }
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
function FsEntryPrivAclAsString               ( [System.Security.AccessControl.FileSystemSecurity] $acl ){
                                                [String] $s = "Owner=$($acl.Owner);Group=$($acl.Group);Acls="; foreach( $a in $acl.Access){ $s += PrivFsRuleAsString $a; } return [String] $s; }
function PrivAclSetProtection                 ( [Object] $acl, [Boolean] $accessRuleProtection, [Boolean] $auditRuleProtection ){ $acl.SetAccessRuleProtection($accessRuleProtection, $auditRuleProtection); }
function PrivFsRuleCreate                     ( [System.Security.Principal.IdentityReference] $account, [System.Security.AccessControl.FileSystemRights] $rights,
                                                [System.Security.AccessControl.InheritanceFlags] $inherit, [System.Security.AccessControl.PropagationFlags] $propagation, [System.Security.AccessControl.AccessControlType] $access ){ 
                                                # combinations see: https://msdn.microsoft.com/en-us/library/ms229747(v=vs.100).aspx
                                                # https://technet.microsoft.com/en-us/library/ff730951.aspx  Rights=(AppendData,ChangePermissions,CreateDirectories,CreateFiles,Delete,DeleteSubdirectoriesAndFiles,ExecuteFile,FullControl,ListDirectory,Modify,Read,ReadAndExecute,ReadAttributes,ReadData,ReadExtendedAttributes,ReadPermissions,Synchronize,TakeOwnership,Traverse,Write,WriteAttributes,WriteData,WriteExtendedAttributes) Inherit=(ContainerInherit,ObjectInherit,None) Propagation=(InheritOnly,NoPropagateInherit,None) Access=(Allow,Deny)
                                                return [System.Security.AccessControl.FileSystemAccessRule] (New-Object System.Security.AccessControl.FileSystemAccessRule($account, $rights, $inherit, $propagation, $access)); }
function PrivFsRuleCreateFullControl          ( [System.Security.Principal.IdentityReference] $account, [Boolean] $useInherit ){ # for dirs usually inherit is used
                                                [System.Security.AccessControl.InheritanceFlags] $inh = switch($useInherit){ $false{[System.Security.AccessControl.InheritanceFlags]::None} $true{[System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"} };
                                                [System.Security.AccessControl.PropagationFlags] $prf = switch($useInherit){ $false{[System.Security.AccessControl.PropagationFlags]::None} $true{[System.Security.AccessControl.PropagationFlags]::None                          } }; # alternative [System.Security.AccessControl.PropagationFlags]::InheritOnly
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
function PrivFsSecurityHasFullControl         ( [System.Security.AccessControl.FileSystemSecurity] $acl, [System.Security.Principal.IdentityReference] $account, [Boolean] $isDir ){
                                                $a = $acl.Access | Where-Object { $_.IdentityReference -eq $account } |
                                                   Where-Object { $_.FileSystemRights -eq "FullControl" -and $_.AccessControlType -eq "Allow" } |
                                                   Where-Object { -not $isDir -or ($_.InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ContainerInherit) -and $_.InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ObjectInherit)) };
                                                   Where-Object { -not $isDir -or $_.PropagationFlags -eq [System.Security.AccessControl.PropagationFlags]::None }
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
                                                  throw [Exception] "RegistrySetValue($key,$name) failed because $($_.Exception.Message) (often it requires elevated mode)"; } }                                                
function RegistryImportFile                   ( [String] $regFile ){
                                                OutProgress "RegistryImportFile '$regFile'"; FileAssertExists $regFile; 
                                                try{ <# stupid, it writes success to stderr #> & "$env:SystemRoot\system32\reg.exe" "IMPORT" $regFile 2>&1 | Out-Null; AssertRcIsOk; 
                                                }catch{ <# ignore always: System.Management.Automation.RemoteException Der Vorgang wurde erfolgreich beendet. #> [String] $expectedMsg = "Der Vorgang wurde erfolgreich beendet."; 
                                                  if( $_.Exception.Message -ne $expectedMsg ){ throw [Exception] "RegistryImportFile '$regFile' failed. We expected an exc but this must match '$expectedMsg' but we got: '$($_.Exception.Message)'"; } ScriptResetRc; } }
function RegistryKeyGetAcl                    ( [String] $key ){
                                                return [System.Security.AccessControl.RegistrySecurity] (Get-Acl -Path $key); } # must be called with shortkey form
function RegistryKeyGetHkey                   ( [String] $key ){
                                                if    ( $key.StartsWith("HKLM:") ){ return [Microsoft.Win32.Registry]::LocalMachine; }  # Note: we must return result immediatly because we had problems if it would be stored in a variable
                                                elseif( $key.StartsWith("HKCU:") ){ return [Microsoft.Win32.Registry]::CurrentUser; }
                                                elseif( $key.StartsWith("HKCR:") ){ return [Microsoft.Win32.Registry]::ClassesRoot; }
                                                elseif( $key.StartsWith("HKCC:") ){ return [Microsoft.Win32.Registry]::CurrentConfig; }
                                                elseif( $key.StartsWith("HKPD:") ){ return [Microsoft.Win32.Registry]::PerformanceData; }
                                                elseif( $key.StartsWith("HKU:" ) ){ return [Microsoft.Win32.Registry]::Users; }
                                                else{ throw [Exception] "Unknown HKey in: '$key'"; } }
function RegistryKeyGetSubkey                 ( [String] $key ){ 
                                                return [String] $key.Split(":",2)[1]; }
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
                                                }catch{ throw [Exception] "RegistryKeySetOwnerForced($key,$account) failed because $($_.Exception.Message)"; } }
function RegistryKeySetAccessRuleForced       ( [String] $key, [System.Security.AccessControl.RegistryAccessRule] $rule ){ # use this if object is protected by TrustedInstaller
                                                ProcessRestartInElevatedAdminMode; PrivEnableTokenPrivilege SeTakeOwnershipPrivilege; PrivEnableTokenPrivilege SeRestorePrivilege;
                                                try{ [Object] $k = (RegistryKeyGetHkey $key).OpenSubKey((RegistryKeyGetSubkey $key),[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership);
                                                  [Object] $acl = $k.GetAccessControl();
                                                  $acl.SetAccessRule($rule); <# alternative: AddAccessRule #> $k.SetAccessControl($acl); $k.Close(); 
                                                }catch{ throw [Exception] "RegistryKeySetAccessRuleForced($key,$rule) failed because $($_.Exception.Message)"; } }
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
                                                [String] $out = & "$env:SystemRoot\system32\POWERCFG.EXE" "-AVAILABLESLEEPSTATES" | Where-Object {   
                                                  $_ -like "Die folgenden Standbymodusfunktionen sind auf diesem System verf*" -or $_ -like "Die folgenden Ruhezustandfunktionen sind auf diesem System verf*" }; 
                                                AssertRcIsOk; return [Boolean] ((($out.Contains("Ruhezustand") -or $out.Contains("Hibernate"))) -and (FileExists "$env:SystemDrive\hiberfil.sys")); }
function ServiceListRunnings                  (){ 
                                                return (Get-Service * | Where-Object {$_.Status -eq "Running"} | Sort-Object Name | Format-Table -auto -HideTableHeaders " ",Name,DisplayName | StreamToStringDelEmptyLeadAndTrLines); }
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
                                                  OutProgress "ServiceSetStartType '$serviceName' $startType"; 
                                                  if( $s.StartType -ne $startTypeExt ){ 
                                                    ProcessRestartInElevatedAdminMode;
                                                    try{ Set-Service -Name $serviceName -StartupType $startTypeExt; }catch{ #ex: for aswbIDSAgent which is antivir protection we got: ServiceCommandException: Service ... cannot be configured due to the following error: Zugriff verweigert
                                                      if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                      OutWarning "ignore failing of ServiceSetStartType($serviceName,$startType) because $($_.Exception.Message)";
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
                                                [String] $result = (Get-Service * | ForEach-Object Name | Where-Object { $_ -like $mask } | Sort | Select -First 1);
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
function FsEntryGetAbsolutePath               ( [String] $fsEntry ){ 
                                                return [String] ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fsEntry)); }
                                                # note: we cannot use (Resolve-Path -LiteralPath $fsEntry) because it will throw if path not exists, see http://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist
function FsEntryHasTrailingBackslash          ( [String] $fsEntry ){ return [Boolean] $fsEntry.EndsWith("\"); }
function FsEntryRemoveTrailingBackslash       ( [String] $fsEntry ){ 
                                                [String] $result = $fsEntry; if( $result -ne "" ){ while( $result.EndsWith("\") ){ $result = $result.Remove($result.Length-1); }
                                                if( $result -eq "" ){ $result = $fsEntry; } } return [String] $result; } # leading backslashes are not removed.
function FsEntryMakeTrailingBackslash         ( [String] $fsEntry ){ 
                                                [String] $result = $fsEntry; if( -not $result.EndsWith("\") ){ $result += "\"; } return [String] $result; }
function FsEntryJoinRelativePatterns          ( [String] $dir, [String[]] $relativeFsEntriesPatternsSemicolonSeparated ){
                                                # dir patterns must be specified by a trailing backslash. 
                                                # ex: $relativeFsEntriesPatternsSemicolonSeparated = @( ".\dir;bin\;bin?\;obj\;", ".\dir;*.tmp;*.suo;", ".\dir\d1\", ".\dir\file*.txt");
                                                return [String[]] ($relativeFsEntriesPatternsSemicolonSeparated.Split(";") | Where-Object { $_ -ne "" } | ForEach-Object { "$dir\$_" }); }
function FsEntryGetFileNameWithoutExt         ( [String] $fsEntry ){ 
                                                return [String] [System.IO.Path]::GetFileNameWithoutExtension($fsEntry); }
function FsEntryGetFileName                   ( [String] $fsEntry ){ 
                                                return [String] [System.IO.Path]::GetFileName($fsEntry); }
function FsEntryMakeAbsolutePath              ( [String] $dirWhenFsEntryIsRelative, [String] $fsEntryRelativeOrAbsolute ){ 
                                                return [String] (FsEntryGetAbsolutePath ([System.IO.Path]::Combine($dirWhenFsEntryIsRelative,$fsEntryRelativeOrAbsolute))); }
function FsEntryGetDrive                      ( [String] $fsEntry ){ # ex: "C:"
                                                return [String] (Split-Path -Qualifier (FsEntryGetAbsolutePath $fsEntry)); }
function FsEntryIsDir                         ( [String] $fsEntry ){ return [Boolean] (Get-Item -Force -LiteralPath $fsEntry).PSIsContainer; }
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
function FsEntryNotExistsOrIsOlderThanNrDays  ( [String] $fsEntry, [Int32] $maxAgeInDays ){ 
                                                return [Boolean] ((FsEntryNotExists $fsEntry) -or ((Get-Item -Force -LiteralPath $fsEntry).LastWriteTime.AddDays($maxAgeInDays) -lt (Get-Date))); }
function FsEntrySetAttributeReadOnly          ( [String] $fsEntry, [Boolean] $val ){ 
                                                OutProgress "FsFileSetAttributeReadOnly $fsEntry $val"; Set-ItemProperty (FsEntryEsc $fsEntry) -name IsReadOnly -value $val; }
function FsEntryFindFlatSingleByPattern       ( [String] $fsEntryPattern ){ 
                                                [System.IO.FileSystemInfo[]] $r = @()+(Get-ChildItem -Force -ErrorAction SilentlyContinue -Path $fsEntryPattern);
                                                if( $r.Count -eq 0 ){ throw [Exception] "No file exists: '$fsEntryPattern'"; }
                                                if( $r.Count -gt 1 ){ throw [Exception] "More than one file exists: '$fsEntryPattern'"; }
                                                return [String] $r[0].FullName; }
function FsEntryListAsFileSystemInfo          ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true ){
                                                # List entries specified by a pattern, which applies to files and directories and which can contain wildards (*,?). 
                                                # Output is unsorted. Ignores case and access denied conditions. If not found an entry then an empty array is returned.
                                                # It works with absolute or relative paths. A leading ".\" for relative paths is optional.
                                                # If recursive is specified then it tries to match pattern in each sub dir.
                                                # Wildcards on parent dir parts are also allowed ("dir*\*.tmp","*\*.tmp").
                                                # If no wildcards are used and then behaviour is the following: 
                                                #   In non-recursive mode and if pattern matches a file (".\f.txt") then it is listed, and if pattern matches a dir (".\dir") its content is listed flat.
                                                #   In recursive mode the last backslash separated part of the pattern ("f.txt" or "dir") is searched in two steps,
                                                #   first if it matches a file (".\f.txt") then it is listed, and if matches a dir (".\dir") then its content is listed deeply,
                                                #   second if pattern was not yet found then searches it recursively but if it is a dir then its content is not listed.
                                                # Trailing backslashes would be handled in powershell quite curious: 
                                                #   In non-recursive mode they are handled as they are not present, so files are also matched ("*\myfile\").
                                                #   In recursive mode they wrongly match only files and not directories ("*\myfile\").
                                                # So we interpret a trailing backslash as it would not be present but it overwrites the arguments (includeDirs=$true,$includeFiles=$false)
                                                #   and then in recursive mode you should not use parent dir parts ("*\dir\" or "d1\dir\") because it would not find find them for unknown reasons.
                                                #   But we improve the case when pattern contains "\*\" by also try to find it at top position by using replaced pattern ("\.\").
                                                # Examples for fsEntryPattern: "C:\*.tmp", ".\dir\*.tmp", "dir\te?*.tmp", "*\dir\*.tmp", "dir\*", "bin\".
                                                Assert ($fsEntryPattern -ne "") "pattern is empty";
                                                [String] $pa = $fsEntryPattern;
                                                [Boolean] $trailingBackslashMode = (FsEntryHasTrailingBackslash $pa);
                                                if( $trailingBackslashMode ){
                                                  $pa = FsEntryRemoveTrailingBackslash $pa;
                                                  $includeDirs = $true; $includeFiles = $false;
                                                }
                                                OutVerbose "FsEntryListAsFileSystemInfo '$pa' recursive=$recursive includeDirs=$includeDirs includeFiles=$includeFiles";
                                                [System.IO.FileSystemInfo[]] $result = @();
                                                if( $trailingBackslashMode -and $pa.Contains("\*\") ){
                                                  # handle that ".\*\dir\" would also find top dir
                                                  $result += (Get-Item -Force -ErrorAction SilentlyContinue -Path $pa.Replace("\*\","\.\"));
                                                }
                                                $result += (Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse:$recursive -Path $pa | 
                                                  Where-Object { ($includeDirs -and $includeFiles) -or ($includeDirs -and $_.PSIsContainer) -or ($includeFiles -and -not $_.PSIsContainer) });
                                                return $result; }
function FsEntryListAsStringArray             ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true ){
                                                # Output of directories will have a trailing backslash. more see FsEntryListAsFileSystemInfo.
                                                return [String[]] (@()+(FsEntryListAsFileSystemInfo $fsEntryPattern $recursive $includeDirs $includeFiles |
                                                  ForEach-Object { $_.FullName+$(switch($_.PSIsContainer){True{"\"}default{""}}) })); }
function FsEntryDelete                        ( [String] $fsEntry ){ 
                                                if( $fsEntry.EndsWith("\") ){ DirDelete $fsEntry; }else{ FileDelete $fsEntry; } }
function FsEntryRename                        ( [String] $fsEntryFrom, [String] $fsEntryTo ){ 
                                                OutProgress "FsEntryRename '$fsEntryFrom' '$fsEntryTo'"; 
                                                FsEntryAssertExists $fsEntryFrom; FsEntryAssertNotExists $fsEntryTo; 
                                                Rename-Item -Path (FsEntryGetAbsolutePath (FsEntryRemoveTrailingBackslash $fsEntryFrom)) -newName (FsEntryGetAbsolutePath (FsEntryRemoveTrailingBackslash $fsEntryTo)) -force; }
function FsEntryCreateDirSymLink              ( [String] $symLinkDir, [String] $symLinkOriginDir ){
                                                if( !(DirExists $symLinkOriginDir)  ){ throw [Exception] "Cannot create dir sym link because original directory not exists: '$symLinkOriginDir'"; }
                                                FsEntryAssertNotExists $symLinkDir "Cannot create dir sym link";
                                                [String] $cd = Get-Location;
                                                Set-Location (FsEntryGetParentDir $symLinkDir);
                                                [String] $symLinkName = FsEntryGetFileName $symLinkDir;
                                                & "cmd.exe" "/c" ('mklink /J "'+$symLinkName+'" "'+$symLinkOriginDir+'"'); AssertRcIsOk;
                                                Set-Location $cd; }
function FsEntryReportMeasureInfo             ( [String] $fsEntry ){ # works recursive
                                                [Microsoft.PowerShell.Commands.GenericMeasureInfo] $size = Get-ChildItem -Force -ErrorAction SilentlyContinue -Recurse -LiteralPath $fsEntry |
                                                Measure-Object -Property length -sum; return [String] "SizeInBytes=$($size.sum); NrOfFsEntries=$($size.count);"; }
function FsEntryCreateParentDir               ( [String] $fsEntry ){ [String] $dir = FsEntryGetParentDir $fsEntry; DirCreate $dir; }
function FsEntryMoveByPatternToDir            ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $showProgressFiles = $false ){ # target dir must exists
                                                OutProgress "FsEntryMoveByPatternToDir '$fsEntryPattern' to '$targetDir'"; DirExistsAssert $targetDir;
                                                FsEntryListAsStringArray $fsEntryPattern | Sort-Object | 
                                                  ForEach-Object { if( $showProgressFiles ){ OutProgress "Source: $_"; }; Move-Item -Force -Path $_ -Destination (FsEntryEsc $targetDir); }; }
function FsEntryCopyByPatternByOverwrite      ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $continueOnErr = $false ){ 
                                                OutProgress "FsEntryCopyByPatternByOverwrite '$fsEntryPattern' to '$targetDir' continueOnErr=$continueOnErr"; 
                                                DirCreate $targetDir; Copy-Item -ErrorAction SilentlyContinue -Recurse -Force -Path $fsEntryPattern -Destination (FsEntryEsc $targetDir); 
                                                if( -not $? ){ if( ! $continueOnErr ){ AssertRcIsOk; }else{ OutWarning "CopyFiles '$fsEntryPattern' to '$targetDir' failed, will continue"; } } }
function FsEntryFindNotExistingVersionedName  ( [String] $fsEntry, [String] $ext = ".bck", [Int32] $maxNr = 9999 ){ # return ex: "C:\Dir\MyName.001.bck"
                                                $fsEntry = (FsEntryGetAbsolutePath $fsEntry);
                                                while( $fsEntry.EndsWith('\') ){ $fsEntry = $fsEntry.Remove($fsEntry.Length-1); }
                                                if( $fsEntry.EndsWith('\') ){ throw [Exception] "FsEntryFindNotExistingVersionedName($fsEntry) not available because has trailing backslash"; }
                                                if( $fsEntry.Length -gt (260-4-$ext.Length) ){ throw [Exception] "FsEntryFindNotExistingVersionedName($fsEntry,$ext) not available because fullpath longer than 260-4-extLength"; }
                                                [Int32] $n = 1; do{ [String] $newFs = $fsEntry + "." + $n.ToString("D3")+$ext; if( (FsEntryNotExists $newFs) ){ return [String] $newFs; } $n += 1; }until( $n -gt $maxNr );
                                                throw [Exception] "FsEntryFindNotExistingVersionedName($fsEntry,$ext,$maxNr) not available because reached maxNr"; }
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
                                                  FsEntryListAsStringArray "$fsEntry\*" $false | ForEach-Object { FsEntryAclRuleWrite $modeSetAddOrDel $_ $rule $true };
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
                                                    FsEntryListAsStringArray "$fs\*" $false | ForEach-Object { FsEntryTrySetOwner $_ $account $true };
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
                                                if( -not (PrivFsSecurityHasFullControl $acl $account $isDir) ){
                                                  FsEntryAclRuleWrite Set $fsEntry $rule $false;
                                                }
                                                if( $recursive -and $isDir ){
                                                  FsEntryListAsStringArray "$fsEntry\*" $false | ForEach-Object { FsEntryTrySetOwnerAndAclsIfNotSet $_ $account $true };
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
function DriveFreeSpace                       ( [String] $drive ){ 
                                                return [Int64] (Get-PSDrive $drive | Select-Object -ExpandProperty Free); }
function DirExists                            ( [String] $dir ){ 
                                                try{ return [Boolean] (Test-Path -PathType Container -path (FsEntryEsc $dir) ); }catch{ throw [Exception] "DirExists($dir) failed because $($_.Exception.Message)"; } }
function DirExistsAssert                      ( [String] $dir ){ 
                                                if( -not (DirExists $dir) ){ throw [Exception] "Dir not exists: '$dir'."; } }
function DirCreate                            ( [String] $dir ){ 
                                                New-Item -type directory -Force (FsEntryEsc $dir) | Out-Null; } # create dir if it not yet exists,;we do not call OutProgress because is not an important change.
function DirDelete                            ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                # remove dir recursively if it exists, be careful when using this.
                                                if( (DirExists $dir) ){ 
                                                  try{ OutProgress "DirDelete$(switch($ignoreReadonly){$true{''}default{'CareReadonly'}}) '$dir'"; Remove-Item -Force:$ignoreReadonly -Recurse -LiteralPath $dir; 
                                                  }catch{ <# ex: Für das Ausführen des Vorgangs sind keine ausreichenden Berechtigungen vorhanden. #> 
                                                    throw [Exception] "DirDelete$(switch($ignoreReadonly){$true{''}default{'CareReadonly'}})('$dir') failed because $($_.Exception.Message) (maybe locked or readonly files exists)"; } } }
function DirDeleteContent                     ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                # remove dir content if it exists, be careful when using this.
                                                if( (DirExists $dir) -and (@()+(Get-ChildItem -Force -Directory -LiteralPath $dir)).Count -gt 0 ){ 
                                                  try{ OutProgress "DirDeleteContent$(switch($ignoreReadonly){$true{''}default{'CareReadonly'}}) '$dir'"; 
                                                    Remove-Item -Force:$ignoreReadonly -Recurse "$(FsEntryEsc $dir)\*"; 
                                                  }catch{ <# ex: Für das Ausführen des Vorgangs sind keine ausreichenden Berechtigungen vorhanden. #> 
                                                    throw [Exception] "DirDeleteContent$(switch($ignoreReadonly){$true{''}default{'CareReadonly'}})('$dir') failed because $($_.Exception.Message) (maybe locked or readonly files exists)"; } } }
function DirDeleteIfIsEmpty                   ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
                                                if( (DirExists $dir) -and (@()+(Get-ChildItem -Force -LiteralPath $dir)).Count -eq 0 ){ DirDelete $dir; } }
function DirCopyToParentDirByAddAndOverwrite  ( [String] $srcDir, [String] $tarParentDir ){ 
                                                OutProgress "DirCopyToParentDirByAddAndOverwrite '$srcDir' to '$tarParentDir'"; 
                                                if( -not (DirExists $srcDir) ){ throw [Exception] "Missing source dir '$srcDir'"; } 
                                                DirCreate $tarParentDir; Copy-Item -Force -Recurse (FsEntryEsc $srcDir) (FsEntryEsc $tarParentDir); }
function FileGetSize                          ( [String] $file ){ 
                                                return [Int64] (Get-ChildItem -Force -File -LiteralPath $file).Length; }
function FileExists                           ( [String] $file ){ 
                                                if( $file -eq "" ){ throw [Exception] "FileExists: Empty file name not allowed"; } 
                                                [String] $f2 = FsEntryGetAbsolutePath $file; if( Test-Path -PathType Leaf -Path $f2 ){ return $true; } # todo literalpath
                                                # Note: Known bug: Test-Path does not work for hidden and system files, so we need an additional check.
                                                # Note2: The following would not works on vista and win7-with-ps2: [String] $d = Split-Path $f2; return ([System.IO.Directory]::EnumerateFiles($d) -contains $f2);
                                                return [System.IO.File]::Exists($f2); }
function FileNotExists                        ( [String] $file ){ 
                                                return [Boolean] -not (FileExists $file); }
function FileAssertExists                     ( [String] $file ){ 
                                                if( (FileNotExists $file) ){ throw [Exception] "File not exists: '$file'."; } }
function FileExistsAndIsNewer                 ( [String] $ftar, [String] $fsrc ){ 
                                                FileAssertExists $fsrc; return [Boolean] ((FileExists $ftar) -and ((Get-Item -Force -LiteralPath $ftar).LastWriteTime -ge (Get-Item -Force -LiteralPath $fsrc).LastWriteTime)); }
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
function FileAppendLine                       ( [String] $file, [String] $line ){ 
                                                FsEntryCreateParentDir $file; Out-File -Encoding Default -Append -LiteralPath $file -InputObject $line; }
function FileAppendLines                      ( [String] $file, [String[]] $lines ){ 
                                                FsEntryCreateParentDir $file; $lines | Out-File -Encoding Default -Append -LiteralPath $file; }
function FileGetTempFile                      (){ 
                                                return [Object] [System.IO.Path]::GetTempFileName(); }
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
                                                OutProgress "Touch: `"$file`""; [String[]] $out = & "touch.exe" $file; AssertRcIsOk; }
function FileContentsAreEqual                 ( [String] $f1, [String] $f2 ){ # first file must exist, second file does not have to exist
                                                FileAssertExists $f1;
                                                if( (FileExists $f2) -and ((Get-Item -Force -LiteralPath $f1).Length -eq (Get-Item -Force -LiteralPath $f2).Length) ){
                                                  & "fc.exe" "/b" (FsEntryEsc $f1) (FsEntryEsc $f2) > $null;
                                                  if( $? ){ return $true; }
                                                  ScriptResetRc;
                                                  # alternative when more than one file should be compared: (Get-FileHash $Filepath1).Hash -eq (Get-FileHash $Filepath2).Hash
                                                }
                                                return $false; }
function FileDelete                           ( [String] $file, [Boolean] $ignoreReadonly = $true ){
                                                if( (FileExists $file) ){ OutProgress "FileDelete$(switch($ignoreReadonly){$true{''}default{'CareReadonly'}}) '$file'"; 
                                                  Remove-Item -Force:$ignoreReadonly -LiteralPath $file; } }
function FileCopy                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){ 
                                                OutProgress "FileCopy(Overwrite=$overwrite) '$srcFile' to '$tarFile'"; 
                                                FsEntryCreateParentDir $tarFile; Copy-Item -Force:$overwrite (FsEntryEsc $srcFile) (FsEntryEsc $tarFile); }
function DriveMapTypeToString                 ( [UInt32] $driveType ){
                                                return [String] $(switch($driveType){ 1{"NoRootDir"} 2{"RemovableDisk"} 3{"LocalDisk"} 4{"NetworkDrive"} 5{"CompactDisk"} 6{"RamDisk"} default{"UnknownDriveType=driveType"}}); }
function DriveList                            (){
                                                return [Object[]] (Get-WmiObject "Win32_LogicalDisk" | Select-Object DeviceID, FileSystem, Size, FreeSpace, VolumeName, DriveType, @{Name="DriveTypeName";Expression={(DriveMapTypeToString $_.DriveType)}}, ProviderName); }
function CredentialGetSecureStrFromHexString  ( [String] $text ){ 
                                                return [System.Security.SecureString] (ConvertTo-SecureString $text); } # will throw if it is not an encrypted string
function CredentialGetSecureStrFromText       ( [String] $text ){ 
                                                if( $text -eq "" ){ throw [Exception] "DoEncryptWithCurrentCredentials is not allowed to be called with empty string"; } return [System.Security.SecureString] (ConvertTo-SecureString $text -AsPlainText -Force); }
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
function CredentialReadFromFile               ( [String] $file ){ 
                                                [String[]] $s = StringSplitIntoLines (FileReadContentAsString $secureCredentialFile); 
                                                try{ [String] $us = $s[0]; [System.Security.SecureString] $pwSecure = CredentialGetSecureStrFromHexString $s[1];
                                                  # alternative: New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content -Encoding Default -LiteralPath $File | ConvertTo-SecureString)
                                                  return (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure));
                                                }catch{ throw [Exception] "Credential file '$secureCredentialFile' has not expected format for credentials, you may remove it and retry"; } }
function CredentialReadFromParamOrInput       ( [String] $username = "", [String] $password = "" ){ 
                                                [String] $us = $username; 
                                                while( $us -eq "" ){ $us = StdInReadLine   "Enter username: "; } 
                                                [System.Security.SecureString] $pwSecure = $null; 
                                                if( $password -eq "" ){ $pwSecure = StdInReadLinePw "Enter password for username=$($us): "; }else{ $pwSecure = CredentialGetSecureStrFromText $password; }
                                                return (New-Object System.Management.Automation.PSCredential((CredentialStandardizeUserWithDomain $us), $pwSecure)); }
function CredentialStandardizeUserWithDomain  ( [String] $username ){
                                                # allowed username as input: "", "u0", "u0@domain", "@domain\u0", "domain\u0"   #> <# used because for unknown reasons sometimes a username like user@domain does not work, it requires domain\user.
                                                if( $username.Contains("\") -or -not $username.Contains("@") ){ return $username; } return [String] ($username.Split("@",2)[1]+"\"+$username.Split("@",2)[0]); }
function CredentialGetAndStoreIfNotExists     ( [String] $secureCredentialFile, [String] $username = "", [String] $password = ""){
                                                # if username or password is empty then they are asked from std input.
                                                # if file exists then it takes credentials from it.
                                                # if file not exists then it is written by given credentials.
                                                [System.Management.Automation.PSCredential] $cred = $null;
                                                if( $secureCredentialFile -ne "" -and (FileExists $secureCredentialFile) ){
                                                  $cred = CredentialReadFromFile $secureCredentialFile;
                                                }else{
                                                  $cred = CredentialReadFromParamOrInput $username $password;
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
                                                  throw [Exception] "ShareRemove(sharename='$shareName') failed because $errMsg";
                                                } }
function ShareCreate                          ( [String] $shareName, [String] $dir, [String] $typeName = "DiskDrive", [Int32] $nrOfAccessUsers = 25, [String] $descr = "", [Boolean] $ignoreIfAlreadyExists = $true ){
                                                if( !(DirExists $dir)  ){ throw [Exception] "Cannot create share because original directory not exists: '$dir'"; }
                                                FsEntryAssertExists $dir "Cannot create share";
                                                [UInt32] $typeNr = ShareGetTypeNr $typeName;
                                                [Object] $existingShare = ShareListAll "." $shareName | Where-Object {$_.Path -ieq $dir -and $_.TypeName -eq $typeName} | Select-Object -First 1;
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
                                                  throw [Exception] "ShareCreate(dir='$dir',sharename='$shareName',typenr=$typeNr) failed because $errMsg";
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
                                                #nslookup $hostName -ErrorAction SilentlyContinue | out-null;
                                                return [Boolean] (Test-Connection -Cn $hostName -BufferSize 16 -Count 1 -ea 0 -quiet); }
function MountPointLocksListAll               (){ 
                                                OutVerbose "List all mount point locks"; return [Object] (Get-SmbConnection | 
                                                Select-Object ServerName,ShareName,UserName,Credential,NumOpens,ContinuouslyAvailable,Encrypted,PSComputerName,Redirected,Signed,SmbInstance,Dialect | 
                                                Sort-Object ServerName, ShareName, UserName, Credential); }
function MountPointListAll                    (){ 
                                                return [Object] (Get-SmbMapping | Select-Object LocalPath, RemotePath, Status); }
function MountPointRemove                     ( [String] $drive, [String] $mountPoint = "" ){ # also remove PsDrive
                                                if( (Get-SmbMapping -LocalPath "$($drive):" -ErrorAction SilentlyContinue) -ne $null ){
                                                  OutProgress "MountPointRemove drive=$($drive):";
                                                  Remove-SmbMapping -LocalPath "$($drive):" -Force -UpdateProfile;
                                                }
                                                if( $mountPoint -ne "" -and (Get-SmbMapping -RemotePath $mountPoint -ErrorAction SilentlyContinue) -ne $null ){
                                                  OutProgress "MountPointRemovePath $mountPoint";
                                                  Remove-SmbMapping -RemotePath $mountPoint -Force -UpdateProfile;
                                                }
                                                if( (Get-PSDrive -Name $drive -ErrorAction SilentlyContinue) -ne $null ){
                                                  OutProgress "MountPointRemovePsDrive $drive";
                                                  Remove-PSDrive -Name $drive -Force; # force means no confirmation
                                                } }
function MountPointCreate                     ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $errorAsWarning = $false ){
                                                MountPointRemove $drive $mountPoint; # required because New-SmbMapping has no force param
                                                [String] $us = switch($cred -eq $null){ True{"CurrentUser($env:USERNAME)"} default{$cred.UserName}};
                                                [String] $pw = switch($cred -eq $null){ True{""} default{(CredentialGetPasswordTextFromCred $cred)}};
                                                OutProgressText "  MountPointCreate drive=$drive mountPoint=$($mountPoint.PadRight(20)) us=$($us.PadRight(12)) pw=*** ";
                                                try{
                                                  # alternative: SaveCredentials 
                                                  if( $pw -eq ""){
                                                    $obj = New-SmbMapping -LocalPath "$($drive):" -RemotePath $mountPoint -Persistent $true -UserName $us;
                                                  }else{
                                                    $obj = New-SmbMapping -LocalPath "$($drive):" -RemotePath $mountPoint -Persistent $true -UserName $us -Password $pw;
                                                  }
                                                  OutSuccess "Ok.";
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
                                                  elseif( $exMsg -eq "Mehrfache Verbindungen zu einem Server oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig. Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut." ){ $msg = "MultiConnectionsByMultiUserNamesNotAllowed"; } # 1219 SESSION_CREDENTIAL_CONFLICT
                                                  else {}
                                                  OutWarning $msg 0;
                                                  # alternative: (New-Object -ComObject WScript.Network).MapNetworkDrive("B:", "\\FPS01\users")
                                                } }
function PsDriveListAll                       (){ 
                                                OutVerbose "List PsDrives"; 
                                                return Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{Name="ShareName";Expression={$_.DisplayRoot+""}},Description,CurrentLocation,Free,Used | Sort-Object Name; }
                                                # not used: Root, Provider. PSDrive: Note are only for current session, even if persist.
function PsDriveCreate                        ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null ){
                                                MountPointRemove $drive $mountPoint;
                                                [String] $us = switch($cred -eq $null){ True{"CurrentUser($env:USERNAME)"} default{$cred.UserName}};
                                                OutProgress "MountPointCreate drive=$drive mountPoint=$mountPoint cred.username=$us";
                                                try{
                                                  $obj = New-PSDrive -Name $drive -Root $mountPoint -PSProvider "FileSystem" -Scope Global -Persist -Description "$mountPoint($drive)" -Credential $cred;
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
                                                else { throw [Exception] "Wether Sql Server 2016, 2014, 2012 nor 2008 is installed so cannot find sqlcmd.exe"; }
                                                [String] $sqlcmd = (RegistryGetValueAsString $k "Path") + "sqlcmd.EXE"; # "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\sqlcmd.EXE"
                                                return [String] $sqlcmd; }
function SqlRunScriptFile                     ( [String] $sqlserver, [String] $sqlfile, [String] $outFile, [Boolean] $continueOnErr ){
                                                FileAssertExists $sqlfile;
                                                OutProgress "SqlRunScriptFile sqlserver=$sqlserver sqlfile='$sqlfile' out='$outfile' contOnErr=$continueOnErr";
                                                [String] $sqlcmd = SqlGetCmdExe;
                                                FsEntryCreateParentDir $outfile;
                                                & $sqlcmd "-b" "-S" $sqlserver "-i" $sqlfile "-o" $outfile;
                                                if( -not $? ){ if( ! $continueOnErr ){ AssertRcIsOk; }else{ OutWarning "Ignore: SqlRunScriptFile '$sqlfile' on '$sqlserver' failed with rc=$LASTEXITCODE, more see outfile, will continue"; } }
                                                FileAssertExists $outfile; }
function SqlPerformCmd                        ( [String] $server, [String] $db, [String] $cmd ){
                                                if( -not (Get-Module "sqlps") ){
                                                  OutProgress "Import module sqlps (needs 15 sec on first call)";
                                                  Import-Module -NoClobber "sqlps" -DisableNameChecking;
                                                  # more see -Verbose; SQL Server 2012 PowerShell extensions from the feature pack. http://www.microsoft.com/download/en/details.aspx?id=29065
                                                }
                                                OutProgress "SqlPerformCmd server=$server db=$db cmd=$cmd";
                                                Invoke-Sqlcmd -ServerInstance $server -Database $db -AbortOnError -Query $cmd; 
                                                # note: this did not work (restore hangs):
                                                #   [Object[]] $relocateFileList = @();
                                                #   [Object] $smoRestore = New-Object Microsoft.SqlServer.Management.Smo.Restore; $smoRestore.Devices.AddDevice($bakFile , [Microsoft.SqlServer.Management.Smo.DeviceType]::File);
                                                #   $smoRestore.ReadFileList($server) | ForEach-Object { [String] $f = Join-Path $dataDir (Split-Path $_.PhysicalName -Leaf); $relocateFileList += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($_.LogicalName, $f); }
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
function ToolCreateLnkIfNotExists             ( [Boolean] $forceRecreate, [String] $workDir, [String] $lnkFile, [String] $srcFile, [String[]] $arguments, [Boolean] $runElevated = $false ){
                                                # usually if target lnkfile already exists it does nothing.
                                                [String] $descr = $srcFile;
                                                FileAssertExists $srcFile;
                                                if( $forceRecreate ){ FileDelete $lnkFile; }
                                                if( (FileExists $lnkFile) ){
                                                  OutVerbose "Unchanged: $lnkFile";
                                                }else{
                                                  function ByWshShell(){
                                                    [String] $argLine = $arguments;
                                                    if( $workDir -eq "" ){ $workDir = FsEntryGetParentDir $srcFile; }
                                                    OutProgress "CreateShortcut '$lnkFile'";
                                                    # OutVerbose "WScript.Shell.CreateShortcut '$workDir' '$lnkFile' '$srcFile' '$argLine' '$descr'";
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
                                                      $s.Save(); # does overwrite; ex: ToolRecreateShortcut "C:\tmp.lnk" "C:\Windows\notepad.exe" "a.tmp" "Call Notepad";
                                                    }catch{
                                                      throw [Exception] "ToolRecreateShortcut('$workDir','$lnkFile','$srcFile','$argLine','$descr') failed because $($_.Exception.Message)";
                                                    }
                                                  }
                                                  # alternative:
                                                  # function ByProgram(){
                                                  #   OutProgress   "& `"MnCreateLnk.exe`" -Workdir `"$workDir`" `"$lnkFile`" `"$srcFile`" $arguments"; #alternative $($arguments|ForEach-Object {'`"'+$_+'`"'})
                                                  #   [String] $out = & "MnCreateLnk.exe" "-Workdir" (StringReplaceEmptyByTwoQuotes $workDir) $lnkFile $srcFile $arguments; AssertRcIsOk $out;
                                                  # } ByProgram;
                                                  ByWshShell;
                                                  if( $runElevated ){ 
                                                    [Byte[]] $bytes = [IO.File]::ReadAllBytes($lnkFile);
                                                    $bytes[0x15] = $bytes[0x15] -bor 0x20; # set byte 21 (0x15) bit 6 (0x20) ON
                                                    [IO.File]::WriteAllBytes($lnkFile,$bytes);
                                                  } } }
function ToolCreateMenuLinksByMenuItemRefFile ( [String] $targetMenuRootDir, [String] $sourceDir, [String] $srcMenuLinkFileExtension ){
                                                # Find all files below sourceDir with the extension srcMenuLinkFileExtension (ex: ".menulink.txt"),
                                                # which we call these files as menu-item-reference-file.
                                                # For each of them it will create a menu item below targetMenuRootDir (ex: "$env:APPDATA\Microsoft\Windows\Start Menu\HomePortableProg").
                                                # The name of the target menu item will be taken from the name of the menu-item-reference-file without the extension.
                                                # The menu sub folder for the target menu item will be taken from the relative location of the menu-item-reference-file below the sourceDir.
                                                # The command for the target menu will be taken from the first line of the content of the menu-item-reference-file.
                                                # if target lnkfile already exists it does nothing.
                                                # ex: ToolCreateMenuLinksByMenuItemRefFile "$env:APPDATA\Microsoft\Windows\Start Menu\HomePortableProg" "D:\MyPortableProgs" ".menulink.txt";
                                                [String] $m = FsEntryGetAbsolutePath $targetMenuRootDir; # ex: "C:\Users\u1\AppData\Roaming\Microsoft\Windows\Start Menu\HomePortableProg"
                                                [String] $sdir = FsEntryGetAbsolutePath $sourceDir; # ex: "D:\MyPortableProgs"
                                                OutProgress "Create menu links to '$m' from '$sdir\*$srcMenuLinkFileExtension' files";
                                                Assert ($srcMenuLinkFileExtension -ne "" -or (-not $srcMenuLinkFileExtension.EndsWith("\"))) "srcMenuLinkFileExtension is empty or has trailing backslash";
                                                [String[]] $menuLinkFiles = FsEntryListAsStringArray "$sdir\*$srcMenuLinkFileExtension" $true $false | Sort-Object;
                                                foreach( $f in $menuLinkFiles ){
                                                  [String] $d = FsEntryGetParentDir $f; # ex: "D:\MyPortableProgs\Appl\Graphic"
                                                  if( -not $d.StartsWith($sdir)){ throw [Exception] "Expected '$d' below '$sdir'"; }
                                                  [String] $relBelowSrcDir = $d.Substring($sdir.Length); # ex: "\Appl\Graphic"
                                                  [String] $workDir = "";
                                                  # ex: "C:\Users\u1\AppData\Roaming\Microsoft\Windows\Start Menu\HomePortableProg\Appl\Graphic\Manufactor ProgramName V1 en 2016.lnk"
                                                  [String] $lnkFile = "$($m)$($relBelowSrcDir)\$((FsEntryGetFileName $f).TrimEnd($srcMenuLinkFileExtension).TrimEnd()).lnk";
                                                  [String] $cmdLine = FileReadContentAsLines $f | Select-Object -First 1;
                                                  [String[]] $ar = StringCommandLineToArray $cmdLine;
                                                  if( $ar.Length -eq 0 ){ throw [Exception] "Missing a command line at first line in file='$f' cmdline=$cmdLine"; }
                                                  if( ($ar.Length-1) -gt 999 ){ throw [Exception] "Command line has more than the allowed 999 arguments at first line infile='$f' nrOfArgs=$($ar.Length) cmdline='$cmdLine'"; }
                                                  [String] $srcFile = FsEntryMakeAbsolutePath $d $ar[0]; # ex: "D:\MyPortableProgs\Manufactor ProgramName\AnyProgram.exe"
                                                  [String[]] $arguments = $ar | Select-Object -Skip 1;
                                                  [Boolean] $forceRecreate = FileNotExistsOrIsOlder $lnkFile $f;
                                                  try{
                                                    ToolCreateLnkIfNotExists $forceRecreate $workDir $lnkFile $srcFile $arguments;
                                                  }catch{
                                                    OutWarning "Create menulink by reading file `"$f`", taking first line as cmdLine ($cmdLine) and calling (ToolCreateLnkIfNotExists $forceRecreate `"$workDir`" `"$lnkFile`" `"$srcFile`" `"$arguments`") failed because $($_.Exception.Message).$(switch(-not $cmdLine.StartsWith('`"')){$true{' Maybe first file of content in menulink file should be quoted.'}default{''}})";
                                                  } } }
function InfoAboutComputerOverview            (){ 
                                                return [String[]] @( "InfoAboutComputerOverview:", "", "ComputerName   : $ComputerName", "UserName       : $env:UserName", 
                                                "Datetime       : $(DateTimeAsStringIso)", "ProductKey     : $(OsGetWindowsProductKey)", 
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
                                                [String[]] $out = & "systeminfo.exe"; AssertRcIsOk $out;
                                                [String] $f = "$env:TEMP\EnvGetInfoAboutSystemInfo_DefaultFileExtensionToAppAssociations.xml";
                                                & "Dism.exe" "/QUIET" "/Online" "/Export-DefaultAppAssociations:$f"; AssertRcIsOk;
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
                                                # - Get-ScheduledTask | where {$_.settings.waketorun}
                                                # - change:
                                                #   - Dism /online /Enable-Feature /FeatureName:TFTP /All
                                                #   - cmd /c assoc .jpg=IrfanView.jpg
                                                #   - cmd /c ftype IrfanView.jpg="C:\Prg\Appl\Graphic\Irfan-Skiljan IrfanView\i_view32.exe" "%1"
                                                #   - import:   ev.:  Dism.exe /Image:C:\test\offline /Import-DefaultAppAssociations:\\Server\Share\AppAssoc.xml
                                                #     remove:  Dism.exe /Image:C:\test\offline /Remove-DefaultAppAssociations
                                                #     more:    https://msdn.microsoft.com/en-us/windows/hardware/commercialize/manufacture/desktop/export-or-import-default-application-associations
                                                #     moee:    http://www.ghacks.net/2016/02/16/how-to-make-any-program-the-default-on-windows-10/
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
                                                      $s += $line.Substring($i + 1,$q – ($i + 1));
                                                      $i = $q+1;
                                                      if( $i -ge $line.Length -or $line[$i] -eq ' ' -or $line[$i] -eq [Char]9 ){ break; }
                                                      if( $line[$i] -eq '"' ){ $s += '"'; }
                                                      else{ throw [Exception] "Expected blank or tab char or end of string but got char=$($line[$i]) after doublequote at pos=$i in cmdline='$line'"; }
                                                    }
                                                    $result += $s;
                                                  }else{
                                                    [Int32] $w = $line.IndexOf(' ',$i + 1); if( $w -lt 0 ){ $w = $line.IndexOf([Char]9,$i + 1); } if( $w -lt 0 ){ $w = $line.Length; }
                                                    $s += $line.Substring($i,$w – $i); 
                                                    if( $s.Contains('"') ){ throw [Exception] "Expected no doublequote in word='$s' after pos=$i in cmdline='$line'"; }
                                                    $i = $w;
                                                    $result += $s;
                                                  }
                                                  while( $i -lt $line.Length -and ($line[$i] -eq ' ' -or $line[$i] -eq [Char]9) ){ $i++; }
                                                }
                                                return [String[]] $result; }
function WgetDownloadSite                     ( [String] $url, [String] $tarDir, [Int32] $level = 999, [Int32] $maxBytes = ([Int32]::MaxValue), [String] $us = "", 
                                                  [String] $pw = "", [Int32] $limitRateBytesPerSec = ([Int32]::MaxValue), [Boolean] $alsoRetrieveToParentOfUrl = $false ){
                                                # mirror site to dir; wget: HTTP, SHTTP, FTP.
                                                [String] $logfn = "$CurrentMonthIsoString.wget.log";
                                                [String] $logf = "$tarDir\$logfn";
                                                OutInfo "WgetDownloadSite from $url to $tarDir (only newer files, logfile=$logfn)";
                                                [String[]] $opt = @(
                                                   "--directory-prefix=$tarDir"
                                                  ,$(switch($alsoRetrieveToParentOfUrl){$true{""}$false{"--no-parent"}})
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
                                                  # --no-check-certificate
                                                  # --ca-certificate file.crt   (more see http://users.ugent.be/~bpuype/wget/#download)
                                                  # more about logon forms: http://wget.addictivecode.org/FrequentlyAskedQuestions
                                                  # backup without file conversions: wget -mirror -p -P c:\wget_files\example2 ftp://username:password@ftp.yourdomain.com
                                                  # download:                        Wget            -P c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                  # download resume:                 Wget -c         -P c:\wget_files\example3 http://ftp.gnu.org/gnu/wget/wget-1.9.tar.gz
                                                );
                                                # maybe we should also: $url/sitemap.xml
                                                DirCreate $tarDir;
                                                [String] $stateBefore = FsEntryReportMeasureInfo "$tarDir";
                                                # alternative would be for wget: Invoke-WebRequest
                                                [String] $wgetExe = ProcessGetCommandInEnvPathOrAltPaths "wget"; # ex: D:\Work\PortableProg\Tool\...
                                                FileAppendLine $logf "$wgetExe $url $opt";
                                                OutProgress "$wgetExe $url $opt";
                                                & $wgetExe $url $opt "--append-output=$logf";
                                                OutWarnIfRcNotOkAndResetRc "Ignore errors: 0=OK. 1=Generic. 2=CommandLineOption. 3=FileIo. 4=Network. 5=SslVerification. 6=Authentication. 7=Protocol. 8=ServerIssuedSomeResponse(ex:404NotFound)."
                                                [String] $state = "TargetDir: $(FsEntryReportMeasureInfo "$tarDir") (BeforeStart: $stateBefore)";
                                                FileAppendLine $logf $state;
                                                OutProgress $state; }
function CurlDownloadFile                     ( [String] $url, [String] $tarFile, [String] $us = "", [String] $pw = "", [Int32] $limitRateBytesPerSec = 2000000000 ){
                                                # download to single file)
                                                # curl: DICT, FILE, FTP, FTPS, Gopher, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMB, SMTP, SMTPS, Telnet and TFTP. 
                                                #       curl supports SSL certificates, HTTP POST, HTTP PUT, FTP uploading, HTTP form based upload, proxies, HTTP/2, cookies, 
                                                #       user+password authentication (Basic, Plain, Digest, CRAM-MD5, NTLM, Negotiate and Kerberos), file transfer resume, proxy tunneling and more. 
                                                # $url: check if slash at end, is empty
                                                if( $us -ne "" -and $pw -eq "" ){ throw [Exception] "Missing password for username=$us"; }
                                                [String[]] $opt = @( "--user-agent", "`"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1`""
                                                  ,"--progress-bar"
                                                  #,"--silent" # no progress meter
                                                  ,"--create-dirs"
                                                  ,"--connect-timeout", "70" # in sec
                                                  ,"--retry","2"
                                                  ,"--retry-delay","5"
                                                  ,"--show-error"
                                                  ,"--create-dirs"
                                                  ,"--remote-time"  # Set the remote file's time on the local output
                                                  ,"--limit-rate","$limitRateBytesPerSec"
                                                  ,"--output", "$tarFile"
                                                  #,"--remote-name"  # Write output to a file named as the remote file ex: "http://a.be/c.ext"
                                                  # --remote-name-all  Use the remote file name for all URLs
                                                  #--max-time <seconds>
                                                  #--netrc-optional
                                                  #--ftp-create-dirs  for put
                                                  #
                                                  #"--stderr <file>"
                                                  #--create-dirs  # When used in conjunction with the -o option, curl will create the necessary local directory hierarchy as needed. This option creates the dirs mentioned with the -o option, nothing else. 
                                                  #                 If the -o file name uses no dir or if the dirs it mentions already exist, no dir will be created. 
                                                );
                                                if( $us -ne "" ){ $opt.Add("--user"); $opt.Add(($us+":"+$pw)); }
                                                OutInfo "CurlDownloadFile from $url to '$tarFile'";
                                                [String] $tarDir = FsEntryGetParentDir $tarFile;
                                                [String] $logf = "$tarDir\$CurrentMonthIsoString.curl.log";
                                                [String] $curlExe = ProcessGetCommandInEnvPathOrAltPaths "curl.exe"; # ex: D:\Work\PortableProg\Tool\...
                                                DirCreate $tarDir;
                                                FileAppendLine $logf "$curlExe $opt --url $url";
                                                OutProgress "$curlExe $opt --url $url";
                                                & $curlExe $opt "--url" $url;
                                                [String] $state = "TargetFile: $(FsEntryReportMeasureInfo $tarFile)";
                                                FileAppendLine $logf $state;
                                                OutProgress $state;
                                                AssertRcIsOk; }
<# Type: SvnEnvInfo #>                        Add-Type -TypeDefinition "public struct SvnEnvInfo {public string Url; public string Path; public string RealmPattern; public string CachedAuthorizationFile; public string CachedAuthorizationUser; public string Revision; }";
                                                # ex: Url="https://myhost/svn/Work"; Path="D:\Work"; RealmPattern="https://myhost:443"; CachedAuthorizationFile="$env:APPDATA\Subversion\auth\svn.simple\25ff84926a354d51b4e93754a00064d6"; CachedAuthorizationUser="myuser"; Revision="1234"
function SvnExe                               (){ 
                                                return [String] ((RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "Directory") + ".\bin\svn.exe"); }
<# Script local variable: svnLogFile #>       [String] $script:svnLogFile = "$env:TEMP\MnLibCommonSvn.$CurrentMonthIsoString.log";
function SvnEnvInfoGet                        ( [String] $dir ){
                                                # return SvnEnvInfo; no param is null.
                                                OutProgress "SvnEnvInfo - Get svn environment info";
                                                FileAppendLine $svnLogFile "SvnEnvInfoGet($dir)";
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
                                                [String[]] $out = & (SvnExe) "info" $dir; AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayAddIndent $out 2);
                                                [String[]] $out2 = & (SvnExe) "propget" "svn:ignore" "-R" $dir; AssertRcIsOk $out2;
                                                # example:
                                                #   work\Users\MyName - test?.txt
                                                #   test2*.txt
                                                FileAppendLine $svnLogFile "  Ignore Properties:";
                                                FileAppendLines $svnLogFile (StringArrayAddIndent $out2 2);
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
                                                $result.RealmPattern = ($result.Url -Split "/svn/")[0] + $(switch($result.Url.Split("/")[0]){ "https:"{":443"} "http:"{":80"} default{""} });
                                                $result.CachedAuthorizationFile = "";
                                                $result.CachedAuthorizationUser = "";
                                                # svn can cache more than one server connection option,
                                                # so we need to find the correct one by matching the realmPattern in realmstring which identifies a server connection.
                                                [String] $svnCachedAuthorizationDir = "$env:APPDATA\Subversion\auth\svn.simple";
                                                # care only file names like "25ff84926a354d51b4e93754a00064d6"
                                                [String[]] $files = FsEntryListAsStringArray "$svnCachedAuthorizationDir\*" $false $false | 
                                                    Where-Object {(FsEntryGetFileName $_) -match "^[0-9a-f]{32}$"} | Sort-Object;
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
                                                      if( $result.CachedAuthorizationFile -ne "" ){ throw [Exception] "there exist more than one file with realmPattern='$($result.RealmPattern)': '$($result.CachedAuthorizationFile)' and '$f'. "; }
                                                      $result.CachedAuthorizationFile = $f;
                                                      $result.CachedAuthorizationUser = $user;
                                                    }
                                                  }
                                                }
                                                OutProgress "SvnEnvInfo: Url=$($result.Url) Path='$($result.Path)' User='$($result.CachedAuthorizationUser)' Revision='$($result.Revision)'"; # not used: RealmPattern='$($r.RealmPattern)' CachedAuthorizationFile='$($r.CachedAuthorizationFile)' 
                                                return $result; }
function SvnGetDotSvnDir                      ( $svnWorkDir ){
                                                [String] $d = FsEntryGetAbsolutePath $svnWorkDir;
                                                for( [Int32] $i = 0; $i -lt 200; $i++ ){
                                                  if( DirExists "$d\.svn" ){ return [String] "$d\.svn"; }
                                                  $d = FsEntryGetAbsolutePath (Join-Path $d "..");
                                                }
                                                throw [Exception] "Missing directory '.svn' within or up from the path '$svnWorkDir'"; }
function SvnAuthorizationSave                ( [String] $dir, [String] $user ){
                                                # if this part fails then you should clear authorization account in svn settings
                                                OutProgress "SvnAuthorizationSave user=$user";
                                                FileAppendLine $svnLogFile "SvnAuthorizationSave($dir)";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $dir;
                                                DirCopyToParentDirByAddAndOverwrite "$env:APPDATA\Subversion\auth\svn.simple" "$dotSvnDir\OwnSvnAuthSimpleSaveUser_$user\"; }
function SvnAuthorizationTryLoadFile          ( [String] $dir, [String] $user ){
                                                # if work auth dir exists then copy content to svn cache dir
                                                OutProgress "SvnAuthorizationTryLoadFile - try to reload from an earlier save";
                                                FileAppendLine $svnLogFile "SvnAuthorizationTryLoadFile($dir)";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $dir;
                                                [String] $svnWorkAuthDir = "$dotSvnDir\OwnSvnAuthSimpleSaveUser_$user\svn.simple";
                                                [String] $svnAuthDir = "$env:APPDATA\Subversion\auth\";
                                                if( DirExists $svnWorkAuthDir ){
                                                  DirCopyToParentDirByAddAndOverwrite $svnWorkAuthDir $svnAuthDir;
                                                }else{
                                                  OutProgress "Load not done because not found dir: '$svnWorkAuthDir'";
                                                } } # for later usage: function SvnAuthorizationClear (){ FileAppendLine $svnLogFile "SvnAuthorizationClear"; [String] $svnAuthCurr = "$env:APPDATA\Subversion\auth\svn.simple"; DirCopyToParentDirByAddAndOverwrite $svnAuthCurr $svnAuthWork; }
function SvnCleanup                           ( [String] $dir ){
                                                FileAppendLine $svnLogFile "SvnCleanup($dir)";
                                                [String[]] $out = & (SvnExe) "cleanup" $dir; AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayAddIndent $out 2); }
function SvnStatus                            ( [String] $dir, [Boolean] $showFiles ){
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
                                                FileAppendLine $svnLogFile "SvnStatus($dir)";
                                                OutVerbose "SvnStatus - List pending changes";
                                                [String[]] $out = & (SvnExe) "status" $dir; AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayAddIndent $out 2);
                                                [Int32] $nrOfPendingChanges = $out | wc -l; # maybe we can ignore lines with '!'
                                                OutProgress "NrOfPendingChanged=$nrOfPendingChanges";
                                                FileAppendLine $svnLogFile "  NrOfPendingChanges=$nrOfPendingChanges";
                                                [Boolean] $hasAnyChange = $nrOfPendingChanges -gt 0;
                                                if( $showFiles -and $hasAnyChange ){ $out | %{ OutProgress $_; }; }
                                                return [Boolean] $hasAnyChange; }
function SvnRevert                            ( [String] $dir, [String[]] $relativeRevertFsEntries ){
                                                foreach( $f in $relativeRevertFsEntries ){
                                                  FileAppendLine $svnLogFile "SvnRevert(`"$dir\$f`")";
                                                  [String[]] $out = & (SvnExe) "revert" "--recursive" "$dir\$f"; AssertRcIsOk $out;
                                                  FileAppendLines $svnLogFile (StringArrayAddIndent $out 2);
                                                } }
function SvnCommit                            ( [String] $dir ){
                                                FileAppendLine $svnLogFile "SvnCommit($dir) call checkin dialog";
                                                [String] $tortoiseExe = (RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "Directory") + ".\bin\TortoiseProc.exe";
                                                Start-Process -NoNewWindow -Wait "$tortoiseExe" @("/closeonend:2","/command:commit","/path:`"$dir`""); AssertRcIsOk; }
function SvnCheckout                          ( [String] $dir, [String] $url, [String] $user ){
                                                OutProgress "SvnCheckout: Get all changes from $url to '$dir'";
                                                FileAppendLine $svnLogFile "SvnCheckout($dir,$url,$user)";
                                                & (SvnExe) "checkout" "--non-interactive" "--ignore-externals" "--username" $user $url $dir | %{ FileAppendLine $svnLogFile ("  "+$_); OutProgress $_ 2; };
                                                # ex: svn: E170013: Unable to connect to a repository at URL 'https://mycomp/svn/Work/mydir'
                                                #     svn: E230001: Server SSL certificate verification failed: issuer is not trusted   Exception: Last operation failed [rc=1].
                                                AssertRcIsOk;
                                                } # alternative tortoiseExe /closeonend:2 /command:checkout /path:$dir /url:$url
function SvnPreCommitCleanupRevertAndDelFiles ( [String] $svnWorkDir, [String[]] $relativeDelFsEntryPatterns, [String[]] $relativeRevertFsEntries ){
                                                OutInfo "SvnPreCommitCleanupRevertAndDelFiles '$svnWorkDir'";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $svnWorkDir;
                                                [String] $svnRequiresCleanup = "$dotSvnDir\OwnSvnRequiresCleanup.txt";
                                                if( (FileExists $svnRequiresCleanup) ){ # optimized because it is slow
                                                  OutProgress "SvnCleanup - Perform cleanup because previous run was not completed";
                                                  SvnCleanup $svnWorkDir;
                                                  FileDelete $svnRequiresCleanup;
                                                }
                                                OutProgress "Remove known unused temp, cache and log directories and files";
                                                FsEntryJoinRelativePatterns $svnWorkDir $relativeDelFsEntryPatterns | 
                                                  ForEach-Object { FsEntryListAsStringArray $_ } | Where-Object { $_ -ne "" } |
                                                  ForEach-Object { FileAppendLines $svnLogFile "  Delete: $_"; FsEntryDelete $_; };
                                                OutProgress "SvnRevert - Restore known unwanted changes of directories and files";
                                                SvnRevert $svnWorkDir $relativeRevertFsEntries; }
function SvnCommitAndGet                      ( [String] $svnWorkDir, [String] $svnUrl, [String] $svnUser, [Boolean] $ignoreIfHostNotReachable ){
                                                # assumes stored credentials are matching specified svn user, check svn dir, do svn cleanup, check svn user, delete temporary files, svn commit, svn update
                                                [String] $traceInfo = "SvnCommitAndGet workdir='$svnWorkDir' url=$svnUrl user=$svnUser";
                                                OutInfo "$traceInfo svnLogFile='$svnLogFile'";
                                                FileAppendLine $svnLogFile ("`r`n"+("-"*80)+"`r`n"+(DateTimeAsStringIso)+" "+$traceInfo);
                                                try{
                                                  [String] $dotSvnDir = SvnGetDotSvnDir $svnWorkDir;
                                                  [String] $svnRequiresCleanup = "$dotSvnDir\OwnSvnRequiresCleanup.txt";
                                                  # check preconditions
                                                  if( $svnUrl  -eq "" ){ throw [Exception] "SvnUrl is empty which is not allowed"; }
                                                  if( $svnUser -eq "" ){ throw [Exception] "SvnUser is empty which is not allowed"; }
                                                  #
                                                  [SvnEnvInfo] $r = SvnEnvInfoGet $svnWorkDir;
                                                  #
                                                  OutProgress "Verify expected SvnUser='$svnUser' matches CachedAuthorizationUser='$($r.CachedAuthorizationUser)' - if last user was not found so try load";
                                                  if( $r.CachedAuthorizationUser -eq "" ){
                                                    SvnAuthorizationTryLoadFile $svnWorkDir $svnUser;
                                                    $r = SvnEnvInfoGet $svnWorkDir;
                                                  }
                                                  if( $r.CachedAuthorizationUser -eq "" ){ throw [Exception] "This script asserts that configured SvnUser='$svnUser' matches last accessed user because it requires stored credentials, but last user was not saved, please call svn-repo-browser, login, save authentication and then retry."; }
                                                  if( $svnUser -ne $r.CachedAuthorizationUser ){ throw [Exception] "Configured SvnUser='$svnUser' does not match last accessed user='$lastUser', please call svn-settings, clear cached authentication-data, call svn-repo-browser, login, save authentication and then retry."; }
                                                  #
                                                  [String] $host = NetExtractHostName $svnUrl;
                                                  if( $ignoreIfHostNotReachable -and -not (NetPingHostIsConnectable $host) ){
                                                    OutWarning "Host '$host' is not reachable, so ignored.";
                                                    return;
                                                  }
                                                  #
                                                  FileAppendLine $svnRequiresCleanup "";
                                                  [Boolean] $hasAnyChange = SvnStatus $svnWorkDir $false;
                                                  while( $hasAnyChange ){
                                                    OutProgress "SvnCommit - Calling dialog to checkin all pending changes and wait for end of it";
                                                    SvnCommit $svnWorkDir;
                                                    $hasAnyChange = SvnStatus $svnWorkDir $true;
                                                  }
                                                  #
                                                  SvnCheckout $svnWorkDir $svnUrl $svnUser;
                                                  SvnAuthorizationSave $svnWorkDir $svnUser;
                                                  [SvnEnvInfo] $r = SvnEnvInfoGet $svnWorkDir;
                                                  #
                                                  FileDelete $svnRequiresCleanup;
                                                }catch{
                                                  FileAppendLine $svnLogFile (StringFromException $_.Exception);
                                                  throw;
                                                } }
function GitClone                             ( [String] $tarDir, [String] $url, [Boolean] $errorAsWarning = $false ){ # ex: GitFetch "C:\WorkGit\mniederw\mn-hibernate" "https://github.com/mniederw/mn-hibernate"
                                                [String] $dir = FsEntryGetAbsolutePath $tarDir;
                                                try{
                                                  # ex: remote: Counting objects: 123, done. \n Receiving objects: 56% (33/123)  0 (delta 0), pack-reused ... \n Receiving objects: 100% (123/123), 205.12 KiB | 0 bytes/s, done. \n Resolving deltas: 100% (123/123), done.
                                                  # ex: Logon failed, use ctrl+c to cancel basic credential prompt.
                                                  OutProgressText "git clone --quiet '$url' '$dir'     ";
                                                  [String[]] $out = & "git" "clone" "--quiet" $url $dir; AssertRcIsOk $out;
                                                  OutProgress "Ok, done. $out";
                                                }catch{
                                                  if( -not $errorAsWarning ){ throw [Exception] "GitClone($url,$tarDir) failed because $($_.Exception.Message)"; }
                                                  OutWarning "GitClone($url,$tarDir) failed because $($_.Exception.Message)";
                                                  ScriptResetRc;
                                                } }
function GitFetch                             ( [String] $tarDir, [String] $url, [Boolean] $errorAsWarning = $false ){ # ex: GitFetch "C:\WorkGit\mniederw\mn-hibernate" "https://github.com/mniederw/mn-hibernate"
                                                [String] $dir = FsEntryGetAbsolutePath $tarDir;
                                                try{
                                                  # ex: Logon failed, use ctrl+c to cancel basic credential prompt.
                                                  OutProgressText "git --git-dir='$dir\.git' fetch --quiet '$url'     ";
                                                  [String[]] $out = & "git" "--git-dir=$dir\.git" "fetch" "--quiet" $url; AssertRcIsOk $out;
                                                  OutProgress "Ok, done.";
                                                }catch{
                                                  if( -not $errorAsWarning ){ throw [Exception] "GitFetch($url,$tarDir) failed because $($_.Exception.Message)"; }
                                                  OutWarning "GitFetch($url,$tarDir) failed because $($_.Exception.Message)";
                                                  ScriptResetRc;
                                                } }
function GitPull                              ( [String] $tarDir, [String] $url ){ # ex: GitPull "C:\WorkGit\mniederw\mn-hibernate" "https://github.com/mniederw/mn-hibernate"
                                                [String] $dir = FsEntryGetAbsolutePath $tarDir;
                                                try{
                                                  OutProgressText "git --git-dir='$dir\.git' pull --quiet '$url'     ";
                                                  [String[]] $out = & "git" "--git-dir=$dir\.git" "pull" "--quiet" $url; AssertRcIsOk $out;
                                                  OutProgress "Ok, done.";
                                                }catch{
                                                  OutWarning "GitPull($url,$tarDir) failed because $($_.Exception.Message)";
                                                  ScriptResetRc;
                                                } }
function FsEntryMakeValidFileName             ( [string] $str ){ [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object {$str = $str.Replace($_,'_')}; return [String] $str; }
function GitLogList                           ( [String] $tarLogDir, [String] $localRepoDir ){
                                                # overwrite git log info to files below specified dir, it writes files as Log.NameOfRepoRoot.NameOfRepo.Commits.log and Log.NameOfRepoRoot.NameOfRepo.CommitsAndFiles.log, 
                                                # ex: GitListLog "C:\WorkGit\Log" "C:\WorkGit\mniederw\mn-hibernate"
                                                [String] $dir = FsEntryGetAbsolutePath $localRepoDir;
                                                [String] $repoName =  (Split-Path -Leaf (Split-Path -Parent $dir)) + "." + (Split-Path -Leaf $dir);
                                                # ex: Logon failed, use ctrl+c to cancel basic credential prompt.
                                                function LogMode ([String] $mode, [String] $fout) {
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
                                                      $out += "Warning: GitLogList($localRepoDir) failed because $($_.Exception.Message)";
                                                      OutProgressText $out;
                                                    }
                                                    ScriptResetRc;
                                                  }
                                                  FileWriteFromLines $fout $out $true;
                                                }
                                                LogMode ""          "$tarLogDir\Log.$repoName.Commits.log";
                                                LogMode "--summary" "$tarLogDir\Log.$repoName.CommitsAndFiles.log"; }
function GitCloneOrFetch                      ( [String] $tarRootDir, [String] $url, [Boolean] $errorAsWarning = $false ){
                                                # extracts path of url below host as relative dir, uses this path below target root dir to create or update git; 
                                                # ex: GitCloneOrFetch "C:\WorkGit" "https://github.com/mniederw/mn-hibernate"
                                                [String] $tarDir = (GitBuildLocalDirFromUrl $tarRootDir $url);
                                                if( (DirExists $tarDir) ){
                                                  GitFetch $tarDir $url;
                                                }else{
                                                  GitClone $tarDir $url $errorAsWarning;
                                                } }
function GitCloneOrFetchIgnoreError           ( [String] $tarRootDir, [String] $url ){ GitCloneOrFetch $tarRootDir $url $true; }
function GitBuildLocalDirFromUrl              ( [String] $tarRootDir, [String] $url ){ return [String] (Join-Path $tarRootDir ([System.Uri]$url).AbsolutePath.Replace("/","\")); } # AbsolutePath ex: "/mydir1/dir2";
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
                                                  $ProcessId = $pid,
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

# ----------------------------------------------------------------------------------------------------

Export-ModuleMember -function *; # export all functions from this script which are above this line (types are implicit usable)

trap [Exception] { StdErrHandleExc $_; break; }

function MnLibCommonSelfTest{
  Assert ((2 + 3) -eq 5);
  Assert ([Math]::Min(-5,-9) -eq -9);
  Assert ("xyz".substring(1,0) -eq "");
  Assert ((DateTimeFromStringAsFormat "2011-12-31"         ) -eq (Get-Date -Date "2011-12-31 00:00:00"));
  Assert ((DateTimeFromStringAsFormat "2011-12-31_23_59"   ) -eq (Get-Date -Date "2011-12-31 23:59:00"));
  Assert ((DateTimeFromStringAsFormat "2011-12-31_23_59_59") -eq (Get-Date -Date "2011-12-31 23:59:59"));
  Assert (($mode -split ",").Count -eq 1 -and $mode.Split(",").Count -eq 1);
} # MnLibCommonSelfTest; # is deactivated because we know it works :-)

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
# - Extensions: download and install PowerShell Community Extensions“ (PSCX) for ntfs-junctions and symlinks.
# - Special predefined variables which are not yet used in this script (use by $global:anyprefefinedvar; names are case insensitive):
#   $null, $true, $false  - some constants
#   $args                 – Contains an array of the parameters passed to a function.
#   $error                – Contains objects for which an error occurred while being processed in a cmdlet.
#   $HOME                 – Specifies the user’s home directory. (C:\Users\myuser)
#   $PsHome               – The directory where the Windows PowerShell is installed. (C:\Windows\SysWOW64\WindowsPowerShell\v1.0)
#   $PROFILE              - C:\Users\myuser\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#   $PS...                - some variables
#   $MaximumAliasCount, $MaximumDriveCount, $MaximumErrorCount, $MaximumFunctionCount, $MaximumHistoryCount, $MaximumVariableCount   - some maximum values
#   $StackTrace, $ConsoleFileName, $ErrorView, $ExecutionContext, $Host, $input, $NestedPromptLevel, $PID, $PWD, $ShellId            - some environment values
# - Comparison operators; -eq, -ne, -lt, -le, -gt, -ge, "abcde" -like "aB?d*", -notlike, 
#   @( "a1", "a2" ) -contains "a2", -notcontains, "abcdef" -match "b[CD]", -notmatch, "abcdef" -cmatch "b[cd]", -notcmatch, -not
# - Automatic variables see: http://technet.microsoft.com/en-us/library/dd347675.aspx
#   $?            : Contains True if last operation succeeded and False otherwise.
#   $LASTEXITCODE : Contains the exit code of the last Win32 executable execution. should never manually set, even not: $global:LASTEXITCODE = $null;
# - Available colors for options -foregroundcolor and -backgroundcolor: 
#   Black DarkBlue DarkGreen DarkCyan DarkRed DarkMagenta DarkYellow Gray DarkGray Blue Green Cyan Red Magenta Yellow White
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
#     $null | foreach-object{ write-host "badly reached." }
#     But: @() | foreach-object{ write-host "ok not reached." }
#     Recommendation: always use: $null | Where-Object {$_ -ne $null} | foreach-object{ write-host "ok not reached." }
#     Alternative: $null | Foreach-Object -Begin{if($_ -eq $null){continue}} -Process {do your stuff here}
#   - Empty array in pipeline is converted to $null: $r = [String[]]@() | Where-Object { $_ -ne "bla" }; $r -eq $null 
#     Workaround:  $r = @()+([String[]]@() | Where-Object { $_ -ne "bla" }); $r -eq $null 
# - Standard module paths:
#   - %windir%\system32\WindowsPowerShell\v1.0\Modules       location for windows modules for all users
#   - %ProgramW6432%\WindowsPowerShell\Modules\              location for any modules     for all users
#   - %ProgramFiles%\WindowsPowerShell\Modules\              location for any modules     for all users but on PowerShell-32bit only, PowerShell-64bit does not have this path
#   - %USERPROFILE%\Documents\WindowsPowerShell\Modules      location for any modules     for current users
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
#       Start-Process myfile.exe myargs
#     Examples: start-process notepad.exe Test.txt; 
#       [Diagnostics.Process]::Start("notepad.exe","test.txt");
#       start-process -filepath C:\batch\demo.cmd -verb runas;
#       start-process notepad -wait -windowstyle Maximized
#       start-process Sort.exe -RedirectStandardInput C:\Demo\Testsort.txt -RedirectStandardOutput C:\Demo\Sorted.txt -RedirectStandardError C:\Demo\SortError.txt
#       $pclass = [wmiclass]'root\cimv2:Win32_Process'; $new_pid = $pclass.Create('notepad.exe', '.', $null).ProcessId;
#     Run powershell with elevated rights: Start-Process powershell.exe -Verb runAs
# - Call module with arguments: ex:  Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1" -ArgumentList $myinvocation.mycommand.Path;
# - FsEntries: -LiteralPath means no interpretation of wildcards
# - Extensions and libraries: https://www.powershellgallery.com/  http://ss64.com/links/pslinks.html
# - Important to know:
#   - Alternative for Split-Path has problems: [System.IO.Path]::GetDirectoryName("c:\") -eq $null; [System.IO.Path]::GetDirectoryName("\\mymach\myshare\") -eq "\\mymach\myshare\";
#
