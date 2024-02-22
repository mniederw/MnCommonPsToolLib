# Extension of MnCommonPsToolLib.psm1 - Common powershell tool library - Parts for windows only

# Import some modules (because it is more performant to do it once than doing this in each function using methods of this module).
# Note: for example on "Windows Server 2008 R2" we currently are missing these modules
#   but we ignore the errors because it its enough if the functions which uses these modules will fail.
#   Example error: The specified module 'ScheduledTasks'/'SmbShare' was not loaded because no valid module file was found in any module directory.
if( $null -ne (Import-Module -NoClobber -Name "ScheduledTasks" -ErrorAction Continue *>&1) ){ $error.clear(); Write-Warning "Ignored failing of Import-Module ScheduledTasks because it will fail later if a function is used from it."; } #
if( $null -ne (Import-Module -NoClobber -Name "SmbShare"       -ErrorAction Continue *>&1) ){ $error.clear(); Write-Warning "Ignored failing of Import-Module SmbShare       because it will fail later if a function is used from it."; } # Example: Get-SMBShare, Get-SMBOpenFile, New-SMBShare, Get-SMBMapping, ...
if( $null -ne (Import-Module -NoClobber -Name "CimCmdlets"     -ErrorAction Continue *>&1) ){ $error.clear(); Write-Warning "Ignored failing of Import-Module CimCmdlets     because it will fail later if a function is used from it."; } # Example: Get-CimInstance.



# Import-Module "SmbWitness"; # for later usage
# Import-Module "ServerManager"; # Is not always available, requires windows-server-os or at least Win10Prof with installed RSAT. Because seldom used we do not try to load it here.

