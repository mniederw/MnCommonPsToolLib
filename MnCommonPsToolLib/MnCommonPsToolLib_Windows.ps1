# Extension of MnCommonPsToolLib.psm1 - Common powershell tool library - Parts for windows only

if( [System.Environment]::OSVersion.Platform -ne "Win32NT" ){ OutVerbose "$PSScriptRoot : Not Running on windows"; [Environment]::Exit("0"); }

# Import some modules (because it is more performant to do it once than doing this in each function using methods of this module).
# Note: for example on "Windows Server 2008 R2" we currently are missing these modules
#   but we ignore the errors because it its enough if the functions which uses these modules will fail.
#   Example error: The specified module 'ScheduledTasks'/'SmbShare' was not loaded because no valid module file was found in any module directory.
if( $null -ne (Import-Module -NoClobber -Name "ScheduledTasks" -ErrorAction Continue *>&1) ){ $error.clear(); Write-Warning "Ignored failing of Import-Module ScheduledTasks because it will fail later if a function is used from it."; } #
if( $null -ne (Import-Module -NoClobber -Name "SmbShare"       -ErrorAction Continue *>&1) ){ $error.clear(); Write-Warning "Ignored failing of Import-Module SmbShare       because it will fail later if a function is used from it."; } # Example: Get-SMBShare, Get-SMBOpenFile, New-SMBShare, Get-SMBMapping, ...
if( $null -ne (Import-Module -NoClobber -Name "CimCmdlets"     -ErrorAction Continue *>&1) ){ $error.clear(); Write-Warning "Ignored failing of Import-Module CimCmdlets     because it will fail later if a function is used from it."; } # Example: Get-CimInstance.
# Import-Module "PSWindowsUpdate"; # Is used for some funtions but currently we do not warn if it is not loadable
# Import-Module "SmbWitness"; # for later usage
# Import-Module "ServerManager"; # Is not always available, requires windows-server-os or at least Win10Prof with installed RSAT. Because seldom used we do not try to load it here.

# Set some self defined constant global variables
if( $null -eq (Get-Variable -Scope Global -ErrorAction SilentlyContinue -Name AllUsersMenuDir) ){ # check wether last variable already exists because reload safe
  New-Variable -option Constant -scope Global -name UserQuickLaunchDir           -Value ([String](FsEntryGetAbsolutePath "$env:APPDATA/Microsoft/Internet Explorer/Quick Launch/"));
  New-Variable -option Constant -scope Global -name UserSendToDir                -Value ([String](FsEntryGetAbsolutePath "$env:APPDATA/Microsoft/Windows/SendTo/"));
  New-Variable -option Constant -scope Global -name UserMenuDir                  -Value ([String](FsEntryGetAbsolutePath "$env:APPDATA/Microsoft/Windows/Start Menu/"));
  New-Variable -option Constant -scope Global -name UserMenuStartupDir           -Value ([String](FsEntryGetAbsolutePath "$env:APPDATA/Microsoft/Windows/Start Menu/Programs/Startup/"));
  New-Variable -option Constant -scope Global -name AllUsersMenuDir              -Value ([String](FsEntryGetAbsolutePath "$env:ALLUSERSPROFILE/Microsoft/Windows/Start Menu/"));
}

