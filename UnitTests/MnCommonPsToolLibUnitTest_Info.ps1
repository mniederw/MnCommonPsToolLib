#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Info(){
  OutProgress (ScriptGetCurrentFuncName);
  #
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  #
  OutInfo "InfoAboutComputerOverview:";
  [String] $a = (InfoAboutComputerOverview);
  OutProgress $a;
    # InfoAboutComputerOverview:
    # 
    # ComputerName    : mycomputer
    # UserName        : u1
    # Datetime        : 2022-12-31 13:14
    # ProductKey      : XY123-88888-88888-88888-88888
    # ConnectedDrives : C:\ D:\
    # PathVariable    : C:\Program Files\...
    # 
  Assert ($a -like "*PathVariable*");
  #
  OutInfo "InfoAboutExistingShares:";
  [String] $a = (InfoAboutExistingShares);
  OutProgress $a;
    # Info about existing shares:
    # 
    #   IPC$         = ''    Remote-IPC
    #   print$       = 'C:\WINDOWS\system32\spool\drivers' Druckertreiber
    #   Transfer     = 'D:\Transfer' Transfer dir for any user
  Assert ($a -like "*IPC$*");
  #
  OutInfo "InfoAboutSystemInfo";
  # TODO: InfoAboutSystemInfo                  this requires elevated mode
  #
  OutInfo "InfoAboutRunningProcessesAndServices";
  # TODO: InfoAboutRunningProcessesAndServices 
    # Info about processes:
    #
    # RunningProcesses:
    #   ABService
    #   ClassicStartMenu
    #   ...
  #
  OutInfo "InfoHdSpeed";
  # TODO: InfoHdSpeed                     requires elevated mode      
    # Windows-Systembewertungstool ... Read                   449.80 MB/s ... Write                  454.22 MB/s ...
  #
  OutInfo "InfoAboutNetConfig";
  # TODO: InfoAboutNetConfig                   
  #
  OutInfo "InfoGetInstalledDotNetVersion";
  InfoGetInstalledDotNetVersion; # to console not output: "4.7.2 or later (533325)"
  InfoGetInstalledDotNetVersion $true;
    #       List Installed DotNet CLRs (clrver.exe):
    #     Installed CLRs: v2.0.50727
    #     Installed CLRs: v4.0.30319
    #   List running DotNet Processes (clrver.exe -all):
    #     Running Processes and its CLR: 8588 devenv.exe              v4.0.30319
    #     Running Processes and its CLR: 8572 PerfWatson2.exe         v4.0.30319
    #     Running Processes and its CLR: 3988 Microsoft.ServiceHub.Controller.exe     v4.0.30319
    #     Running Processes and its CLR: 12664        ServiceHub.VSDetouredHost.exe   v4.0.30319
    #     Running Processes and its CLR: 8376 ServiceHub.SettingsHost.exe     v4.0.30319
    #     Running Processes and its CLR: 12968        ServiceHub.IntellicodeModelService.exe  v4.0.30319
    #     Running Processes and its CLR: 4364 FcContextMenu64.exe     v4.0.30319
    #     Running Processes and its CLR: 7672 notepad++.exe           v4.0.30319
    #     Running Processes and its CLR: 9992 notepad++.exe           v4.0.30319
    # 4.7.2 or later (533325)
  #
}
Test_Info;
