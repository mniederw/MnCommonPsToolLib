#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Array(){
  OutProgress (ScriptGetCurrentFuncName);
  function TestReturnEmptyArray1(){ return [String[]] @()                                       ; }
  function TestReturnEmptyArray2(){ return [String[]] (@()+($null | Where-Object{$null -ne $_})); }
  function TestReturnEmptyArray3(){ return [String[]] (    ($null | Where-Object{$null -ne $_})); }
  function TestReturnNullArray  (){ return [String[]] $null                                     ; }
  # ArrayIsNullOrEmpty
  Assert ( ArrayIsNullOrEmpty (TestReturnEmptyArray1) );
  Assert ( ArrayIsNullOrEmpty (TestReturnEmptyArray2) );
  Assert ( ArrayIsNullOrEmpty (TestReturnEmptyArray3) );
  Assert ( ArrayIsNullOrEmpty (TestReturnNullArray  ) );
  Assert ( ArrayIsNullOrEmpty (@()                  ) );
  Assert ( ArrayIsNullOrEmpty ($null                ) );
  Assert ( -not (ArrayIsNullOrEmpty @("aa")) );
  # Count for arrays
  Assert ( (@()      ).Count -eq 0 );
  Assert ( (@()+$null).Count -eq 1 );
  Assert ( (@(3,4)   ).Count -eq 2 );
  # func return null for empty arrays
  Assert ( $null -eq ($null | Where-Object{$null -ne $_}) );
  Assert ( $null -eq (TestReturnEmptyArray1));
  Assert ( $null -eq (TestReturnEmptyArray2));
  Assert ( $null -eq (TestReturnEmptyArray3));
  Assert ( $null -eq (TestReturnNullArray  ));
  # adding null to array inserts it.
  Assert ((@()+($null | Where-Object{$null -ne $_})).Count -eq 0);
  Assert ((@()+(@()                               )).Count -eq 0);
  Assert ((@()+(TestReturnEmptyArray1             )).Count -eq 0);
  Assert ((@()+(TestReturnEmptyArray2             )).Count -eq 0);
  Assert ((@()+(TestReturnEmptyArray3             )).Count -eq 1);
  Assert ((@()+(TestReturnNullArray               )).Count -eq 1);
  Assert ((@()+($null                             )).Count -eq 1);
  [String[]] $a = @(); $a += ($null | Where-Object{$null -ne $_}); Assert ($a -is [String[]]); Assert ($a.Count -eq 0);
  [String[]] $a = @(); $a += (TestReturnEmptyArray1             ); Assert ($a -is [String[]]); Assert ($a.Count -eq 0);
  [String[]] $a = @(); $a += (TestReturnEmptyArray2             ); Assert ($a -is [String[]]); Assert ($a.Count -eq 0);
  [String[]] $a = @(); $a += (TestReturnEmptyArray3             ); Assert ($a -is [String[]]); Assert ($a.Count -eq 1);
  [String[]] $a = @(); $a += (TestReturnNullArray               ); Assert ($a -is [String[]]); Assert ($a.Count -eq 1);
  # empty array has expected type
  [String[]] $a = @(); Assert ($a -is [String[]]);
}
UnitTest_Array;