function ProcessGetNrOfCores                  (){ return [Int32] (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors; }
function ProcessOpenAssocFile                 ( [String] $fileOrUrl ){ & "rundll32" "url.dll,FileProtocolHandler" $fileOrUrl; AssertRcIsOk; }
function JobStart                             ( [ScriptBlock] $scr, [Object[]] $scrArgs = $null, [String] $name = "Job" ){ # Return job object of type PSRemotingJob, the returned object of the script block can later be requested.
                                                return [System.Management.Automation.Job] (Start-Job -name $name -ScriptBlock $scr -ArgumentList $scrArgs); }
function JobGet                               ( [String] $id ){ return [System.Management.Automation.Job] (Get-Job -Id $id); } # Return job object.
function JobGetState                          ( [String] $id ){ return [String] (JobGet $id).State; } # NotStarted, Running, Completed, Stopped, Failed, and Blocked.
function JobWaitForNotRunning                 ( [Int32] $id, [Int32] $timeoutInSec = -1 ){ [Object] $dummyJob = Wait-Job -Id $id -Timeout $timeoutInSec; }
function JobWaitForState                      ( [Int32] $id, [String] $state, [Int32] $timeoutInSec = -1 ){ [Object] $dummyJob = Wait-Job -Id $id -State $state -Force -Timeout $timeoutInSec; }
function JobWaitForEnd                        ( [Int32] $id ){ JobWaitForNotRunning $id; return [Object] (Receive-Job -Id $id); } # Return result object of script block, job is afterwards deleted.
function OsIsWinVistaOrHigher                 (){ return [Boolean] ([Environment]::OSVersion.Version -ge (new-object "Version" 6,0)); }
function OsIsWin7OrHigher                     (){ return [Boolean] ([Environment]::OSVersion.Version -ge (new-object "Version" 6,1)); }
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
function PrivGetUserFromName                  ( [String] $username ){ # optionally as domain\username
                                                return [System.Security.Principal.NTAccount] $username; }
function PrivGetUserCurrent                   (){ return [System.Security.Principal.IdentityReference] ([System.Security.Principal.WindowsIdentity]::GetCurrent().User); } # alternative: PrivGetUserFromName "$env:userdomain\$env:username"
function PrivGetUserSystem                    (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18"                                                      )).Translate([System.Security.Principal.NTAccount]); } # NT AUTHORITY\SYSTEM = NT-AUTORITÄT\SYSTEM
function PrivGetGroupAdministrators           (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544"                                                  )).Translate([System.Security.Principal.NTAccount]); } # BUILTIN\Administrators = VORDEFINIERT\Administratoren  (more https://msdn.microsoft.com/en-us/library/windows/desktop/aa379649(v=vs.85).aspx)
function PrivGetGroupAuthenticatedUsers       (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-11"                                                      )).Translate([System.Security.Principal.NTAccount]); } # NT AUTHORITY\Authenticated Users = NT-AUTORITÄT\Authentifizierte Benutzer
function PrivGetGroupEveryone                 (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0"                                                       )).Translate([System.Security.Principal.NTAccount]); } # Jeder
function PrivGetUserTrustedInstaller          (){ return [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464")).Translate([System.Security.Principal.NTAccount]); } # NT SERVICE\TrustedInstaller
function PrivFsRuleAsString                   ( [System.Security.AccessControl.FileSystemAccessRule] $rule ){
                                                return [String] "($($rule.IdentityReference);$(($rule.FileSystemRights).Replace(' ',''));$($rule.InheritanceFlags.Replace(' ',''));$($rule.PropagationFlags.Replace(' ',''));$($rule.AccessControlType);IsInherited=$($rule.IsInherited))";
                                                } # for later: CentralAccessPolicyId, CentralAccessPolicyName, Sddl="O:BAG:SYD:PAI(A;OICI;FA;;;SY)(A;;FA;;;BA)"
function PrivAclAsString                      ( [System.Security.AccessControl.FileSystemSecurity] $acl ){
                                                [String] $s = "Owner=$($acl.Owner);Group=$($acl.Group);Acls=";
                                                foreach( $a in $acl.Access){ $s += PrivFsRuleAsString $a; } return [String] $s; }
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
function PrivDirSecurityCreateOwner           ( [System.Security.Principal.IdentityReference] $account ){
                                                [System.Security.AccessControl.DirectorySecurity] $result = New-Object System.Security.AccessControl.DirectorySecurity;
                                                $result.SetOwner($account);
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
                                                $dummyPriv = $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable); }
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
                                                [String] $s = "$($rule.IdentityReference.ToString()):"; # Example: VORDEFINIERT\Administratoren
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
function ServiceListRunnings                  (){
                                                return [String[]] (@()+(Get-Service -ErrorAction SilentlyContinue * |
                                                  # 2023-03: for: get-service McpManagementService on we got the following error without any specific error:
                                                  #   "Get-Service: Service 'McpManagementService (McpManagementService)' cannot be queried due to the following error:"
                                                  # In services.msc the description is "<Fehler beim Lesen der Beschreibung. Fehlercode: 15100 >".
                                                  # Since around 10 years thats the first error on this command, according googling it happens on Win10 and Win11,
                                                  # please Microsoft fix this asap.
                                                  # The workaround is to use (ErrorAction SilentlyContinue) what is a dirty solution.
                                                  Where-Object{ $_.Status -eq "Running" } |
                                                  Sort-Object Name |
                                                  Format-Table -auto -HideTableHeaders " ",Name,DisplayName |
                                                  StreamToStringDelEmptyLeadAndTrLines)); }
function ServiceListExistings                 (){ # We could also use Get-Service but members are lightly differnet;
                                                # 2017-06 we got (RuntimeException: You cannot call a method on a null-valued expression.) so we added null check.
                                                return [CimInstance[]](@()+(Get-CimInstance win32_service | Where-Object{$null -ne $_} | Sort-Object ProcessId,Name)); }
function ServiceListExistingsAsStringArray    (){
                                                return [String[]] (StringSplitIntoLines (@()+(ServiceListExistings | Where-Object{$null -ne $_} |
                                                  Format-Table -auto -HideTableHeaders ProcessId,Name,StartMode,State | StreamToStringDelEmptyLeadAndTrLines ))); }
function ServiceNotExists                     ( [String] $serviceName ){
                                                return [Boolean] -not (ServiceExists $serviceName); }
function ServiceExists                        ( [String] $serviceName ){
                                                return [Boolean] ($null -ne (Get-Service $serviceName -ErrorAction SilentlyContinue)); }
function ServiceAssertExists                  ( [String] $serviceName ){
                                                OutVerbose "Assert service exists: $serviceName";
                                                Assert (ServiceExists $serviceName) "service not exists: $serviceName"; }
function ServiceGet                           ( [String] $serviceName ){
                                                return [Object] (Get-Service -Name $serviceName -ErrorAction SilentlyContinue); } # Standard result is name,displayname,status.
function ServiceGetState                      ( [String] $serviceName ){
                                                [Object] $s = ServiceGet $serviceName;
                                                if( $null -eq $s ){ return [String] ""; }
                                                return [String] $s.Status; }
                                                # ServiceControllerStatus: "","ContinuePending","Paused","PausePending","Running","StartPending","Stopped","StopPending".
function ServiceStop                          ( [String] $serviceName, [Boolean] $ignoreIfFailed = $false ){
                                                [String] $s = ServiceGetState $serviceName;
                                                if( $s -eq "" -or $s -eq "stopped" ){ return; }
                                                OutProgress "ServiceStop $serviceName $(switch($ignoreIfFailed){($true){'ignoreIfFailed'}default{''}})";
                                                ProcessRestartInElevatedAdminMode;
                                                try{ Stop-Service -Name $serviceName; } # Instead of check for stopped service we could also use -PassThru.
                                                catch{
                                                  # Example: ServiceCommandException: Service 'Check Point Endpoint Security VPN (TracSrvWrapper)' cannot be stopped
                                                  #   due to the following error: Cannot stop TracSrvWrapper service on computer '.'.
                                                  if( $ignoreIfFailed ){ OutWarning "Warning: Stopping service failed, ignored: $($_.Exception.Message)"; }else{ throw; }
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
function TaskIsDisabled                       ( [String] $taskPathAndName ){
                                                [String] $taskPath = (FsEntryMakeTrailingDirSep (FsEntryRemoveTrailingDirSep (Split-Path -Parent $taskPathAndName)));
                                                [String] $taskName = Split-Path -Leaf $taskPathAndName;
                                                return [Boolean] ((Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName).State -eq "Disabled"); }
function TaskDisable                          ( [String] $taskPathAndName ){
                                                [String] $taskPath = (FsEntryMakeTrailingDirSep (FsEntryRemoveTrailingDirSep (Split-Path -Parent $taskPathAndName)));
                                                [String] $taskName = Split-Path -Leaf $taskPathAndName;
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
                                                  Select-Object DeviceID, FileSystem, Size, FreeSpace, VolumeName, DriveType, @{Name="DriveTypeName";Expression={(DriveMapTypeToString $_.DriveType)}}, ProviderName)); }
function NetAdapterListAll                    (){
                                                return [Object[]] (@()+(Get-CimInstance -Class win32_networkadapter |
                                                  Where-Object{$null -ne $_} |
                                                  Select-Object Name,NetConnectionID,MACAddress,Speed,@{Name="Status";Expression={(NetAdapterGetConnectionStatusName $_.NetConnectionStatus)}})); }
function NetGetIpConfig                       (){ [String[]] $out = @()+(& "IPCONFIG.EXE" "/ALL"          ); AssertRcIsOk $out; return [String[]] $out; }
function NetGetNetView                        (){ [String[]] $out = @()+(& "NET.EXE" "VIEW" $ComputerName ); AssertRcIsOk $out; return [String[]] $out; }
function NetGetNetStat                        (){ [String[]] $out = @()+(& "NETSTAT.EXE" "/A"             ); AssertRcIsOk $out; return [String[]] $out; }
function NetGetRoute                          (){ [String[]] $out = @()+(& "ROUTE.EXE" "PRINT"            ); AssertRcIsOk $out; return [String[]] $out; }
function NetGetNbtStat                        (){ [String[]] $out = @()+(& "NBTSTAT.EXE" "-N"             ); AssertRcIsOk $out; return [String[]] $out; }
function ShareGetTypeName                     ( [UInt32] $typeNr ){
                                                return [String] $(switch($typeNr){ 0{"DiskDrive"} 1 {"PrintQueue"} 2{"Device"} 3{"IPC"}
                                                2147483648{"DiskDriveAdmin"} 2147483649{"PrintQueueAdmin"} 2147483650{"DeviceAdmin"} 2147483651{"IPCAdmin"} default{"unknownNr=$typeNr"} }); }
function ShareGetTypeNr                       ( [String] $typeName ){
                                                return [UInt32] $(switch($typeName){ "DiskDrive"{0} "PrintQueue"{1} "Device"{2} "IPC"{3}
                                                "DiskDriveAdmin"{2147483648} "PrintQueueAdmin"{2147483649} "DeviceAdmin"{2147483650} "IPCAdmin"{2147483651} default{4294967295} }); }
function ShareExists                          ( [String] $shareName ){
                                                FsEntryRemoveTrailingDirSep $shareName;
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
function ShareLocksList                       ( [String] $path = "" ){
                                                # list currenty read or readwrite locked open files of a share, requires elevated admin mode
                                                $path = FsEntryGetAbsolutePath $path;
                                                ProcessRestartInElevatedAdminMode;
                                                return [Object] (Get-SmbOpenFile | Where-Object{$null -ne $_} | Where-Object{ $_.Path.StartsWith($path,"OrdinalIgnoreCase") } |
                                                  Select-Object FileId, SessionId, Path, ClientComputerName, ClientUserName, Locks | Sort-Object Path); }
function ShareLocksClose                      ( [String] $path = "" ){
                                                # closes locks, Example: $path="D:/Transfer/" or $path="D:/Transfer/MyFile.txt"
                                                $path = FsEntryGetAbsolutePath $path;
                                                ProcessRestartInElevatedAdminMode;
                                                ShareLocksList $path |
                                                  Where-Object{$null -ne $_} |
                                                  ForEach-Object{
                                                    OutProgress "ShareLocksClose `"$($_.Path)`"";
                                                    Close-SmbOpenFile -Force -FileId $_.FileId; }; }
function ShareCreate                          ( [String] $shareName, [String] $dir, [String] $descr = "", [Int32] $nrOfAccessUsers = 25, [Boolean] $ignoreIfAlreadyExists = $true ){
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
                                                [Object] $dummyObj = New-SmbShare -Path $dir -Name $shareName -Description $descr -ConcurrentUserLimit $nrOfAccessUsers -FolderEnumerationMode Unrestricted -FullAccess (PrivGetGroupEveryone); }
function ShareRemove                          ( [String] $shareName ){ # no action if it not exists
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
                                                    $dummyObj = New-SmbMapping -LocalPath $drive -RemotePath $mnt -Persistent $true -UserName $us;
                                                  }else{
                                                    $dummyObj = New-SmbMapping -LocalPath $drive -RemotePath $mnt -Persistent $true -UserName $us -Password $pw;
                                                  }
                                                  OutProgress "$($traceInfo)Ok.";
                                                }catch{
                                                  # Example: System.Exception: New-SmbMapping(Z,\\spider\Transfer,spider\u0) failed because Mehrfache Verbindungen zu einem Server
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
function InfoAboutComputerOverview            (){ return [String[]] @(
                                                "InfoAboutComputerOverview:", "",
                                                "ComputerName   : $ComputerName",
                                                "UserName       : $env:UserName",
                                                "Datetime       : $(DateTimeNowAsStringIso 'yyyy-MM-dd HH:mm')",
                                                "ProductKey     : $(OsGetWindowsProductKey)",
                                                "ConnectedDrives: $([System.IO.DriveInfo]::getdrives())",
                                                "PathVariable   : $env:PATH" ); }
function InfoAboutExistingShares              (){
                                                [String[]] $result = @( "Info about existing shares:", "" );
                                                foreach( $shareObj in (ShareListAll | Sort-Object Name) ){
                                                  [Object] $share = $shareObj | Select-Object -ExpandProperty Name;
                                                  [Object] $dummyObjShareSec = Get-CimInstance -Class Win32_LogicalShareSecuritySetting -Filter "name='$share'";
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
                                                $result += @( "", "", "List of DefaultAppAssociations:"                          , (FileReadContentAsString $f "Default") );
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
                                                [String[]] $out2 = @()+(& "winsat.exe" "disk" "-seq" "-write" "-drive" "c"); AssertRcIsOk $out2; return [String[]] @( $out1, $out2 ); }
function InfoAboutNetConfig                   (){
                                                return [String[]] @( "InfoAboutNetConfig:", ""
                                                ,"NetGetIpConfig:"     ,(NetGetIpConfig) , ""
                                                ,"NetGetNetView:"      ,(NetGetNetView)  , ""
                                                ,"NetGetNetStat:"      ,(NetGetNetStat)  , ""
                                                ,"NetGetRoute:"        ,(NetGetRoute)    , ""
                                                ,"NetGetNbtStat:"      ,(NetGetNbtStat)  , ""
                                                ,"NetGetAdapterSpeed:" ,(NetAdapterListAll | StreamToTableString | StreamToStringIndented)  ,"" ); }
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
function ToolRdpConnect                       ( [String] $rdpfile, [String] $mstscOptions = "" ){
                                                # Run RDP gui program with some mstsc options: /edit /admin  (use /edit temporary to set password in .rdp file)
                                                OutProgress "ToolRdpConnect: `"$rdpfile`" $mstscOptions";
                                                & "$env:SystemRoot/System32/mstsc.exe" $mstscOptions $rdpfile; AssertRcIsOk;
                                              }
function ToolHibernateModeEnable              (){
                                                OutInfo "Enable hibernate mode";
                                                if( (OsIsHibernateEnabled) ){
                                                  OutProgress "Ok, is enabled.";
                                                }elseif( (DriveFreeSpace 'C') -le ((OsInfoMainboardPhysicalMemorySum) * 1.3) ){
                                                  OutWarning "Warning: Cannot enable hibernate because has not enought hd-space (RAM=$(OsInfoMainboardPhysicalMemorySum),DriveC-Free=$(DriveFreeSpace 'C'); ignored.";
                                                }else{
                                                  ProcessRestartInElevatedAdminMode;
                                                  & "$env:SystemRoot/System32/powercfg.exe" "-HIBERNATE" "ON"; AssertRcIsOk;
                                                }
                                              }
function ToolHibernateModeDisable             (){
                                                OutInfo "Disable hibernate mode";
                                                if( -not (OsIsHibernateEnabled) ){
                                                  OutProgress "Ok, is disabled.";
                                                }else{
                                                  ProcessRestartInElevatedAdminMode;
                                                  & "$env:SystemRoot/System32/powercfg.exe" "-HIBERNATE" "OFF"; AssertRcIsOk;
                                                }
                                              }
function ToolActualizeHostsFileByMaster       ( [String] $srcHostsFile ){
                                                OutInfo "Actualize hosts file by a master file";
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
function ToolCreate7zip                       ( [String] $srcDirOrFile, [String] $tar7zipFile ){ # target must end with 7z. uses 7z.exe in path or in "C:/Program Files/7-Zip/"
                                                if( (FsEntryGetFileExtension $tar7zipFile) -ne ".7z" ){ throw [Exception] "Expected extension 7z for target file `"$tar7zipFile`"."; }
                                                [String] $src = "";
                                                [String] $recursiveOption = "";
                                                if( (DirExists $srcDirOrFile) ){ $recursiveOption = "-r"; $src = "$(FsEntryMakeTrailingDirSep $srcDirOrFile)*";
                                                }else{ FileAssertExists $srcDirOrFile; $recursiveOption = "-r-"; $src = $srcDirOrFile; }
                                                [String] $Prog7ZipExe = ProcessGetCommandInEnvPathOrAltPaths "7z.exe" @("C:/Program Files/7-Zip/");
                                                # Options: -t7z : use 7zip format; -mmt=4 : try use nr of threads; -w : use temp dir; -r : recursively; -r- : not-recursively;
                                                [Array] $arguments = "-t7z", "-mx=9", "-mmt=4", "-w", $recursiveOption, "a", "$tar7zipFile", $src;
                                                OutProgress "$Prog7ZipExe $arguments";
                                                [String] $out = (& $Prog7ZipExe $arguments); AssertRcIsOk $out;
                                              }
function ToolUnzip                            ( [String] $srcZipFile, [String] $tarDir ){ # tarDir is created if it not exists, no overwriting, requires DotNetFX4.5.
                                                Add-Type -AssemblyName "System.IO.Compression.FileSystem";
                                                $srcZipFile = FsEntryGetAbsolutePath $srcZipFile; $tarDir = FsEntryGetAbsolutePath $tarDir;
                                                OutProgress "Unzip `"$srcZipFile`" to `"$tarDir`"";
                                                # alternative: in PS5 there is: Expand-Archive zipfile -DestinationPath tardir
                                                [System.IO.Compression.ZipFile]::ExtractToDirectory($srcZipFile, $tarDir);
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
                                                $workDir    = FsEntryGetAbsolutePath $workDir;
                                                $lnkFile    = FsEntryGetAbsolutePath $lnkFile;
                                                $srcFsEntry = FsEntryGetAbsolutePath $srcFsEntry;
                                                [String] $descr = $srcFsEntry;
                                                [Boolean] $isDir = FsEntryHasTrailingDirSep $srcFsEntry;
                                                if( $ignoreIfSrcNotExists -and (($isDir -and (DirNotExists $srcFsEntry)) -or (-not $isDir -and (FileNotExists $srcFsEntry))) ){
                                                  OutVerbose "NotCreatedBecauseSourceFileNotExists: $lnkFile"; return;
                                                }
                                                if( $isDir ){ DirAssertExists $srcFsEntry; }else{ FileAssertExists $srcFsEntry; }
                                                if( $forceRecreate ){ FileDelete $lnkFile; }
                                                if( (FileExists $lnkFile) ){
                                                  OutVerbose "Unchanged: $lnkFile";
                                                }else{
                                                    [String] $argLine = $arguments; # array to string
                                                    if( $workDir -eq "" ){ if( $isDir ){ $workDir = $srcFsEntry; }else{ $workDir = FsEntryGetParentDir $srcFsEntry; } }
                                                    [String] $iconFile = (StringRemoveRight (FsEntryRemoveTrailingDirSep $srcFsEntry) (FsEntryGetFileExtension $srcFsEntry)) + ".ico";
                                                    [String] $ico = $(switch((FileNotExists $iconFile)){($true){$iconFile}($false){",0"}});
                                                    OutProgress "CreateShortcut `"$lnkFile`"";
                                                    try{
                                                      [Object] $wshShell = New-Object -comObject WScript.Shell;
                                                      [Object] $s   = $wshShell.CreateShortcut($lnkFile); # do not use FsEntryEsc otherwise [ will be created as `[
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
                                                [String] $m = FsEntryGetAbsolutePath $targetMenuRootDir; # Example: "$env:APPDATA\Microsoft\Windows\Start Menu\MyPortableProg"
                                                [String] $sdir = FsEntryGetAbsolutePath $sourceDir; # Example: "D:\MyPortableProgs"
                                                OutProgress "Create menu links to `"$m`" from files below `"$sdir`" with extension `"$srcFileExtMenuLink`" or `"$srcFileExtMenuLinkOpt`" files";
                                                Assert ($srcFileExtMenuLink    -ne "" -or (-not (FsEntryHasTrailingDirSep $srcFileExtMenuLink   ))) "srcMenuLinkFileExt=`"$srcFileExtMenuLink`" is empty or has trailing backslash";
                                                Assert ($srcFileExtMenuLinkOpt -ne "" -or (-not (FsEntryHasTrailingDirSep $srcFileExtMenuLinkOpt))) "srcMenuLinkOptFileExt=`"$srcFileExtMenuLinkOpt`" is empty or has trailing backslash";
                                                if( -not (DirExists $sdir) ){ OutWarning "Warning: Ignoring dir not exists: `"$sdir`""; }
                                                [String[]] $menuLinkFiles =  (@()+(FsEntryListAsStringArray "$sdir$(DirSep)*$srcFileExtMenuLink"    $true $false));
                                                           $menuLinkFiles += (FsEntryListAsStringArray "$sdir$(DirSep)*$srcFileExtMenuLinkOpt" $true $false);
                                                           $menuLinkFiles =  (@()+($menuLinkFiles | Where-Object{$null -ne $_} | Sort-Object));
                                                foreach( $f in $menuLinkFiles ){ # Example: "...\MyProg .menulinkoptional.txt"
                                                  [String] $d = FsEntryGetParentDir $f; # Example: "D:\MyPortableProgs\Appl\Graphic"
                                                  [String] $relBelowSrcDir = FsEntryMakeRelative $d $sdir; # Example: "Appl\Graphic" or "."
                                                  [String] $workDir = "";
                                                  # Example: "$env:APPDATA\Microsoft\Windows\Start Menu\MyPortableProg\Appl\Graphic\Manufactor ProgramName V1 en 2016.lnk"
                                                  [String] $fn = FsEntryGetFileName $f; $fn = StringRemoveRight $fn $srcFileExtMenuLink;
                                                  $fn = StringRemoveRight $fn $srcFileExtMenuLinkOpt; $fn = $fn.TrimEnd();
                                                  [String] $lnkFile = "$($m)$(DirSep)$($relBelowSrcDir)$(DirSep)$fn.lnk";
                                                  [String] $encodingIfNoBom = "Default"; # Encoding Default is ANSI on windows and UTF8 on other platforms.
                                                  [String] $cmdLine = FileReadContentAsLines $f $encodingIfNoBom | Select-Object -First 1;
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
                                                # Sign (apply strong name) a given source executable with a given key and write it to a target file.
                                                # If the sourcefile has an correspondig xml file with the same name then this is also copied to target.
                                                # If the input file was already signed then it creates a target file with the same name and the extension ".originalWasAlsoSigned.txt".
                                                # Note: Generate your own key with: sn.exe -k mykey.snk
                                                OutInfo "Sign dot-net assembly: keySnk=`"$keySnk`" srcDllOrExe=`"$srcDllOrExe`" tarDllOrExe=`"$tarDllOrExe`" overwrite=$overwrite ";
                                                [Boolean] $execHasStrongName = ([String](& sn -vf $srcDllOrExe | Select-Object -Skip 4 )) -like "Assembly '*' is valid";
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
function ToolVs2019UserFolderGetLatestUsed    (){
                                                # return the current visual studio 2019 config folder or empty string if it not exits.
                                                # example: "$env:LOCALAPPDATA\Microsoft\VisualStudio\16.0_d70392ef\"
                                                [String] $result = "";
                                                # we internally locate the private registry file used by vs2019, later maybe we use https://github.com/microsoft/vswhere
                                                [String[]] $a = (@()+(FsEntryListAsStringArray "$env:LOCALAPPDATA\Microsoft\VisualStudio\16.0_*\privateregistry.bin" $false $false));
                                                if( $a.Count -gt 0 ){
                                                  $result = $a[0];
                                                  $a | Select-Object -Skip 1 | ForEach-Object { if( FileExistsAndIsNewer $_ $result ){ $result = $_; } }
                                                  $result = FsEntryGetParentDir $result;
                                                }
                                                return [String] $result; }
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
                                                  [String] $dummyOut = Add-WindowsCapability -Online -name $name; # example output: "Path          :\nOnline        : True\nRestartNeeded : False"
                                                  [String] $restartNeeded = (Get-WindowsCapability -Online -name $packageName).RestartNeeded;
                                                  OutInfo "Ok, installation done, current state=$(ToolWin10PackageGetState $packageName) RestartNeeded=$restartNeeded Name=$name";
                                                } }
function ToolWin10PackageDeinstall            ( [String] $packageName ){
                                                OutProgress "Deinstall Win10 Package: `"$packageName`"";
                                                ProcessRestartInElevatedAdminMode;
                                                if( (ToolWin10PackageGetState $packageName) -ne "Installed" ){
                                                  OutProgress "Ok, `"$packageName`" is already deinstalled."; }
                                                else{
                                                  [String] $name = (Get-WindowsCapability -Online | Where-Object name -like "${packageName}~*").Name;
                                                  [String] $dummyOut = Remove-WindowsCapability -Online -name $name;
                                                  [String] $restartNeeded = (Get-WindowsCapability -Online -name $packageName).RestartNeeded;
                                                  OutInfo "Ok, deinstallation done, current state=$(ToolWin10PackageGetState $packageName) RestartNeeded=$restartNeeded Name=$name";
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
                                                OutInfo "Ok, checked and repaired missing, corrupted or ownership-settings of system files and logged to '$env:Windows/Logs/CBS/CBS.log'"; }
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
                                                  OutInfo "Update file `"$targetFile`"";
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
                                                  ProcessRefreshEnvVars;
                                                  return [Boolean] $true;
                                                }catch{
                                                  OutWarning "Warning: Update failed because $($_.Exception.Message)";
                                                  if( $doWaitIfFailed ){
                                                    StdInReadLine "Press enter to continue.";
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
                                                  OutInfo "Installmedia `"$installMedia`"";
                                                  $installDirs | ForEach-Object{ OutInfo "  Accepted-Installdir: `"$_`""; };
                                                  if( $installHints -ne "" ){ OutInfo "  InstallHints: $installHints"; }
                                                  if( StdInAskForBoolean ){
                                                    & $installMedia; AssertRcIsOk;
                                                  }
                                                }else{
                                                  OutProgress "Is up-to-date: `"$installMedia`"";
                                                } }
function ToolInstallNuPckMgrAndCommonPsGalMo  (){
                                                OutInfo     "Install or actualize Nuget Package Manager and from PSGallery some common modules: ";
                                                OutProgress "  InstallModules: SqlServer, ThreadJob, PsReadline, PSScriptAnalyzer, Pester, PSWindowsUpdate. Update-Help. ";
                                                OutProgress "  Needs about 1 min.";
                                                ProcessRestartInElevatedAdminMode;
                                                OutProgress "Set repository PSGallery:";
                                                Set-PSRepository PSGallery -InstallationPolicy Trusted; # uses 14 sec
                                                OutProgress "List of installed package providers:";
                                                Get-PackageProvider -ListAvailable | Where-Object{$null -ne $_} |
                                                  Select-Object Name, Version, DynamicOptions |
                                                  StreamToTableString | StreamToStringIndented;
                                                OutProgress "Update NuGet"; # works asynchron
                                                # On PS7 for "Install-PackageProvider NuGet" we got:
                                                #   Install-PackageProvider: No match was found for the specified search criteria for the provider 'NuGet'. The package provider requires 'PackageManagement' and 'Provider' tags. Please check if the specified package has the tags.
                                                # So we ignore errors.
                                                Install-PackageProvider -Name NuGet -ErrorAction SilentlyContinue |
                                                  Select-Object Name, Status, Version, Source |
                                                  StreamToTableString | StreamToStringIndented;
                                                OutProgress "List of modules:";
                                                Get-Module | Sort-Object Name | Select-Object Name,ModuleType,Version,Path |
                                                  StreamToTableString | StreamToStringIndented;
                                                OutProgress "List of installed modules having an installdate:";
                                                Get-InstalledModule | Where-Object{$null -ne $_ -and $null -ne $_.InstalledDate } |
                                                  Select-Object Name | Get-InstalledModule -AllVersions |
                                                  Select-Object Name, Version, InstalledDate, UpdatedDate, Dependencies, Repository, PackageManagementProvider, InstalledLocation |
                                                  StreamToTableString | StreamToStringIndented;
                                                # https://docs.microsoft.com/en-us/powershell/scripting/how-to-use-docs?view=powershell-7.2  take lts version
                                                OutProgress "Install-Module -AcceptLicense -Scope AllUsers -Name PowerShellGet, SqlServer, ThreadJob, PsReadline, PSScriptAnalyzer, Pester, PSWindowsUpdate; ";
                                                # alternatives: Install-Module -Force [-MinimumVersion <String>] [-MaximumVersion <String>] [-RequiredVersion <String>]
                                                try{
                                                  Install-Module -AcceptLicense -Scope AllUsers -Name PowerShellGet, SqlServer, ThreadJob, PsReadline, PSScriptAnalyzer, Pester, PSWindowsUpdate;
                                                }catch{
                                                    # Install-Module : A parameter cannot be found that matches parameter name 'AcceptLicense'. ParameterBindingException
                                                    [String] $msg = $_.Exception.Message;
                                                    OutProgress "Failed because $msg";
                                                    OutProgress "Sometimes it failed because unknown parameter AcceptLicense, so we retry without it. ";
                                                    OutProgress "Install-Module -Scope AllUsers -Name PowerShellGet, SqlServer, ThreadJob, PsReadline, PSScriptAnalyzer, Pester, PSWindowsUpdate; ";
                                                    Install-Module -Scope AllUsers -Name PowerShellGet, SqlServer, ThreadJob, PsReadline, PSScriptAnalyzer, Pester, PSWindowsUpdate;
                                                }
                                                # On PS7 we would get: Update-Module: Module 'PowerShellGet' was not installed by using Install-Module, so it cannot be updated.
                                                if( (ProcessIsLesserEqualPs5) ){
                                                  OutProgress "Update  modules: PowerShellGet, SqlServer, ThreadJob, PsReadline, PSScriptAnalyzer, Pester, PSWindowsUpdate";
                                                  try{
                                                    Update-Module -AcceptLicense -Scope AllUsers -Name PowerShellGet, SqlServer, ThreadJob, PsReadline, PSScriptAnalyzer, Pester, PSWindowsUpdate;
                                                  }catch{
                                                    # 2023-10: option AcceptLicense not exists ...
                                                    OutWarning "Warning: Update-Module failed because $($_.Exception.Message), ignored.";
                                                  }
                                                }
                                                # Set-Culture -CultureInfo de-CH; # change default culture for current user
                                                OutProgress "Current Culture: $((Get-Culture).Name) = $((Get-Culture).DisplayName) "; # show current culture, Example: "de-CH"
                                                OutProgress "update-help";
                                                try{
                                                  (update-help -ErrorAction continue *>&1) | ForEach-Object{ OutProgress "  $_"; };
                                                }catch{
                                                  # example 2022-02: update-help : Failed to update Help for the module(s) 'ConfigDefender, PSReadline' with UI culture(s) {en-US} :
                                                  #   Unable to retrieve the HelpInfo XML file for UI culture en-US.
                                                  #   Make sure the HelpInfoUri property in the module manifest is valid or check your network connection and then try the command again.
                                                  OutWarning "Warning: Update-help failed because $($_.Exception.Message), ignored.";
                                                }
                                                OutProgress "List of installed modules having an installdate:";
                                                Get-InstalledModule | Where-Object{$null -ne $_ -and $null -ne $_.InstalledDate } |
                                                  Select-Object Name | Get-InstalledModule -AllVersions |
                                                  Select-Object Name, Version, InstalledDate, UpdatedDate, Dependencies, Repository, PackageManagementProvider, InstalledLocation |
                                                  StreamToTableString | StreamToStringIndented;
                                                # Hints:
                                                # - Install-Module -Force -Name myModule; # 2021-12: Paralled installed V1.0.0.1 and V2.2.5
                                                #   we got: WARNING: The version '1.4.7' of module 'myModule' is currently in use. Retry the operation after closing the applications.
                                                # - https://github.com/PowerShell/PSReadLine
                                                # - Install-Module -Force -Name PsReadline; # 2021-12: Paralled installed V1.0.0.1 and V2.2.5
                                                #   Install-Module -Force -SkipPublisherCheck -Name Pester;
                                                #   Note: Ein zuvor installiertes, von Microsoft signiertes Modul Pester V3.4.0 verursacht Konflikte
                                                #     mit dem neuen Modul Pester V5.3.1 vom Herausgeber CN=DigiCert Assured ID Root CA, OU=www.digicert.com, O=DigiCert Inc, C=US.
                                                #     Durch die Installation des neuen Moduls kann das System instabil werden. Falls Sie trotzdem eine Installation oder ein Update durchführen möchten, verwenden Sie den -SkipPublisherCheck-Parameter.
                                                #     And Update-Module : Das Modul 'Pester' wurde nicht mithilfe von 'Install-Module' installiert und kann folglich nicht aktualisiert werden.
                                                # - Example: Uninstall-Module -MaximumVersion "0.9.99" -Name SqlServer;
                                                }
function ToolManuallyDownloadAndInstallProg   ( [String] $programName, [String] $programDownloadUrl, [String] $mainTargetFileMinIsoDate = "0001-01-01", [String] $programExecutableOrDir = "", [String] $programConfigurations = "" ){
                                                # Example: ToolManuallyDownloadAndInstallProg "Powershell-V7"     "https://learn.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-windows" "0001-01-01" "pwsh.exe" "";
                                                # Example: ToolManuallyDownloadAndInstallProg "TortoiseGit 64bit" "https://tortoisegit.org/download/" "0001-01-01" "C:/Program Files/TortoiseGit/bin/TortoiseGit.dll" "";
                                                OutInfo "Check `"$programName`" by existance of executable or dir `"$programExecutableOrDir`" and $mainTargetFileMinIsoDate ";
                                                [Boolean] $isDir = (FsEntryHasTrailingDirSep $programExecutableOrDir);
                                                [DateTime] $mainTargetFileMinDate = DateTimeFromStringIso $mainTargetFileMinIsoDate;
                                                while($true){
                                                  if( $programExecutableOrDir -ne "" ){
                                                    [String] $exe = (ProcessFindExecutableInPath $programExecutableOrDir);
                                                    if( $isDir ){
                                                      if( (DirExists $programExecutableOrDir) ){ return; }
                                                    }else{
                                                      if( $exe -ne "" ){
                                                        if( $mainTargetFileMinDate -eq [DateTime]::MinValue ){ return; }
                                                        [DateTime] $mainTargetFileDate = FsEntryGetLastModified $exe;
                                                        if( $mainTargetFileDate -ge $mainTargetFileMinDate ){ return; }
                                                      }
                                                    }
                                                  }
                                                  OutInfo "Please download and install `"$programName`" ";
                                                  OutProgress "Follow the configurations: `"$programConfigurations`" ";
                                                  ProcessOpenAssocFile $programDownloadUrl;
                                                  StdInAskForEnterContinue;
                                                  ProcessRefreshEnvVars;
                                                  if( $programExecutableOrDir -eq "" ){ return; } # if exec not specified then we open url only once!
                                                } }
function MnCommonPsToolLibSelfUpdate          (){
                                                # If installed in standard mode (saved under c:/Program Files/WindowsPowerShell/Modules/...)
                                                # then it performs a self update to the newest version from github otherwise output a note.
                                                [String]  $additionalOkUpdMsg = "`n  Please restart all processes which currently loaded this module before using changed functions of this library.";
                                                [Boolean] $requireElevatedAdminMode = $true;
                                                [Boolean] $assertFilePreviouslyExists = $true;
                                                [Boolean] $performPing = $true;
                                                [String]  $moduleName = "MnCommonPsToolLib";
                                                [String]  $tarRootDir = FsEntryGetAbsolutePath "$Env:ProgramW6432/WindowsPowerShell/Modules/"; # more see: https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx
                                                [String]  $moduleFile = FsEntryGetAbsolutePath "$tarRootDir/$moduleName/${moduleName}.psm1";
                                                if( (FileNotExists $moduleFile) ){
                                                  OutProgress "MnCommonPsToolLibSelfUpdate: Nothing done because is not installed in standard mode under `"$tarRootDir`". ";
                                                  if( (OsPsModulePathContains $PSScriptRoot) ){ OutProgress "  Current script is in PsModulePath so it is Installed-for-Developers! "; }else{ ProcessSleepSec 5; }
                                                  return;
                                                }
                                                #
                                                [String]  $modFile     = "$tarRootDir/$moduleName/${moduleName}.psm1";
                                                [String]  $url         = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/$moduleName/${moduleName}.psm1";
                                                [Boolean] $dummyResult = ToolPerformFileUpdateAndIsActualized $modFile $url $requireElevatedAdminMode $doWaitForEnterKeyIfFailed $additionalOkUpdMsg $assertFilePreviouslyExists $performPing;
                                                #
                                                [String]  $modFile     = "$tarRootDir/$moduleName/${moduleName}_Windows.ps1";
                                                [String]  $url         = "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/$moduleName/${moduleName}_Windows.ps1";
                                                [Boolean] $dummyResult = ToolPerformFileUpdateAndIsActualized $modFile $url $requireElevatedAdminMode $doWaitForEnterKeyIfFailed $additionalOkUpdMsg $assertFilePreviouslyExists $performPing;
                                                }
