# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Process_Job(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   ProcessFindExecutableInPath          ( [String] $exec ){ # Return full path or empty if not found.
  #                                          [Object] $p = (Get-Command $exec -ErrorAction SilentlyContinue); if( $null -eq $p ){ return [String] ""; } return [String] $p.Source; }
  #   ProcessIsRunningInElevatedAdminMode  (){ return [Boolean] ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"); }
  #   ProcessAssertInElevatedAdminMode     (){ if( -not (ProcessIsRunningInElevatedAdminMode) ){ throw [Exception] "Assertion failed because requires to be in elevated admin mode"; } }
  #   ProcessRestartInElevatedAdminMode    (){ if( (ProcessIsRunningInElevatedAdminMode) ){ return; }
  #                                          # ex: "C:\myscr.ps1" or if interactive then statement name ex: "ProcessRestartInElevatedAdminMode"
  #   ProcessGetCurrentThreadId            (){ return [Int32] [Threading.Thread]::CurrentThread.ManagedThreadId; }
  #   ProcessGetNrOfCores                  (){ return [Int32] (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors; }
  #   ProcessListRunnings                  (){ return [Object[]] (@()+(Get-Process * | Where-Object{$null -ne $_} | Where-Object{ $_.Id -ne 0 } | Sort-Object ProcessName)); }
  #   ProcessListRunningsFormatted         (){ return [Object[]] (@()+( ProcessListRunnings | Select-Object Name, Id,
  #   ProcessListRunningsAsStringArray     (){ return [String[]] (@()+(ProcessListRunnings |
  #   ProcessIsRunning                     ( [String] $processName ){ return [Boolean] ($null -ne (Get-Process -ErrorAction SilentlyContinue ($processName -replace ".exe",""))); }
  #   ProcessCloseMainWindow               ( [String] $processName ){ # enter name without exe extension.
  #   ProcessKill                          ( [String] $processName ){ # kill all with the specified name, note if processes are not from owner then it requires to previously call ProcessRestartInElevatedAdminMode
  #   ProcessSleepSec                      ( [Int32] $sec ){ Start-Sleep -Seconds $sec; }
  #   ProcessListInstalledAppx             (){ return [String[]] (@()+(Get-AppxPackage | Where-Object{$null -ne $_} | Select-Object PackageFullName | Sort-Object PackageFullName)); }
  #   ProcessGetCommandInEnvPathOrAltPaths ( [String] $commandNameOptionalWithExtension, [String[]] $alternativePaths = @(), [String] $downloadHintMsg = ""){
  #   ProcessStart                         ( [String] $cmd, [String[]] $cmdArgs = @(), [Boolean] $careStdErrAsOut = $false, [Boolean] $traceCmd = $false ){
  #                                          # Mainly intended for starting a program with a window.
  #                                          # But also used for starting a command in path when arguments are provided in an array.
  #                                          # Return output as a single string.
  #                                          # If careStdErrAsOut is true then stderr will be appended to stdout and stderr set to empty.
  #                                          # If exitCode is not 0 or stderr is not empty then it throws.
  #                                          # But if ErrorActionPreference is Continue true then stderr is simply appended to output.
  #                                          # Before it throws it will first OutProgress the non empty stdout lines.
  #                                          # You can use StringSplitIntoLines on output to get it as lines.
  #                                          # Internally the stdout and stderr are stored to variables and not temporary files to avoid file system IO.
  #                                          # Important Note: The original Process.Start(ProcessStartInfo) cannot run a ps1 file
  #                                          #   even if $env:PATHEXT contains the PS1 because it does not preceed it with (powershell.exe -File).
  #                                          #   Our solution will do this by automatically use powershell.exe -NoLogo -File before the ps1 file
  #                                          #   and it surrounds the arguments correctly by double-quotes to support blanks in any argument.
  #                                          # There is a special handling of the commandline as descripted 
  #                                          # in "Parsing C++ command-line arguments" https://docs.microsoft.com/en-us/cpp/cpp/main-function-command-line-args
  #                                          # - Arguments are delimited by white space, which is either a space or a tab.
  #                                          # - The first argument (argv[0]) is treated specially. It represents the program name. 
  #                                          #   Because it must be a valid pathname, parts surrounded by double quote marks (") are allowed. 
  #                                          #   The double quote marks aren't included in the argv[0] output. 
  #                                          #   The parts surrounded by double quote marks prevent interpretation of a space or tab character 
  #                                          #   as the end of the argument. The later rules in this list don't apply.
  #                                          # - A string surrounded by double quote marks is interpreted as a single argument, 
  #                                          #   which may contain white-space characters. A quoted string can be embedded in an argument. 
  #                                          #   The caret (^) isn't recognized as an escape character or delimiter. 
  #                                          #   Within a quoted string, a pair of double quote marks is interpreted as a single escaped double quote mark. 
  #                                          #   If the command line ends before a closing double quote mark is found, 
  #                                          #   then all the characters read so far are output as the last argument.
  #                                          # - A double quote mark preceded by a backslash (\") is interpreted as a literal double quote mark (").
  #                                          # - Backslashes are interpreted literally, unless they immediately precede a double quote mark.
  #                                          # - If an even number of backslashes is followed by a double quote mark, 
  #                                          #   then one backslash (\) is placed in the argv array for every pair of backslashes (\\), 
  #                                          #   and the double quote mark (") is interpreted as a string delimiter.
  #                                          # - If an odd number of backslashes is followed by a double quote mark, 
  #                                          #   then one backslash (\) is placed in the argv array for every pair of backslashes (\\). 
  #                                          #   The double quote mark is interpreted as an escape sequence by the remaining backslash, 
  #                                          #   causing a literal double quote mark (") to be placed in argv.
  #   ProcessEnvVarGet                     ( [String] $name, [System.EnvironmentVariableTarget] $scope = [System.EnvironmentVariableTarget]::Process ){
  #   ProcessEnvVarSet                     ( [String] $name, [String] $val, [System.EnvironmentVariableTarget] $scope = [System.EnvironmentVariableTarget]::Process ){
  #                                           # Scope: MACHINE, USER, PROCESS.
  #   ProcessRemoveAllAlias                ( [String[]] $excludeAliasNames = @(), [Boolean] $doTrace = $false ){ # remove all existing aliases on any levels (local, script, private, and global).
  #                                          # Is used because in powershell5 there are a predefined list of about 180 aliases in each session which cannot be avoided.
  #                                          # This is very bad because there are also aliases defined as curl->Invoke-WebRequest or wget->Invoke-WebRequest which are incompatible to their known tools.
  #                                          # All aliases can be listed by:
  #                                          #   powershell -NoProfile { Get-Alias | Select-Object Name, Definition, Visibility, Options, Module | StreamToTableString }
  #                                                   # example: ProcessRemoveAllAlias @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir");
  #                                                   # example: ProcessRemoveAllAlias @("cd","cat","clear","echo","dir","cp","mv","popd","pushd","rm","rmdir","select","where","foreach");
  #   ProcessOpenAssocFile                 ( [String] $fileOrUrl ){ & "rundll32" "url.dll,FileProtocolHandler" $fileOrUrl; AssertRcIsOk; }
  #   JobStart                             ( [ScriptBlock] $scr, [Object[]] $scrArgs = $null, [String] $name = "Job" ){ # Return job object of type PSRemotingJob, the returned object of the script block can later be requested.
  #   JobGet                               ( [String] $id ){ return [System.Management.Automation.Job] (Get-Job -Id $id); } # Return job object.
  #   JobGetState                          ( [String] $id ){ return [String] (JobGet $id).State; } # NotStarted, Running, Completed, Stopped, Failed, and Blocked.
  #   JobWaitForNotRunning                 ( [Int32] $id, [Int32] $timeoutInSec = -1 ){ [Object] $dummyJob = Wait-Job -Id $id -Timeout $timeoutInSec; }
  #   JobWaitForState                      ( [Int32] $id, [String] $state, [Int32] $timeoutInSec = -1 ){ [Object] $dummyJob = Wait-Job -Id $id -State $state -Force -Timeout $timeoutInSec; }
  #   JobWaitForEnd                        ( [Int32] $id ){ JobWaitForNotRunning $id; return [Object] (Receive-Job -Id $id); } # Return result object of script block, job is afterwards deleted.
}
Test_Process_Job;
