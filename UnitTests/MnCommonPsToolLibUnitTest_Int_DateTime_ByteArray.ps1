﻿# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Int_DateTime_ByteArray(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert         ((Int32Clip -5 0 9) -eq 0 -and (Int32Clip 5 0 9) -eq 5 -and (Int32Clip 15 0 9) -eq 9);
  # todo function DateTimeAsStringIso                  ( [DateTime] $ts, [String] $fmt = "yyyy-MM-dd HH:mm:ss" ){
  OutVerbose "DateTimeGetBeginOf Year     : $(DateTimeGetBeginOf "Year"     )";
  OutVerbose "DateTimeGetBeginOf Semester : $(DateTimeGetBeginOf "Semester" )";
  OutVerbose "DateTimeGetBeginOf Quarter  : $(DateTimeGetBeginOf "Quarter"  )";
  OutVerbose "DateTimeGetBeginOf TwoMonth : $(DateTimeGetBeginOf "TwoMonth" )";
  OutVerbose "DateTimeGetBeginOf Month    : $(DateTimeGetBeginOf "Month"    )";
  OutVerbose "DateTimeGetBeginOf Week     : $(DateTimeGetBeginOf "Week"     )";
  OutVerbose "DateTimeGetBeginOf Hour     : $(DateTimeGetBeginOf "Hour"     )";
  OutVerbose "DateTimeGetBeginOf Minute   : $(DateTimeGetBeginOf "Minute"   )";
  # todo function DateTimeNowAsStringIso               ( [String] $fmt = "yyyy-MM-dd HH:mm:ss" ){ return [String] (Get-Date -format $fmt); }
  # todo function DateTimeNowAsStringIsoDate           (){ return [String] (Get-Date -format "yyyy-MM-dd"); }
  # todo function DateTimeNowAsStringIsoMonth          (){ return [String] (Get-Date -format "yyyy-MM"); }
  # todo function DateTimeNowAsStringIsoInMinutes      (){ return [String] (Get-Date -format "yyyy-MM-dd HH:mm"); }
  Assert         ((DateTimeFromStringIso "2011-12-31"             ) -eq (Get-Date -Date "2011-12-31 00:00:00"    ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59"       ) -eq (Get-Date -Date "2011-12-31 23:59:00"    ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59"    ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59."   ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59.0"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.0"  ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59.9"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.9"  ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59.99" ) -eq (Get-Date -Date "2011-12-31 23:59:59.99" ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert         ((DateTimeFromStringIso "2011-12-31T23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert         ((ByteArraysAreEqual @()               @()              ) -eq $true );
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01,0xFF)) -eq $true );
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x02,0xFF)) -eq $false);
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01     )) -eq $false);
}
Test_Int_DateTime_ByteArray;