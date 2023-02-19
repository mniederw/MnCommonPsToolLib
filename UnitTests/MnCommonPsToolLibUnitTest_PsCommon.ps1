#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_PsCommon(){
  OutProgress (ScriptGetCurrentFuncName);
  # Assert
  Assert ( $true );
  AssertIsFalse ( $false );
  AssertNotEmpty "this-string-is-not-empty" "test fail msg";
  ScriptResetRc; AssertRcIsOk;
  # string is never null
  [String] $s = $null; Assert ($null -ne $s -and $s -eq "" -and $s -is [String]);
  # pipelining with $null iterates at least once
  [Int32] $n = 0; $null | ForEach-Object{ $n++; }; Assert ($n -gt 0);
  # empty array not iterates to pipelining
  [Int32] $n = 0; @()   | ForEach-Object{ $n++; }; Assert ($n -eq 0);
  # null on left side is mandatory
  [String[]] $a = @()  ; AssertIsFalse ( $null -eq $a );
  [String[]] $a = @()  ; Assert        ( $null -ne $a );
  [String[]] $a = $null; AssertIsFalse ( $null -ne $a );
  [String[]] $a = $null; Assert        ( $null -eq $a );
  # within double quotes parameters are replaced.
  [String] $myvar = "abc"; Assert ( "$myvar".Length -eq 3 );
  Assert ( '$anyUnknownVar'.Length -gt 0 ); # within single quotes parameters were not replaced.
  # String builtin functions
  Assert ((2 + 3) -eq 5);
  Assert ([Math]::Min(-5,-9) -eq -9);
  Assert ("xyz".SubString(1,0) -eq "");
  Assert (("abc" -split ",").Count -eq 1 -and "abc,".Split(",").Count -eq 2 -and ",abc".Split(",").Count -eq 2);
  # No IO is done for the followings:
  if( ! OsIsWindows ){ # not windows
    Assert ([System.IO.Path]::GetDirectoryName("\\anyhostname\AnyFolder\") -eq "");
    Assert ([System.IO.Path]::GetDirectoryName("//anyhostname/AnyFolder/") -eq "/anyhostname/AnyFolder");
    Assert ("" -eq [System.IO.Path]::GetDirectoryName("C:\"));
  }else{ # windows
    Assert ([System.IO.Path]::GetDirectoryName("\\anyhostname\AnyFolder\") -eq "\\anyhostname\AnyFolder");
    Assert ([System.IO.Path]::GetDirectoryName("//anyhostname/AnyFolder/") -eq "\\anyhostname\AnyFolder");
    Assert ($null -eq [System.IO.Path]::GetDirectoryName("C:\"));
  }
  #
  OutVerbose "Test expecting exceptions on assigning string to boolean";
  [Boolean] $isOk = $false;
  try{
    [Boolean] $r = "anystring"; # ArgumentTransformationMetadataException: Cannot convert value "System.String" to type "System.Boolean". Boolean parameters accept only Boolean values and numbers, such as $True, $False, 1 or 0.
	OutVerbose "$r";
  }catch{ $isOk = $true; }
  if( -not $isOk ){
    OutVerbose "  IsInteractive=$(ScriptIsProbablyInteractive); Trap=Enabled; Note: Exception was not throwed and catch block not reached. We found out this happens in batch only for unknown reason. If runing interactive then works ok. Analyse it later.";
  }
  # OutProgress "Test when ignoring traps";
  # for later:
  # trap [Exception] { OutVerbose "Ignored trap: $_"; continue; } # temporary ignore
  # # Count is for all classes defined when exceptions are ignored but otherwise it throws
  # Assert ( ($false   ).Count -eq 1 ); # Throws: Die Eigenschaft "Count" wurde für dieses Objekt nicht gefunden. Vergewissern Sie sich, dass die Eigenschaft vorhanden ist.
  # Assert ( (123      ).Count -eq 1 );
  # Assert ( ("ab"     ).Count -eq 1 );
  # Assert ( ($null    ).Count -eq 0 );
  # trap [Exception] { StdErrHandleExc $_; break; } # restore
}
Test_PsCommon;
