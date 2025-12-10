#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_PsCommon(){
  OutProgress (ScriptGetCurrentFuncName);
  #
  # Assert
  Assert ( $true );
  AssertIsFalse ( $false );
  AssertNotEmpty "this-string-is-not-empty" "test fail msg";
  ScriptResetRc; AssertRcIsOk;
  #
  # string is never null
  [String] $s = $null; Assert ($null -ne $s -and $s -eq "" -and $s -is [String]);
  #
  # pipelining with $null iterates at least once
  [Int32] $n = 0; $null | ForEach-Object{ $n++; }; Assert ($n -gt 0);
  #
  # empty array not iterates to pipelining
  [Int32] $n = 0; @()   | ForEach-Object{ $n++; }; Assert ($n -eq 0);
  #
  # null on left side is mandatory
  [String[]] $a = @()  ; AssertIsFalse ( $null -eq $a );
  [String[]] $a = @()  ; Assert        ( $null -ne $a );
  [String[]] $a = $null; AssertIsFalse ( $null -ne $a );
  [String[]] $a = $null; Assert        ( $null -eq $a );
  #
  # No element through pipelining results in null array
  [String[]] $a = @() | Where-Object{ $false }; Assert ($null -eq $a);
  #
  # null in switch works ok if compared with string but not otherwise
  [String] $s = ""   ; [String] $r = switch ($s){$null {"IS_NULL"} "" {"IS_EMPTY"}}; Assert ($r -eq "IS_EMPTY");
  [String] $s = $null; [String] $r = switch ($s){$null {"IS_NULL"} "" {"IS_EMPTY"}}; Assert ($r -eq "IS_EMPTY");
  [Object] $o = $null; [String] $r = switch ($o){$null {"IS_NULL"} "" {"IS_EMPTY"}}; Assert ($r -eq "IS_NULL IS_EMPTY"); # strange behaviour
  #
  # within double quotes parameters are replaced.
  [String] $myvar = "abc"; Assert ( "$myvar".Length -eq 3 );
  Assert ( '$anyUnknownVar'.Length -gt 0 ); # within single quotes parameters were not replaced.
  #
  # String builtin functions
  Assert ((2 + 3) -eq 5);
  Assert ([Math]::Min(-5,-9) -eq -9);
  Assert ("xyz".SubString(1,0) -eq "");
  Assert (("abc" -split ",",0).Count -eq 1 -and "abc,".Split(",").Count -eq 2 -and ",abc".Split(",").Count -eq 2);
  #
  # No IO is done for the followings:
  if( OsIsWindows ){
    Assert ([System.IO.Path]::GetDirectoryName("\\anyhostname\AnyFolder\") -eq "\\anyhostname\AnyFolder");
    Assert ([System.IO.Path]::GetDirectoryName("//anyhostname/AnyFolder/") -eq "\\anyhostname\AnyFolder");
    Assert ($null -eq [System.IO.Path]::GetDirectoryName("C:\"));
  }else{ # is not windows
    Assert ([System.IO.Path]::GetDirectoryName("\\anyhostname\AnyFolder\") -eq "");
    Assert ([System.IO.Path]::GetDirectoryName("//anyhostname/AnyFolder/") -eq "/anyhostname/AnyFolder");
    Assert ("" -eq [System.IO.Path]::GetDirectoryName("C:\"));
  }
  #
  # check wrong type assignment
  OutVerbose "Test expecting exceptions on assigning string to boolean";
  [Boolean] $isOk = $false;
  try{
    [Boolean] $r = "anystring"; # ArgumentTransformationMetadataException: Cannot convert value "System.String" to type "System.Boolean". Boolean parameters accept only Boolean values and numbers, such as $True, $False, 1 or 0.
    OutVerbose "$r";
  }catch{ $isOk = $true; }
  if( -not $isOk ){
    OutVerbose "  IsInteractive=$(ScriptIsProbablyInteractive); Trap=Enabled; Note: Exception was not throwed and catch block not reached. We found out this happens in batch only for unknown reason. If runing interactive then works ok. Analyse it later.";
  }
  #
  # Check match
  Assert ("hello" -match "hallo|hello|hullo" -and -not ("hello" -match "hallo|xhello|hullo"));
  #
  # Unexpected behaviour (undocumented)
  if( OsIsWindows ){
    Push-Location "C:\Windows";
    Assert ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("C:") -eq "C:\Windows"); # returns unexpected current dir of the drive
    Assert ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("C:\") -eq "C:\"); # ok, expected
    Assert ([IO.Path]::GetFullPath("C:\") -eq "C:\"); # ok, expected
    if( ProcessIsLesserEqualPs5 ){
      Assert ([IO.Path]::GetFullPath("C:/") -eq "C:\" ); # returns unexpected current dir of the drive
    }else{
      [String] $d = [IO.Path]::GetFullPath("C:/");
      Assert ($d.StartsWith("C:")); # returns unexpected dir (when run in ps1 then "C:\" and when run GetFullPath interactive then "C:\Windows\system32")
    }
    Pop-Location;
  }
  #
  # using ref param
  function TestUsingRefParam{
    function f ( [String] $key = "abc", [ref] $s ){
      if( $null -ne $s ){
        Assert ($s.Value -is [String]) "Argument s cannot be specified as [String] because it is [ref] and only one attr is allowed, but it must be of type String instead of: $($s.Value?.GetType())";
        $s.Value = "hello";
        return "SET-S-TO-VAL";
      }elseif( $null -ne $s ){
        Assert ("$($s?.Value)" -eq "")
        return "REF-TO-NUL";
      }else{ # $null -eq $s
        # Note: On accessing $s?.Value we would get: RuntimeException: The variable '$s?' cannot be retrieved because it has not been set.
        return "REF-IS-UNINIT";
      }
    }
    [String] $str = "";
    [String] $out = "";
    $str = ""; $out = f          -s ([ref]$str); Assert ($out -eq "SET-S-TO-VAL"  -and $str -eq "hello");
    $str = ""; $out = f "dummy"     ([ref]$str); Assert ($out -eq "SET-S-TO-VAL"  -and $str -eq "hello");
    $str = ""; $out = f;                         Assert ($out -eq "REF-IS-UNINIT" -and $str -eq "");
    $str = ""; $out = f "dummy";                 Assert ($out -eq "REF-IS-UNINIT" -and $str -eq "");
    $str = ""; $out = f -key "dummy";            Assert ($out -eq "REF-IS-UNINIT" -and $str -eq "");
    function TestRefToIntSoAnotherTypeAsStringExpectingThrow(){
      [Boolean] $doThrow = $false;
      try{
        [Int32] $int32 = 0; f -s ([ref]$int32) | Out-Null;
      }catch{
        $doThrow = $true;
      }
      Assert $doThrow;
    } TestRefToIntSoAnotherTypeAsStringExpectingThrow;
    function TestRefToNullObjSoAnotherTypeAsStringExpectingThrow(){
      [Boolean] $doThrow = $false;
      try{
        [Object] $nul = $null; f -s ([ref]$nul) | Out-Null;
      }catch{
        $doThrow = $true;
      }
      Assert $doThrow;
    }TestRefToNullObjSoAnotherTypeAsStringExpectingThrow;
  }
  TestUsingRefParam;
  #
  # OutProgress "Test when ignoring traps";
  # for later:
  # trap [Exception] { OutVerbose "Ignored trap: $_"; continue; } # temporary ignore
  # # Count is for all classes defined when exceptions are ignored but otherwise it throws
  # Assert ( ($false   ).Count -eq 1 ); # Throws: Die Eigenschaft "Count" wurde für dieses Objekt nicht gefunden. Vergewissern Sie sich, dass die Eigenschaft vorhanden ist.
  # Assert ( (123      ).Count -eq 1 );
  # Assert ( ("ab"     ).Count -eq 1 );
  # Assert ( ($null    ).Count -eq 0 );
  # trap [Exception] { StdErrHandleExc $_; break; } # restore
  #
}
UnitTest_PsCommon;
