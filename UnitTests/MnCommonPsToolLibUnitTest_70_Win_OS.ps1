#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_OS(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  Assert ($UserQuickLaunchDir    ).StartsWith("C:\");
  Assert ($UserSendToDir         ).StartsWith("C:\");
  Assert ($UserMenuDir           ).StartsWith("C:\");
  Assert ($UserMenuStartupDir    ).StartsWith("C:\");
  Assert ($AllUsersMenuDir       ).StartsWith("C:\");
  Assert ($AllUsersMenuStartupDir).StartsWith("C:\");
  #
  Assert (OsIs64BitOs);
  Assert ((OsIsHibernateEnabled) -or $true);
  Assert ((OsInfoMainboardPhysicalMemorySum) -gt 1000000000);
  # TODO OsWindowsFeatureGetInstalledNames  # 2024-03 We get now: "Import-Module: The specified module 'ServerManager' was not loaded because no valid module file was found in any module directory." # Requires windows-server-os or at least Win10Prof with installed RSAT https://www.microsoft.com/en-au/download/details.aspx?id=45520
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ OsWindowsFeatureDoInstall   "Telnet-Client"; }
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){ OsWindowsFeatureDoUninstall "Telnet-Server"; }
  Assert ((OsGetWindowsProductKey).Length -ge 29);
  #
}
UnitTest_Win_OS;
