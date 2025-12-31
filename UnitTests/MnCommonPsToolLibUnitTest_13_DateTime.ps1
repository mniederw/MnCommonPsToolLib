#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_DateTime(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert    ((DateTimeFromStringIso "2020-12-31 23:59" "yyyy-MM-dd HH:mm:ss") -eq "2020-12-31 23:59:00");
  OutVerbose "DateTimeGetBeginOf Year       : $(DateTimeGetBeginOf "Year"                 )"; # Example: 2024-01-01 00:00:00
  OutVerbose "DateTimeGetBeginOf Semester   : $(DateTimeGetBeginOf "Semester"             )"; # Example: 2024-01-01 00:00:00
  OutVerbose "DateTimeGetBeginOf Quarter    : $(DateTimeGetBeginOf "Quarter"              )"; # Example: 2024-01-01 00:00:00
  OutVerbose "DateTimeGetBeginOf TwoMonth   : $(DateTimeGetBeginOf "TwoMonth"             )"; # Example: 2024-01-01 00:00:00
  OutVerbose "DateTimeGetBeginOf Month      : $(DateTimeGetBeginOf "Month"                )"; # Example: 2024-01-01 00:00:00
  OutVerbose "DateTimeGetBeginOf Week       : $(DateTimeGetBeginOf "Week"                 )"; # Example: 2024-03-03 00:00:00
  OutVerbose "DateTimeGetBeginOf Hour       : $(DateTimeGetBeginOf "Hour"                 )"; # Example: 2024-03-03 12:00:00
  OutVerbose "DateTimeGetBeginOf Minute     : $(DateTimeGetBeginOf "Minute"               )"; # Example: 2024-01-01 12:58:00
  OutVerbose "DateTimeNowAsStringIso        : $(DateTimeNowAsStringIso "yyyy-MM-dd HH:mm" )"; # Example: 2024-03-03 12:58
  OutVerbose "DateTimeNowAsStringIso        : $(DateTimeNowAsStringIso                    )"; # Example: 2024-01-01 12:58:00
  OutVerbose "DateTimeNowAsStringIsoMinutes : $(DateTimeNowAsStringIsoMinutes             )"; # Example: 2024-01-01 12:58
  OutVerbose "DateTimeNowAsStringIsoDate    : $(DateTimeNowAsStringIsoDate                )"; # Example: 2024-03-03
  OutVerbose "DateTimeNowAsStringIsoMonth   : $(DateTimeNowAsStringIsoMonth               )"; # Example: 2024-03
  OutVerbose "DateTimeNowAsStringIsoYear    : $(DateTimeNowAsStringIsoYear                )"; # Example: 2024
  Assert    ((DateTimeFromStringIso "2011-12-31"             ) -eq (Get-Date -Date "2011-12-31 00:00:00"    ));
  Assert    ((DateTimeFromStringIso "2011-12-31 23:59"       ) -eq (Get-Date -Date "2011-12-31 23:59:00"    ));
  Assert    ((DateTimeFromStringIso "2011-12-31 23:59:59"    ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert    ((DateTimeFromStringIso "2011-12-31 23:59:59."   ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert    ((DateTimeFromStringIso "2011-12-31 23:59:59.0"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.0"  ));
  Assert    ((DateTimeFromStringIso "2011-12-31 23:59:59.9"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.9"  ));
  Assert    ((DateTimeFromStringIso "2011-12-31 23:59:59.99" ) -eq (Get-Date -Date "2011-12-31 23:59:59.99" ));
  Assert    ((DateTimeFromStringIso "2011-12-31 23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert    ((DateTimeFromStringIso "2011-12-31T23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert    ((DateTimeFromStringOrDateTimeValue                 "2011-12-31T23:59:59.123+0000" ) -eq (Get-Date -Date "2011-12-31 23:59:59.123+0000"));
  Assert    ((DateTimeFromStringOrDateTimeValue (Get-Date -Date "2011-12-31 23:59:59.123+0000")) -eq (Get-Date -Date "2011-12-31 23:59:59.123+0000"));
}
UnitTest_DateTime;
