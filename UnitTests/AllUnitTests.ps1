#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

[String[]] $ps1Files = FsEntryListAsStringArray "$PSScriptRoot/MnCommonPsToolLib*" -includeDirs $false;

OutProgressTitle "MnCommonPsToolLib - AllUnitTest - running powershell V$($Host.Version.ToString())";
OutProgress "It is compatible for PS5/PS7, elevated, platforms Windows/Linux/MacOS!";
OutProgress "If it is running elevated then it performs additional tests. ";
[String[]] $errorPs1Files = @();
for( [Int32] $i = 0; $i -lt $ps1Files.Count; $i++ ){

  OutProgressTitle ("----- "+(FsEntryGetFileName $ps1Files[$i])+" -----").PadRight(120,'-');
  try{
    AssertRcIsOk;
    & $ps1Files[$i];
    [Int32] $rc = ScriptGetAndClearLastRc;
    if( $rc -ne 0 ){ throw [ExcMsg] "End of was reached, but the last operation failed [rc=$rc] because it did call a program but it did not handle or reset the rc."; }
  }catch{
    ScriptResetRc; $errorPs1Files += $ps1Files[$i]; StdErrHandleExc $_;
    OutProgress "Continue but will throw at the end of processing all items.";
  }

}
OutProgressTitle ("----- AllUnitTests.ps1 ended -----").PadRight(120,'-');
if( $errorPs1Files.Count -gt 0 ){ throw [ExcMsg] "AllUnitTests failed for the $($errorPs1Files.Count) files: $errorPs1Files"; }
AssertRcIsOk;
OutProgressSuccess "Ok, done. All unit tests are successful. Exit after 2 seconds. ";
ProcessSleepSec 2;
# for future use: GlobalSetModeVerboseEnable;