function OsIs64BitOs                          (){ return [Boolean] (Get-CimInstance -Class Win32_OperatingSystem -ErrorAction SilentlyContinue).OSArchitecture -eq "64-Bit"; }
function OsIsWinScreenLocked                  (){ return [Boolean] ((@()+(Get-Process | Where-Object{ $_.ProcessName -eq "LogonUI"})).Count -gt 0); }
function OsIsHibernateEnabled                 (){
                                                if( (FileNotExists "$env:SystemDrive/hiberfil.sys") ){ return [Boolean] $false; }
                                                if( OsIsWin7OrHigher ){ return [Boolean] (RegistryGetValueAsString "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "HibernateEnabled") -eq "1"; }
                                                # win7     Example: Die folgenden Standbymodusfunktionen sind auf diesem System verfügbar: Standby ( S1 S3 ) Ruhezustand Hybrider Standbymodus
                                                # winVista Example: Die folgenden Ruhezustandfunktionen sind auf diesem System verfügbar: Standby ( S3 ) Ruhezustand Hybrider Standbymodus
                                                [String] $out = @()+(& "$env:SystemRoot/System32/powercfg.exe" "-AVAILABLESLEEPSTATES" | Where-Object{
                                                  $_ -like "Die folgenden Standbymodusfunktionen sind auf diesem System verf*" -or $_ -like "Die folgenden Ruhezustandfunktionen sind auf diesem System verf*" });
                                                AssertRcIsOk; return [Boolean] ((($out.Contains("Ruhezustand") -or $out.Contains("Hibernate"))) -and (FileExists "$env:SystemDrive/hiberfil.sys")); }
function OsInfoMainboardPhysicalMemorySum     (){ return [Int64] (Get-CimInstance -class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum; }
function OsWindowsPackageListInstalled        (){
                                                [PSCustomObject[]] $a = @()+
                                                  (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*")+
                                                  (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*");
                                                return $a | Select-Object DisplayVersion, Publisher, DisplayName, UninstallString; }
function OsWindowsPackageUninstall            ( [String] $displayName ){
                                                [PSCustomObject[]] $a = @()+(OsWindowsPackageListInstalled | Where-Object{ $null -ne $_ } |
                                                  Where-Object{ "$($_.DisplayName)" -ne "" -and $_.DisplayName -eq $displayName });
                                                if( $a.Count -eq 0 ){ OutProgress "Uninstall `"$displayName`" already uninstalled, nothing done. "; return; }
                                                $a | ForEach-Object{
                                                  [String] $uninstallCmd = $_.UninstallString; # maybe we can append option: " /quiet"
                                                  OutProgress "Uninstall-Ignoring-Errors `"$displayName`" with: `"$uninstallCmd`" ";
                                                  ProcessRestartInElevatedAdminMode;
                                                  ProcessStartByCmdLine $uninstallCmd $true $true;
                                                } }
function OsWindowsFeatureGetInstalledNames    (){ # Requires windows-server-os or at least Win10Prof with installed RSAT https://www.microsoft.com/en-au/download/details.aspx?id=45520
                                                  ScriptImportModuleIfNotDone "ServerManager";
                                                  return [String[]] (@()+(Get-WindowsFeature | Where-Object{ $_.InstallState -eq "Installed" } | ForEach-Object{ $_.Name })); } # states: Installed, Available, Removed.
function OsWindowsFeatureDoInstall            ( [String] $name ){
                                                # Example: Web-Server, Web-Mgmt-Console, Web-Scripting-Tools, Web-Basic-Auth, Web-Windows-Auth, NET-FRAMEWORK-45-Core,
                                                #   NET-FRAMEWORK-45-ASPNET, Web-HTTP-Logging, Web-NET-Ext45, Web-ASP-Net45, Telnet-Server, Telnet-Client.
                                                ScriptImportModuleIfNotDone "ServerManager";
                                                  # Used for Install-WindowsFeature; Requires at least Win10Prof: RSAT https://www.microsoft.com/en-au/download/details.aspx?id=45520
                                                OutProgress "Install-WindowsFeature -name $name -IncludeManagementTools";
                                                [Object] $res = Install-WindowsFeature -name $name -IncludeManagementTools;
                                                [String] $out = "Result: IsSuccess=$($res.Success) RequiresRestart=$($res.RestartNeeded) ExitCode=$($res.ExitCode) FeatureResult=$($res.FeatureResult)";
                                                # Example: "Result: IsSuccess=True RequiresRestart=No ExitCode=NoChangeNeeded FeatureResult="
                                                OutProgress $out; if( -not $res.Success ){ throw [Exception] "Install $name was not successful, please solve manually. $out"; } }
function OsWindowsFeatureDoUninstall          ( [String] $name ){
                                                ScriptImportModuleIfNotDone "ServerManager";
                                                OutProgress "Uninstall-WindowsFeature -name $name";
                                                [Object] $res = Uninstall-WindowsFeature -name $name;
                                                [String] $out = "Result: IsSuccess=$($res.Success) RequiresRestart=$($res.RestartNeeded) ExitCode=$($res.ExitCode) FeatureResult=$($res.FeatureResult)";
                                                OutProgress $out;
                                                if( -not $res.Success ){ throw [Exception] "Uninstall $name was not successful, please solve manually. $out"; } }
function OsWindowsAppxImportModule            (){ # On pwsh the Appx module must be loaded by an internal ps5 shell.
                                                # 2023-03: Problems using Get-AppxPackage in PS7, see end of: https://github.com/PowerShell/PowerShell/issues/13138
                                                # We suppress the output: WARNING: Module Appx is loaded in Windows PowerShell using WinPSCompatSession remoting session;
                                                #   please note that all input and output of commands from this module will be deserialized objects.
                                                #   If you want to load this module into PowerShell please use 'Import-Module -SkipEditionCheck' syntax.
                                                if( (ProcessIsLesserEqualPs5) ){ Import-Module -Name Appx; }else{ Import-Module -Name Appx -UseWindowsPowerShell 3> $null; } }
function OsWindowsAppxListInstalled           (){ OsWindowsAppxImportModule;
                                                return [String[]] (@()+(Get-AppxPackage | Where-Object{$null -ne $_} | Sort-Object PackageFullName |
                                                  ForEach-Object{ "$($_.PackageFullName)" })); } # alternative field: Name.
function OsWindowsRegRunDisable               ( [String] $regItem, [Boolean] $fromHklmNotHkcu = $false, [Boolean] $fromRunonceNotRun = $false ){
                                                # Ignore if key not exists. Creates backup entry under "AutorunsDisabled".
                                                [String] $key = ""; [String] $msg = "";
                                                if( $fromRunonceNotRun ){ if( $fromHklmNotHkcu ){ $msg = "Autorunonce-CurrentUser" ; $key = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce"; }
                                                                          else{                   $msg = "Autorunonce-LocalMachine"; $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"            ; } }
                                                else{                     if( $fromHklmNotHkcu ){ $msg = "Autorun-CurrentUser"     ; $key = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"    ; }
                                                                          else{                   $msg = "Autorun-LocalMachine"    ; $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"                ; } }
                                                OutProgress "$($msg)-Remove: $regItem";
                                                [String] $val = RegistryGetValueAsString $key -Name $regItem;
                                                if( $val -ne "" ){ RegistrySetValue "$key\AutorunsDisabled" $regItem "String" $val; }
                                                Remove-ItemProperty -Path $key -Name $regItem -ErrorAction SilentlyContinue;
                                              }
function OsGetWindowsProductKey               (){
                                                [String] $map = "BCDFGHJKMPQRTVWXY2346789";
                                                [Object] $value = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").digitalproductid[0x34..0x42]; [String] $p = "";
                                                for( $i = 24; $i -ge 0; $i-- ){
                                                  $r = 0; for( $j = 14; $j -ge 0; $j-- ){
                                                    $r = ($r * 256) -bxor $value[$j];
                                                    $value[$j] = [math]::Floor([double]($r/24));
                                                    $r = $r % 24;
                                                  }
                                                  $p = $map[$r] + $p;
                                                  if( ($i % 5) -eq 0 -and $i -ne 0 ){ $p = "-" + $p; }
                                                }
                                                return [String] $p; }
function OsWinPowerOff                        ( [Int32] $waitSec = 60, [Boolean] $forceIfScreenLocked = $false ){
                                                OutWarning "Warning: In $waitSec seconds calling Power-Off (forceIfScreenLocked=$forceIfScreenLocked) (use ctrl-c to abort)!";
                                                ProcessSleepSec "$waitSec";
                                                if( $forceIfScreenLocked -and (OsIsWinScreenLocked) ){ Stop-Computer -Force; }else{ Stop-Computer; } }
function OsWinCreateUser                      ( [String] $us, [String] $pw, [String] $fullName = "", [String] $descr = "", [Boolean] $denyInteractiveLogon = $false ){
                                                Assert ($us -ne "");
                                                if( $null -ne (Get-LocalUser -Name $us -ErrorAction SilentlyContinue) ){ OutProgress "User $us already exists, nothing done. "; return; }
                                                OutProgress "CreateUser us=$us denyInteractiveLogon=$denyInteractiveLogon ";
                                                # 2024-08-18 On Win11 we get the bug: https://github.com/PowerShell/PowerShell/issues/18624
                                                #   New-LocalUser Could not load type 'Microsoft.PowerShell.Telemetry.Internal.TelemetryAPI' from assembly 'System.Management.Automation
                                                # workaround is:
                                                if( (ProcessIsLesserEqualPs5) ){ Import-Module microsoft.powershell.localaccounts; }else{ Import-Module microsoft.powershell.localaccounts -UseWindowsPowerShell 3> $null; }
                                                [Object] $u = New-LocalUser -Name $us -Password (ConvertTo-SecureString $pw -AsPlainText -Force) -FullName $fullName -Description $descr -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword -Disabled;
                                                OutVerbose "OsWinCreateUser $u  (FullName=$fullName; Descr=$descr; Is-Disabled)";
                                                if( $denyInteractiveLogon ){
                                                  # Manually procedure would be: Call gpedit.msc and add user to: Computerkonfiguration->WindowsSettings->SecuritySettings->LokaleRichtlinien-ZuweisenVonBenutzerrechten->LokalAnmeldenVerweigern ";
                                                  [String] $tmp = (FileGetTempFile);
                                                  & secedit /export /cfg $tmp | Out-Null; AssertRcIsOk; # export current security policies
                                                  # Example: "SeDenyInteractiveLogonRight = u0,Gast"
                                                  [String[]] $currentDeniedUsers = StringSplitToArray "," ((FileReadContentAsLines $tmp "Default" | Select-String -Pattern "SeDenyInteractiveLogonRight").Line).Replace("SeDenyInteractiveLogonRight = ","");
                                                    # TODO: try to replace Default by UTF8.
                                                  if( -not (StringArrayContains $currentDeniedUsers $us) ){
                                                    [String] $tmp2 = (FileGetTempFile);
                                                    [String] $content = "[Unicode]`r`nUnicode=yes`r`n[Privilege Rights]`r`nSeDenyInteractiveLogonRight = $us,$($currentDeniedUsers -join ',')`r`n";
                                                    FileWriteFromString $tmp2 $content $true "Default"; # TODO: try to replace Default by UTF8.
                                                    OutProgress "& secedit /configure /db 'secedit.sdb' /cfg `"$tmp2`" /areas USER_RIGHTS ; # set SeDenyInteractiveLogonRight";
                                                    try{
                                                      [String] $out = & secedit /configure /db 'secedit.sdb' /cfg $tmp2 /areas USER_RIGHTS 2>&1; AssertRcIsOk $out; # more in "$env:windir\security\logs\scesrv.log"
                                                    }catch{
                                                      OutWarning "Warning: The command to set SeDenyInteractiveLogonRight failed, is ignored, please perform this manually. ";
                                                    }
                                                    Remove-Item $tmp2;
                                                  }
                                                  Remove-Item $tmp;
                                                  Enable-LocalUser -Name $us;
                                                }
                                                # for future use: Add-LocalGroupMember -Group Users -Member $us;
                                                # for future use: [Object] $gr = [Security.Principal.WindowsBuiltInRole] "Guest";
                                                # for future use: Get-LocalUser ; # list all users
                                                # for future use: Remove-LocalUser -Name $us;
                                              }
function OsWindowsUpdateEnableNonOsAppUpdates (){
                                                OutProgress "Enable Microsoft Update for Non-OS-App-Updates";
                                                ProcessRestartInElevatedAdminMode;
                                                Import-Module PSWindowsUpdate; # for Get-WUServiceManager
                                                OutProgress "List Registered Service Manager:";
                                                Get-WUServiceManager | Sort-Object Name | Select-Object Name, IsDefaultAUService, IsManaged, ServiceId, ServiceUrl |
                                                  StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                  #   ServiceID                            IsManaged IsDefault Name
                                                  #   ---------                            --------- --------- ----
                                                  #   7971f918-a847-4430-9279-4a52d1efe18d False     True      Microsoft Update
                                                  #   8b24b027-1dee-babb-9a95-3517dfb9c552 False     False     DCat Flighting Prod
                                                  #   117cab2d-82b1-4b5a-a08c-4d62dbee7782 False     False     Windows Store
                                                  #   855e8a7c-ecb4-4ca3-b045-1dfa50104289 False     False     Windows Store (DCat Prod)
                                                  #   9482f4b4-e343-43b6-b170-9a65bc822c77 False     False     Windows Update
                                                OutProgress "List Registered Service Manager:";
                                                Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Select-Object Name, IsDefaultAUService, IsManaged, ServiceId, ServiceUrl |
                                                  StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                  # for future use: RegistrationStateName, ContentValidationCert, ExpirationDate, IsRegisteredWithAU, IssueDate, OffersWindowsUpdates, RedirectUrls, IsScanPackageService, CanRegisterWithAU, SetupPrefix
                                                  # Option -MicrosoftUpdate is the same as: Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d;
                                                  #   It seams this is also for Non-OS-App-Updates
                                                  # Confirm=false means no request before execution.
                                                OutProgress "Ok, done.";
                                              }
function OsWindowsUpdatePackagesShowPending   (){
                                                OutProgress "Show Pending Microsoft Windows Update Packages";
                                                ProcessRestartInElevatedAdminMode;
                                                Import-Module PSWindowsUpdate; # for Get-WindowsUpdate
                                                Get-WindowsUpdate | Select-Object ComputerName, Status, KB, Size, Title |
                                                  StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                OutProgress "Ok, done.";
                                              }
function OsWindowsUpdatePerform               ( [Boolean] $withAutoReboot = $false ){
                                                OutProgress "Perform Microsoft Windows Update (withAutoReboot=$withAutoReboot)";
                                                ProcessRestartInElevatedAdminMode;
                                                Import-Module PSWindowsUpdate; # for Get-WindowsUpdate
                                                # for performing on remote computers use: $c = "comp1, comp2, comp3";
                                                #   Invoke-WUJob -ComputerName $c -Script {Import-Module PSWindowsUpdate; Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot} -RunNow -Confirm:$false |
                                                #     Out-File "/server/share/logs/$computer-$(Get-Date -f yyyy-MM-dd)-MSUpdates.log" -Force; # Appends nl to each line.
                                                # Install-WindowsUpdate is an alias to Get-WindowsUpdate -Install; But Install-WindowsUpdate seams not to enabled on PS7
                                                # Alternatives: -KBArticleID "KB9876543,KB9876542" -NotKBArticleID "KB9876541" -NotCategory "Drivers" -NotTitle "OneDrive"
                                                # for unknown reason if we use: Get-WindowsUpdate | Select-Object Status, Size, KB, Title;  then the values are empty, so we use conversion to [Object[]]
                                                ([Object[]](Get-WindowsUpdate)) | Select-Object Status, Size, KB, Title |
                                                  StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                OutProgress "List finished, now download and install all";
                                                # Perform and lists all properties; later try to list: EulaAccepted,IsBeta,IsInstalled,IsMandatory,RebootRequired,IsPresent,PerUser,LastDeploymentChangeTime
                                                Get-WindowsUpdate -Install -AcceptAll -MicrosoftUpdate -AutoReboot:$withAutoReboot -IgnoreReboot:$(-not $withAutoReboot) *>&1 |
                                                  Select-Object X, Result, Status, Size, KB, Title | StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                  # Example:
                                                  #   Reboot is required, but do it manually.
                                                  #   X Result     Status  Size  KB        Title
                                                  #   - ------     ------  ----  --        -----
                                                  #   1 Accepted   AD----- 128GB KB5041585 2024-08 Kumulatives Update für Windows 11 Version 23H2 für x64-basierte Systeme (KB5041585)
                                                  #   2 Downloaded AD----- 128GB KB5041585 2024-08 Kumulatives Update für Windows 11 Version 23H2 für x64-basierte Systeme (KB5041585)
                                                  #   3 Installed  ADR---- 128GB KB5041585 2024-08 Kumulatives Update für Windows 11 Version 23H2 für x64-basierte Systeme (KB5041585)
                                                  # Example:
                                                  #   Size                            : 64MB
                                                  #   Status                          : ADR----
                                                  #   ComputerName                    : MYCOMPUTER
                                                  #   KB                              : KB5032339
                                                  #   X                               : 3
                                                  #   ChooseResult                    : Accepted
                                                  #   Result                          : Installed
                                                  #   DownloadResult                  : Downloaded
                                                  #   InstallResult                   : Installed
                                                  #   Title                           : 2023-11 Kumulatives Update f�r .NET Framework 3.5, 4.8 und 4.8.1 f�r Windows 10 Version 22H2 f�r x64 ((KB5032339))
                                                  #   AutoSelectOnWebSites            : True
                                                  #   BundledUpdates                  : System.__ComObject
                                                  #   CanRequireSource                : False
                                                  #   Categories                      : System.__ComObject
                                                  #   Deadline                        :
                                                  #   DeltaCompressedContentAvailable : False
                                                  #   DeltaCompressedContentPreferred : True
                                                  #   Description                     : In einem Microsoft-Softwareprodukt wurde ein Sicherheitsproblem festgestellt, das Auswirkungen auf Ihr System haben k�nnte. Durch die Installation dieses Updates von Microsoft k�nnen Sie zum Schutz Ihres Systems beitragen. Eine vollst�ndige Liste der Problembehebungen in diesem Update finden Sie in dem entsprechenden Microsoft Knowledge Base-Artikel. Nach der Installation dieses Updates m�ssen Sie das System gegebenenfalls neu starten.
                                                  #   EulaAccepted                    : True
                                                  #   EulaText                        :
                                                  #   HandlerID                       :
                                                  #   Identity                        : System.__ComObject
                                                  #   Image                           :
                                                  #   InstallationBehavior            : System.__ComObject
                                                  #   IsBeta                          : False
                                                  #   IsDownloaded                    : True
                                                  #   IsHidden                        : False
                                                  #   IsInstalled                     : False
                                                  #   IsMandatory                     : False
                                                  #   IsUninstallable                 : False
                                                  #   Languages                       : System.__ComObject
                                                  #   LastDeploymentChangeTime        : 2023-11-14 00:00:00
                                                  #   MaxDownloadSize                 : 67042638
                                                  #   MinDownloadSize                 : 0
                                                  #   MoreInfoUrls                    : System.__ComObject
                                                  #   MsrcSeverity                    : Important
                                                  #   RecommendedCpuSpeed             : 0
                                                  #   RecommendedHardDiskSpace        : 0
                                                  #   RecommendedMemory               : 0
                                                  #   ReleaseNotes                    :
                                                  #   SecurityBulletinIDs             : System.__ComObject
                                                  #   SupersededUpdateIDs             : System.__ComObject
                                                  #   SupportUrl                      : http://support.microsoft.com
                                                  #   Type                            : 1
                                                  #   UninstallationNotes             : Dieses Softwareupdate kann in der Systemsteuerung unter "Programme und Funktionen" unter der Option "Installierte Updates anzeigen" entfernt werden.
                                                  #   UninstallationBehavior          : System.__ComObject
                                                  #   UninstallationSteps             : System.__ComObject
                                                  #   KBArticleIDs                    : System.__ComObject
                                                  #   DeploymentAction                : 1
                                                  #   DownloadPriority                : 2
                                                  #   DownloadContents                : System.__ComObject
                                                  #   RebootRequired                  : True
                                                  #   IsPresent                       : False
                                                  #   CveIDs                          : System.__ComObject
                                                  #   BrowseOnly                      : False
                                                  #   PerUser                         : False
                                                  #   AutoSelection                   : 0
                                                  #   AutoDownload                    : 0
                                                OutProgress "Ok, done.";
                                              }
function ProcessGetNrOfCores                  (){ return [Int32] (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors; }
function ProcessOpenAssocFile                 ( [String] $fileOrUrl ){ & "rundll32" "url.dll,FileProtocolHandler" $fileOrUrl; AssertRcIsOk; }
function JobStart                             ( [ScriptBlock] $scr, [Object[]] $scrArgs = @(), [String] $name = "Job" ){ # Return job object of type PSRemotingJob, the returned object of the script block can later be requested.
                                                [Object[]] $scrArgs2 = $(switch(ArrayIsNullOrEmpty $scrArgs){($true){$null}($false){$scrArgs}}); # TODO test wether this is nessessary.
                                                return [System.Management.Automation.Job] (Start-Job -name $name -ScriptBlock $scr -ArgumentList $scrArgs2); }
function JobGet                               ( [String] $id ){ return [System.Management.Automation.Job] (Get-Job -Id $id); } # Return job object.
function JobGetState                          ( [String] $id ){ return [String] (JobGet $id).State; } # NotStarted, Running, Completed, Stopped, Failed, and Blocked.
function JobWaitForNotRunning                 ( [Int32] $id, [Int32] $timeoutInSec = -1 ){ Wait-Job -Id $id -Timeout $timeoutInSec | Out-Null; }
function JobWaitForState                      ( [String] $state = "Completed", [Int32] $timeoutInSec = -1 ){ Wait-Job -State $state -Force -Timeout $timeoutInSec | Out-Null; }
function JobWaitForEnd                        ( [Int32] $id ){ JobWaitForNotRunning $id; return [Object] (Receive-Job -Id $id); } # Return result object of script block, job is afterwards deleted.
function PrivGetUserFromName                  ( [String] $username ){ # optionally as domain\username
                                                return [System.Security.Principal.NTAccount] $username; }
function PrivGetUserCurrent                   (){ return [System.Security.Principal.IdentityReference] ([System.Security.Principal.WindowsIdentity]::GetCurrent().User); } # alternative: PrivGetUserFromName "$env:userdomain\$env:USERNAME"
function PrivGetUserSystem                    (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18"                                                      )).Translate([System.Security.Principal.NTAccount]); } # NT AUTHORITY\SYSTEM = NT-AUTORITÄT\SYSTEM
function PrivGetGroupAdministrators           (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544"                                                  )).Translate([System.Security.Principal.NTAccount]); } # BUILTIN\Administrators = VORDEFINIERT\Administratoren  (more https://msdn.microsoft.com/en-us/library/windows/desktop/aa379649(v=vs.85).aspx)
function PrivGetGroupAuthenticatedUsers       (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-11"                                                      )).Translate([System.Security.Principal.NTAccount]); } # NT AUTHORITY\Authenticated Users = NT-AUTORITÄT\Authentifizierte Benutzer
function PrivGetGroupEveryone                 (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0"                                                       )).Translate([System.Security.Principal.NTAccount]); } # Jeder
function PrivGetUserTrustedInstaller          (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464")).Translate([System.Security.Principal.NTAccount]); } # NT SERVICE\TrustedInstaller
function PrivFsRuleAsString                   ( [System.Security.AccessControl.FileSystemAccessRule] $rule ){
                                                return [String] "($($rule.IdentityReference);$(($rule.FileSystemRights).ToString().Replace(' ',''));$($rule.InheritanceFlags.ToString().Replace(' ',''));$($rule.PropagationFlags.ToString().Replace(' ',''));$($rule.AccessControlType);IsInherited=$($rule.IsInherited))";
                                                } # for later: CentralAccessPolicyId, CentralAccessPolicyName, Sddl="O:BAG:SYD:PAI(A;OICI;FA;;;SY)(A;;FA;;;BA)"
function PrivAclAsString                      ( [System.Security.AccessControl.FileSystemSecurity] $acl ){
                                                [String] $s = "Owner=$($acl.Owner);Group=$($acl.Group);Acls=";
                                                foreach( $a in $acl.Access){ $s += PrivFsRuleAsString $a; } return [String] $s; }
function PrivAclSetProtection                 ( [System.Security.AccessControl.ObjectSecurity] $acl, [Boolean] $isProtectedFromInheritance, [Boolean] $preserveInheritance ){
                                                # set preserveInheritance to false to remove inherited access rules, param is ignored if $isProtectedFromInheritance is false.
                                                $acl.SetAccessRuleProtection($isProtectedFromInheritance, $preserveInheritance); }
function PrivFsRuleCreateFullControl          ( [System.Security.Principal.IdentityReference] $account, [Boolean] $useInherit ){ # for dirs usually inherit is used
                                                [System.Security.AccessControl.InheritanceFlags] $inh = switch($useInherit){ ($false){[System.Security.AccessControl.InheritanceFlags]::None} ($true){[System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"} };
                                                [System.Security.AccessControl.PropagationFlags] $prf = switch($useInherit){ ($false){[System.Security.AccessControl.PropagationFlags]::None} ($true){[System.Security.AccessControl.PropagationFlags]::None                          } }; # alternative [System.Security.AccessControl.PropagationFlags]::InheritOnly
                                                return [System.Security.AccessControl.FileSystemAccessRule] (PrivFsRuleCreate $account ([System.Security.AccessControl.FileSystemRights]::FullControl) $inh $prf ([System.Security.AccessControl.AccessControlType]::Allow)); }
function PrivFsRuleCreateByString             ( [System.Security.Principal.IdentityReference] $account, [String] $s ){
                                                # format:  access inherit rights ; access = ('+'|'-') ; rights = ('F' | { ('R'|'M'|'W'|'X'|...) [','] } ) ; inherit = ('/'|'') ;
                                                # examples: "+F", "+F/", "-M", "+RM", "+RW"
                                                [System.Security.AccessControl.AccessControlType] $access = 0;
                                                [String] $a = (StringLeft $s 1);
                                                if    ( $a -eq "+" ){ $access = [System.Security.AccessControl.AccessControlType]::Allow; }
                                                elseif( $a -eq "-" ){ $access = [System.Security.AccessControl.AccessControlType]::Deny ; }
                                                else{ throw [Exception] "Invalid permission-right string, missing '+' or '-' at beginning of: `"$s`""; }
                                                $s = $s.Substring(1);
                                                [Boolean] $useInherit = $false;
                                                if( (StringRight $s 1) -eq "/" ){ $useInherit = $true; $s = (StringLeft $s ($s.Length-1)); }
                                                [String[]] $r = @()+(StringSplitToArray "," $s $true);
                                                [System.Security.AccessControl.FileSystemRights] $rights = (PrivAclFsRightsFromString $r);
                                                [System.Security.AccessControl.InheritanceFlags] $inh = switch($useInherit){ ($false){[System.Security.AccessControl.InheritanceFlags]::None} ($true){[System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"} };
                                                [System.Security.AccessControl.PropagationFlags] $prf = switch($useInherit){ ($false){[System.Security.AccessControl.PropagationFlags]::None} ($true){[System.Security.AccessControl.PropagationFlags]::None                          } }; # alternative [System.Security.AccessControl.PropagationFlags]::InheritOnly
                                                return [System.Security.AccessControl.FileSystemAccessRule] (PrivFsRuleCreate $account $rights $inh $prf $access); }
function PrivDirSecurityCreateFullControl     ( [System.Security.Principal.IdentityReference] $account ){
                                                [System.Security.AccessControl.DirectorySecurity] $result = New-Object System.Security.AccessControl.DirectorySecurity;
                                                $result.AddAccessRule((PrivFsRuleCreateFullControl $account $true));
                                                return [System.Security.AccessControl.DirectorySecurity] $result; }
function PrivFileSecurityCreateOwner          ( [System.Security.Principal.IdentityReference] $account ){
                                                [System.Security.AccessControl.FileSecurity] $result = New-Object System.Security.AccessControl.FileSecurity;
                                                $result.SetOwner($account);
                                                return [System.Security.AccessControl.FileSecurity] $result; }
function PrivAclHasFullControl                ( [System.Security.AccessControl.FileSystemSecurity] $acl, [System.Security.Principal.IdentityReference] $account, [Boolean] $isDir ){
                                                [Object] $a = $acl.Access | Where-Object{$null -ne $_} |
                                                   Where-Object{ $_.IdentityReference -eq $account } |
                                                   Where-Object{ $_.FileSystemRights -eq "FullControl" -and $_.AccessControlType -eq "Allow" } |
                                                   Where-Object{ -not $isDir -or ($_.InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ContainerInherit) -and $_.InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ObjectInherit)) };
                                                   Where-Object{ -not $isDir -or $_.PropagationFlags -eq [System.Security.AccessControl.PropagationFlags]::None }
                                                 return [Boolean] ($null -ne $a); }
function PrivShowTokenPrivileges              (){
                                                whoami /priv; }
function PrivEnableTokenPrivilege             (){
                                                # Required for example for Set-ACL if it returns "The security identifier is not allowed to be the owner of this object.";
                                                # Then you need for example the Privilege SeRestorePrivilege;
                                                # Based on https://gist.github.com/fernandoacorreia/3997188
                                                #   or http://www.leeholmes.com/blog/2010/09/24/adjusting-token-privileges-in-powershell/
                                                #   or https://social.technet.microsoft.com/forums/windowsserver/en-US/e718a560-2908-4b91-ad42-d392e7f8f1ad/take-ownership-of-a-registry-key-and-change-permissions
                                                # Alternative: https://www.powershellgallery.com/packages/PoshPrivilege/0.3.0.0/Content/Scripts%5CEnable-Privilege.ps1
                                                Param(
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
                                                $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable) | Out-Null; }
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
function PrivAclFsRightsToString              ( [System.Security.AccessControl.FileSystemRights] $r ){ # as ICACLS https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls
                                                [String] $s = "";
                                                # Ref: https://referencesource.microsoft.com/#mscorlib/system/security/accesscontrol/filesecurity.cs
                                                # Ref: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=netframework-4.8
                                                if(   $r -band [System.Security.AccessControl.FileSystemRights]::FullControl                        ){ $s += "F,"   ; } # exert full control over a folder or file, and to modify access control and audit rules. This value represents the right to do anything with a file and is the combination of all rights in this enumeration.
                                                else{
                                                  [Boolean] $notR = -not ($r -band [System.Security.AccessControl.FileSystemRights]::Read);
                                                  [Boolean] $notM = -not ($r -band [System.Security.AccessControl.FileSystemRights]::Modify);
                                                  [Boolean] $notW = -not ($r -band [System.Security.AccessControl.FileSystemRights]::Write);
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::Read                               ){ $s += "R,"   ; } # Same as ReadData|ReadExtendedAttributes|ReadAttributes|ReadPermissions. open and copy folders or files as read-only.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::Modify                             ){ $s += "M,"   ; } # Same as Read|ExecuteFile|Write|Delete.                                  read, write, list folder contents, delete folders and files, and run application files.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::Write                              ){ $s += "W,"   ; } # Same as WriteData|AppendData|WriteExtendedAttributes|WriteAttributes.   create folders and files, and to add or remove data from files.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::ExecuteFile                        ){ $s += "X,"   ; } # run an application file. For directories: list the contents of a folder and to run applications contained within that folder.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::Synchronize                        ){ $s += "s,"   ; } # whether the application can wait for a file handle to synchronize with the completion of an I/O operation. This value is automatically set when allowing access and automatically excluded when denying access.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::Delete                  -and $notM ){ $s += "d,"   ; } # delete a folder or file.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::ReadData                -and $notR ){ $s += "rd,"  ; } # open and copy a file or folder. This does not include the right to read file system attributes, extended file system attributes, or access and audit rules. For directories: read the contents of a directory.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::ReadExtendedAttributes  -and $notR ){ $s += "rea," ; } # open and copy extended file system attributes from a folder or file. For example, this value specifies the right to view author and content information. This does not include the right to read data, file system attributes, or access and audit rules.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::ReadAttributes          -and $notR ){ $s += "ra,"  ; } # open and copy file system attributes from a folder or file. For example, this value specifies the right to view the file creation or modified date. This does not include the right to read data, extended file system attributes, or access and audit rules.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::ReadPermissions         -and $notR ){ $s += "rc,"  ; } # read control, open and copy access and audit rules from a folder or file. This does not include the right to read data, file system attributes, and extended file system attributes.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::WriteData               -and $notW ){ $s += "wd,"  ; } # open and write to a file or folder. This does not include the right to open and write file system attributes, extended file system attributes, or access and audit rules. For directories: create a file. This right requires the Synchronize value.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::AppendData              -and $notW ){ $s += "ad,"  ; } # append data to the end of a file. For directories: create a folder This right requires the Synchronize value.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -and $notW ){ $s += "wea," ; } # open and write extended file system attributes to a folder or file. This does not include the ability to write data, attributes, or access and audit rules.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::WriteAttributes         -and $notW ){ $s += "wa,"  ; } # open and write file system attributes to a folder or file. This does not include the ability to write data, extended attributes, or access and audit rules.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles       ){ $s += "dc,"  ; } # delete a folder and any files contained within that folder. It only makes sense on directories, but the shell explicitly sets it for files in its UI. So its includeed in FullControl.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::ChangePermissions                  ){ $s += "wdac,"; } # change the security and audit rules associated with a file or folder.
                                                  if( $r -band [System.Security.AccessControl.FileSystemRights]::TakeOwnership                      ){ $s += "wo,"  ; } # change the owner of a folder or file. Note that owners of a resource have full access to that resource.
                                                  if( $r -band 0x10000000                                                                           ){ $s += "ga,"  ; } # generic all
                                                  if( $r -band 0x80000000                                                                           ){ $s += "gr,"  ; } # generic read
                                                  if( $r -band 0x20000000                                                                           ){ $s += "ge,"  ; } # generic execute
                                                  if( $r -band 0x40000000                                                                           ){ $s += "gw,"  ; } # generic write
                                                  # Not yet used: ListDirectory=ReadData; Traverse=ExecuteFile; CreateFiles=WriteData; CreateDirectories=AppendData; ReadAndExecute=Read|ExecuteFile=RX(=open and copy folders or files as read-only, and to run application files. This right includes the Read right and the ExecuteFile right).
                                                }
                                                return [String] $s; }
function PrivAclFsRightsFromString            ( [String] $s ){ # inverse of PrivAclFsRightsToString
                                                [System.Security.AccessControl.FileSystemRights] $result = 0x00000000;
                                                [String[]] $r = @()+(StringSplitToArray "," $s $true);
                                                $r | Where-Object{$null -ne $_} | ForEach-Object{
                                                  [String] $w = switch($_){
                                                    "F"   {"FullControl"}
                                                    "R"   {"Read"}
                                                    "M"   {"Modify"}
                                                    "W"   {"Write"}
                                                    "X"   {"ExecuteFile"}
                                                    "s"   {"Synchronize"}
                                                    "d"   {"Delete"}
                                                    "rd"  {"ReadData"}
                                                    "rea" {"ReadExtendedAttributes"}
                                                    "ra"  {"ReadAttributes"}
                                                    "rc"  {"ReadPermissions"}
                                                    "wd"  {"WriteData"}
                                                    "ad"  {"AppendData"}
                                                    "wea" {"WriteExtendedAttributes"}
                                                    "wa"  {"WriteAttributes"}
                                                    "dc"  {"DeleteSubdirectoriesAndFiles"}
                                                    "wdac"{"ChangePermissions"}
                                                    "wo"  {"TakeOwnership"}
                                                    default {""}};
                                                  if( $w -eq "" ){ throw [Exception] "Invalid FileSystemRight-Code `"$_`"."; }
                                                  $result = $result -bor ([System.Security.AccessControl.FileSystemRights]$w);
                                                }; return [System.Security.AccessControl.FileSystemRights] $result; }
function RegistryMapToShortKey                ( [String] $key ){ # Note: HKCU: will be replaced by HKLM:\SOFTWARE\Classes" otherwise it would not work
                                                if( -not $key.StartsWith("HKEY_","CurrentCultureIgnoreCase") ){ return [String] $key; }
                                                return [String] $key.Replace("HKEY_LOCAL_MACHINE:","HKLM:").Replace("HKEY_CURRENT_USER:","HKCU:").Replace("HKEY_CLASSES_ROOT:","HKCR:").Replace("HKCR:","HKLM:\SOFTWARE\Classes").Replace("HKEY_USERS:","HKU:").Replace("HKEY_CURRENT_CONFIG:","HKCC:"); }
function RegistryRequiresElevatedAdminMode    ( [String] $key ){
                                                if( (RegistryMapToShortKey $key).StartsWith("HKLM:","CurrentCultureIgnoreCase") ){ ProcessRestartInElevatedAdminMode; } }
function RegistryAssertIsKey                  ( [String] $key ){
                                                $key = RegistryMapToShortKey $key;
                                                if( $key.StartsWith("HK","CurrentCultureIgnoreCase") ){ return; }
                                                throw [Exception] "Missing registry key instead of: `"$key`""; }
function RegistryExistsKey                    ( [String] $key ){
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key;
                                                return [Boolean] (Test-Path $key); }
function RegistryExistsValue                  ( [String] $key, [String] $name = ""){
                                                $key = RegistryMapToShortKey $key;
                                                RegistryAssertIsKey $key;
                                                if( $name -eq "" ){ $name = "(default)"; }
                                                [Object] $k = Get-Item -Path $key -ErrorAction SilentlyContinue;
                                                return [Boolean] ($k -and $null -ne $k.GetValue($name, $null)); }
function RegistryCreateKey                    ( [String] $key ){  # creates key if not exists
                                                $key = RegistryMapToShortKey $key; RegistryAssertIsKey $key;
                                                if( -not (RegistryExistsKey $key) ){
                                                  OutProgress "RegistryCreateKey `"$key`"";
                                                  RegistryRequiresElevatedAdminMode $key;
                                                  New-Item -Force -Path $key | Out-Null; } }
function RegistryGetValueAsObject             ( [String] $key, [String] $name = ""){ # Return null if value not exists.
                                                $key = RegistryMapToShortKey $key;
                                                RegistryAssertIsKey $key;
                                                if( $name -eq "" ){ $name = "(default)"; }
                                                [Object] $v = Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue;
                                                if( $null -eq $v ){ return [Object] $null; }else{ return [Object] $v.$name; } }
function RegistryGetValueAsString             ( [String] $key, [String] $name = "" ){ # return empty string if value not exists
                                                $key = RegistryMapToShortKey $key;
                                                RegistryAssertIsKey $key;
                                                [Object] $obj = RegistryGetValueAsObject $key $name;
                                                if( $null -eq $obj ){ return [String] ""; }
                                                return [String] $obj.ToString(); }
function RegistryListValueNames               ( [String] $key ){
                                                $key = RegistryMapToShortKey $key;
                                                RegistryAssertIsKey $key;
                                                return [String[]] (Get-Item -Path $key).GetValueNames(); } # Throws if key not found, if (default) value is assigned then empty string is returned for it.
function RegistryDelKey                       ( [String] $key ){
                                                $key = RegistryMapToShortKey $key;
                                                RegistryAssertIsKey $key;
                                                if( -not (RegistryExistsKey $key) ){ return; }
                                                OutProgress "RegistryDelKey `"$key`"";
                                                RegistryRequiresElevatedAdminMode;
                                                Remove-Item -Path "$key"; }
function RegistryDelValue                     ( [String] $key, [String] $name = "" ){
                                                $key = RegistryMapToShortKey $key;
                                                RegistryAssertIsKey $key;
                                                if( $name -eq "" ){ $name = "(default)"; }
                                                if( -not (RegistryExistsValue $key $name) ){ return; }
                                                OutProgress "RegistryDelValue `"$key`" `"$name`"";
                                                RegistryRequiresElevatedAdminMode;
                                                Remove-ItemProperty -Path $key -Name $name; }
function RegistrySetValue                     ( [String] $key, [String] $name, [String] $type, [Object] $val, [Boolean] $overwriteEvenIfStringValueIsEqual = $false ){
                                                # Creates key-value if it not exists; value is changed only if it is not equal than previous value;
                                                # available types (https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-itemproperty and
                                                #                  https://learn.microsoft.com/de-de/windows/win32/sysinfo/registry-value-types):
                                                #   String         REG_SZ         String, null-terminated.
                                                #   ExpandString   REG_EXPAND_SZ  String can contain variables as %PATH%, null-terminated. internally expanded at runtime by [Environment]::ExpandEnvironmentVariables().
                                                #   Binary         REG_BINARY     Binary.
                                                #   DWord          REG_DWORD      32-Bit integer.
                                                #   MultiString    REG_MULTI_SZ   Sequence of null-terminated strings, ended with null-term.
                                                #   QWord          REG_QWORD      64-Bit integer.
                                                #   Unknown        .              Other non supported types as REG_RESOURCE_LIST, REG_DWORD_LITTLE_ENDIAN, REG_DWORD_BIG_ENDIAN, REG_LINK, REG_NONE, REG_QWORD_LITTLE_ENDIAN
                                                $key = RegistryMapToShortKey $key;
                                                RegistryAssertIsKey $key;
                                                if( $name -eq "" ){ $name = "(default)"; }
                                                RegistryCreateKey $key;
                                                if( -not $overwriteEvenIfStringValueIsEqual ){
                                                  [Object] $obj = RegistryGetValueAsObject $key $name;
                                                  if( $null -ne $obj -and $null -ne $val -and $obj.GetType() -eq $val.GetType() -and $obj.ToString() -eq $val.ToString() ){ return; }
                                                }
                                                try{
                                                  OutProgress "RegistrySetValue `"$key`" `"$name`" `"$type`" `"$val`"";
                                                  Set-ItemProperty -Path $key -Name $name -Type $type -Value $val;
                                                }catch{ # Example: SecurityException: Requested registry access is not allowed.
                                                  throw [Exception] "$(ScriptGetCurrentFunc)($key,$name) failed because $($_.Exception.Message) (often it requires elevated mode)"; } }
function RegistryImportFile                   ( [String] $regFile ){
                                                $regFile = (FsEntryGetAbsolutePath $regFile);
                                                OutProgress "RegistryImportFile `"$regFile`""; FileAssertExists $regFile;
                                                try{ <# unbelievable, it writes success to stderr #>
                                                  & "$env:SystemRoot/System32/reg.exe" "IMPORT" $regFile *>&1 | Out-Null; AssertRcIsOk;
                                                }catch{ <# ignore always: System.Management.Automation.RemoteException Der Vorgang wurde erfolgreich beendet. #>
                                                  [String[]] $expectedMsgs = @( "Der Vorgang wurde erfolgreich beendet.", "The operation completed successfully." );
                                                  if( $expectedMsgs -notcontains $_.Exception.Message ){
                                                    throw [Exception] "$(ScriptGetCurrentFunc)(`"$regFile`") failed. We expected an exc but this must match one of [$(StringArrayDblQuoteItems $expectedMsgs)] but we got: `"$($_.Exception.Message)`"";
                                                  }
                                                  ScriptResetRc; } }
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
                                                [String[]] $s = (@()+($key -split ":\\",2)); # means only one backslash
                                                if( $s.Count -le 1 ){ throw [Exception] "Missing `":\`" in `"$key`""; }
                                                return [String] $s[1]; }
function RegistryPrivRuleCreate               ( [System.Security.Principal.IdentityReference] $account, [String] $regRight = "" ){
                                                # Example: (PrivGetGroupAdministrators) "FullControl";
                                                # regRight Example: "ReadKey", available enums: https://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights(v=vs.110).aspx
                                                if( $regRight -eq "" ){ return [System.Security.AccessControl.AccessControlSections]::None; }
                                                $inh = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit";
                                                $pro = [System.Security.AccessControl.PropagationFlags]::None;
                                                return New-Object System.Security.AccessControl.RegistryAccessRule($account,[System.Security.AccessControl.RegistryRights]$regRight,$inh,$pro,[System.Security.AccessControl.AccessControlType]::Allow); }
                                                # alternative: "ObjectInherit,ContainerInherit"
function RegistryPrivRuleToString             ( [System.Security.AccessControl.RegistryAccessRule] $rule ){
                                                # Example: RegistryPrivRuleToString (RegistryPrivRuleCreate (PrivGetGroupAdministrators) "FullControl")
                                                [String] $s = "$($rule.IdentityReference.ToString()):"; # Example: VORDEFINIERT\Administratoren    TODO: use english
                                                if( $rule.AccessControlType -band [System.Security.AccessControl.AccessControlType]::Allow             ){ $s += "+"; }
                                                if( $rule.AccessControlType -band [System.Security.AccessControl.AccessControlType]::Deny              ){ $s += "-"; }
                                                if( $rule.IsInherited ){
                                                  $s += "I,";
                                                  if(   $rule.InheritanceFlags -eq   [System.Security.AccessControl.InheritanceFlags]::None              ){ $s += ""; }
                                                  else{
                                                    if( $rule.InheritanceFlags -band [System.Security.AccessControl.InheritanceFlags]::ContainerInherit  ){ $s += "IC,"; }
                                                    if( $rule.InheritanceFlags -band [System.Security.AccessControl.InheritanceFlags]::ObjectInherit     ){ $s += "IO,"; }
                                                  }
                                                  if(   $rule.PropagationFlags -eq   [System.Security.AccessControl.PropagationFlags]::None              ){ $s += ""; }
                                                  else{
                                                    if( $rule.PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::NoPropagateInherit){ $s += "PN,"; }
                                                    if( $rule.PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::InheritOnly       ){ $s += "PI,"; }
                                                  }
                                                }
                                                $s += (PrivAclRegRightsToString $rule.RegistryRights);
                                                return [String] $s; }
function RegistryKeyGetOwnerAsString          ( [String] $key ){
                                                # Example: "HKLM:\Software\MyManufactor"
                                                $key = RegistryMapToShortKey $key;
                                                [Microsoft.Win32.RegistryKey] $hk = [Microsoft.Win32.RegistryKey]::OpenBaseKey((RegistryKeyGetHkey $key),[Microsoft.Win32.RegistryView]::Default);
                                                [Microsoft.Win32.RegistryKey] $k = $hk.OpenSubKey((RegistryKeyGetSubkey $key),[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree);
                                                [System.Security.AccessControl.RegistrySecurity] $acl = $k.GetAccessControl();
                                                [System.Security.Principal.IdentityReference] $owner = $acl.GetOwner([System.Security.Principal.NTAccount]);
                                                return [String] $owner.Value; }
function RegistryKeySetOwner                  ( [String] $key, [System.Security.Principal.IdentityReference] $account ){
                                                # Example: "HKLM:\Software\MyManufactor" (PrivGetGroupAdministrators);
                                                # Changes only if owner is not yet the required one.
                                                # Note: Throws PermissionDenied if object is protected by TrustedInstaller.
                                                # Use force this if object is protected by TrustedInstaller,
                                                # then it asserts elevated mode and enables some token privileges.
                                                $key = RegistryMapToShortKey $key;
                                                OutProgress "RegistryKeySetOwner `"$key`" `"$($account.ToString())`"";
                                                if( (RegistryKeyGetOwnerAsString $key) -eq $account.Value ){ return; }
                                                RegistryRequiresElevatedAdminMode;
                                                PrivEnableTokenPrivilege SeTakeOwnershipPrivilege;
                                                PrivEnableTokenPrivilege SeRestorePrivilege;
                                                PrivEnableTokenPrivilege SeBackupPrivilege;
                                                #[System.Security.AccessControl.RegistrySecurity] $acl = Get-Acl -Path $key;
                                                try{
                                                  [Microsoft.Win32.RegistryKey] $hk = [Microsoft.Win32.RegistryKey]::OpenBaseKey((RegistryKeyGetHkey $key),[Microsoft.Win32.RegistryView]::Default);
                                                  [Microsoft.Win32.RegistryKey] $k = $hk.OpenSubKey((RegistryKeyGetSubkey $key),[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership);
                                                  [System.Security.AccessControl.RegistrySecurity] $acl = $k.GetAccessControl([System.Security.AccessControl.AccessControlSections]::None); # alternatives: None, Audit, Access, Owner, Group, All
                                                  if( (ProcessIsLesserEqualPs5) ){                 $acl = $k.GetAccessControl([System.Security.AccessControl.AccessControlSections]::All); }
                                                  if( $acl.Owner -eq $account.Value ){ return; }
                                                  $acl.SetOwner([System.Security.Principal.NTAccount]$account);
                                                  $k.SetAccessControl($acl);
                                                  $k.Close(); $hk.Close();
                                                  # alternative but sometimes access denied (probably same problem as with the AccessControlSections None and All):
                                                  #   [System.Security.AccessControl.RegistrySecurity] $acl = RegistryKeyGetAcl $key;
                                                  #   $acl.SetOwner($account); Set-Acl -Path $key -AclObject $acl;
                                                }catch{ throw [Exception] "$(ScriptGetCurrentFunc)($key,$account) failed because $($_.Exception.Message)"; } }
function RegistryKeySetAclRight               ( [String] $key, [System.Security.Principal.IdentityReference] $account, [String] $regRight = "FullControl" ){
                                                # Example: "HKLM:\Software\MyManufactor" (PrivGetGroupAdministrators) "FullControl";
                                                RegistryKeySetAclRule $key (RegistryPrivRuleCreate $account $regRight); }
function RegistryKeyAddAclRule                ( [String] $key, [System.Security.AccessControl.RegistryAccessRule] $rule ){
                                                RegistryKeySetAclRule $key $rule $true; }
function RegistryKeySetAclRule                ( [String] $key, [System.Security.AccessControl.RegistryAccessRule] $rule, [Boolean] $useAddNotSet = $false ){
                                                # Example: "HKLM:\Software\MyManufactor" (RegistryPrivRuleCreate (PrivGetGroupAdministrators) "FullControl");
                                                $key = RegistryMapToShortKey $key;
                                                [String] $traceInfo = "$(ScriptGetCurrentFunc)(`"$key`",`"$(RegistryPrivRuleToString $rule)`",useAddNotSet=$useAddNotSet)";
                                                OutProgress $traceInfo;
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
                                                }catch{ throw [Exception] "$traceInfo failed because $($_.Exception.Message)"; } }
function ServiceListRunnings                  (){
                                                return [String[]] (@()+(Get-Service -ErrorAction SilentlyContinue * |
                                                  # 2023-03: for: get-service McpManagementService on we got the following error without any specific error:
                                                  #   "Get-Service: Service 'McpManagementService (McpManagementService)' cannot be queried due to the following error:"
                                                  #   In services.msc the description is "<Fehler beim Lesen der Beschreibung. Fehlercode: 15100 >".
                                                  # Since around 10 years thats the first error on this command, according googling it happens on Win10 and Win11,
                                                  # please Microsoft fix this asap.
                                                  # The workaround is to use (ErrorAction SilentlyContinue) what is a dirty solution.
                                                  # unbelievable but even with the ErrorAction set we got the following exception (later it went ok):
                                                  # 2024-06-25 On mach=mus*** Win32Exception: The resource loader failed to find MUI file.
                                                  #   StackTrace: at System.ServiceProcess.ServiceController.get_StartType()
                                                  #               at Microsoft.PowerShell.Commands.GetServiceCommand.AddProperties(ServiceController service)
                                                  #               at Microsoft.PowerShell.Commands.GetServiceCommand.ProcessRecord()
                                                  #               at System.Management.Automation.CommandProcessor.ProcessRecord()
                                                  #   ScriptStackTrace:
                                                  #     at ServiceListRunnings, C:\Program Files\WindowsPowerShell\Modules\MnCommonPsToolLib\MnCommonPsToolLib_Windows.ps1: line 462
                                                  #   InvocationInfo:
                                                  #     At C:\Program Files\WindowsPowerShell\Modules\MnCommonPsToolLib\MnCommonPsToolLib_Windows.ps1:462 char:73
                                                  #       + … return [String[]] (@()+(Get-Service -ErrorAction SilentlyContinue * |
                                                  Where-Object{ $_.Status -eq "Running" } |
                                                  Sort-Object Name |
                                                  Format-Table -AutoSize -HideTableHeaders " ",Name,DisplayName |
                                                  StreamToStringDelEmptyLeadAndTrLines)); }
function ServiceListExistings                 (){ # We could also use Get-Service but members are lightly differnet;
                                                # 2017-06 we got (RuntimeException: You cannot call a method on a null-valued expression.) so we added null check.
                                                return [CimInstance[]](@()+(Get-CimInstance win32_service | Where-Object{$null -ne $_} | Sort-Object ProcessId,Name)); }
function ServiceListExistingsAsStringArray    (){
                                                return [String[]] (@()+(StringSplitIntoLines (@()+(ServiceListExistings | Where-Object{$null -ne $_} |
                                                  Format-Table -AutoSize -HideTableHeaders ProcessId,Name,StartMode,State | StreamToStringDelEmptyLeadAndTrLines )))); }
function ServiceNotExists                     ( [String] $serviceName ){
                                                return [Boolean] -not (ServiceExists $serviceName); }
function ServiceExists                        ( [String] $serviceName ){
                                                return [Boolean] ($null -ne (Get-Service $serviceName -ErrorAction SilentlyContinue)); }
function ServiceAssertExists                  ( [String] $serviceName ){
                                                OutVerbose "Assert service exists: $serviceName";
                                                Assert (ServiceExists $serviceName) "service not exists: $serviceName"; }
function ServiceGet                           ( [String] $serviceName ){
                                                return [Object] (Get-Service -Name $serviceName -ErrorAction SilentlyContinue); # Standard result is name,displayname,status.
                                                # Some Service Properties:
                                                #   ErrorControl:
                                                #     0x3=Critical  Fail the attempted system startup. If the startup is not using the LastKnownGood control set, switch to LastKnownGood. If the startup attempt is using LastKnownGood, run a bug-check routine.
                                                #     0x2=Severe    If the startup is not using the LastKnownGood control set, switch to LastKnownGood. If the startup attempt is using LastKnownGood, continue on in case of error.
                                                #     0x1=Normal    If the driver fails to load or initialize, startup should proceed, but display a warning.
                                                #     0x0=Ignore    If the driver fails to load or initialize, start up proceeds. No warning is displayed.
                                                #   Start:
                                                #     0x0=Boot      Loader: Kernel driver            Represents a part of the stack for the boot (startup) volume and must therefore be loaded by the Boot Loader.
                                                #     0x1=System    Loader: I/O  subsystem           Represents a driver to be loaded at Kernel initialization.
                                                #     0x2=Autoload  Loader: Service Control Manager  To be loaded or started automatically for all startups, regardless of service type.
                                                #     0x3=Manual    Loader: Service Control Manager  Load on demand Available, regardless of type, but will not be started until the user starts it, (for example, by using the Devices icon in Control Panel).
                                                #     0x4=disabled  Loader: Service Control Manager  NOT TO BE STARTED UNDER ANY CONDITIONS.
                                                #   Type:
                                                #     0x1   A Kernel device driver.
                                                #     0x2   File system driver, which is also a Kernel device driver.
                                                #     0x4   A set of arguments for an adapter.
                                                #     0x10  A Win32 program that can be started by the Service Controller and that obeys the service control protocol. This type of Win32 service runs in a process by itself.
                                                #     0x20  A Win32 service that can share a process with other Win32 services.
                                                }
function ServiceGetState                      ( [String] $serviceName ){
                                                [Object] $s = ServiceGet $serviceName;
                                                if( $null -eq $s ){ return [String] ""; }
                                                return [String] $s.Status; }
                                                # ServiceControllerStatus: "","ContinuePending","Paused","PausePending","Running","StartPending","Stopped","StopPending".
function ServiceStop                          ( [String] $serviceName, [Boolean] $ignoreIfFailed = $false, [Boolean] $suppressWarningIfFailed = $false ){
                                                [String] $s = ServiceGetState $serviceName;
                                                if( $s -eq "" -or $s -eq "stopped" ){ return; }
                                                OutProgress "ServiceStop $serviceName $(switch($ignoreIfFailed){($true){'ignoreIfFailed'}default{''}}) $(switch($suppressWarningIfFailed){($true){'suppressWarningIfFailed'}default{''}})";
                                                ProcessRestartInElevatedAdminMode;
                                                try{ Stop-Service -Name $serviceName; } # Instead of check for stopped service we could also use -PassThru.
                                                catch{
                                                  # Example: ServiceCommandException: Service 'Check Point Endpoint Security VPN (TracSrvWrapper)' cannot be stopped
                                                  #   due to the following error: Cannot stop TracSrvWrapper service on computer '.'.
                                                  if( $ignoreIfFailed ){
                                                    if( -not $suppressWarningIfFailed ){ OutWarning "Warning: Stopping service failed, ignored: $($_.Exception.Message)"; }
                                                  }else{ throw; }
                                                } }
function ServiceStart                         ( [String] $serviceName ){
                                                OutVerbose "Check if either service $ServiceName is running or otherwise go in elevate mode and start service";
                                                [String] $s = ServiceGetState $serviceName;
                                                if( $s -eq "" ){ throw [Exception] "Service not exists: `"$serviceName`""; }
                                                if( $s -eq "Running" ){ return; }
                                                OutProgress "ServiceStart $serviceName";
                                                ProcessRestartInElevatedAdminMode;
                                                Start-Service -Name $serviceName; } # alternative: -displayname or Restart-Service
function ServiceSetStartType                  ( [String] $serviceName, [String] $startType, [Boolean] $errorAsWarning = $false ){
                                                [String] $startTypeExt = switch($startType){ "Disabled" {$startType} "Manual" {$startType} "Automatic" {$startType} "Automatic_Delayed" {"Automatic"}
                                                  default { throw [Exception] "Unknown startType=$startType expected Disabled,Manual,Automatic,Automatic_Delayed."; } };
                                                [Nullable[UInt32]] $targetDelayedAutostart = switch($startType){ "Automatic" {0} "Automatic_Delayed" {1} default {$null} };
                                                [String] $key = "HKLM:\System\CurrentControlSet\Services\$serviceName";
                                                [String] $regName = "DelayedAutoStart";
                                                [UInt32] $delayedAutostart = RegistryGetValueAsObject $key $regName; # null converted to 0
                                                [Object] $s = ServiceGet $serviceName;
                                                if( $null -eq $s ){ throw [Exception] "Service $serviceName not exists"; }
                                                if( $s.StartType -ne $startTypeExt -or ($null -ne $targetDelayedAutostart -and $targetDelayedAutostart -ne $delayedAutostart) ){
                                                  OutProgress "$(ScriptGetCurrentFunc) `"$serviceName`" $startType";
                                                  if( $s.StartType -ne $startTypeExt ){
                                                    ProcessRestartInElevatedAdminMode;
                                                    try{ Set-Service -Name $serviceName -StartupType $startTypeExt;
                                                    }catch{
                                                      # Example: for aswbIDSAgent which is antivir protection we got:
                                                      #   ServiceCommandException: Service ... cannot be configured due to the following error: Zugriff verweigert
                                                      [String] $msg = "$(ScriptGetCurrentFunc)($serviceName,$startType) because $($_.Exception.Message)";
                                                      if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                      OutWarning "Warning: Ignore failing of $msg";
                                                    }
                                                  }
                                                  if( $null -ne $targetDelayedAutostart -and $targetDelayedAutostart -ne $delayedAutostart ){
                                                    RegistrySetValue $key $regName "DWORD" $targetDelayedAutostart;
                                                    # Default autostart delay of 120 sec is stored at: HKLM\SYSTEM\CurrentControlSet\services\$serviceName\AutoStartDelay = DWORD n
                                                  } } }
function ServiceMapHiddenToCurrentName        ( [String] $serviceName ){
                                                # Hidden services on Windows 10: Some services do not have a static service name because they do not have any associated DLL or executable.
                                                # This method maps a symbolic name as MessagingService_###### by the currently correct service name (example: "MessagingService_26a344").
                                                # The ###### symbolizes a random hex string of 5-6 chars. Example: (ServiceMapHiddenName "MessagingService_######") -eq "MessagingService_26a344";
                                                # Currently all these known hidden services are internally started by "C:\WINDOWS\System32\svchost.exe -k UnistackSvcGroup". The following are known:
                                                [String[]] $a = @( "MessagingService_######", "PimIndexMaintenanceSvc_######", "UnistoreSvc_######", "UserDataSvc_######", "WpnUserService_######", "CDPUserSvc_######", "OneSyncSvc_######" );
                                                if( $a -notcontains $serviceName ){ return [String] $serviceName; }
                                                [String] $mask = $serviceName.Replace("_######","_*");
                                                [String] $result = (Get-Service * |
                                                  Where-Object{$null -ne $_} |
                                                  ForEach-Object{ Name } |
                                                  Where-Object{ $_ -like $mask } |
                                                  Sort-Object |
                                                  Select-Object -First 1);
                                                if( $result -eq "" ){ $result = $serviceName;}
                                                return [String] $result; }
function TaskList                             (){
                                                Get-ScheduledTask | Where-Object{$null -ne $_} |
                                                  Select-Object @{Name="Name";Expression={($_.TaskPath+$_.TaskName)}}, State, Author, Description |
                                                  Sort-Object Name; }
                                                # alternative: schtasks.exe /query /NH /FO CSV
function TaskIsDisabled                       ( [String] $taskPathAndName ){ # Example: "\Microsoft\VisualStudio\VSIX Auto Update"
                                                [String] $taskPath = (Split-Path -Parent $taskPathAndName); # Example: "\Microsoft\VisualStudio"
                                                if( -not $taskPath.EndsWith("\") ){ $taskPath += "\"; }
                                                [String] $taskName =  Split-Path -Leaf   $taskPathAndName ; # Example: "VSIX Auto Update"
                                                [CimInstance] $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue;
                                                if( $null -eq $task ){ Throw "Task not exists: `"$taskPathAndName`" "; }
                                                return [Boolean] ($task.State -eq "Disabled"); }
function TaskDisable                          ( [String] $taskPathAndName, [Boolean] $useLikeOperator = $false ){
                                                if( $useLikeOperator ){
                                                  TaskList | Where-Object{ $_.Name -like $taskPathAndName } | ForEach-Object{ TaskDisable $_.Name $false; }
                                                  return;
                                                }
                                                [String] $taskPath = (Split-Path -Parent $taskPathAndName); # Example: "\Microsoft\VisualStudio"
                                                if( -not $taskPath.EndsWith("\") ){ $taskPath += "\"; }
                                                [String] $taskName =  Split-Path -Leaf   $taskPathAndName       ; # Example: "VSIX Auto Update"
                                                [CimInstance] $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue;
                                                if( $null -eq $task ){ Throw "Task not exists: `"$taskPathAndName`" "; }
                                                if( -not (TaskIsDisabled $taskPathAndName) ){
                                                  OutProgress "TaskDisable $taskPathAndName"; ProcessRestartInElevatedAdminMode;
                                                  try{ Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName | Out-Null; }
                                                  catch{ OutWarning "Warning: Ignore failing of disabling task `"$taskPathAndName`" because $($_.Exception.Message)"; } } }
function FileNtfsAlternativeDataStreamAdd     ( [String] $srcFile, [String] $adsName, [String] $val ){
                                                Add-Content -Path $srcFile -Value $val -Stream $adsName; }
function FileNtfsAlternativeDataStreamDel     ( [String] $srcFile, [String] $adsName ){
                                                Clear-Content -Path $srcFile -Stream $adsName; }
function FileAdsDownloadedFromInternetAdd     ( [String] $srcFile ){
                                                FileNtfsAlternativeDataStreamAdd $srcFile "Zone.Identifier" "[ZoneTransfer]`nZoneId=3"; }
function FileAdsDownloadedFromInternetDel     ( [String] $srcFile ){
                                                FileNtfsAlternativeDataStreamDel $srcFile "Zone.Identifier"; } # alternative: Unblock-File -LiteralPath $file
function DriveMapTypeToString                 ( [UInt32] $driveType ){
                                                return [String] $(switch($driveType){ 1{"NoRootDir"} 2{"RemovableDisk"} 3{"LocalDisk"} 4{"NetworkDrive"} 5{"CompactDisk"} 6{"RamDisk"} default{"UnknownDriveType=driveType"}}); }
function DriveList                            (){
                                                return [Object[]] (@()+(Get-CimInstance "Win32_LogicalDisk" |
                                                  Where-Object{$null -ne $_} |
                                                  Select-Object DeviceID, FileSystem, Size, FreeSpace, VolumeName, DriveType, @{Name="DriveTypeName";Expression={(DriveMapTypeToString $_.DriveType)}}, ProviderName)) | Format-Table -AutoSize; }
function ShareGetTypeName                     ( [UInt32] $typeNr ){
                                                return [String] $(switch($typeNr){ 0{"DiskDrive"} 1 {"PrintQueue"} 2{"Device"} 3{"IPC"}
                                                2147483648{"DiskDriveAdmin"} 2147483649{"PrintQueueAdmin"} 2147483650{"DeviceAdmin"} 2147483651{"IPCAdmin"} default{"unknownNr=$typeNr"} }); }
function ShareGetTypeNr                       ( [String] $typeName ){
                                                return [UInt32] $(switch($typeName){ "DiskDrive"{0} "PrintQueue"{1} "Device"{2} "IPC"{3}
                                                "DiskDriveAdmin"{2147483648} "PrintQueueAdmin"{2147483649} "DeviceAdmin"{2147483650} "IPCAdmin"{2147483651} default{4294967295} }); }
function ShareExists                          ( [String] $shareName ){
                                                AssertNotEmpty $shareName "shareName";
                                                return [Boolean] ($null -ne (Get-SMBShare | Where-Object{$null -ne $_} |
                                                  Where-Object{ $shareName -ne "" -and (FsEntryPathIsEqual $_.Name $shareName) })); }
function ShareListAll                         ( [String] $selectShareName = "" ){
                                                # uses newer module SmbShare
                                                OutVerbose "List shares selectShareName=`"$selectShareName`"";
                                                # Example: ShareState: Online, ...; ShareType: InterprocessCommunication, PrintQueue, FileSystemDirectory;
                                                return [Object] (Get-SMBShare | Where-Object{$null -ne $_} |
                                                  Where-Object{ $selectShareName -eq "" -or ($_.Name -eq $selectShareName) } |
                                                  Select-Object Name, ShareType, Path, Description, ShareState, ConcurrentUserLimit, CurrentUsers |
                                                  Sort-Object TypeName, Name); }
function ShareLocksList                       ( [String] $fsEntryPath = "" ){
                                                # list currenty read or readwrite locked open files of a share, requires elevated admin mode
                                                $fsEntryPath = FsEntryGetAbsolutePath $fsEntryPath;
                                                ProcessRestartInElevatedAdminMode;
                                                return [Object] (Get-SmbOpenFile | Where-Object{$null -ne $_} | Where-Object{ $_.Path.StartsWith($fsEntryPath,"OrdinalIgnoreCase") } |
                                                  Select-Object FileId, SessionId, Path, ClientComputerName, ClientUserName, Locks | Sort-Object Path); }
function ShareLocksClose                      ( [String] $fsEntryPath = "" ){
                                                # closes locks, Example: $fsEntryPath="D:/Transfer/" or $fsEntryPath="D:/Transfer/MyFile.txt"
                                                $fsEntryPath = FsEntryGetAbsolutePath $fsEntryPath;
                                                ProcessRestartInElevatedAdminMode;
                                                ShareLocksList $fsEntryPath |
                                                  Where-Object{$null -ne $_} |
                                                  ForEach-Object{
                                                    OutProgress "ShareLocksClose `"$($_.Path)`"";
                                                    Close-SmbOpenFile -Force -FileId $_.FileId; }; }
function ShareCreate                          ( [String] $shareName, [String] $dir, [String] $descr = "", [Int32] $nrOfAccessUsers = 25, [Boolean] $ignoreIfAlreadyExists = $true ){
                                                AssertNotEmpty $shareName "shareName";
                                                FsEntryAssertHasTrailingDirSep $dir;
                                                $dir = FsEntryGetAbsolutePath $dir;
                                                DirAssertExists $dir "ShareCreate($shareName)";
                                                [Object] $existingShare = ShareListAll $shareName |
                                                  Where-Object{$null -ne $_} |
                                                  Where-Object{ FsEntryPathIsEqual $_.Path $dir } |
                                                  Select-Object -First 1;
                                                if( $null -ne $existingShare ){
                                                  OutVerbose "Already exists shareName=`"$shareName`" dir=`"$dir`" ";
                                                  if( $ignoreIfAlreadyExists ){ return; }
                                                }
                                                OutVerbose "CreateShare name=`"$shareName`" dir=`"$dir`" ";
                                                ProcessRestartInElevatedAdminMode;
                                                # alternative: -FolderEnumerationMode AccessBased; Note: this is not allowed but it is the default: -ContinuouslyAvailable $true
                                                New-SmbShare -Path $dir -Name $shareName -Description $descr -ConcurrentUserLimit $nrOfAccessUsers -FolderEnumerationMode Unrestricted -FullAccess (PrivGetGroupEveryone) | Out-Null; }
function ShareRemove                          ( [String] $shareName ){ # no action if it not exists
                                                AssertNotEmpty $shareName "shareName";
                                                if( -not (ShareExists $shareName) ){ return; }
                                                OutProgress "Remove shareName=`"$shareName`"";
                                                Remove-SmbShare -Name $shareName -Confirm:$false; }
function MountPointLocksListAll               (){
                                                OutVerbose "List all mount point locks"; return [Object] (Get-SmbConnection |
                                                Select-Object ServerName,ShareName,UserName,Credential,NumOpens,ContinuouslyAvailable,Encrypted,PSComputerName,Redirected,Signed,SmbInstance,Dialect |
                                                Sort-Object ServerName, ShareName, UserName, Credential); }
function MountPointListAll                    (){ # we define mountpoint as a share mapped to a local path
                                                return [Object] (Get-SmbMapping | Select-Object LocalPath, RemotePath, Status); }
function MountPointGetByDrive                 ( [String] $drive ){ # Example: "C:"; return null if not found.
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
                                                return [Object] (Get-SmbMapping -LocalPath $drive -ErrorAction SilentlyContinue); }
function MountPointRemove                     ( [String] $drive, [String] $mountPoint = "", [Boolean] $suppressProgress = $false ){
                                                # Example: "C:"; Also remove PsDrive; drive can be empty then mountPoint must be given
                                                if( $drive -eq "" -and $mountPoint -eq "" ){ throw [Exception] "$(ScriptGetCurrentFunc): missing either drive or mountPoint."; }
                                                if( $drive -ne "" -and -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
                                                FsEntryAssertHasTrailingDirSep $mountPoint;
                                                $mountPoint = FsEntryGetAbsolutePath $mountPoint;
                                                [String] $mnt = FsEntryRemoveTrailingDirSep $mountPoint;
                                                if( $drive -ne "" -and $null -ne (MountPointGetByDrive $drive) ){
                                                  if( -not $suppressProgress ){ OutProgress "MountPointRemove drive=$drive"; }
                                                  Remove-SmbMapping -LocalPath $drive -Force -UpdateProfile;
                                                }
                                                if( $mnt -ne "" -and $null -ne (Get-SmbMapping -RemotePath $mnt -ErrorAction SilentlyContinue) ){
                                                  if( -not $suppressProgress ){ OutProgress "MountPointRemovePath $mountPoint"; }
                                                  Remove-SmbMapping -RemotePath $mnt -Force -UpdateProfile;
                                                }
                                                if( $drive -ne "" -and $null -ne (Get-PSDrive -Name $drive.Replace(":","") -ErrorAction SilentlyContinue) ){
                                                  if( -not $suppressProgress ){ OutProgress "MountPointRemovePsDrive $drive"; }
                                                  Remove-PSDrive -Name $drive.Replace(":","") -Force; # Force means no confirmation
                                                } }
function MountPointCreate                     ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $errorAsWarning = $false ){
                                                # Example: MountPointCreate "S:" "//localhost/Transfer" (CredentialCreate "user1" "mypw")
                                                if( -not $drive.EndsWith(":") ){ throw [Exception] "Expected drive=`"$drive`" with trailing colon"; }
                                                FsEntryAssertHasTrailingDirSep $mountPoint;
                                                $mountPoint = FsEntryGetAbsolutePath $mountPoint;
                                                [String] $mnt = FsEntryRemoveTrailingDirSep $mountPoint;
                                                [String] $us = CredentialGetUsername $cred $true;
                                                [String] $pw = CredentialGetPassword $cred;
                                                [String] $traceInfo = "MountPointCreate drive=$drive mountPoint=$($mountPoint.PadRight(22)) us=$($us.PadRight(12)) pw=*** state=";
                                                [Object] $smbMap = MountPointGetByDrive $drive;
                                                if( $null -ne $smbMap -and (FsEntryPathIsEqual $smbMap.RemotePath $mnt) -and $smbMap.Status -eq "OK" ){
                                                  OutProgress "$($traceInfo)OkNoChange.";
                                                  return;
                                                }
                                                try{
                                                  MountPointRemove $drive $mountPoint $true; # Required because New-SmbMapping has no force param.
                                                  if( $pw -eq ""){
                                                    New-SmbMapping -LocalPath $drive -RemotePath $mnt -Persistent $true -UserName $us | Out-Null;
                                                  }else{
                                                    New-SmbMapping -LocalPath $drive -RemotePath $mnt -Persistent $true -UserName $us -Password $pw | Out-Null;
                                                  }
                                                  OutProgress "$($traceInfo)Ok.";
                                                }catch{
                                                  # Example: System.Exception: New-SmbMapping(Z,\\mydomain\Transfer,mydomain\myuser) failed because Mehrfache Verbindungen zu einem Server
                                                  #          oder einer freigegebenen Ressource von demselben Benutzer unter Verwendung mehrerer Benutzernamen sind nicht zulässig.
                                                  #          Trennen Sie alle früheren Verbindungen zu dem Server bzw. der freigegebenen Ressource, und versuchen Sie es erneut.
                                                  # Example: Der Netzwerkname wurde nicht gefunden.
                                                  # Example: Der Netzwerkpfad wurde nicht gefunden.
                                                  # Example: Das angegebene Netzwerkkennwort ist falsch.
                                                  [String] $excMsg = $_.Exception.Message.Trim();
                                                  [String] $msg = "New-SmbMapping($drive,$mnt,$us) failed because $excMsg";
                                                  if( -not $errorAsWarning ){ throw [Exception] $msg; }
                                                  # also see http://www.winboard.org/win7-allgemeines/137514-windows-fehler-code-liste.html http://www.megos.ch/files/content/diverses/doserrors.txt
                                                  if    ( $excMsg -eq "Der Netzwerkpfad wurde nicht gefunden."                      ){ $msg = "HostNotFound.";  } # 53 BAD_NETPATH
                                                  elseif( $excMsg -eq "Der Netzwerkname wurde nicht gefunden."                      ){ $msg = "NameNotFound.";  } # 67 BAD_NET_NAME
                                                  elseif( $excMsg -eq "Zugriff verweigert"                                          ){ $msg = "AccessDenied.";  } # 5 ACCESS_DENIED:
                                                  elseif( $excMsg -eq "Das angegebene Netzwerkkennwort ist falsch."                 ){ $msg = "WrongPassword."; } # 86 INVALID_PASSWORD
                                                  elseif( $excMsg -eq "Mehrfache Verbindungen zu einem Server oder einer "+
                                                                     "freigegebenen Ressource von demselben Benutzer unter "+
                                                                     "Verwendung mehrerer Benutzernamen sind nicht zulässig. "+
                                                                     "Trennen Sie alle früheren Verbindungen zu dem Server bzw. "+
                                                                     "der freigegebenen Ressource, und versuchen Sie es erneut."   ){ $msg = "MultiConnectionsByMultiUserNamesNotAllowed."; } # 1219 SESSION_CREDENTIAL_CONFLICT
                                                  else {}
                                                  OutProgress "$($traceInfo)$msg";
                                                } }
function NetAdapterListAll                    (){
                                                return [Object[]] (@()+(Get-CimInstance -Class win32_networkadapter | Where-Object{$null -ne $_} |
                                                Select-Object Name,NetConnectionID,MACAddress,Speed,@{Name="Status";Expression={(NetAdapterGetConnectionStatusName $_.NetConnectionStatus)}})); }
function NetGetIpConfig                       (){ # as "IPCONFIG.EXE" "/ALL"
                                                return [Object[]] (@()+(Get-NetIPConfiguration -Detailed -All | Where-Object{$null -ne $_} | Sort-Object InterfaceAlias |
                                                # unused: ComputerName, InterfaceIndex, NetCompartment.CompartmentId, NetCompartment.CompartmentDescription,
                                                #   @{Name="NetIPv6InterfNlMTU";Expression={$_.NetIPv6Interface.NlMTU}},@{Name="NetIPv4InterfNlMTU";Expression={$_.NetIPv4Interface.NlMTU}},
                                                Select-Object InterfaceAlias,InterfaceDescription,@{Name="NetAdSt";Expression={$_.NetAdapter.Status}},
                                                @{Name="IPv4Address";Expression={$_.IPv4Address.IPAddress}},
                                                @{Name="IPv6LinkLocalAddress";Expression={$_.IPv6LinkLocalAddress.IPAddress}},
                                                @{Name="NetAdapterLLAdr";Expression={$_.NetAdapter.LinkLayerAddress}},
                                                @{Name="IPv4InDhcp";Expression={$_.NetIPv4Interface.DHCP}},
                                                @{Name="IPv6InDhcp";Expression={$_.NetIPv6Interface.DHCP}},
                                                @{Name="NetProfilName";Expression={$_.NetProfile.Name}},
                                                @{Name="ProfilCat";Expression={$_.NetProfile.NetworkCategory}},
                                                @{Name="NetProfilIPv4Co";Expression={$_.NetProfile.IPv4Connectivity}},
                                                @{Name="NetProfilIPv6Co";Expression={$_.NetProfile.IPv6Connectivity}},
                                                @{Name="IPv4DefaultGateway";Expression={$_.IPv4DefaultGateway.NextHop}},
                                                @{Name="IPv6DefaultGateway";Expression={$_.IPv6DefaultGateway.NextHop}},
                                                @{Name="DNSServer";Expression={$_.DNSServer.ServerAddresses -join "; "}} )); }
function NetGetIpAddress                      (){ # IP V4 and V6 address configuration and interfaces with which addresses are associated
                                                return [Object[]] (@()+(Get-NetIPAddress | Where-Object{$null -ne $_} | Sort-Object AddressFamily, InterfaceAlias, IPAddress | # unused: InterfaceIndex, SkipAsSource,PolicyStore
                                                Select-Object @{Name="Fam";Expression={$_.AddressFamily}}, InterfaceAlias, IPAddress, Type,PrefixLength,PrefixOrigin,SuffixOrigin,AddressState,ValidLifetime,PreferredLifetime)); }
function NetGetNetView                        (){ # List provided shares (later for portability list mounts)
                                                [String[]] $out = @()+(& "NET.EXE" "VIEW" $ComputerName ); AssertRcIsOk $out; return [String[]] $out; }
function NetGetNetStat                        (){ [String[]] $out = @()+(& "NETSTAT.EXE" "/A"  ); AssertRcIsOk $out; return [String[]] $out; }
function NetGetRoute                          (){ [String[]] $out = @()+(& "ROUTE.EXE" "PRINT" ); AssertRcIsOk $out; return [String[]] $out; }
function NetGetNbtStat                        (){ [String[]] $out = @()+(& "NBTSTAT.EXE" "-N"  ); AssertRcIsOk $out; return [String[]] $out; }
function JuniperNcEstablishVpnConn            ( [String] $secureCredentialFile, [String] $url, [String] $realm ){
                                                [String] $serviceName = "DsNcService";
                                                [String] $vpnProg = "${env:ProgramFiles(x86)}/Juniper Networks/Network Connect 8.0/nclauncher.exe";
                                                # Using: nclauncher [-url Url] [-u username] [-p password] [-r realm] [-help] [-stop] [-signout] [-version] [-d DSID] [-cert client certificate] [-t Time(Seconds min:45, max:600)] [-ir true | false]
                                                # Alternatively we could take: "HKLM:\SOFTWARE\Wow6432Node\Juniper Networks\Network Connect 8.0\InstallPath":  "${env:ProgramFiles(x86)}\Juniper Networks\Network Connect 8.0"
                                                function JuniperNetworkConnectStop(){
                                                  OutProgress "Call: `"$vpnProg`" -signout";
                                                  try{
                                                    [String] $out = (& "$vpnProg" "-signout");
                                                    if( $out -eq "Network Connect is not running. Unable to signout from Secure Gateway." ){
                                                      # Example: "Network Connect wird nicht ausgef³hrt. Die Abmeldung vom sicheren Gateway ist nicht m÷glich."
                                                      ScriptResetRc; OutVerbose "Service is not running.";
                                                    }else{ AssertRcIsOk $out; }
                                                  }catch{ ScriptResetRc; OutProgress "Ignoring signout exception: $($_.Exception.Message)"; }
                                                }
                                                function JuniperNetworkConnectStart( [Int32] $maxPwTries = 9 ){
                                                  for ($i = 1; $i -le $maxPwTries; $i += 1){
                                                    OutVerbose "Read last saved encrypted username and password: `"$secureCredentialFile`"";
                                                    [System.Management.Automation.PSCredential] $cred = CredentialGetAndStoreIfNotExists $secureCredentialFile;
                                                    [String] $us = CredentialGetUsername $cred;
                                                    [String] $pw = CredentialGetPassword $cred;
                                                    OutDebug "UserName=`"$us`"  Password=`"$pw`"";
                                                    OutProgress "Call: $vpnProg -url $url -u $us -r $realm -t 75 -p *** ";
                                                    [String] $out = (& $vpnProg "-url" $url "-u" $us "-r" $realm "-t" "75" "-p" $pw); ScriptResetRc;
                                                    ProcessSleepSec 2; # Required to make ready to use rdp.
                                                    if( $out -eq "The specified credentials do not authenticate." -or $out -eq "Die Authentifizierung ist mit den angegebenen Anmeldeinformationen nicht m÷glich." ){
                                                      # On some machines we got german messages.
                                                      OutProgress "Handling authentication failure by removing credential file and retry";
                                                      CredentialRemoveFile $secureCredentialFile; }
                                                    elseif( $out -eq "Network Connect has started." -or $out -eq "Network Connect is already running" -or $out -eq "Network Connect wurde gestartet." ){ return; }
                                                    else{ OutWarning "Warning: Ignoring unexpected program output: `"$out`", will continue but maybe it does not work"; ProcessSleepSec 5; return; }
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
                                                ToolRdpConnect $rdpfile; }
function InfoAboutComputerOverview            (){ return [String[]] @( "InfoAboutComputerOverview:", ""
                                                  ,"Common.Datetime                : $(DateTimeNowAsStringIso 'yyyy-MM-dd HH:mm')"
                                                  ,"OS.ComputerName                : $ComputerName"
                                                  ,"OS.Win.ProductKey              : $(OsGetWindowsProductKey)"
                                                  ,"FS.ConnectedDrives             : $([System.IO.DriveInfo]::getdrives())"
                                                  ,"Session.UserName               : $env:UserName"
                                                  ,"Session.PathVariable           : $env:PATH"
                                                  ,"Session.PSVersion              : $((Get-Host).Version.ToString())"
                                                  ,"Session.Culture                : $((Get-Host).CurrentCulture.Name)" # "de-CH", "en-US"
                                                  ,"Session.CultureUI              : $((Get-Host).CurrentUICulture.Name)" # "de-CH", "en-US"
                                                  ,"Session.Culture.DtPattern      : $((Get-Host).CurrentCulture.DateTimeFormat.FullDateTimePattern)" # "yyyy-MM-dd HH:mm:ss"
                                                  ); }
function InfoAboutExistingShares              (){
                                                [String[]] $result = @( "Info about existing shares:", "" );
                                                foreach( $shareObj in (ShareListAll | Sort-Object Name) ){
                                                  [Object] $share = $shareObj | Select-Object -ExpandProperty Name;
                                                  Get-CimInstance -Class Win32_LogicalShareSecuritySetting -Filter "name='$share'" | Out-Null;
                                                  [String] $s = "  "+$shareObj.Name.PadRight(12)+" = "+("'"+$shareObj.Path+"'").PadRight(5)+" "+$shareObj.Description;
                                                  # Since migration from wmi to cim we cannot get acls anymore, refactor it later:
                                                  #   try{
                                                  #     [Object] $sd = $objShareSec.GetSecurityDescriptor().Descriptor;
                                                  #     foreach( $ace in $sd.DACL ){
                                                  #       [Object] $username = $ace.Trustee.Name;
                                                  #       if( $null -ne $ace.Trustee.Domain -and $ace.Trustee.Domain -ne "" ){ $username = "$($ace.Trustee.Domain)\$username" }
                                                  #       if( $null -eq $ace.Trustee.Name   -or  $ace.Trustee.Name   -eq "" ){ $username = $ace.Trustee.SIDString }
                                                  #       [Object] $o = New-Object Security.AccessControl.FileSystemAccessRule($username,$ace.AccessMask,$ace.AceType);
                                                  #       # Example: FileSystemRights=FullControl; AccessControlType=Allow; IsInherited=False; InheritanceFlags=None; PropagationFlags=None; IdentityReference=Jeder;
                                                  #       # Example: FileSystemRights=FullControl; AccessControlType=Allow; IsInherited=False; InheritanceFlags=None; PropagationFlags=None; IdentityReference=VORDEFINIERT\Administratoren;
                                                  #       $s += "$([Environment]::NewLine)"+"".PadRight(26)+" (ACT="+$o.AccessControlType+",INH="+$o.IsInherited+",FSR="+$o.FileSystemRights+",INHF="+$o.InheritanceFlags+",PROP="+$o.PropagationFlags+",IDREF="+$o.IdentityReference+") ";
                                                  #     }
                                                  #   }catch{ $s += "$([Environment]::NewLine)"+"".PadRight(26)+" (unknown)"; }
                                                  $result += $s;
                                                }
                                                return [String[]] $result; }
function InfoAboutSystemInfo                  (){ # Works only on Windows
                                                ProcessAssertInElevatedAdminMode; # because DISM.exe
                                                [String[]] $out = @()+(& "systeminfo.exe"); AssertRcIsOk $out;
                                                # Get default associations for file extensions to programs for windows 10, this can be used later for imports.
                                                # configuring: Control Panel->Default Programs-> Set Default Program.  Choos program and "set this program as default."
                                                # View:        Control Panel->Programs-> Default Programs-> Set Association.
                                                # Edit:        for imports the xml file can be edited and stripped for your needs.
                                                # import cmd:  dism.exe /online /Import-DefaultAppAssociations:"mydefaultapps.xml"
                                                # removing:    dism.exe /Online /Remove-DefaultAppAssociations
                                                [String] $f = (FsEntryGetAbsolutePath "$env:TEMP/tmp/EnvGetInfoAboutSystemInfo_DefaultFileExtensionToAppAssociations.xml");
                                                & "Dism.exe" "/QUIET" "/Online" "/Export-DefaultAppAssociations:$f"; AssertRcIsOk;
                                                #
                                                [String[]] $result = @( "InfoAboutSystemInfo:", "" );
                                                $result += $out;
                                                $result += "OS-SerialNumber: "+(Get-CimInstance Win32_OperatingSystem|Select-Object -ExpandProperty SerialNumber);
                                                $result += @( "", "", "List of associations of fileextensions to a filetypes:"   , (& "cmd.exe" "/c" "ASSOC") ); AssertRcIsOk;
                                                $result += @( "", "", "List of associations of filetypes to executable programs:", (& "cmd.exe" "/c" "FTYPE") ); AssertRcIsOk;
                                                $result += @( "", "", "List of DefaultAppAssociations:"                          , (FileReadContentAsString $f "Default") ); # TODO: try to replace Default by UTF8.
                                                $result += @( "", "", "List of windows feature enabling states:"                 , (& "Dism.exe" "/online" "/Get-Features") ); AssertRcIsOk;
                                                # For future use:
                                                # - powercfg /lastwake
                                                # - powercfg /waketimers
                                                # - Get-ScheduledTask | Where-Object{ $_.settings.waketorun }
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
                                                  ,"AvailablePowershellModules:" ,(HelpListOfAllModules)
                                                  # usually: AppLocker, BitsTransfer, PSDiagnostics, TroubleshootingPack, WebAdministration, SQLASCMDLETS, SQLPS.
                                                ); }
function InfoHdSpeed                          (){ # Works only on Windows
                                                ProcessRestartInElevatedAdminMode;
                                                [String[]] $out1 = @()+(& "winsat.exe" "disk" "-seq" "-read"  "-drive" "c"); AssertRcIsOk $out1;
                                                [String[]] $out2 = @()+(& "winsat.exe" "disk" "-seq" "-write" "-drive" "c"); AssertRcIsOk $out2; return [String[]] ($out1+$out2); }
function InfoAboutNetConfig                   (){
                                                return [String[]] @( "InfoAboutNetConfig:", ""
                                                ,"NetGetIpConfig:"     ,(NetGetIpConfig                                                  ),""
                                                ,"NetGetNetView:"      ,(NetGetNetView                                                   ),""
                                                ,"NetGetNetStat:"      ,(NetGetNetStat                                                   ),""
                                                ,"NetGetRoute:"        ,(NetGetRoute                                                     ),""
                                                ,"NetGetNbtStat:"      ,(NetGetNbtStat                                                   ),""
                                                ,"NetGetAdapterSpeed:" ,(NetAdapterListAll | StreamToTableString | StreamToStringIndented),""); }
function InfoGetInstalledDotNetVersion        ( [Boolean] $alsoOutInstalledClrAndRunningProc = $false ){
                                                # Requires clrver.exe in path, for example "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\x64\clrver.exe"
                                                if( $alsoOutInstalledClrAndRunningProc ){
                                                  [String[]] $a = @();
                                                  $a += "List Installed DotNet CLRs (clrver.exe):";
                                                  $a += (& "clrver.exe"        |
                                                    Where-Object{ $_.Trim() -ne "" -and -not $_.StartsWith("Copyright (c) Microsoft Corporation.  All rights reserved.") -and
                                                      -not $_.StartsWith("Microsoft (R) .NET CLR Version Tool") -and -not $_.StartsWith("Versions installed on the machine:") } |
                                                    ForEach-Object{ "  Installed CLRs: $_" }); AssertRcIsOk;
                                                  $a += "List running DotNet Processes (clrver.exe -all):";
                                                  $a += (& "clrver.exe" "-all" |
                                                    Where-Object{ $_.Trim() -ne "" -and -not $_.StartsWith("Copyright (c) Microsoft Corporation.  All rights reserved.") -and
                                                      -not $_.StartsWith("Microsoft (R) .NET CLR Version Tool") -and -not $_.StartsWith("Versions installed on the machine:") } |
                                                    ForEach-Object{ "  Running Processes and its CLR: $_" }); AssertRcIsOk;
                                                  $a | ForEach-Object{ OutProgress $_; };
                                                }
                                                [Int32] $relKey = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release;
                                                # see: https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
                                                [String]                      $relStr = "No 4.5 or later version detected.";
                                                if    ( $relKey -ge 533320 ){ $relStr = "4.8.1 or later ($relKey)"; } # on Win10CreatorsUpdate
                                                elseif( $relKey -ge 528040 ){ $relStr = "4.8"  ; }
                                                elseif( $relKey -ge 461808 ){ $relStr = "4.7.2"; }
                                                elseif( $relKey -ge 461308 ){ $relStr = "4.7.1"; }
                                                elseif( $relKey -ge 460798 ){ $relStr = "4.7"  ; }
                                                elseif( $relKey -ge 394802 ){ $relStr = "4.6.2"; }
                                                elseif( $relKey -ge 394254 ){ $relStr = "4.6.1"; }
                                                elseif( $relKey -ge 393295 ){ $relStr = "4.6"  ; }
                                                elseif( $relKey -ge 379893 ){ $relStr = "4.5.2"; }
                                                elseif( $relKey -ge 378675 ){ $relStr = "4.5.1"; }
                                                elseif( $relKey -ge 378389 ){ $relStr = "4.5"  ; }
                                                return [String] $relStr; }
# Type: SvnEnvInfo
Add-Type -TypeDefinition "public struct SvnEnvInfo {public string Url; public string Path; public string RealmPattern; public string CachedAuthorizationFile; public string CachedAuthorizationUser; public string Revision; }";
                                                # Example: Url="https://myhost/svn/Work"; Path="D:\Work"; RealmPattern="https://myhost:443";
                                                # CachedAuthorizationFile="$env:APPDATA\Subversion\auth\svn.simple\25ff84926a354d51b4e93754a00064d6"; CachedAuthorizationUser="myuser"; Revision="1234"
# Script local variable: svnLogFile
[String] $script:svnLogFile = FsEntryGetAbsolutePath "${env:TEMP}/tmp/MnCommonPsToolLibLog/$(DateTimeNowAsStringIsoYear)/$(DateTimeNowAsStringIsoMonth)/Svn.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
function SvnEnvInfoGet                        ( [String] $workDir ){
                                                # Return SvnEnvInfo; no param is null.
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
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
                                                [String[]] $out = @()+(& "svn" "info" $workDir); AssertRcIsOk $out;
                                                FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                [String[]] $out2 = @()+(& "svn" "propget" "svn:ignore" "-R" $workDir); AssertRcIsOk $out2;
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
                                                $result.RealmPattern = ($result.Url -Split "/svn/",2)[0] + $(switch(($result.Url -split "/",2)[0]){ "https:"{":443"} "http:"{":80"} default{""} });
                                                $result.CachedAuthorizationFile = "";
                                                $result.CachedAuthorizationUser = "";
                                                # Svn can cache more than one server connection option, so we need to find the correct one by matching the realmPattern in realmstring which identifies a server connection.
                                                [String] $svnCachedAuthorizationDir = "$env:APPDATA/Subversion/auth/svn.simple/";
                                                # Care only file names like "25ff84926a354d51b4e93754a00064d6"
                                                [String[]] $files = (@()+(FsEntryListAsStringArray "$svnCachedAuthorizationDir/*" $false $false |
                                                  Where-Object{$null -ne $_} |
                                                  Where-Object{ (FsEntryGetFileName $_) -match "^[0-9a-f]{32}$" } |
                                                  Sort-Object));
                                                foreach( $f in $files ){
                                                  [String[]] $lines = @()+(FileReadContentAsLines $f -encodingIfNoBom "Default"); # TODO: try to replace Default by UTF8.
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
                                                $workSubDir = FsEntryGetAbsolutePath $workSubDir;
                                                FsEntryAssertHasTrailingDirSep $workSubDir;
                                                [String] $d = $workSubDir;
                                                for( [Int32] $i = 0; $i -lt 200; $i++ ){
                                                  if( DirExists "$d/.svn/" ){ return [String] (FsEntryGetAbsolutePath "$d/.svn/"); }
                                                  $d = FsEntryGetAbsolutePath (Join-Path $d "../");
                                                }
                                                throw [Exception] "Missing directory '.svn' within or up from the path `"$workSubDir`""; }
function SvnAuthorizationSave                ( [String] $workDir, [String] $user ){
                                                # If this part fails then you should clear authorization account in svn settings.
                                                # Note: if certificate is not accepted then a pem file (for example lets-encrypt-r3.pem) can be added to file "$env:APPDATA\Subversion\servers"
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                OutProgress "SvnAuthorizationSave user=$user ";
                                                FileAppendLineWithTs $svnLogFile "SvnAuthorizationSave(`"$workDir`")";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                DirCopyToParentDirByAddAndOverwrite "$env:APPDATA/Subversion/auth/svn.simple/" "$dotSvnDir/OwnSvnAuthSimpleSaveUser_$user/"; }
function SvnAuthorizationTryLoadFile          ( [String] $workDir, [String] $user ){
                                                # If work auth dir exists then copy content to svn cache dir.
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                OutProgress "SvnAuthorizationTryLoadFile - try to reload from an earlier save";
                                                FileAppendLineWithTs $svnLogFile "SvnAuthorizationTryLoadFile(`"$workDir`")";
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                [String] $svnWorkAuthDir = "$dotSvnDir/OwnSvnAuthSimpleSaveUser_$user/svn.simple/";
                                                [String] $svnAuthDir = "$env:APPDATA/Subversion/auth/";
                                                if( DirExists $svnWorkAuthDir ){
                                                  DirCopyToParentDirByAddAndOverwrite $svnWorkAuthDir $svnAuthDir;
                                                }else{
                                                  OutProgress "Load not done because not found dir: `"$svnWorkAuthDir`"";
                                                } } # For later usage: function SvnAuthorizationClear (){ FileAppendLineWithTs $svnLogFile "SvnAuthorizationClear"; [String] $svnAuthCurr = "$env:APPDATA/Subversion/auth/svn.simple/"; DirCopyToParentDirByAddAndOverwrite $svnAuthCurr $svnAuthWork; }
function SvnCleanup                           ( [String] $workDir ){
                                                # Cleanup a previously failed checkout, update or commit operation.
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                FileAppendLineWithTs $svnLogFile "SvnCleanup(`"$workDir`")";
                                                # For future alternative option: --trust-server-cert-failures unknown-ca,cn-mismatch,expired,not-yet-valid,other
                                                [String[]] $out = @()+(& "svn" "cleanup" --non-interactive $workDir); AssertRcIsOk $out;
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
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                FileAppendLineWithTs $svnLogFile "SvnStatus(`"$workDir`")";
                                                OutVerbose "SvnStatus - List pending changes";
                                                [String[]] $out = @()+(& "svn" "status" $workDir); AssertRcIsOk $out;
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
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                foreach( $e in (@()+$relativeRevertFsEntries) ){
                                                  [String] $f = "$workDir/$e";
                                                  FileAppendLineWithTs $svnLogFile "SvnRevert(`"$f`")";
                                                  # avoid:  svn: E155010: The node 'C:\MyWorkDir\UnexistingDir' was not found.
                                                  if( (FsEntryExists $f) ){
                                                    [String[]] $out = @()+(& "svn" "revert" "--recursive" "$f"); AssertRcIsOk $out;
                                                    FileAppendLines $svnLogFile (StringArrayInsertIndent $out 2);
                                                  }
                                                } }
function SvnTortoiseCommit                    ( [String] $workDir ){
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                FileAppendLineWithTs $svnLogFile "SvnTortoiseCommit(`"$workDir`") call checkin dialog";
                                                [String] $tortoiseExe = FsEntryGetAbsolutePath (RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseSVN" "ProcPath"); # Example: "C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe"
                                                Start-Process -NoNewWindow -Wait -FilePath "$tortoiseExe" -ArgumentList @("/closeonend:2","/command:commit","/path:`"$workDir`""); AssertRcIsOk; }
function SvnUpdate                            ( [String] $workDir, [String] $user ){
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                SvnCheckoutAndUpdate $workDir "" $user $true; }
function SvnCheckoutAndUpdate                 ( [String] $workDir, [String] $url, [String] $user, [Boolean] $doUpdateOnly = $false, [String] $pw = "", [Boolean] $ignoreSslCheck = $false ){
                                                # Init working copy and get (init and update) last changes. If pw is empty then it uses svn-credential-cache.
                                                # If specified update-only then no url is nessessary but if given then it verifies it.
                                                # Note: we do not use svn-update because svn-checkout does the same (the difference is only the use of an url).
                                                # Note: sometimes often after 5-20 GB received there is a network problem which aborts svn-checkout,
                                                #   so if it is recognised as a known exception then it will automatically do a cleanup, wait for 30 sec and retry (max 100 times).
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                if( $doUpdateOnly ){
                                                  Assert ((DirExists $workDir) -and (SvnGetDotSvnDir $workDir)) "missing work dir or it is not a svn repo: `"$workDir`"";
                                                  [String] $repoUrl = (SvnEnvInfoGet $workDir).Url;
                                                  if( $url -eq "" ){ $url = $repoUrl; }else{ Assert ($url -eq $repoUrl) "given url=$url does not match url in repository: $repoUrl"; }
                                                }
                                                [String] $tmp = (FileGetTempFile);
                                                [Int32] $maxNrOfTries = 100; [Int32] $nrOfTries = 0;
                                                while($true){ $nrOfTries++;
                                                  OutProgress "SvnCheckoutAndUpdate: get all changes from $url to `"$workDir`" $(switch($doUpdateOnly){($true){''}default{'and if it not exists and then init working copy first'}}). ";
                                                  FileAppendLineWithTs $svnLogFile "SvnCheckoutAndUpdate(`"$workDir`",$url,$user) ";
                                                  # For future alternative option: --trust-server-cert-failures unknown-ca,cn-mismatch,expired,not-yet-valid,other
                                                  # For future alternative option: --quite
                                                  [String[]] $opt = @( "--non-interactive", "--ignore-externals" );
                                                  if( $ignoreSslCheck ){ $opt += "--trust-server-cert"; }
                                                  if( $user -ne "" ){ $opt += @( "--username", $user ); }
                                                  if( $pw -ne "" ){ $opt += @( "--password", $pw, "--no-auth-cache" ); } # is visible in process list.
                                                  # Alternative for checkout: tortoiseExe /closeonend:2 /command:checkout /path:$workDir /url:$url
                                                  if( $doUpdateOnly ){ $opt = @( "update"  ) + $opt + @(       $workDir ); }
                                                  else               { $opt = @( "checkout") + $opt + @( $url, $workDir ); }
                                                  [String] $logline = $opt; $logline = $logline.Replace("--password $pw","--password ...");
                                                  FileAppendLineWithTs $svnLogFile "`"svn`" $logline";
                                                  try{
                                                    & "svn" $opt 2> $tmp | ForEach-Object{ FileAppendLineWithTs $svnLogFile ("  "+$_); OutProgress "$_ " 2; };
                                                    AssertRcIsOk (FileReadContentAsLines $tmp -encodingIfNoBom "Default") $true; # TODO: try to replace Default by UTF8.
                                                    break;
                                                  }catch{
                                                    # exc: "svn: E230001: Server SSL certificate verification failed: issuer is not trusted"
                                                    # exc: "svn: E205000: Try 'svn help checkout' for more information"
                                                    # Note: if throwed then tmp file is empty.
                                                    [String] $m = $_.Exception.Message;
                                                    if( $m.Contains(" E170013:") ){  # exc: "svn: E170013: Unable to connect to a repository at URL 'https://mycomp/svn/Work/mydir'"
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
                                                      $m.Contains(" E120106:") -or # exc: "svn: E120106: ra_serf: The server sent a truncated HTTP response body"
                                                      $m.Contains(" E155037:") -or # exc: "svn: E155037: Previous operation has not finished; run 'cleanup' if it was interrupted"
                                                      $m.Contains(" E155004:") -or # exc: "svn: E155004: Run 'svn cleanup' to remove locks (type 'svn help cleanup' for details)"
                                                      $m.Contains(" E175002:") -or # exc: "svn: E175002: REPORT request on '/svn/Work/!svn/me' failed"
                                                      $m.Contains(" E200030:") -or # exc: "svn: E200030: sqlite[S10]: disk I/O error, executing statement 'VACUUM '"
                                                      $m.Contains(" E730054:") -or # exc: "svn: E730054: Error running context: Eine vorhandene Verbindung wurde vom Remotehost geschlossen."
                                                      $m.Contains(" E170013:") -or # exc: "svn: E170013: Unable to connect to a repository at URL 'https://mycomp/svn/Work/mydir'"
                                                      $m.Contains(" E200014:")   ; # exc: "svn: E200014: Checksum mismatch for '...file...'"
                                                                                   #        (2023-12: we had a case with a unicode name of length 237chars which did not repair; in case we get another case then do not retry anymore)
                                                    if( -not $isKnownProblemToSolveWithRetry -or $nrOfTries -ge $maxNrOfTries ){ throw [ExcMsg] $msg; }
                                                    [String] $msg2 = "Is try nr $nrOfTries of $maxNrOfTries, will do cleanup, wait 30 sec and if not reached max then retry.";
                                                    OutWarning "Warning: $msg $msg2 ";
                                                    FileAppendLineWithTs $svnLogFile $msg2;
                                                    SvnCleanup $workDir;
                                                    ProcessSleepSec 30;
                                                  }finally{ FileDelTempFile $tmp; } } }
function SvnPreCommitCleanupRevertAndDelFiles ( [String] $workDir, [String[]] $relativeDelFsEntryPatterns, [String[]] $relativeRevertFsEntries ){
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                OutProgressTitle "SvnPreCommitCleanupRevertAndDelFiles `"$workDir`"";
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                [String] $svnRequiresCleanup = "$dotSvnDir/OwnSvnRequiresCleanup.txt";
                                                if( (FileExists $svnRequiresCleanup) ){ # Optimized because it is slow.
                                                  OutProgress "SvnCleanup - Perform cleanup because previous run was not completed";
                                                  SvnCleanup $workDir;
                                                  FileDelete $svnRequiresCleanup;
                                                }
                                                OutProgress "Remove known unused temp, cache and log directories and files ";
                                                OutProgress "  Is failing when locked by programs, then terminate programs first. ";
                                                FsEntryJoinRelativePatterns $workDir (@()+$relativeDelFsEntryPatterns) |
                                                  Where-Object{$null -ne $_} | ForEach-Object{
                                                    FsEntryListAsStringArray $_ | Where-Object{$null -ne $_} | ForEach-Object{
                                                      FileAppendLines $svnLogFile "  Delete: `"$_`""; FsEntryDelete $_; }; };
                                                OutProgress "SvnRevert - Restore known unwanted changes of directories and files";
                                                SvnRevert $workDir (@()+$relativeRevertFsEntries); }
function SvnTortoiseCommitAndUpdate           ( [String] $workDir, [String] $svnUrl, [String] $svnUser, [Boolean] $ignoreIfHostNotReachable, [String] $pw = "" ){
                                                # Check svn dir, do svn cleanup, check svn user by asserting it matches previously used svn user, delete temporary files, svn commit (interactive), svn update.
                                                # If pw is empty then it takes it from svn-credential-cache.
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                [String] $traceInfo = "SvnTortoiseCommitAndUpdate workdir=`"$workDir`" url=$svnUrl user=$svnUser";
                                                OutProgressTitle $traceInfo;
                                                OutProgress "SvnLogFile: `"$svnLogFile`"";
                                                FileAppendLineWithTs $svnLogFile ("$([Environment]::NewLine)"+("-"*80)+"$([Environment]::NewLine)"+(DateTimeNowAsStringIso "yyyy-MM-dd HH:mm")+" "+$traceInfo);
                                                try{
                                                  [String] $dotSvnDir = SvnGetDotSvnDir $workDir;
                                                  [String] $svnRequiresCleanup = "$dotSvnDir/OwnSvnRequiresCleanup.txt";
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
                                                  (FsEntryGetAbsolutePath "$(FsEntryGetParentDir (StringRemoveOptEnclosingDblQuotes (RegistryGetValueAsString "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe")))/$tfExe")
                                                );
                                                foreach( $i in $a ){ if( FileExists $i ) { return [String] $i; } }
                                                throw [ExcMsg] "Missing one of the files: $a"; }
                                                # for future use: tf.exe checkout /lock:checkout /recursive file
                                                # for future use: tf.exe merge /baseless /recursive /version:C234~C239 branchFrom branchTo
                                                # for future use: tf.exe workfold /workspace:ws /cloak
# Script local variable: tfsLogFile
[String] $script:tfsLogFile = FsEntryGetAbsolutePath "${env:TEMP}/tmp/MnCommonPsToolLibLog/$(DateTimeNowAsStringIsoYear)/$(DateTimeNowAsStringIsoMonth)/Tfs.$(DateTimeNowAsStringIsoMonth).$($PID)_$(ProcessGetCurrentThreadId).log";
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
                                                # Example: url=https://devops.mydomain.ch/MyTfsRoot
                                                OutProgress "Show all tfs workspaces (showPaths=$showPaths,currentMachineOnly=$currentMachineOnly)";
                                                [String] $fmt = "Brief"; if( $showPaths ){ $fmt = "Detailed"; }
                                                [String] $mach = "*"; if( $currentMachineOnly ){ $mach = $ComputerName; }
                                                OutProgress                                    "& `"$(TfsExe)`" vc workspaces /noprompt /format:$fmt /owner:* /computer:$mach /collection:$url";
                                                [String[]] $out = @()+(StringArrayInsertIndent (&    (TfsExe)   vc workspaces /noprompt /format:$fmt /owner:* /computer:$mach /collection:$url) 2); ScriptResetRc;
                                                $out | ForEach-Object{ $_.Replace("--------------------------------------------------","-") } |
                                                       ForEach-Object{ $_.Replace("==================================================","=") } |
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
                                                $out | ForEach-Object{ $_.Replace("--------------------------------------------------","-") } |
                                                  ForEach-Object{ OutProgress $_ };
                                                # Format Detailed is only allowed if collection is specified
                                                # Example1:
                                                #   Auf dem Computer "MYCOMPUTER" ist kein entsprechender Arbeitsbereich "*;John Doe" für den Azure DevOps Server-Computer "https://devops.mydomain.ch/MyTfsRoot" vorhanden.
                                                # Example2:
                                                #   Sammlung: https://devops.mydomain.ch/MyTfsRoot
                                                #   Arbeitsbereich Besitzer          Computer Kommentar
                                                #   -------------- ----------------- -------- -----------
                                                #   MYCOMPUTER     John Doe          MYCOMPUTER
                                                # Example3 with option /computer:$ComputerName :
                                                #   Der Quellcodeverwaltungsserver kann nicht bestimmt werden.
                                                }
function TfsHasLocalMachWorkspace             ( [String] $url ){ # we support only workspace name identic to computername
                                                [string] $wsName = $ComputerName;
                                                [string] $mach = $ComputerName;
                                                OutProgress "Check if local tfs workspaces with name identic to computername exists";
                                                OutProgress           "  & `"$(TfsExe)`" vc workspaces /noprompt /format:Brief /owner:* /computer:$mach /collection:$url";
                                                [String[]] $out = @()+(&    (TfsExe)   vc workspaces /noprompt /format:Brief /owner:* /computer:$mach /collection:$url *>&1 |
                                                  Select-Object -Skip 2 | Where-Object{ $_.StartsWith("$wsName ") }); ScriptResetRc;
                                                $out | ForEach-Object{ $_.Replace("--------------------------------------------------","-") } | ForEach-Object{ OutProgress $_ };
                                                return [Boolean] ($out.Length -gt 0); }
function TfsInitLocalWorkspaceIfNotDone       ( [String] $url, [String] $rootDir ){
                                                # also creates the directory "./$tf/" (or "./$tf1/", etc. ).
                                                $rootDir = FsEntryGetAbsolutePath $rootDir;
                                                FsEntryAssertHasTrailingDirSep $rootDir;
                                                [string] $wsName = $ComputerName;
                                                OutProgress "Init local tfs workspaces with name identic to computername if not yet done of $url to `"$rootDir`"";
                                                FsEntryAssertHasTrailingDirSep $rootDir;
                                                if( (TfsHasLocalMachWorkspace $url) ){ OutProgress "Init-Workspace not nessessary because has already workspace identic to computername."; return; }
                                                [String] $cd = (Get-Location); Set-Location $rootDir; try{
                                                    OutProgress         "& `"$(TfsExe)`" vc workspace /new /noprompt /location:local /collection:$url $wsName";
                                                    [String] $out = @()+(&    (TfsExe)   vc workspace /new /noprompt /location:local /collection:$url $wsName); AssertRcIsOk $out;
                                                    # The workspace MYCOMPUTER;John Doe already exists on computer MYCOMPUTER.
                                                }finally{ Set-Location $cd; } }
function TfsDeleteLocalMachWorkspace          ( [String] $url ){ # we support only workspace name identic to computername
                                                OutProgressTitle "Delete local tfs workspace with name of current computer";
                                                if( -not (TfsHasLocalMachWorkspace $url) ){ OutProgress "Delete-Workspace not nessessary because has no workspace of name identic to computername."; return; }
                                                [string] $wsName = $ComputerName;
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
function TfsGetNewestNoOverwrite              ( [String] $wsdir, [String] $tfsPath, [String] $url ){ # Example: TfsGetNewestNoOverwrite C:\MyWorkspace\Src $/Src https://devops.mydomain.ch/MyTfsRoot
                                                $wsdir = FsEntryGetAbsolutePath $wsdir;
                                                AssertNotEmpty $wsdir "wsdir";
                                                FsEntryAssertHasTrailingDirSep $wsdir;
                                                Assert $tfsPath.StartsWith("`$/") "expected tfsPath=`"$tfsPath`" begins with `$/.";
                                                OutProgress "TfsGetNewestNoOverwrite `"$wsdir`" `"$tfsPath`" $url";
                                                FileAppendLineWithTs $tfsLogFile "TfsGetNewestNoOverwrite(`"$wsdir`",`"$tfsPath`",$url )";
                                                if( ((FsEntryFindInParents $wsdir "`$tf") -eq "") -and ((FsEntryFindInParents $wsdir "`$tf1") -eq "") -and ((FsEntryFindInParents $wsdir "`$tf2") -eq "") ){
                                                  OutProgress "Not found any dir (`"`$tf`",`"`$tf1`",`"`$tf2`") in parents of `"$wsdir`", so calling init workspace.";
                                                  TfsInitLocalWorkspaceIfNotDone $url (FsEntryGetParentDir $wsdir);
                                                }else{
                                                  # If workspace was some months not used then for the get command we got the error:
                                                  # "Der Arbeitsbereich kann nicht bestimmt werden. Dies lässt sich möglicherweise durch Ausführen von "tf workspaces /collection:Teamprojektsammlungs-URL" beheben."
                                                  # After performing this it worked, so we now perform this each time.
                                                  TfsHasLocalMachWorkspace $url | Out-Null;
                                                }
                                                if( FileNotExists $wsdir ){ DirCreate $wsdir; }
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{ # alternative option: /noprompt
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc get /recursive /version:T `"$tfsPath`" ";
                                                  [String[]] $out = @()+(     &    (TfsExe)   vc get /recursive /version:T   $tfsPath); AssertRcIsOk $out;
                                                  # Output: "Alle Dateien sind auf dem neuesten Stand."
                                                  if( $out.Count -gt 0 ){ $out | ForEach-Object{ OutProgress "  $_"; }; }
                                                }finally{ Set-Location $cd; } }
function TfsListOwnLocks                      ( [String] $wsdir, [String] $tfsPath ){
                                                $wsdir = FsEntryGetAbsolutePath $wsdir;
                                                AssertNotEmpty $wsdir "wsdir";
                                                FsEntryAssertHasTrailingDirSep $wsdir;
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc status /noprompt /recursive /format:brief `"$tfsPath`" ";
                                                  [String[]] $out = @()+((    &    (TfsExe)   vc status /noprompt /recursive /format:brief   $tfsPath *>&1 ) |
                                                    Select-Object -Skip 2 | Where-Object{ StringIsFilled $_ }); AssertRcIsOk $out;
                                                  # Example:
                                                  #    Dateiname    Ändern     Lokaler Pfad
                                                  #    ------------ ---------- -------------------------------------
                                                  #    $/Src/MyBranch
                                                  #    MyFile.txt   bearbeiten C:\MyWorkspace\Src\MyBranch\MyFile.txt
                                                  #
                                                  #    1 Änderungen
                                                  # Example: Es sind keine ausstehenden Änderungen vorhanden.
                                                  return [String[]] $out;
                                                }finally{ Set-Location $cd; } }
function TfsAssertNoLocksInDir                ( [String] $wsdir, [String] $tfsPath ){ # Example: "C:\MyWorkspace" "$/Src";
                                                $wsdir = FsEntryGetAbsolutePath $wsdir;
                                                AssertNotEmpty $wsdir "wsdir";
                                                FsEntryAssertHasTrailingDirSep $wsdir;
                                                [String[]] $allLocks = @()+(TfsListOwnLocks $wsdir $tfsPath);
                                                if( $allLocks.Count -gt 0 ){
                                                  $allLocks | ForEach-Object{ OutProgress "Found Lock: $_"; };
                                                  throw [ExcMsg] "Assertion failed because there exists pending locks under `"$tfsPath`"";
                                                } }
function TfsMergeDir                          ( [String] $wsdir, [String] $tfsPath, [String] $tfsTargetBranch ){
                                                $wsdir = FsEntryGetAbsolutePath $wsdir;
                                                AssertNotEmpty $wsdir "wsdir";
                                                FsEntryAssertHasTrailingDirSep $wsdir;
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc merge /noprompt /recursive /format:brief /version:T `"$tfsPath`" `"$tfsTargetBranch`" ";
                                                                              &    (TfsExe)   vc merge /noprompt /recursive /format:brief /version:T   $tfsPath     $tfsTargetBranch | Out-Null; # later we would like to suppress stderr
                                                  ScriptResetRc;
                                                  # Example:
                                                  #    Konflikt ("mergen, bearbeiten"): $/Src/MyBranch1/MyFile.txt;C123~C129 -> $/Src/MyBranch2/MyFile.txt;C121
                                                  #    3 Konflikte. Geben Sie "/format:detailed" an, um die einzelnen Konflikte in der Zusammenfassung aufzulisten.
                                                  #    mergen, bearbeiten: $/Src/MyBranch1/MyFile2.txt;C123~C129 -> $/Src/MyBranch2/MyFile2.txt;C121
                                                  #    The item $/Src/MyBranch1/MyFile2.txt is locked for check-out by MyDomain\MyUser in workspace MYMACH.
                                                  #
                                                  #    ---- Zusammenfassung: 31 Konflikte, 0 Warnungen, 0 Fehler ----
                                                  # does not work: | Where-Object{ $_ -contains "---- Zusammenfassung:*" }
                                                #}catch{ ScriptResetRc; OutProgress "Ignoring Error: $($_.Exception)";
                                                }finally{ Set-Location $cd; } }
function TfsResolveMergeConflict              ( [String] $wsdir, [String] $tfsPath, [Boolean] $keepTargetAndNotTakeSource ){
                                                $wsdir = FsEntryGetAbsolutePath $wsdir;
                                                AssertNotEmpty $wsdir "wsdir";
                                                FsEntryAssertHasTrailingDirSep $wsdir;
                                                [String] $resolveMode = switch( $keepTargetAndNotTakeSource ){ $true{"TakeTheirs"} $false{"AcceptYours"} };
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc resolve /noprompt /recursive /auto:$resolveMode `"$tfsPath`" ";
                                                  [String[]] $out = @()+(     &    (TfsExe)   vc resolve /noprompt /recursive /auto:$resolveMode   $tfsPath ); AssertRcIsOk $out;
                                                #}catch{ ScriptResetRc; OutProgress "Ignoring Error: $($_.Exception)";
                                                }finally{ Set-Location $cd; } }
function TfsCheckinDirWhenNoConflict          ( [String] $wsdir, [String] $tfsPath, [String] $comment, [Boolean] $handleErrorsAsWarnings ){
                                                # Return true if checkin was successful.
                                                $wsdir = FsEntryGetAbsolutePath $wsdir;
                                                AssertNotEmpty $wsdir "wsdir";
                                                FsEntryAssertHasTrailingDirSep $wsdir;
                                                [String] $cd = (Get-Location); Set-Location $wsdir; try{
                                                  # Note: sometimes it seem to write this to stderror:
                                                  #  "Es sind keine ausstehenden Änderungen vorhanden, die mit den angegebenen Elementen übereinstimmen.\nEs wurden keine Dateien eingecheckt."
                                                  OutProgress "CD `"$wsdir`"; & `"$(TfsExe)`" vc checkin /noprompt /recursive /noautoresolve /comment:`"$comment`" `"$tfsPath`" ";
                                                                              &    (TfsExe)   vc checkin /noprompt /recursive /noautoresolve /comment:"$comment"     $tfsPath | Out-Null;
                                                  ScriptResetRc;
                                                  return [Boolean] $true;
                                                }catch{
                                                  if( -not $handleErrorsAsWarnings ){ throw; }
                                                  OutWarning "Warning: Ignoring checkin problem which requires manually resolving: $($_.Exception.Message)";
                                                  return [Boolean] $false;
                                                }finally{ Set-Location $cd; } }
function TfsUndoAllLocksInDir                 ( [String] $dir ){ # Undo all locks below dir to cleanup a previous failed operation as from merging.
                                                $dir = FsEntryGetAbsolutePath $dir;
                                                AssertNotEmpty $dir "dir";
                                                FsEntryAssertHasTrailingDirSep $dir;
                                                OutProgress           "& `"$(TfsExe)`" vc undo /noprompt /recursive `"$dir`"";
                                                [String[]] $out = @()+(&    (TfsExe)   vc undo /noprompt /recursive   $dir); AssertRcIsOk $out; }
function SqlGetCmdExe                         (){
                                                [String] $result = (ProcessFindExecutableInPath "sqlcmd.EXE");
                                                if( $result -eq "" ){
                                                  # old style. It is recommended to use: SqlPerformFile
                                                  $result = @(
                                                       "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\150\Tools\ClientSetup" # sql server 2022 and 2019
                                                      ,"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\140\Tools\ClientSetup" # sql server 2017
                                                      ,"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\130\Tools\ClientSetup" # sql server 2016
                                                      ,"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\120\Tools\ClientSetup" # sql server 2014
                                                      ,"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\110\Tools\ClientSetup" # sql server 2012
                                                      ,"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\ClientSetup" # sql server 2008
                                                    ) | Where-Object{ (RegistryExistsValue $_ "Path") } |
                                                    ForEach-Object{ ((RegistryGetValueAsString $_ "Path")+"sqlcmd.EXE") } |
                                                    Where-Object{ (FileExists $_) } | Select-Object -First 1; # Example: "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\sqlcmd.EXE"
                                                }
                                                if( $result -eq "" ){ throw [ExcMsg] "Cannot find sqlcmd.exe wether in path nor is any Sql Server 2022, 2019, 2016, 2014, 2012 or 2008 installed. "; }
                                                return [String] $result; }
function SqlRunScriptFile                     ( [String] $sqlserver, [String] $sqlfile, [String] $outFile, [Boolean] $continueOnErr ){ # old style. It is recommended to use: SqlPerformFile
                                                $sqlfile = FsEntryGetAbsolutePath $sqlfile;
                                                $outFile = FsEntryGetAbsolutePath $outFile;
                                                FileAssertExists $sqlfile;
                                                OutProgress "SqlRunScriptFile sqlserver=$sqlserver sqlfile=`"$sqlfile`" out=`"$outfile`" contOnErr=$continueOnErr";
                                                FsEntryCreateParentDir $outfile;
                                                & (SqlGetCmdExe) "-b" "-S" $sqlserver "-i" $sqlfile "-o" $outfile;
                                                if( -not $? ){
                                                  [String] $trace = "SqlRunScriptFile `"$sqlfile`" on `"$sqlserver`" failed with rc=$(ScriptGetAndClearLastRc), more see outfile";
                                                  if( -not $continueOnErr ){ throw [Exception] "$trace"; } else{ OutWarning "Warning: $trace, will continue."; }
                                                }else{ AssertRcIsOk; }
                                                FileAssertExists $outfile; }
function SqlPerformFile                       ( [String] $connectionString, [String] $sqlFile, [String] $logFileToAppend = "", [Int32] $queryTimeoutInSec = 0, [Boolean] $showPrint = $true, [Boolean] $showRows = $true){
                                                # Print are given out in yellow by internal verbose option; rows are currently given out only in a simple csv style without headers.
                                                # ConnectString example: "Server=myInstance;Database=TempDB;Integrated Security=True;"  queryTimeoutInSec: 1..65535,0=endless;
                                                $sqlfile = FsEntryGetAbsolutePath $sqlfile;
                                                $logFileToAppend = FsEntryGetAbsolutePath $logFileToAppend;
                                                ScriptImportModuleIfNotDone "SqlServer";
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
                                                ScriptImportModuleIfNotDone "SqlServer";
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
                                                # Example: SqlGenerateFullDbSchemaFiles "MyLogicEnvironment" "MySqlInstance" "MyDbName" "$env:TEMP/tmp/DumpFullDbSchemas"
                                                $targetRootDir = FsEntryGetAbsolutePath $targetRootDir;
                                                [String] $currentUser = "$env:USERDOMAIN\$env:USERNAME";
                                                [String] $traceInfo = "SqlGenerateFullDbSchemaFiles(logicalEnv=$logicalEnv,dbInstanceServerName=$dbInstanceServerName,dbname=$dbName,targetRootDir=$targetRootDir,currentUser=$currentUser)";
                                                OutProgressTitle $traceInfo;
                                                [String] $tarDir = "$targetRootDir/$(Get-Date -Format yyyy-MM-dd)/$logicalEnv/$dbName/";
                                                if( DirExists $tarDir ){
                                                  [String] $msg = "Nothing done because target dir already exists: `"$tarDir`"";
                                                  if( $errorAsWarning ){ OutWarning "Warning: $msg"; return; }
                                                  throw [ExcMsg] $msg;
                                                }
                                                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null;
                                                [System.Reflection.Assembly]::LoadWithPartialName("System.Data") | Out-Null;
                                                [Microsoft.SqlServer.Management.Smo.Server] $srv = new-object "Microsoft.SqlServer.Management.SMO.Server" $dbInstanceServerName;
                                                # Example: $srv.Name = "MySqlInstance"; $srv.State = "Existing"; $srv.ConnectionContext = "Data Source=MySqlInstance;Integrated Security=True;MultipleActiveResultSets=False;Encrypt=False;TrustServerCertificate=False;Application Name=`"SQL Management`""
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
                                                  [String] $fileDbInfo = "$tarDir/DbInfo.$dbName.out";
                                                  #try{
                                                  #  [String] $dummy = $db.Parent; # check for read access
                                                  #}catch{
                                                  #  # Example: ExtendedTypeSystemException: The following exception occurred while trying to enumerate the collection: "An exception occurred while executing a Transact-SQL statement or batch.".
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
                                                      ,"  Parent               : $($db.Parent                 )" # Example: [MySqlInstance.MyDomain.ch]
                                                      ,"  Collation            : $($db.Collation              )" # Example: Latin1_General_CI_AS
                                                      ,"  CompatibilityLevel   : $($db.CompatibilityLevel     )" # Example: Version100
                                                      ,"  SpaceUsedDataInMB    : $spaceUsedDataInMB            " # Example: 40
                                                      ,"  SpaceUsedIndexInMB   : $spaceUsedIndexInMB           " # Example: 12
                                                      ,"  SpaceAvailableInMB   : $spaceAvailableInMB           " # Example: 11
                                                      ,"  DefaultSchema        : $($db.DefaultSchema          )" # Example: dbo
                                                      ,"  NrOfTables           : $($tables.Count              )" # Example: 2
                                                      ,"  NrOfViews            : $($views.Count               )" # Example: 2
                                                      ,"  NrOfStoredProcedures : $($storedProcedures.Count    )" # Example: 2
                                                      ,"  NrOfUserDefinedFuncs : $($userDefFunctions.Count    )" # Example: 2
                                                      ,"  NrOfDbTriggers       : $($dbTriggers.Count          )" # Example: 2
                                                      ,"  NrOfTableTriggers    : $($tableTriggers.Count       )" # Example: 2
                                                      ,"  NrOfIndexesNonUnique : $($indexesNonUnique.Count    )" # Example: 20
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
                                                    $options.FileName = "$tarDir/Schema.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgress "Roles ";
                                                  foreach( $i in $dbRoles ){
                                                    [String] $name = FsEntryMakeValidFileName $i.Name;
                                                    $options.FileName = "$tarDir/Role.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgress "DbTriggers ";
                                                  foreach( $i in $dbTriggers ){
                                                    [String] $name = FsEntryMakeValidFileName $i.Name;
                                                    $options.FileName = "$tarDir/DbTrigger.$name.sql";
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
                                                    $options.FileName = "$tarDir/Table.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $smoObjects = New-Object Microsoft.SqlServer.Management.Smo.UrnCollection;
                                                    $smoObjects.Add($i.Urn);
                                                    $i.indexes | Where-Object{$null -ne $_ -and $_.IsUnique} | ForEach-Object{ $smoObjects.Add($_.Urn); };
                                                    $scr.Script($smoObjects);
                                                  }
                                                  OutProgress "Views ";
                                                  foreach( $i in $views ){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir/View.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  OutProgress "StoredProcedures";
                                                  foreach( $i in $storedProcedures ){
                                                    [String] $name = FsEntryMakeValidFileName "$($i.Schema).$($i.Name)";
                                                    $options.FileName = "$tarDir/StoredProcedure.$name.sql";
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
                                                    $options.FileName = "$tarDir/UserDefinedFunction.$name.sql";
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
                                                    $options.FileName = "$tarDir/TableTrigger.$name.sql";
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
                                                    $options.FileName = "$tarDir/IndexesNonUnique.$name.sql";
                                                    New-Item $options.FileName -type file -force | Out-Null;
                                                    $scr.Script($i);
                                                  }
                                                  # for future use: remove the lines when in sequence: "SET ANSI_NULLS ON","GO","SET QUOTED_IDENTIFIER ON","GO".
                                                  OutProgress "";
                                                  OutProgressSuccess "ok, done. Written files below: `"$tarDir`"";
                                                }catch{
                                                  # exc: "The given path's format is not supported."
                                                  # exc: "Illegal characters in path."  (if table name contains double quotes)
                                                  # exc: System.Management.Automation.ExtendedTypeSystemException: The following exception occurred while trying to enumerate the collection:
                                                  #        "An exception occurred while executing a Transact-SQL statement or batch.".
                                                  #        ---> Microsoft.SqlServer.Management.Common.ExecutionFailureException: An exception occurred while executing a Transact-SQL statement or batch.
                                                  #        ---> System.Data.SqlClient.SqlException: The server principal "MyDomain\MyUser" is not able to access the database "MyDatabaseName" under the current security context.
                                                  # exc: System.Management.Automation.MethodInvocationException: Exception calling "Script" with "1" argument(s):
                                                  #        "The StoredProcedure '[mySchema].[MyTable]' cannot be scripted as its data is not accessible."
                                                  #        ---> Microsoft.SqlServer.Management.Smo.FailedOperationException: The StoredProcedure '[mySchema].[MyTable]' cannot be scripted as its data is not accessible.
                                                  #        ---> Microsoft.SqlServer.Management.Smo.PropertyCannotBeRetrievedException: Property TextHeader is not available for StoredProcedure '[mySchema].[MyTable]'.
                                                  #        This property may not exist for this object, or may not be retrievable due to insufficient access rights. The text is encrypted.
                                                  #        at Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase.GetTextProperty(String requestingProperty, ScriptingPreferences sp, Boolean bThrowIfCreating)
                                                  [String] $msg = $traceInfo + " failed because $($_.Exception)";
                                                  FileWriteFromLines "$tarDir/DbInfo.$dbName.err" $msg;
                                                  if( -not $errorAsWarning ){ throw [ExcMsg] $msg; }
                                                  OutWarning "Warning: Ignore failing of $msg `nCreated `"$tarDir/DbInfo.$dbName.err`".";
                                                }
                                              }
function ToolRdpConnect                       ( [String] $rdpfile, [String] $mstscOptions = "" ){
                                                # Run RDP gui program with some mstsc options: /edit /admin  (use /edit temporary to set password in .rdp file)
                                                OutProgress "ToolRdpConnect: `"$rdpfile`" $mstscOptions";
                                                & "$env:SystemRoot/System32/mstsc.exe" $mstscOptions $rdpfile; AssertRcIsOk;
                                              }
function ToolHibernateModeEnable              (){
                                                OutProgressTitle "Enable hibernate mode";
                                                if( (OsIsHibernateEnabled) ){
                                                  OutProgress "Ok, is enabled.";
                                                }elseif( (DriveFreeSpace 'C') -le ((OsInfoMainboardPhysicalMemorySum) * 1.3) ){
                                                  OutWarning "Warning: Cannot enable hibernate because has not enought hd-space (RAM=$(OsInfoMainboardPhysicalMemorySum),DriveC-Free=$(DriveFreeSpace 'C'),expect RAM*1.3); ignored. You can manually try by: powercfg -HIBERNATE ON; ";
                                                }else{
                                                  ProcessRestartInElevatedAdminMode;
                                                  & "$env:SystemRoot/System32/powercfg.exe" "-HIBERNATE" "ON"; AssertRcIsOk;
                                                }
                                              }
function ToolHibernateModeDisable             (){
                                                OutProgressTitle "Disable hibernate mode";
                                                if( -not (OsIsHibernateEnabled) ){
                                                  OutProgress "Ok, is disabled.";
                                                }else{
                                                  ProcessRestartInElevatedAdminMode;
                                                  & "$env:SystemRoot/System32/powercfg.exe" "-HIBERNATE" "OFF"; AssertRcIsOk;
                                                }
                                              }
function ToolActualizeHostsFileByMaster       ( [String] $srcHostsFile ){
                                                OutProgressTitle "Actualize hosts file by a master file";
                                                # regular manually way: run notepad.exe with admin rights, open the file, edit, save.
                                                [String] $tarHostsFile = FsEntryGetAbsolutePath "$env:SystemRoot/System32/drivers/etc/hosts";
                                                [String] $tardir = FsEntryMakeTrailingDirSep (RegistryGetValueAsString "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DataBasePath");
                                                if( $tardir -ne (FsEntryGetParentDir $tarHostsFile) ){
                                                  throw [Exception] "Expected HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters:DataBasePath=`"$tardir`" equal to dir of: `"$tarHostsFile`"";
                                                }
                                                if( -not (FileContentsAreEqual $srcHostsFile $tarHostsFile $true) ){
                                                  ProcessRestartInElevatedAdminMode;
                                                  [String] $tmp = "";
                                                  if( (FsEntryGetFileName $srcHostsFile) -eq "hosts" ){
                                                     # Note: Its unbelievable but the name cannot be `"hosts`" because MS-Defender, so we need to copy it first to a temp file";
                                                     # https://www.microsoft.com/en-us/wdsi/threats/malware-encyclopedia-description?name=SettingsModifier%3aWin32%2fHostsFileHijack&threatid=265754
                                                     $tmp = (FileGetTempFile);
                                                     FileCopy $srcHostsFile $tmp $true;
                                                     FsEntrySetAttributeReadOnly $tmp $false;
                                                     $srcHostsFile = $tmp;
                                                  }
                                                  FileCopy $srcHostsFile $tarHostsFile $true;
                                                  if( $tmp -ne "" ){ FileDelete $tmp; }
                                                }else{
                                                  OutProgress "Ok, content is already correct.";
                                                }
                                              }
function ToolCreateLnkIfNotExists             ( [Boolean] $forceRecreate, [String] $workDir, [String] $lnkFile, [String] $srcFsEntry, [String[]] $arguments = @(),
                                                  [Boolean] $runElevated = $false, [Boolean] $ignoreIfSrcNotExists = $false ){
                                                # Creates links to files as programs or document files or to directories.
                                                # Example: ToolCreateLnkIfNotExists $false "" "$env:APPDATA/Microsoft/Windows/Start Menu/Programs/LinkToNotepad.lnk" "C:/Windows/notepad.exe";
                                                # Example: ToolCreateLnkIfNotExists $false "" "$env:APPDATA/Microsoft/Internet Explorer/Quick Launch/LinkToNotepad.lnk" "C:/Windows/notepad.exe";
                                                # Example: ToolCreateLnkIfNotExists $false "" "$env:APPDATA/Microsoft/Windows/Start Menu/- Folders/C - SendTo.lnk" "$HOME/AppData/Roaming/Microsoft/Windows/SendTo/";
                                                # forceRecreate: if is false and target lnkfile already exists then it does nothing.
                                                # workDir             : can be empty string. Internally it then takes the parent of the file.
                                                # srcFsEntry          : file or dir. A dir must be specified by a trailing dir separator!
                                                # runElevated         : the link is marked to request for run in elevated mode.
                                                # ignoreIfSrcNotExists: if source not exists it will be silently ignored, but then the lnk file cannot be created.
                                                # Icon: If next to the srcFile an ico file with the same filename exists then this will be taken.
                                                AssertNotEmpty $srcFsEntry;
                                                $workDir    = FsEntryGetAbsolutePath $workDir;
                                                $lnkFile    = FsEntryGetAbsolutePath $lnkFile;
                                                $srcFsEntry = FsEntryGetAbsolutePath $srcFsEntry;
                                                [String] $descr = $srcFsEntry;
                                                [Boolean] $isDir = FsEntryHasTrailingDirSep $srcFsEntry;
                                                if( $ignoreIfSrcNotExists -and (($isDir -and (DirNotExists $srcFsEntry)) -or (-not $isDir -and (FileNotExists $srcFsEntry))) ){
                                                  OutVerbose "NotCreatedBecauseSourceFileNotExists: $lnkFile"; return;
                                                }
                                                if( $isDir ){ DirAssertExists $srcFsEntry; }else{ FileAssertExists $srcFsEntry; }
                                                if( $forceRecreate ){ FileDelete $lnkFile -traceCmd:$false; }
                                                if( (FileExists $lnkFile) ){
                                                  OutVerbose "Unchanged: $lnkFile";
                                                }else{
                                                    [String] $argLine = $arguments; # array to string
                                                    if( $workDir -eq "" ){ if( $isDir ){ $workDir = $srcFsEntry; }else{ $workDir = FsEntryGetParentDir $srcFsEntry; } }
                                                    [String] $iconFile = (StringRemoveRight (FsEntryRemoveTrailingDirSep $srcFsEntry) (FsEntryGetFileExtension $srcFsEntry)) + ".ico";
                                                    [String] $ico = $(switch((FileExists $iconFile)){($true){$iconFile}($false){",0"}});
                                                    OutProgress "CreateShortcut `"$lnkFile`"";
                                                    try{
                                                      [Object] $wshShell = New-Object -comObject WScript.Shell;
                                                      [Object] $s = $wshShell.CreateShortcut($lnkFile); # do not use FsEntryEsc otherwise [ will be created as `[
                                                      $s.TargetPath       = FsEntryEsc $srcFsEntry;
                                                      $s.Arguments        = $argLine;
                                                      $s.WorkingDirectory = FsEntryEsc $workDir;
                                                      $s.Description      = $descr;
                                                      $s.IconLocation     = $ico; # one of: ",0" "myprog.exe, 0" "myprog.ico";
                                                      OutVerbose "WScript.Shell.CreateShortcut workDir=`"$workDir`" lnk=`"$lnkFile`" src=`"$srcFsEntry`" arg=`"$argLine`" descr=`"$descr`" ico==`"$ico`"";
                                                      FsEntryCreateParentDir $lnkFile;
                                                      # $s.WindowStyle = 1; 1=Normal; 3=Maximized; 7=Minimized;
                                                      # $s.Hotkey = "CTRL+SHIFT+F"; # requires restart explorer
                                                      # $s.RelativePath = ...
                                                      $s.Save(); # does overwrite
                                                    }catch{
                                                      throw [ExcMsg] "$(ScriptGetCurrentFunc)(`"$workDir`",`"$lnkFile`",`"$srcFsEntry`",`"$argLine`",`"$descr`") failed because $($_.Exception.Message)";
                                                    }
                                                  if( $runElevated ){
                                                    [Byte[]] $bytes = [IO.File]::ReadAllBytes($lnkFile); $bytes[0x15] = $bytes[0x15] -bor 0x20; [IO.File]::WriteAllBytes($lnkFile,$bytes);  # set bit 6 of byte nr 21
                                                  } } }
function ToolCreateMenuLinksByMenuItemRefFile ( [String] $targetMenuRootDir, [String] $sourceDir,
                                                [String] $srcFileExtMenuLink    = ".menulink.txt",
                                                [String] $srcFileExtMenuLinkOpt = ".menulinkoptional.txt" ){
                                                # Create menu entries based on menu-item-linkfiles below a dir.
                                                # - targetMenuRootDir      : target start menu folder, example: "$env:APPDATA\Microsoft\Windows\Start Menu\Apps"
                                                # - sourceDir              : Used to finds all files below sourceDir with the extension (example: ".menulink.txt").
                                                #                            For each of these files it will create a menu item below the target menu root dir.
                                                # - srcFileExtMenuLink     : Extension for mandatory menu linkfiles. The containing referenced command (in general an executable) must exist.
                                                # - $srcFileExtMenuLinkOpt : Extension for optional  menu linkfiles. Menu item is created only if the containing referenced executable will exist.
                                                # The name of the target menu item (example: "Manufactor ProgramName V1") will be taken from the name
                                                #   of the menu-item-linkfile (example: ...\Manufactor ProgramName V1.menulink.txt) without the extension (example: ".menulink.txt")
                                                #   and the sub menu folder will be taken from the relative location of the menu-item-linkfile below the sourceDir.
                                                # The command for the target menu will be taken from the first line (example: "D:\MyApps\Manufactor ProgramName\AnyProgram.exe")
                                                #   of the content of the menu-item-linkfile.
                                                # If target lnkfile already exists it does nothing.
                                                # Example: ToolCreateMenuLinksByMenuItemRefFile "$env:APPDATA\Microsoft\Windows\Start Menu\Apps" "D:\MyApps" ".menulink.txt";
                                                FsEntryAssertHasTrailingDirSep $targetMenuRootDir;
                                                FsEntryAssertHasTrailingDirSep $sourceDir;
                                                [String] $m    = FsEntryGetAbsolutePath $targetMenuRootDir; # Example: "$env:APPDATA\Microsoft\Windows\Start Menu\MyPortableProg\"
                                                [String] $sdir = FsEntryGetAbsolutePath $sourceDir; # Example: "D:\MyPortableProgs"
                                                OutProgress "Create menu links to `"$m`" from files below `"$sdir`" with extension `"$srcFileExtMenuLink`" or `"$srcFileExtMenuLinkOpt`" files";
                                                Assert ($srcFileExtMenuLink    -ne "" -or (-not (FsEntryHasTrailingDirSep $srcFileExtMenuLink   ))) "srcMenuLinkFileExt=`"$srcFileExtMenuLink`" is empty or has trailing backslash";
                                                Assert ($srcFileExtMenuLinkOpt -ne "" -or (-not (FsEntryHasTrailingDirSep $srcFileExtMenuLinkOpt))) "srcMenuLinkOptFileExt=`"$srcFileExtMenuLinkOpt`" is empty or has trailing backslash";
                                                if( -not (DirExists $sdir) ){ OutWarning "Warning: Ignoring dir not exists: `"$sdir`""; }
                                                [String[]] $menuLinkFiles =  (@()+(FsEntryListAsStringArray "$sdir$(DirSep)*$srcFileExtMenuLink"    $true $false));
                                                           $menuLinkFiles += (FsEntryListAsStringArray "$sdir$(DirSep)*$srcFileExtMenuLinkOpt" $true $false);
                                                           $menuLinkFiles =  (@()+($menuLinkFiles | Where-Object{$null -ne $_} | Sort-Object));
                                                foreach( $f in $menuLinkFiles ){ # Example: "...\MyProg .menulinkoptional.txt"
                                                  [String] $d = FsEntryGetParentDir $f; # Example: "D:\MyPortableProgs\Appl\Graphic\"
                                                  [String] $relBelowSrcDir = FsEntryMakeRelative $d $sdir; # Example: "Appl\Graphic\" or ".\"
                                                  [String] $workDir = "";
                                                  # Example: "$env:APPDATA\Microsoft\Windows\Start Menu\MyPortableProg\Appl\Graphic\Manufactor ProgramName V1 en 2016.lnk"
                                                  [String] $fn = FsEntryGetFileName $f; $fn = StringRemoveRight $fn $srcFileExtMenuLink; $fn = StringRemoveRight $fn $srcFileExtMenuLinkOpt; $fn = $fn.TrimEnd();
                                                  [String] $lnkFile = FsEntryGetAbsolutePath "$m/$relBelowSrcDir/$fn.lnk";
                                                  [String] $cmdLine = FileReadContentAsLines $f -encodingIfNoBom "Default" | Select-Object -First 1; # TODO: try to replace Default by UTF8.
                                                  [String] $addTraceInfo = "";
                                                  [Boolean] $forceRecreate = FileNotExistsOrIsOlder $lnkFile $f;
                                                  [Boolean] $ignoreIfSrcNotExists = $f.EndsWith($srcFileExtMenuLinkOpt);
                                                  try{
                                                    [String[]] $ar = @()+(StringCommandLineToArray $cmdLine); # can throw: Expected blank or tab char or end of string but got char ...
                                                    if( $ar.Length -eq 0 ){ throw [Exception] "Missing a command line at first line in file=`"$f`" cmdline=`"$cmdLine`""; }
                                                    if( ($ar.Length-1) -gt 999 ){
                                                      throw [Exception] "Command line has more than the allowed 999 arguments at first line infile=`"$f`" nrOfArgs=$($ar.Length) cmdline=`"$cmdLine`""; }
                                                    # Example: "D:\MyPortableProgs\Manufactor ProgramName\AnyProgram.exe"
                                                    [String] $srcFile = FsEntryGetAbsolutePath ([System.IO.Path]::Combine($d,$ar[0]));
                                                    [String[]] $arguments = @()+($ar | Select-Object -Skip 1);
                                                    $addTraceInfo = "and calling (ToolCreateLnkIfNotExists $forceRecreate `"$workDir`" `"$lnkFile`" `"$srcFile`" `"$arguments`" $false $ignoreIfSrcNotExists) ";
                                                    ToolCreateLnkIfNotExists $forceRecreate $workDir $lnkFile $srcFile $arguments $false $ignoreIfSrcNotExists;
                                                  }catch{
                                                    [String] $msg = "$($_.Exception.Message).$(switch(-not $cmdLine.StartsWith('`"')){($true){' Maybe first file of content in menulink file should be quoted.'}default{' Maybe if first file not exists you may use file extension `".menulinkoptional`" instead of `".menulink`".'}})";
                                                    OutWarning "Warning: Create menulink by reading file `"$f`", taking first line as cmdLine ($cmdLine) $addTraceInfo failed because $msg";
                                                  } } }
function ToolSignDotNetAssembly               ( [String] $keySnk, [String] $srcDllOrExe, [String] $tarDllOrExe, [Boolean] $overwrite = $false ){
                                                # Sign (apply strong name) a given source executable (dll or exe) with a given key and write it to a target file.
                                                # If the sourcefile has an correspondig xml file with the same name then this is also copied to target.
                                                # If the input file was already signed then it creates a target file with the same name and the extension ".originalWasAlsoSigned.txt".
                                                # Note: Generate your own key with: sn.exe -k mykey.snk
                                                $keySnk      = FsEntryGetAbsolutePath $keySnk;
                                                $srcDllOrExe = FsEntryGetAbsolutePath $srcDllOrExe;
                                                $tarDllOrExe = FsEntryGetAbsolutePath $tarDllOrExe;
                                                OutProgressTitle "Sign dot-net assembly: keySnk=`"$keySnk`" srcDllOrExe=`"$srcDllOrExe`" tarDllOrExe=`"$tarDllOrExe`" overwrite=$overwrite ";
                                                [Boolean] $execHasStrongName = ([String](& sn -vf $srcDllOrExe | Select-Object -Skip 4 )) -like "Assembly '*' is valid"; AssertRcIsOk;
                                                [Boolean] $isDllNotExe = $srcDllOrExe.ToLower().EndsWith(".dll");
                                                if( -not $isDllNotExe -and -not $srcDllOrExe.ToLower().EndsWith(".exe") ){
                                                  throw [Exception] "Expected ends with .dll or .exe, srcDllOrExe=`"$srcDllOrExe`""; }
                                                if( -not $overwrite -and (FileExists $tarDllOrExe) ){
                                                  OutProgress "Ok, nothing done because target already exists: $tarDllOrExe"; return; }
                                                FsEntryCreateParentDir  $tarDllOrExe;
                                                [String] $n = FsEntryGetFileName $tarDllOrExe;
                                                [String] $d = DirCreateTemp "SignAssembly_";
                                                OutProgress "ildasm.exe -NOBAR -all `"$srcDllOrExe`" `"-out=$d$(DirSep)$n.il`"";
                                                & "ildasm.exe" -TEXT -all $srcDllOrExe "-out=$d$(DirSep)$n.il"; AssertRcIsOk;
                                                OutProgress "ilasm.exe -QUIET -DLL -PDB `"-KEY=$keySnk`" `"$d$(DirSep)$n.il`" `"-RESOURCE=$d$(DirSep)$n.res`" `"-OUTPUT=$tarDllOrExe`"";
                                                & "ilasm.exe" -QUIET -DLL -PDB "-KEY=$keySnk" "$d$(DirSep)$n.il" "-RESOURCE=$d$(DirSep)$n.res" "-OUTPUT=$tarDllOrExe"; AssertRcIsOk;
                                                DirDelete $d;
                                                # Note: We do not take the pdb of original unsigned assembly because ilmerge would fail because pdb is outdated. But we created a new pdb if it is available.
                                                [String] $srcXml = (StringRemoveRightNr $srcDllOrExe 4) + ".xml";
                                                [String] $tarXml = (StringRemoveRightNr $tarDllOrExe 4) + ".xml";
                                                [String] $tarOri = (StringRemoveRightNr $tarDllOrExe 4) + ".originalWasAlsoSigned.txt";
                                                if( $execHasStrongName ){ FileWriteFromString $tarOri "Original executable has also a strong name: $srcDllOrExe" $true; }
                                                if( FileExists $srcXml ){ FileCopy $srcXml $tarXml $true; } }
function ToolSetAssocFileExtToCmd             ( [String[]] $fileExtensions, [String] $cmd, [String] $ftype = "", [Boolean] $assertPrgExists = $false ){ # Works only on Windows
                                                # Sets the association of a file extension to a command by overwriting it.
                                                # FileExtensions: must begin with a dot, must not content blanks or commas,
                                                #   if it is only a dot then it is used for files without a file ext.
                                                # Cmd: if it is empty then association is deleted.
                                                #  Can contain variables as %SystemRoot% which will be replaced at runtime.
                                                #   If cmd does not begin with embedded double quotes then it is interpreted as a full path to an executable
                                                #   otherwise it uses the cmd as it is.
                                                # Ftype: Is a group of file extensions. If it not yet exists then a default will be created
                                                #   in the style {extWithoutDot}file (example: ps1file).
                                                # AssertPrgExists: You can assert that the program in the command must exist but note that
                                                #   variables enclosed in % char cannot be expanded because these are not powershell variables.
                                                # Example: ToolSetAssocFileExtToCmd @(".log",".out") "$env:SystemRoot\System32\notepad.exe" "" $true;
                                                # Example: ToolSetAssocFileExtToCmd ".log"           "$env:SystemRoot\System32\notepad.exe";
                                                # Example: ToolSetAssocFileExtToCmd ".log"           "%SystemRoot%\System32\notepad.exe" "txtfile";
                                                # Example: ToolSetAssocFileExtToCmd ".out"           "`"C:\Any.exe`" `"%1`" -xy";
                                                # Example: ToolSetAssocFileExtToCmd ".out" "";
                                                [String] $prg = $cmd; if( $cmd.StartsWith("`"") ){ $prg = ($prg -split "`"",0)[1]; }
                                                [String] $exec = $cmd; if( -not $cmd.StartsWith("`"") ){ $exec = "`"$cmd`" `"%1`""; }
                                                [String] $traceInfo = "ToolSetAssocFileExtToCmd($fileExtensions,`"$cmd`",$ftype,$assertPrgExists)";
                                                if( $assertPrgExists -and $cmd -ne "" -and (FileNotExists $prg) ){
                                                  throw [ExcMsg] "$traceInfo failed because not exists: `"$prg`""; }
                                                $fileExtensions | Where-Object{$null -ne $_} | ForEach-Object{
                                                  if( -not $_.StartsWith(".") ){ throw [ExcMsg] "$traceInfo failed because file ext not starts with dot: `"$_`""; };
                                                  if( $_.Contains(" ") ){ throw [ExcMsg] "$traceInfo failed because file ext contains blank: `"$_`""; };
                                                  if( $_.Contains(",") ){ throw [ExcMsg] "$traceInfo failed because file ext contains blank: `"$_`""; };
                                                };
                                                $fileExtensions | Where-Object{$null -ne $_} | ForEach-Object{
                                                  [String] $ext = $_; # Example: ".ps1"
                                                  if( $cmd -eq "" ){
                                                    OutProgress "DelFileAssociation ext=$ext :  cmd /c assoc $ext=";
                                                    [String] $out = (& cmd.exe /c "assoc $ext=" *>&1); AssertRcIsOk; # Example: ""
                                                  }else{
                                                    [String] $ft = $ftype;
                                                    if( $ftype -eq "" ){
                                                      try{
                                                        $ft = (& cmd.exe /c "assoc $ext" *>&1); AssertRcIsOk; # Example: ".ps1=Microsoft.PowerShellScript.1"
                                                      }catch{ # Example: "Dateizuordnung für die Erweiterung .ps9 nicht gefunden."
                                                        $ft = (& cmd.exe /c "assoc $ext=$($ext.Substring(1))file" *>&1); AssertRcIsOk; # Example: ".ps1=ps1file"
                                                      }
                                                      $ft = $ft.Split("=")[-1]; # "Microsoft.PowerShellScript.1" or "ps1file"
                                                    }
                                                     # Example: Microsoft.PowerShellScript.1="C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe" "%1"
                                                    [String] $out = (& cmd.exe /c "ftype $ft=$exec"); AssertRcIsOk;
                                                    OutProgress "SetFileAssociation ext=$($ext.PadRight(6)) ftype=$($ft.PadRight(20)) cmd=$exec";
                                                  }
                                                }; }
function ToolVsUserFolderGetLatestUsed        (){
                                                # return the current user config folder of visual studio 2022 or 2019 or empty string if it not exits.
                                                # example: "$env:LOCALAPPDATA\Microsoft\VisualStudio\16.0_d70392ef\"
                                                [String] $result = "";
                                                # we internally locate the private registry file used by vs2019, later maybe we use https://github.com/microsoft/vswhere
                                                [String[]] $a  = (@()+(FsEntryListAsStringArray "$env:LOCALAPPDATA\Microsoft\VisualStudio\17.0_*\privateregistry.bin" $false $false));
                                                           $a += (@()+(FsEntryListAsStringArray "$env:LOCALAPPDATA\Microsoft\VisualStudio\16.0_*\privateregistry.bin" $false $false));
                                                if( $a.Count -gt 0 ){
                                                  $result = $a[0];
                                                  $a | Select-Object -Skip 1 | ForEach-Object { if( FileExistsAndIsNewer $_ $result ){ $result = $_; } }
                                                  $result = FsEntryGetParentDir $result;
                                                }
                                                return [String] $result; }
function ToolGitTortoiseCommit                ( [String] $workDir, [String] $commitMessage = "" ){
                                                $workDir = FsEntryGetAbsolutePath $workDir;
                                                FsEntryAssertHasTrailingDirSep $workDir;
                                                [String] $tortoiseExe = (RegistryGetValueAsString "HKLM:\SOFTWARE\TortoiseGit" "ProcPath"); # Example: "C:\Program Files\TortoiseGit\bin\TortoiseGitProc.exe"
                                                Start-Process -NoNewWindow -Wait -FilePath "$tortoiseExe" -ArgumentList @("/command:commit","/path:`"$workDir`"", "/logmsg:$commitMessage"); AssertRcIsOk; }
function ToolWin10PackageGetState             ( [String] $packageName ){ # Example: for "OpenSSH.Client" return "Installed","NotPresent".
                                                ProcessRestartInElevatedAdminMode;
                                                if( $packageName -eq "" ){ throw [Exception] "Missing packageName"; }
                                                return [String] ((Get-WindowsCapability -Online | Where-Object name -like "${packageName}~*").State); }
function ToolWin10PackageInstall              ( [String] $packageName ){ # Example: "OpenSSH.Client"
                                                OutProgress "Install Win10 Package if not installed: `"$packageName`"";
                                                ProcessRestartInElevatedAdminMode;
                                                if( (ToolWin10PackageGetState $packageName) -eq "Installed" ){
                                                  OutProgress "Ok, `"$packageName`" is already installed."; }
                                                else{
                                                  [String] $name = (Get-WindowsCapability -Online | Where-Object name -like "${packageName}~*").Name;
                                                  Add-WindowsCapability -Online -name $name | Out-Null; # example output: "Path          :\nOnline        : True\nRestartNeeded : False"
                                                  [String] $restartNeeded = (Get-WindowsCapability -Online -name $packageName).RestartNeeded;
                                                  OutProgressTitle "Ok, installation done, current state=$(ToolWin10PackageGetState $packageName) RestartNeeded=$restartNeeded Name=$name";
                                                } }
function ToolWin10PackageDeinstall            ( [String] $packageName ){
                                                OutProgress "Deinstall Win10 Package: `"$packageName`"";
                                                ProcessRestartInElevatedAdminMode;
                                                if( (ToolWin10PackageGetState $packageName) -ne "Installed" ){
                                                  OutProgress "Ok, `"$packageName`" is already deinstalled."; }
                                                else{
                                                  [String] $name = (Get-WindowsCapability -Online | Where-Object name -like "${packageName}~*").Name;
                                                  Remove-WindowsCapability -Online -name $name | Out-Null;
                                                  [String] $restartNeeded = (Get-WindowsCapability -Online -name $packageName).RestartNeeded;
                                                  OutProgressTitle "Ok, deinstallation done, current state=$(ToolWin10PackageGetState $packageName) RestartNeeded=$restartNeeded Name=$name";
                                                } }
function ToolOsWindowsResetSystemFileIntegrity(){ # uses about 4 min
                                                [String] $f = "$env:SystemRoot$(DirSep)Logs$(DirSep)CBS$(DirSep)CBS.log";
                                                OutProgress "Check and repair missing, corrupted or ownership-settings of system files and afterwards dump last lines of logfile '$f'";
                                                ProcessRestartInElevatedAdminMode;
                                                # https://support.microsoft.com/de-ch/help/929833/use-the-system-file-checker-tool-to-repair-missing-or-corrupted-system
                                                # https://support.microsoft.com/en-us/kb/929833
                                                OutProgress "Run: sfc.exe /scannow";
                                                & "sfc.exe" "/SCANNOW"; ScriptResetRc; # system-file-checker-tool; usually rc=-1; alternative: sfc.exe /VERIFYONLY;
                                                OutProgress "Run: Dism.exe /Online /Cleanup-Image /ScanHealth ";
                                                & "Dism.exe" "/Online" "/Cleanup-Image" "/ScanHealth"   ; ScriptResetRc; # uses about 2 min
                                                OutProgress "Run: Dism.exe /Online /Cleanup-Image /CheckHealth ";
                                                & "Dism.exe" "/Online" "/Cleanup-Image" "/CheckHealth"  ; ScriptResetRc; # uses about 2 sec
                                                OutProgress "Run: Dism.exe /Online /Cleanup-Image /RestoreHealth ";
                                                & "Dism.exe" "/Online" "/Cleanup-Image" "/RestoreHealth"; ScriptResetRc; # uses about 2 min; also repairs autoupdate;
                                                OutProgress "Dump last lines of logfile '$f':";
                                                FileGetLastLines $f 100 | Foreach-Object{ OutProgress "  $_"; };
                                                OutProgressTitle "Ok, checked and repaired missing, corrupted or ownership-settings of system files and logged to '$env:Windows/Logs/CBS/CBS.log'"; }
function ToolPerformFileUpdateAndIsActualized ( [String] $targetFile, [String] $url, [Boolean] $requireElevatedAdminMode = $false,
                                                  [Boolean] $doWaitIfFailed = $false, [String] $additionalOkUpdMsg = "",
                                                  [Boolean] $assertFilePreviouslyExists = $true, [Boolean] $performPing = $true ){
                                                # Check if target file exists, checking wether host is reachable by ping, downloads the file, check for differences,
                                                # check for admin mode, overwriting the file and a success message is given out.
                                                # Otherwise if it failed it will output a warning message and optionally wait for pressing enter key.
                                                # It returns true if the file is now actualized.
                                                # Note: if not in elevated admin mode and if it is required then it will download file twice,
                                                #   once to check for differences and once after switching to elevated admin mode.
                                                # Example: ToolPerformFileUpdateAndIsActualized "$env:TEMP/tmp/a.psm1" "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/MnCommonPsToolLib/MnCommonPsToolLib.psm1" $true $true "Please restart" $false $true;
                                                $targetFile = FsEntryGetAbsolutePath $targetFile;
                                                try{
                                                  OutProgressTitle "Update file `"$targetFile`"";
                                                  OutProgress "FromUrl: $url";
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
                                                    [String] $hostname = (NetExtractHostName $url);
                                                    if( -not (NetPingHostIsConnectable $hostname) ){
                                                      throw [Exception] "Host $hostname is not pingable.";
                                                    }
                                                  }
                                                  [String] $tmp = (FileGetTempFile); NetDownloadFile $url $tmp;
                                                  OutProgress "Checking for differences.";
                                                  if( $targetFileExists -and $hashInstalled -eq (FileGetHexStringOfHash512BitsSha2 $tmp) ){
                                                    FileDelete $tmp;
                                                    OutProgress "Ok, is up to date, nothing done.";
                                                  }else{
                                                    OutProgress "There are changes between the current file and the downloaded file, so overwrite it.";
                                                    if( $requireElevatedAdminMode ){
                                                      if( -not (ProcessIsRunningInElevatedAdminMode) ){ FileDelete $tmp; }
                                                      ProcessRestartInElevatedAdminMode;
                                                      OutProgress "Is running in elevated admin mode.";
                                                    }
                                                    FileMove $tmp $targetFile $true;
                                                    OutProgressSuccess "Ok, updated `"$targetFile`". $additionalOkUpdMsg";
                                                  }
                                                  ProcessRefreshEnvVars;
                                                  return [Boolean] $true;
                                                }catch{
                                                  OutWarning "Warning: Update failed because $($_.Exception.Message)";
                                                  if( $doWaitIfFailed ){
                                                    StdInReadLine "Press Enter to continue.";
                                                  }
                                                  return [Boolean] $false;
                                                } }
function ToolInstallOrUpdate                  ( [String] $installMedia, [String] $mainTargetFileMinIsoDate, [String] $mainTargetRelFile, [String] $installDirsSemicSep, [String] $installHints = "" ){
                                                # Check if a main target file exists in one of the installDirs and wether it has a minimum expected date.
                                                # If not it will be installed or updated by calling installmedia asynchronously which is in general a half automatic installation procedure.
                                                # Example: ToolInstallOrUpdate "Freeware\NetworkClient\Browser\OpenSource-MPL2 Firefox V89.0 64bit multilang 2021.exe" "2021-05-27" "firefox.exe" "$env:ProgramFiles\Mozilla Firefox ; C:\Prg\Network\Browser\OpenSource-MPL2 Firefox\" "Not install autoupdate";
                                                $installMedia   = FsEntryGetAbsolutePath $installMedia;
                                                [String[]] $installDirs = @()+(StringSplitToArray ";" $installDirsSemicSep);
                                                [DateTime] $mainTargetFileMinDate = DateTimeFromStringIso $mainTargetFileMinIsoDate;
                                                [DateTime] $mainTargetFileDate = [DateTime]::MinValue; # default also means not installed
                                                [String]   $installDirsStr = $installDirs | ForEach-Object{ FsEntryGetAbsolutePath $_; }| ForEach-Object{ "`"$_`"; " };
                                                Assert ($installDirs.Count -gt 0) "Missing an installDir";
                                                $installDirs | ForEach-Object{
                                                  [String] $f = FsEntryGetAbsolutePath ([System.IO.Path]::Combine($_,$mainTargetRelFile));
                                                  if( FileExists $f ){
                                                    if( $mainTargetFileDate -ne [DateTime]::MinValue ){
                                                      OutWarning "Warning: Installed main target file already found in previous installDir so ignore duplicate also installed main target file: `"$f`"";
                                                    }else{ $mainTargetFileDate = FsEntryGetLastModified $f; }
                                                  }
                                                };
                                                OutProgress "Target: MinDate=$mainTargetFileMinIsoDate FileTs=$(DateTimeAsStringIso $mainTargetFileDate "yyyy-MM-dd") File=`"$mainTargetRelFile`" InstallDirs=$installDirsStr";
                                                if( FileNotExists $installMedia ){
                                                  OutWarning "Warning: Missing Installmedia `"$installMedia`"";
                                                }elseif( $mainTargetFileDate -lt $mainTargetFileMinDate ){
                                                  OutProgressTitle "Installmedia `"$installMedia`"";
                                                  $installDirs | ForEach-Object{ OutProgressTitle "  Accepted-Installdir: `"$_`""; };
                                                  if( $installHints -ne "" ){ OutProgressTitle "  InstallHints: $installHints"; }
                                                  if( StdInAskForBoolean ){
                                                    & $installMedia; AssertRcIsOk;
                                                  }
                                                }else{
                                                  OutProgress "Is up-to-date: `"$installMedia`"";
                                                } }
function ToolInstallNuPckMgrAndCommonPsGalMo  (){ # runs in about 12-90 sec and if nessessary then the update help requires about 2 minutes.
                                                OutProgressTitle     "Install or actualize Nuget Package Manager and from PSGallery some common ps modules: ";
                                                [String[]] $moduleNames = @(
                                                  # Predefined on Win  : Microsoft.PowerShell.Core          ; # Std     : Where-Object
                                                  # Predefined on Linux: Microsoft.PowerShell.PSResourceGet ; # Std     : ?
                                                  # Predefined         : Microsoft.PowerShell.Utility       ; # Std     : Write-Output
                                                  # Predefined         : Microsoft.PowerShell.Host          ; # Std     : Start-Transcript
                                                  # Predefined         : Microsoft.PowerShell.Management    ; # Std     : Start-Process
                                                  # Predefined         : Microsoft.PowerShell.Security      ; # Std     : Get-ExecutionPolicy, Set-ExecutionPolicy
                                                    "PowerShellGet"                 # Provides: Set-PSRepository, Install-Module
                                                  , "PackageManagement"             # Provides: Install-PackageProvider, Get-Package
                                                  , "SqlServer"                     # UsedBy  : SqlPerformFile, SqlPerformCmd.
                                                  , "ThreadJob"                     # UsedBy  : GitCloneOrPullUrls
                                                  , "PSScriptAnalyzer"              # UsedBy  : testing files for analysing powershell code
                                                  , "Pester"                        # UsedBy  : Run ps tests
                                                  , "PSWindowsUpdate"               # On Windows only
                                                  , "PsReadline"                    # Provides: Write-Output
                                                  , "Microsoft.PowerShell.Archive"  # Provides: Compress-Archive, Expand-Archive
                                                  # for future use: Microsoft.EntityFrameworkCore.Tools
                                                  # Import-Module Microsoft.PowerShell.Host;"; # seams to be required once for vs-code-terminal-pwsh
                                                   );
                                                OutProgress "Install or update modules and its help: ";
                                                OutProgress "  $moduleNames ";
                                                ProcessRestartInElevatedAdminMode;
                                                OutProgress "Import-Module PowerShellGet for command Install-Module:";
                                                Import-Module "PowerShellGet"; # provides: Set-PSRepository, Install-Module
                                                #
                                                OutProgress "List of available ps modules for import to current session ";
                                                [PSCustomObject[]] $availableModules = Get-Module -ListAvailable | Where-Object{ $null -ne $_ } |
                                                  Sort-Object Name, Version, ModuleType | Select-Object Name, Version, ModuleType, Path;
                                                $availableModules | StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                OutProgress "List of imported modules in current session:";
                                                Get-Module | Sort-Object Name, Version, ModuleType | Select-Object Name,ModuleType,Version,Path |
                                                  StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                function DownloadNuPckAndUnzipIfDirNotExists( [String] $url, [String] $tarDir ){
                                                  if( (DirNotExists $tarDir) ){
                                                    [String] $ftmp = FileGetTempFile;
                                                    NetDownloadFile $url $ftmp;
                                                    Unblock-File $ftmp;
                                                    ToolUnzip $ftmp $tarDir;
                                                    Get-ChildItem -Path $tarDir -Recurse | Unblock-File;
                                                    FileDelete $ftmp;
                                                    # maybe later we delete some nuget specific obsolete files as: "_rels".
                                                  }
                                                }
                                                function MakeSureForPs5InstalledPackageManagement(){
                                                  # Works for Ps 5 and 7; There is no automatic installation or update;
                                                  # if we are running in PS5.1 and Get-PackageProvider (from PackageManagement) was found then do nothing.
                                                  if( (ProcessIsLesserEqualPs5) -and $null -ne (Get-Command "Get-PackageProvider" -ErrorAction SilentlyContinue) ){ return; }
                                                  DownloadNuPckAndUnzipIfDirNotExists "https://www.powershellgallery.com/api/v2/package/PackageManagement/1.4.8.1" "C:/Program Files/WindowsPowerShell/Modules/PackageManagement/1.4.8.1/"; # 2025-02
                                                }
                                                function MakeSureForPs5InstalledPowerShellGet(){
                                                  # Works for Ps 5 and 7; Required because there is no automatic installation or update for PS5-V1.0.0.1;
                                                  # if we are running in PS5.1 and Install-Module (from PowerShellGet) was found then do nothing.
                                                  if( (ProcessIsLesserEqualPs5) -and $null -ne (Get-Command "Install-Module" -ErrorAction SilentlyContinue) ){ return; }
                                                  DownloadNuPckAndUnzipIfDirNotExists "https://www.powershellgallery.com/api/v2/package/PowerShellGet/2.2.5"       "C:/Program Files/WindowsPowerShell/Modules/PowerShellGet/2.2.5/"      ; # 2025-02
                                                }
                                                # Note: PackageManagement is a required dependency for PowerShellGet
                                                MakeSureForPs5InstalledPackageManagement;
                                                MakeSureForPs5InstalledPowerShellGet;
                                                OutProgress "List of installed modules (having an installdate):"; # only on PS5 we found the modules "Azure*" having no installdate.
                                                [PSCustomObject[]] $installedModules = Get-InstalledModule | 
                                                  Where-Object{ $null -ne $_ -and $null -ne $_.InstalledDate } | 
                                                  Select-Object Name | Get-InstalledModule -AllVersions | Sort-Object Name, Version, InstalledDate, InstalledLocation |
                                                  Select-Object Name, Version, InstalledDate, UpdatedDate, Dependencies, Repository, PackageManagementProvider, InstalledLocation;
                                                    # Get-InstalledModule -AllVersions  must be called with a single name otherwise we get:
                                                    #   Get-InstalledModule: The RequiredVersion, MinimumVersion, MaximumVersion, AllVersions or AllowPrerelease parameters
                                                    #   are allowed only when you specify a single name as the value of the Name parameter, without any wildcard characters.
                                                $installedModules | StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                #
                                                OutProgress "List ps gallery repositories: ";
                                                [PSCustomObject[]] $psRepos = Get-PSRepository | Where-Object{ $null -ne $_} | Sort-Object Name, SourceLocation |
                                                  Select-Object Name, Trusted, Registered, InstallationPolicy, PackageManagementProvider, SourceLocation;
                                                $psRepos | StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                  # Example: PSGallery True True Trusted NuGet https://www.powershellgallery.com/api/v2
                                                #
                                                OutProgress "List of installed package providers:";
                                                [PSCustomObject[]] $pckProviders = Get-PackageProvider -ListAvailable | Where-Object{ $null -ne $_ } |
                                                  Sort-Object Name, Version |
                                                  Select-Object Name, Version; # alternative: DynamicOptions
                                                $pckProviders | StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                  # example: Nuget V3.0, PowerShellGet V2.2, PowerShellGet V1.0.
                                                  #   PowerShellGet is a package provider for PowerShell PackageManagement (also known as OneGet).
                                                #
                                                OutProgress "Make sure we have package provider NuGet in minimum version 2.8.5.201 ";
                                                if( (ProcessIsLesserEqualPs5) ){
                                                  # On PS7 we would get: Install-PackageProvider: No match was found for the specified search criteria for the provider 'NuGet'.
                                                  #   The package provider requires 'PackageManagement' and 'Provider' tags. Please check if the specified package has the tags.
                                                  # PowerShellGet requires minimum NuGet V2.8.5.201; Needs 2-4 sec.
                                                  OutProgress "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; ";
                                                               Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Select-Object Name, Version, Status, Source |
                                                    StreamToTableString | StreamToStringIndented | ForEach-Object{ OutProgress $_; };
                                                }
                                                OutProgress "Make sure ps repo PSGallary is trusted ";
                                                [PSCustomObject] $psGallery = $psRepos | Where-Object{ $_.Name -eq "PSGallery" };
                                                if( $null -ne $psGallery -and $psGallery.InstallationPolicy -ne "Trusted" ){
                                                  OutProgress "Set repository PSGallery to trusted: ";
                                                  Set-PSRepository PSGallery -InstallationPolicy Trusted; # uses 14 sec
                                                }
                                                OutProgress "Update NuGet"; # works asynchron
                                                # On PS7 for "Install-PackageProvider NuGet" we got:
                                                #   Install-PackageProvider: No match was found for the specified search criteria for the provider 'NuGet'.
                                                #     The package provider requires 'PackageManagement' and 'Provider' tags. Please check if the specified package has the tags.
                                                # So we ignore errors.
                                                Install-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Where-Object{ $null -ne $_} |
                                                  Select-Object Name, Version, Status, Source |
                                                  StreamToTableString | StreamToStringIndented | Where-Object{ $_.Trim() -ne ""} |
                                                  ForEach-Object{ OutProgress $_; }; # Needs 1 sec.
                                                # https://docs.microsoft.com/en-us/powershell/scripting/how-to-use-docs?view=powershell-7.2  take lts version
                                                # alternatives: Install-Module -Force [-MinimumVersion <String>] [-MaximumVersion <String>] [-RequiredVersion <String>]
                                                OutProgress "Install or update required modules ";
                                                function InstallOrUpdateModule( [String] $module ){
                                                  [Boolean] $isNotInstalled = (@()+($installedModules | Where-Object{ $null -ne $_ -and $_.Name -eq $module })).Count -eq 0;
                                                  [String[]] $out = @();
                                                  if( $isNotInstalled ){
                                                    if( (ProcessIsLesserEqualPs5) ){ # has no AcceptLicense option
                                                      OutProgress   "  Install-Module -Name $module                -Scope AllUsers; ";
                                                      $out = [String]( Install-Module -Name $module                -Scope AllUsers 3>&1 );
                                                    }else{
                                                      OutProgress   "  Install-Module -Name $module -AcceptLicense -Scope AllUsers; ";
                                                      $out = [String]( Install-Module -Name $module -AcceptLicense -Scope AllUsers 3>&1 );
                                                    }
                                                    $out | Where-Object{ $null -ne $_ } | Where-Object{ -not $_ -match "^Version\ \'[0-9\.]+\'\ of\ module\ \'[a-zA-Z0-9]+\'\ is\ already\ installed\ at\ .*$" } |
                                                      StreamToTableString | StreamToStringIndented 4 | Where-Object{ $_.Trim() -ne "" } | ForEach-Object{ OutProgress $_; };
                                                      # 2024-09: We get:
                                                      #   WARNING: Version '2.2.1.4' of module 'PSWindowsUpdate' is already installed at 'C:\Program Files\PowerShell\Modules\PSWindowsUpdate\2.2.1.4'.
                                                      #     To install version '2.2.1.5', run Install-Module and add the -Force parameter, this command will install version '2.2.1.5' side-by-side with version '2.2.1.4'                                                                                  .
                                                      #   WARNING: Version '3.4.0' of module 'Pester' is already installed at 'C:\Program Files\WindowsPowerShell\Modules\Pester\3.4.0'.
                                                      #     To install version '5.6.1', run Install-Module and add the -Force parameter, this command will install version '5.6.1' side-by-side with version '3.4.0'.
                                                      # for future use: PowerShellGet -Force
                                                      #   2025-01: but we get: WARNING: The version '1.4.8.1' of module 'PackageManagement' is currently in use. Retry the operation after closing the applications.
                                                  }
                                                  if( -not (ProcessIsLesserEqualPs5) -and $module -eq "PsReadline" ){
                                                    # 2024-03: On PS7 we would get: Update-Module: Module 'PsReadline' was not installed by using Install-Module, so it cannot be updated.
                                                    OutProgress "  #Update-Module -Name PsReadline ...; # not called on PS7 because we would get: it was not installed by using Install-Module. ";
                                                    return;
                                                  }
                                                  [String[]] $out = @();
                                                  if( (ProcessIsLesserEqualPs5) ){ # has no scope parameter
                                                    OutProgress   "  Update-Module  -Name $module -ErrorAction SilentlyContinue                               ; ";
                                                    $out = [String]( Update-Module  -Name $module -ErrorAction SilentlyContinue                                3>&1 );
                                                  }else{
                                                    OutProgress   "  Update-Module  -Name $module -ErrorAction SilentlyContinue -AcceptLicense -Scope AllUsers; ";
                                                    $out = [String]( Update-Module  -Name $module -ErrorAction SilentlyContinue -AcceptLicense -Scope AllUsers 3>&1 );
                                                  }
                                                  $out | Where-Object{ $null -ne $_ } | 
                                                    StreamToTableString | StreamToStringIndented 4 | Where-Object{ $_.Trim() -ne "" } | ForEach-Object{ OutProgress $_; };
                                                    # Example: "Module 'PowerShellGet' was not installed by using Install-Module, so it cannot be updated."
                                                }
                                                $moduleNames | Where-Object{ $null -ne $_ } | ForEach-Object{ InstallOrUpdateModule $_; };
                                                #
                                                OutProgress "Uninstall old versions of modules: ";
                                                Get-InstalledModule | ForEach-Object {
                                                  [String] $v = $_.Version;
                                                  OutProgress "  Uninstall all older versions than $($_.Name.PadRight(32,' ')) V$v ";
                                                  Get-InstalledModule -Name $_.Name -AllVersions | Where-Object -Property Version -LT -Value $v | ForEach-Object{
                                                    try{ Uninstall-Module -Name $_; 
                                                    }catch{ # Example: Exception: Module 'PSReadLine' is in currently in use or you don't have the required permissions.
                                                      ScriptResetRc; OutWarning "Warning: Ignoring: $($_.Exception.Message)";
                                                    }
                                                  }
                                                }
                                                #
                                                [String] $v1001PathOfModulePowerShellGet = ""+(Get-Module -ListAvailable -Name "PowerShellGet" | 
                                                  Where-Object{ $null -ne $_ } | Where-Object{ $_.Version -eq "1.0.0.1" } | Select-Object -First 1 |
                                                  ForEach-Object{ FsEntryGetParentDir $_.Path }); # Example: "C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\1.0.0.1\" or ""
                                                Assert ($v1001PathOfModulePowerShellGet -eq "" -or $v1001PathOfModulePowerShellGet.EndsWith("\PowerShellGet\1.0.0.1\"));
                                                [Int32] $nrOfHigherVersionsOfModulePowerShellGet = (@()+(Get-Module -ListAvailable -Name "PowerShellGet" | 
                                                  Where-Object{ $null -ne $_ } | Where-Object{ $_.Version -ne "1.0.0.1" })).Count;
                                                  # Example: 2.2.5 C:\Users\myuser\Documents\PowerShell\Modules\PowerShellGet\2.2.5\PowerShellGet.psd1
                                                  #          2.2.5 C:\Program Files\PowerShell\Modules\PowerShellGet\2.2.5\PowerShellGet.psd1
                                                  #          2.2.5 C:\program files\powershell\7\Modules\PowerShellGet\PowerShellGet.psd1
                                                if( $v1001PathOfModulePowerShellGet -ne "" -and $nrOfHigherVersionsOfModulePowerShellGet -ge 1 ){
                                                  MakeSureForPs5InstalledPowerShellGet;
                                                  DirDelete $v1001PathOfModulePowerShellGet;
                                                }
                                                #
                                                [String] $v1001PathOfModulePackageManagement = ""+(Get-Module -ListAvailable -Name "PackageManagement" | 
                                                  Where-Object{ $null -ne $_ } | Where-Object{ $_.Version -eq "1.0.0.1" } | Select-Object -First 1 |
                                                  ForEach-Object{ FsEntryGetParentDir $_.Path }); # Example: "C:\Program Files\WindowsPowerShell\Modules\PackageManagement\1.0.0.1\" or ""
                                                [Int32] $nrOfHigherVersionsOfModulePackageManagement = (@()+(Get-Module -ListAvailable -Name "PackageManagement" | 
                                                  Where-Object{ $null -ne $_ } | Where-Object{ $_.Version -ne "1.0.0.1" })).Count;
                                                  # Example: 1.4.8.1 C:\Program Files\WindowsPowerShell\Modules\PackageManagement\1.4.8.1\PackageManagement.psd1
                                                # V1.0.0.1 was not installed by Install-Module, so it cannot automatically be removed by updates, so we have to manually delete (rename) the folder.
                                                if( $v1001PathOfModulePackageManagement -ne "" -and $nrOfHigherVersionsOfModulePackageManagement -ge 1 ){
                                                  MakeSureForPs5InstalledPackageManagement;
                                                  DirDelete $v1001PathOfModulePackageManagement;
                                                }
                                                #
                                                function HasKnowErrMsg( [String] $msg ){
                                                  # Example: 2024-07 Failed to update Help for the module(s)
                                                  #   'PSReadline, WindowsUpdateProvider' with UI culture(s) {en-US} : One or more errors occurred.
                                                  #   (Response status code does not indicate success: 404 (Not Found).).
                                                  #   English-US help content is available and can be installed using: Update-Help -UICulture en-US.
                                                  # Example: 2025-01: Got known response 404=NotFound for en-US of: ConfigDefender, ConfigDefenderPerformance, Dism, Get-NetView, Kds, NetQos, Pester, PKI, Whea, WindowsUpdate.
                                                  # Example: 2025-01 Failed to update Help for the module(s)
                                                  #   'ConfigDefenderPerformance, Dism, Get-NetView, Kds, NetQos, Pester, PKI, Whea, WindowsUpdate' with UI culture(s) {en-US} :
                                                  #   One or more errors occurred. (Response status code does not indicate success: 404 (The specified blob does not exist.).).
                                                  #   English-US help content is available and can be installed using: Update-Help -UICulture en-US.
                                                  # Example: 2025-02: Got known response 404=NotFound for en-US of: ConfigDefenderPerformance, Dism, Get-NetView, Kds, NetQos, Pester, PKI, Whea, WindowsUpdate.
                                                  return [Boolean] ($msg.StartsWith("Failed to update Help for the module(s) '") -and
                                                    $msg.StartsWith("ConfigDefenderPerformance, Dism, Get-NetView, Kds, NetQos, Pester, PKI, Whea, WindowsUpdate") -and
                                                    $msg.StartsWith("(Response status code does not indicate success: 404 (The requested content does not exist.)") -and
                                                    $msg.StartsWith("Update-Help -UICulture en-US."));
                                                }
                                                [DateTime] $lastModuleUpdateTs = (Get-Module -ListAvailable | Where-Object { $null -ne $_.HelpInfoUri } | Select-Object Name,Version,ModuleType,HelpInfoUri,Path | 
                                                  Foreach-Object { FsEntryGetLastModified $_.Path } | Measure-Object -Maximum).Maximum; # Example: 77 modules
                                                [String] $touchFile = "$env:APPDATA/MnCommonPsToolLib/TouchFile.PsUpdateHelp.tmp";
                                                OutProgress "Update-Help check if run is nessessary by comparing lastModifiedAt(`"$touchFile`") with lastModuleUpdateTs=$(DateTimeNowAsStringIso $lastModuleUpdateTs) ";
                                                if( (FileNotExists $touchFile) -or (FsEntryGetLastModified $touchFile) -lt $lastModuleUpdateTs ){
                                                  OutProgress "Update-Help to en-US with continue-on-error ";
                                                  [String] $out = Update-Help -UICulture en-US -ErrorAction Continue *>&1 | ForEach-Object{ "$_"; };
                                                  if( (HasKnowErrMsg $out) ){ $out = "Got known response 404=NotFound for en-US of: ConfigDefenderPerformance, Dism, Get-NetView, Kds, NetQos, Pester, PKI, Whea, WindowsUpdate. "; }
                                                  Write-Progress -Activity " " -Status " " -Completed;
                                                  OutProgress "  $out";
                                                  OutProgress "Update-Help to current Culture with continue-on-error: $((Get-Culture).Name) = $((Get-Culture).DisplayName)"; # Example: "de-CH"
                                                  [String] $out = Update-Help -ErrorAction Continue *>&1 | ForEach-Object{ "$_"; };
                                                    # Usually we get the same errors as with en-US
                                                  if( (HasKnowErrMsg $out) ){ $out = "Got known response 404=NotFound for en-US of: ConfigDefenderPerformance, Dism, Get-NetView, Kds, NetQos, Pester, PKI, Whea, WindowsUpdate. "; }
                                                  Write-Progress -Activity " " -Status " " -Completed;
                                                  OutProgress "  $out";
                                                  FileTouch $touchFile;
                                                }
                                                # Some Infos:
                                                # - Install-Module -Force -Name myModule; # 2021-12: Paralled installed V1.0.0.1 and V2.2.5
                                                #   we got: WARNING: The version '1.4.7' of module 'myModule' is currently in use. Retry the operation after closing the applications.
                                                # - https://github.com/PowerShell/PSReadLine
                                                # - Install-Module -Force -Name PsReadline; # 2021-12: Paralled installed V1.0.0.1 and V2.2.5
                                                #   Install-Module -Force -SkipPublisherCheck -Name Pester;
                                                #   Note: Ein zuvor installiertes, von Microsoft signiertes Modul Pester V3.4.0 verursacht Konflikte
                                                #     mit dem neuen Modul Pester V5.3.1 vom Herausgeber CN=DigiCert Assured ID Root CA, OU=www.digicert.com, O=DigiCert Inc, C=US.
                                                #     Durch die Installation des neuen Moduls kann das System instabil werden. 
                                                #     Falls Sie trotzdem eine Installation oder ein Update durchführen möchten, verwenden Sie den -SkipPublisherCheck-Parameter.
                                                #     And Update-Module : Das Modul 'Pester' wurde nicht mithilfe von 'Install-Module' installiert und kann folglich nicht aktualisiert werden.
                                                # - Example: Uninstall-Module -MaximumVersion "0.9.99" -Name SqlServer;
                                                }
function ToolWinGetCleanLine                  ( [String] $s ){
                                                if( $null -eq $s ){ $s = ""; }
                                                $s = "$s".Trim();
                                                if( $s -ne "" -and -not @("-","/","|","\").Contains($s)                                                                    -and
                                                    $s -notmatch "^\█*\▒*\¦*\ +[0-9\.]+\ [KMG]B\ \/\ +[0-9\.]+\ [KMG]B$"                                                      -and # ██████████████████████▒▒▒▒▒▒▒▒  1024 KB / 1.31 MB
                                                    $s -notmatch "^\█*\▒*\¦*\ +[0-9][0-9]?[0-9]?\%$"                                                                          -and # ███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  10%
                                                    $s -ne "Alle Quellen werden aktualisiert..."                                                                           -and # for: winget source update
                                                    $s -ne "Fertig"                                                                                                        -and # for: winget source update
                                                    $s -ne "Alle Quellen werden zurückgesetzt...Fertig"                                                                    -and # for: winget source reset
                                                    $s -ne "Die Quelle `"msstore`" erfordert, dass Sie die folgenden Vereinbarungen vor der Verwendung anzeigen."          -and # for: winget list
                                                    $s -ne "Terms of Transaction: https://aka.ms/microsoft-store-terms-of-transaction"                                     -and # for: winget list
                                                    $s -ne ("Die Quelle erfordert, dass die geografische Region des aktuellen Computers aus 2 Buchstaben " +
                                                            "an den Back-End-Dienst gesendet wird, damit er ordnungsgemäß funktioniert (z. B. `„US`“).")                   -and # for: winget list
                                                    $s -ne "Paket-Deinstallation wird gestartet..."                                                                        -and # for: winget uninstall
                                                    $s -ne "Es wurde bereits ein vorhandenes Paket gefunden. Es wird versucht, das installierte Paket zu aktualisieren..." -and # for: winget install
                                                    $s -ne "In den konfigurierten Quellen sind keine neueren Paketversionen verfügbar."                                    -and # for: winget install
                                                    $s -ne "Diese Anwendung wird von ihrem Besitzer an Sie lizenziert."                                                    -and # for: winget install
                                                    $s -ne "Der Installer-Hash wurde erfolgreich überprüft"                                                                -and # for: winget install
                                                    $s -ne "Paketinstallation wird gestartet..."                                                                           -and # for: winget install
                                                    $s -ne "Microsoft ist nicht verantwortlich und erteilt keine Lizenzen für Pakete von Drittanbietern."                       # for: winget install
                                                    ){}else{ $s = ""; }
                                                $s = $s.Replace("Kein verfügbares Upgrade gefunden.","Is up to date.");                                                                   # for: winget install
                                                $s = $s.Replace("Erfolgreich installiert","Successful installed.");                                                                       # for: winget install
                                                $s = $s.Replace("Es wurde kein installiertes Paket gefunden, das den Eingabekriterien entspricht.","Already uninstalled, nothing done."); # for: winget uninstall
                                                $s = $s.Replace("Erfolgreich deinstalliert","Successful uninstalled.");                                                                   # for: winget uninstall
                                                # 2025-01: Example of rest of output of updateAll:
                                                #   (2/2) Gefunden ...packagename... [...packageid...] Version ...version...
                                                # 2025-01: Example of rest of output of install:
                                                #   Gefunden ...packagename... Version ...version...
                                                #   Download läuft https://...urlToExecutable...
                                                #   Successful installed.
                                                # 2025-02: Example of rest of output of install which fails:
                                                #   Sie haben die Installation abgebrochen.
                                                #   Installation fehlgeschlagen mit Exitcode: 1602
                                                #   Das Installationsprotokoll ist verfügbar unter: C:\Users\myuser\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir\WinGet-Microsoft.PowerShell.7.5.0.0-2025-02-09-12-02-09.818.log
                                                # 2025-02: Example of rest of output of install which fails ("Blizzard.BattleNet"):
                                                #   Für dieses Paket ist ein Installationsspeicherort erforderlich
                                                #   Der Installationsspeicherort ist für das Paket erforderlich, wurde jedoch nicht angegeben.
                                                # Example of rest of output of uninstall:
                                                #   Uninstall-Package(source=winget): "...packagename..."
                                                #   Already uninstalled, nothing done.
                                                return [String] $s;
                                                }
function ToolWinGetSetup                      (){ # install and update winget; update sources; if elevated it works for all users otherwise for current user; requires minimum: Windows 10 1709 (build 16299) 
                                                function WingetVersion(){
                                                  [String] $wingetVersionString = & WinGet --version; AssertRcIsOk; # 2025-02: v1.9.25200; 2024-11: V1.9.25180; 2024-09: V1.8.1911; 2024-07: v1.2.10691;
                                                  return [System.Version] ($wingetVersionString -replace "^v","");
                                                }
                                                function WingetIsVeryOld (){ return [Boolean] (WingetVersion) -lt ([System.Version]"1.6"); }
                                                function WinGetApproveEulas(){
                                                  OutProgress "Make sure eulas are approved by: Winget search; ";
                                                  Write-Output "y" | & WinGet search | Out-Null; # default source is "msstore"; alternative option: --accept-source-agreements
                                                  ScriptResetRc; # Example: OperationStopped: Last operation failed [ExitCode=-1978335230]. For the reason see the previous output.
                                                    # Skip: Fehler beim Versuch, die Quelle zu aktualisieren: winget \n Die Quelle "msstore" erfordert, dass Sie die folgenden Verträge
                                                    #       vor der Verwendung anzeigen. \n Terms of Transaction: https://aka.ms/microsoft-store-terms-of-transaction \n
                                                    #       Die Quelle erfordert, dass die geografische Region des aktuellen Computers aus 2 Buchstaben an den Back-End-Dienst gesendet wird,
                                                    #       damit er ordnungsgemäß funktioniert (z. B. „US“). \n Stimmen Sie allen Nutzungsbedingungen der Quelle zu? \n [Y] Ja  [N] Nein:
                                                }
                                                function WinGetSourcesListAndReset(){
                                                  OutProgress "List WinGet Sources: ";
                                                  [String[]] $a = & winget source list | ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" }; AssertRcIsOk $a;
                                                    #   Name    Argument                                      Anstößig
                                                    #   --------------------------------------------------------------
                                                    #   msstore https://storeedgefd.dsx.mp.microsoft.com/v9.0 false
                                                    #   winget  https://cdn.winget.microsoft.com/cache        false
                                                  if( $a.Count -eq 4 -and $a[0].StartsWith("Name ") -and $a[1].StartsWith("-----") ){ $a = $a[2..($a.Length-1)] | Sort-Object; }
                                                  $a | ForEach-Object{ OutProgress "  $_"; }; # msstore, winget.
                                                  if( (ProcessIsRunningInElevatedAdminMode) -and $a[0].StartsWith("msstore ") -and $a[1].StartsWith("winget ") ){
                                                    OutProgress "WinGet has the two default source (msstore,winget) so we can safely call reset source:  winget source reset --force; ";
                                                    & WinGet source reset --force | ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" } | ForEach-Object{ OutProgress $_ 2; };
                                                    AssertRcIsOk; # requires admin mode
                                                  }else{
                                                    OutProgress "Note: For reset back to msstore,winget use in admin mode: winget source reset --force; ";
                                                  }
                                                }
                                                function WinGetSourcesUpdate(){
                                                  OutProgress "Update WinGet sources ";
                                                  [String[]] $out = & WinGet source update | ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" }; AssertRcIsOk $out;
                                                  $out | ForEach-Object{ OutProgress $_ 2; };
                                                }
                                                OutProgressTitle "Setup WinGet by install and update it to latest version (method depends on wether process is in elevated mode or not) ";
                                                OsWindowsAppxImportModule;
                                                # on win11 usually user must be logged in once to enable winget, otherwise we must install it now
                                                if( (ProcessFindExecutableInPath "winget") -eq "" -or (WingetIsVeryOld) ){
                                                  [String] $pckName = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe";
                                                  [String] $msixName = "$pckName.msixbundle";
                                                  [String] $urlMsix = "https://github.com/microsoft/winget-cli/releases/latest/download/$msixName"; # 225 MB; alternative: "https://aka.ms/getwinget"
                                                  if( (WingetIsVeryOld) ){
                                                    Add-AppxPackage -Path $urlMsix; #  -ForceApplicationShutdown;
                                                      AssertRcIsOk; Write-Progress -Activity " " -Status " " -Completed;
                                                    # alternative: Invoke-WebRequest -Uri $urlMsix -OutFile $msixName; Add-AppxPackage $msixName;
                                                  }elseif( (ProcessIsRunningInElevatedAdminMode) ){
                                                    OutProgress "Currently in elevated-mode , so we cannot use WinGet itself and so we use Add-AppxPackage. ";
                                                    # Note: Add-AppxPackage sometimes requires: -ForceApplicationShutdown
                                                    # more see: https://github.com/microsoft/winget-cli/releases
                                                    [String] $jsonUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest";
                                                    OutProgress "Download and extract latest msi installer from: $jsonUrl ";
                                                    [Object] $apiObj = NetDownloadToString $jsonUrl | ConvertFrom-Json;
                                                    [String] $msiUrl = ($apiObj.assets | Where-Object{ $_.Name -eq $pckName -and $_.content_type -eq "application/octet-stream" }).browser_download_url;
                                                      # Example: "https://github.com/microsoft/winget-cli/releases/download/v1.9.25200/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                                                    OutProgress "Add-AppxPackage -Path $msiUrl; ";
                                                    Add-AppxPackage -Path $msiUrl;
                                                      AssertRcIsOk; Write-Progress -Activity " " -Status " " -Completed;
                                                    if( $false ){ # we currently not perform actions for new users
                                                      OutProgress "Add appx package that will install for each new user to the os. ";
                                                      [String] $tmpMsix = (FileGetTempFile); # alternative name: DesktopAppInstaller.msixbundle
                                                      Invoke-webrequest $urlMsix -OutFile $tmpMsix;
                                                      Add-ProvisionedAppPackage -online -skiplicense -PackagePath $tmpMsix;
                                                        AssertRcIsOk; Write-Progress -Activity " " -Status " " -Completed;
                                                      Remove-Item $tmpMsix;
                                                    }
                                                  }else{
                                                    OutProgress "Currently not in elevated-mode, so we use Add-AppxPackage for install it for current user. ";
                                                    OutProgress "Add-AppxPackage -RegisterByFamilyName -MainPackage $pckName; ";
                                                    # Register Winget (On Win11 automatically done after first user logon) for current user
                                                    Add-AppxPackage -RegisterByFamilyName -MainPackage $pckName;
                                                      # alternative option: -ForceApplicationShutdown
                                                      AssertRcIsOk; Write-Progress -Activity " " -Status " " -Completed;
                                                  }
                                                  # Alternative to install winget without microsoft store which is also required on windows sandboxes
                                                  #   Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | Out-Null;
                                                  #   [String] $instScope = "CurrentUser; $scope = "AllUsers; # choose scope
                                                  #   Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope $instScope -ErrorAction SilentlyContinue | Out-Null; # Installing WinGet PowerShell module from PSGallery
                                                  #   Repair-WinGetPackageManager -ErrorAction SilentlyContinue; # bootstrap WinGet;
                                                }
                                                OutProgress "WinGet current version: V$(WingetVersion) "; 
                                                WinGetApproveEulas;
                                                WinGetSourcesListAndReset;
                                                WinGetSourcesUpdate;
                                                ToolWingetInstallPackage "Microsoft.AppInstaller" -scope:User; # only works for scope User.
                                                # winget --help
                                                #   Folgende Befehle sind verfügbar:
                                                #     install    Installiert das angegebene Paket
                                                #     show       Zeigt Informationen zu einem Paket an
                                                #     source     Verwalten von Paketquellen
                                                #     search     Suchen und Anzeigen grundlegender Informationen zu Paketen
                                                #     list       Installierte Pakete anzeigen
                                                #     upgrade    Zeigt verfügbare Upgrades an und führt sie aus.
                                                #     uninstall  Deinstalliert das angegebene Paket
                                                #     hash       Hilfsprogramm zum Hashen von Installationsdateien
                                                #     validate   Überprüft eine Manifestdatei
                                                #     settings   Einstellungen öffnen oder Administratoreinstellungen festlegen
                                                #     features   Zeigt den Status von experimentellen Features an
                                                #     export     Exportiert eine Liste der installierten Pakete
                                                #     import     Installiert alle Pakete in einer Datei
                                                #     pin        Paketpins verwalten
                                                #     configure  Konfiguriert das System in einem gewünschten Zustand
                                                #     download   Lädt das Installationsprogramm aus einem bestimmten Paket herunter.
                                                #     repair     Repariert das ausgewählte Paket
                                                #   Die folgenden Optionen stehen zur Verfügung:
                                                #     -v,--version                Version des Tools anzeigen
                                                #     --info                      Allgemeine Informationen zum Tool anzeigen
                                                #     -?,--help                   Zeigt Hilfe zum ausgewählten Befehl an
                                                #     --wait                      Fordert den Benutzer auf, vor dem Beenden eine beliebige Taste zu drücken
                                                #     --logs,--open-logs          Öffnen des Standardspeicherorts für Protokolle
                                                #     --verbose,--verbose-logs    Aktiviert die ausführliche Protokollierung für WinGet
                                                #     --nowarn,--ignore-warnings  Unterdrückt Warnungsausgaben.
                                                #     --disable-interactivity     Interaktive Eingabeaufforderungen deaktivieren
                                                #     --proxy                     Legen Sie einen Proxy fest, der für diese Ausführung verwendet werden soll.
                                                #     --no-proxy                  Verwendung des Proxys für diese Ausführung deaktivieren
                                                #   Weitere Hilfe finden Sie unter: „https://aka.ms/winget-command-help“
                                              }
function ToolWingetListInstalledPackages      (){
                                                # call the tool "winget" to list installed packages
                                                OutProgress "List of installed packages of scope [User,$(switch(ProcessIsRunningInElevatedAdminMode){($true){''}($false){'but not '}})Machine]: ";
                                                [String[]] $out1 = & WinGet list --disable-interactivity --accept-source-agreements --scope User *>&1 |
                                                  ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" }; AssertRcIsOk $out1;
                                                [String[]] $out2 = @();
                                                if( (ProcessIsRunningInElevatedAdminMode) ){
                                                  [String[]] $out2 = & WinGet list --disable-interactivity --accept-source-agreements --scope Machine *>&1 |
                                                  ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" }; AssertRcIsOk $out2;
                                                }
                                                [Int32] $len = StringArrayGetMaxItemLength ($out1+$out2);
                                                $out1 = $out1 | Where-Object{ $_ -ne "" } | ForEach-Object{ "$($_.PadRight($len)) User    "; };
                                                $out2 = $out2 | Where-Object{ $_ -ne "" } | ForEach-Object{ "$($_.PadRight($len)) Machine "; };
                                                $out1 | Where-Object{ $_ -ne "" } | Select-Object -First 1 | ForEach-Object{ OutProgress $_ 2; };
                                                $out2 | Where-Object{ $_ -ne "" } | Select-Object -First 1 | ForEach-Object{ OutProgress $_ 2; };
                                                OutProgress "$('-'*$len)-------- " 2;
                                                (($out1 | Select-Object -Skip 2) + ($out2 | Select-Object -Skip 2)) | Sort-Object | Where-Object{ $_ -ne "" } | ForEach-Object{ OutProgress $_ 2; };
                                                # Example: Es wurde kein anwendbares Upgrade gefunden.
                                                # Example: In einer konfigurierten Quelle ist eine neuere Paketversion verfügbar, die jedoch nicht auf Ihr System oder Ihre Anforderungen zutrifft.
                                                # Example: Es wurde eine neuere Version gefunden, die Installationstechnologie unterscheidet sich jedoch von der aktuellen installierten Version. Deinstallieren Sie das Paket, und installieren Sie die neuere Version.
                                              }
function ToolWingetListUpgradablePackages     ( [String] $scope = "Auto" ){
                                                # Note: for evaluated scope=Machine it also performs scope=User.
                                                [String] $instScope = $scope; if( $scope -eq "Auto" ){ $instScope = switch(ProcessIsRunningInElevatedAdminMode){($true){"Machine"}($false){"User"}}; }
                                                OutProgress "List all upgradable packages of winget:  winget upgrade --scope $instScope --include-unknown --disable-interactivity --accept-source-agreements ";
                                                & WinGet upgrade --scope $instScope --include-unknown --disable-interactivity --accept-source-agreements | # can ask multiple for elevated mode; alternative: --skip-dependencies
                                                  ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" } | ForEach-Object{ OutProgress $_ 2; };
                                                ScriptResetRc;
                                                if( $instScope -eq "Machine" ){
                                                  ToolWingetListUpgradablePackages "User";
                                                }
                                              }
function ToolWingetUpdateInstalledPackages    ( [String] $scope = "Auto" ){
                                                # Note: for evaluated scope=Machine it also performs scope=User.
                                                # Ignores errors. If not elevated then it will ask multiple for it.
                                                # Scope is one of: "User","Machine","Auto"(depends on elevated admin mode).
                                                [String] $instScope = $scope; if( $scope -eq "Auto" ){ $instScope = switch(ProcessIsRunningInElevatedAdminMode){($true){"Machine"}($false){"User"}}; }
                                                OutProgress "Upgrade all packages of winget:  winget upgrade --scope $instScope --include-unknown --disable-interactivity --accept-source-agreements --all ";
                                                & WinGet upgrade --scope $instScope --include-unknown --disable-interactivity --accept-source-agreements --all | # can ask multiple for elevated mode; alternative: --skip-dependencies
                                                  ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" } | ForEach-Object{ OutProgress $_ 2; };
                                                  # Example: Die Anwendung wird zurzeit ausgeführt. Beenden Sie die Anwendung, und versuchen Sie es noch mal.
                                                  #          Installation fehlgeschlagen mit Exitcode: 5
                                                  #          Mindestens 5 Paket verfügt über Versionsnummern, die nicht ermittelt werden können. Verwenden Sie „--include-unknown“, um alle Ergebnisse anzuzeigen.
                                                  #          1 Pakete sind angeheftet und müssen explizit aktualisiert werden.
                                                ScriptResetRc; # Example: OperationStopped: Last operation failed [ExitCode=-1978335188]. For the reason see the previous output.
                                                if( $instScope -eq "Machine" ){
                                                  ToolWingetUpdateInstalledPackages "User";
                                                }
                                              }
function ToolWingetInstallPackage             ( [String] $idAndOptionalBlankSepVersion, [String] $source = "winget", [Boolean] $canRetry = $false, [String] $scope = "Auto" ){
                                                # Call the tool "winget" to intall from a given source. Ignores errors.
                                                # Id can be specifed by optional blanks separated version.
                                                # Scope is one of: "User","Machine","Auto"(depends on elevated admin mode).
                                                # If canRetry and install-result is not up-to-date then it tries an uninstall and again an install.
                                                [String] $instScope = $scope; if( $scope -eq "Auto" ){ $instScope = switch(ProcessIsRunningInElevatedAdminMode){($true){"Machine"}($false){"User"}}; }
                                                [String[]] $a = ($idAndOptionalBlankSepVersion -split "\s+");
                                                [String] $id = $a[0];
                                                [String] $pckVersion = switch($a.Count -le 1){($true){""}($false){$a[1]}};
                                                if( $a.Count -gt 2 ){ throw [Exception] "ToolWingetInstallPackage(id=`"$id`") unknown third blanks separated part: `"$a[2]`""; }
                                                OutProgress "Install-or-Update-Package(source=$source,scope=$instScope$(switch($canRetry){($true){',canRetry'}($false){''}})): `"$id`" $pckVersion ";
                                                # We recommend to use source=winget because otherwise we can get for example for:  winget install --verbose --disable-interactivity "Google.Chrome";
                                                #   Die Quelle "msstore" erfordert, dass Sie die folgenden Vereinbarungen vor der Verwendung anzeigen.
                                                #   Terms of Transaction: https://aka.ms/microsoft-store-terms-of-transaction
                                                #   Die Quelle erfordert, dass die geografische Region des aktuellen Computers aus 2 Buchstaben an den Back-End-Dienst gesendet wird, damit er ordnungsgemäß funktioniert (z. B. „US“).
                                                #   Mindestens einer der Quellvereinbarungen wurde nicht zugestimmt. Vorgang abgebrochen. Akzeptieren Sie bitte die Quellvereinbarungen, oder entfernen Sie die entsprechenden Quellen.
                                                [String[]] $out = & WinGet install --verbose --disable-interactivity --accept-source-agreements --scope $instScope --source $source --id $id --version $pckVersion *>&1 | # alternatives: --all-versions
                                                  ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" };
                                                [Int32] $rc = ScriptGetAndClearLastRc; # Example: OperationStopped: Last operation failed [ExitCode=-1978335189]. For the reason see the previous output. Is up to date.
                                                $out | ForEach-Object{ OutProgress $_ 2; };
                                                if( $rc -ne -1978335189 -and $rc -ne 0 ){ # Is up to date.
                                                  OutProgress "rc=$rc; Program is not up-to-date. Retry=$canRetry; " 2;
                                                  if( $canRetry ){
                                                    ToolWingetUninstallPackage $idAndOptionalBlankSepVersion $source $scope;
                                                    ToolWingetInstallPackage   $idAndOptionalBlankSepVersion $source $false $scope;
                                                  }
                                                }
                                                # 2025-02: winget install $id;
                                                #            Es wurde bereits ein vorhandenes Paket gefunden. Es wird versucht, das installierte Paket zu aktualisieren...
                                                #            Es wurde kein anwendbares Upgrade gefunden.
                                                #            In einer konfigurierten Quelle ist eine neuere Paketversion verfügbar, die jedoch nicht auf Ihr System oder Ihre Anforderungen zutrifft.
                                                #          Solution which worked: winget uninstall $id; winget install $id;
                                                # 2025-02: winget install $id;
                                                #            Es wurde kein anwendbares Upgrade gefunden.
                                                #            In einer konfigurierten Quelle ist eine neuere Paketversion verfügbar,
                                                #            die jedoch nicht auf Ihr System oder Ihre Anforderungen zutrifft.
                                                #          Solution which worked: winget uninstall $id; winget install $id;
                                                # 2025-02: winget install "Discord.Discord"
                                                #            rc=-1978334956; Das Paket kann nicht mit winget aktualisiert werden. Verwenden Sie die vom Herausgeber bereitgestellte Methode zum Aktualisieren dieses Pakets.
                                                # 2025-02: ToolWingetInstallPackage "Microsoft.Powershell"
                                                #            Es wurde eine neuere Version gefunden, die Installationstechnologie unterscheidet sich jedoch von der aktuellen installierten Version. Deinstallieren Sie das Paket, und installieren Sie die neuere Version.
                                                # 2025-02: ToolWingetInstallPackage "Blizzard.BattleNet"
                                                #            rc=-1978335137; Program is not up-to-date. Retry=False;
                                              }
function ToolWingetUninstallPackage           ( [String] $idAndOptionalBlankSepVersion, [String] $source = "winget", [String] $scope = "Auto" ){
                                                # Call the tool "winget" to uninstall from a given source. Ignores errors.
                                                # Id can be specifed by optional blanks separated version.
                                                # Scope is one of: "User","Machine","Auto"(depends on elevated admin mode).
                                                [String] $instScope = $scope; if( $scope -eq "Auto" ){ $instScope = switch(ProcessIsRunningInElevatedAdminMode){($true){"Machine"}($false){"User"}}; }
                                                [String[]] $a = ($idAndOptionalBlankSepVersion -split "\s+");
                                                [String] $id = $a[0];
                                                [String] $pckVersion = switch($a.Count -le 1){($true){""}($false){$a[1]}};
                                                if( $a.Count -gt 2 ){ throw [Exception] "ToolWingetInstallPackage(id=`"$id`") unknown third blanks separated part: `"$a[2]`""; }
                                                OutProgress "UnInstall-Package(source=$source,scope=$instScope): `"$id`" $pckVersion ";
                                                [String[]] $out = & WinGet uninstall --verbose --disable-interactivity --accept-source-agreements --scope $instScope --source $source --id $id --version $pckVersion *>&1 |
                                                  ForEach-Object{ ToolWinGetCleanLine $_; } | Where-Object{ $_ -ne "" };
                                                ScriptResetRc; # Example: OperationStopped: Last operation failed [ExitCode=-1978335212]. For the reason see the previous output. Already uninstalled, nothing done.
                                                $out | ForEach-Object{ OutProgress $_ 2; };
                                              }
function ToolManuallyDownloadAndInstallProg   ( [String] $programName, [String] $programDownloadUrl, [String] $mainTargetFileMinIsoDate = "0001-01-01",
                                                  [String[]] $programExecutableOrDir = "", [String] $programConfigurations = "" ){
                                                # programExecutableOrDir: one or alternative targets can be specified.
                                                # Example: ToolManuallyDownloadAndInstallProg "Powershell-V7"     "https://learn.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-windows" "0001-01-01" "pwsh.exe" "";
                                                # Example: ToolManuallyDownloadAndInstallProg "TortoiseGit 64bit" "https://tortoisegit.org/download/" "0001-01-01" "C:/Program Files/TortoiseGit/bin/TortoiseGit.dll" "";
                                                for( [Int32] $i = 0; $i -lt $programExecutableOrDir.Count; $i++ ){ $programExecutableOrDir[$i] = FsEntryUnifyDirSep $programExecutableOrDir[$i]; }
                                                OutProgressTitle ("Check "+ "`"$programName`"".PadRight(40));
                                                OutProgress "Expecting newer existance than minimum $mainTargetFileMinIsoDate of one of the target executables or dirs ";
                                                OutProgress ("[" + (($programExecutableOrDir|ForEach-Object{"`"$_`""}) -join ",") + "] ");
                                                [Boolean] $noExecSoReturnAfterOneRun = $programExecutableOrDir[0] -eq "" -and $programExecutableOrDir.Count -le 1;
                                                [String] $tar = $programExecutableOrDir[0];
                                                [Boolean] $isDir = (FsEntryHasTrailingDirSep $tar);
                                                [DateTime] $mainTargetFileMinDate = DateTimeFromStringIso $mainTargetFileMinIsoDate;
                                                function TargetReached(){
                                                  return [String] ($programExecutableOrDir | Where-Object{ "" -ne "$_" } |
                                                    Where-Object{
                                                      if( $isDir ){ return (DirExists $_); }
                                                      [String] $exe = ProcessFindExecutableInPath $_;
                                                      if( $exe -eq "" ){ return $false; }
                                                      return $mainTargetFileMinDate -eq [DateTime]::MinValue -or (FsEntryGetLastModified $exe) -ge $mainTargetFileMinDate; } |
                                                    Select-Object -First 1);
                                                }
                                                while($true){
                                                  [String] $tar = TargetReached;
                                                  if( -not $noExecSoReturnAfterOneRun -and $tar -ne "" ){ OutProgress "Found installed: `"$tar`""; return; }
                                                  OutProgress "No target found so please download and install `"$programName`" ";
                                                  OutProgress "Follow the configurations: `"$programConfigurations`" ";
                                                  ProcessOpenAssocFile $programDownloadUrl;
                                                  StdInReadLine "Press Enter to continue.";
                                                  ProcessRefreshEnvVars;
                                                  if( $noExecSoReturnAfterOneRun ){ return; }
                                                } }
function MnCommonPsToolLibSelfUpdate          (){
                                                # If installed in standard mode (saved under c:/Program Files/WindowsPowerShell/Modules/)
                                                # then it performs a self update to the newest version from github otherwise output a note.
                                                [String]  $additionalOkUpdMsg = "`n  Please restart all processes which currently loaded this module before using changed functions of this library.";
                                                [Boolean] $requireElevatedAdminMode = $true;
                                                [Boolean] $assertFilePreviouslyExists = $true;
                                                [Boolean] $performPing = $true;
                                                [Boolean] $doWaitIfFailed = $false;
                                                [String]  $moduleName = "MnCommonPsToolLib";
                                                [String]  $tarRootDir = FsEntryGetAbsolutePath "$Env:ProgramW6432/WindowsPowerShell/Modules/"; # more see: https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx
                                                [String]  $moduleFile = FsEntryGetAbsolutePath "$tarRootDir/$moduleName/${moduleName}.psm1";
                                                [String]  $scrRootModDir = FsEntryGetAbsolutePath "$PSScriptRoot/../";
                                                if( (FileNotExists $moduleFile) ){
                                                  OutProgress "MnCommonPsToolLibSelfUpdate: Nothing done because is not installed in standard mode under `"$tarRootDir`". ";
                                                  if( (OsPsModulePathContains $scrRootModDir) ){
                                                    OutProgress "  It is Installed-for-Developers by having in PsModulePath the current script root: `"$scrRootModDir`"";
                                                  }else{ ProcessSleepSec 5; }
                                                  return;
                                                }
                                                #
                                                [String]  $modFile = "$tarRootDir/$moduleName/${moduleName}.psm1";
                                                [String]  $url     = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/$moduleName/${moduleName}.psm1";
                                                ToolPerformFileUpdateAndIsActualized $modFile $url $requireElevatedAdminMode $doWaitIfFailed $additionalOkUpdMsg $assertFilePreviouslyExists $performPing | Out-Null;
                                                #
                                                [String]  $modFile = "$tarRootDir/$moduleName/${moduleName}_Windows.ps1";
                                                [String]  $url     = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/$moduleName/${moduleName}_Windows.ps1";
                                                ToolPerformFileUpdateAndIsActualized $modFile $url $requireElevatedAdminMode $doWaitIfFailed $additionalOkUpdMsg $assertFilePreviouslyExists $performPing | Out-Null;
                                                #
                                                [String]  $modFile = "$tarRootDir/$moduleName/${moduleName}.psd1";
                                                [String]  $url     = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/$moduleName/${moduleName}.psd1";
                                                ToolPerformFileUpdateAndIsActualized $modFile $url $requireElevatedAdminMode $doWaitIfFailed $additionalOkUpdMsg $assertFilePreviouslyExists $performPing | Out-Null;
                                                OutProgress "Current-MnCommonPsToolLibVersion: V$((Get-Module -Name MnCommonPsToolLib -ListAvailable).Version)";
                                                Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1" -Force; 
                                                }

function ToolVs2019UserFolderGetLatestUsed    (){ OutWarning "ToolVs2019UserFolderGetLatestUsed is DEPRECATED, replace it now by: ToolVsUserFolderGetLatestUsed "; return (ToolVsUserFolderGetLatestUsed); }
function SvnExe                               (){ OutWarning "SvnExe is DEPRECATED, replace it now by (expect it in path): `"svn`" "; return "svn"; }
