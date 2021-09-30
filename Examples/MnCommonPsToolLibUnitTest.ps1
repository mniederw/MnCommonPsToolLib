# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function TestReturnEmptyArray1(){ return [String[]] @()                                       ; }
function TestReturnEmptyArray2(){ return [String[]] (@()+($null | Where-Object{$null -ne $_})); }
function TestReturnEmptyArray3(){ return [String[]] (    ($null | Where-Object{$null -ne $_})); }
function TestReturnNullArray  (){ return [String[]] $null                                     ; }

function MnLibCommonSelfTest(){ # perform some tests
  OutInfo "MnCommonPsToolLibUnitTest";

  Assert ( $true );
  AssertIsFalse ( $false );

  # Count for arrays
  Assert ( (@()      ).Count -eq 0 );
  Assert ( (@()+$null).Count -eq 1 );
  Assert ( (@(3,4)   ).Count -eq 2 );

  # ArrayIsNullOrEmpty
  Assert ( ArrayIsNullOrEmpty (TestReturnEmptyArray1) );
  Assert ( ArrayIsNullOrEmpty (TestReturnEmptyArray2) );
  Assert ( ArrayIsNullOrEmpty (TestReturnEmptyArray3) );
  Assert ( ArrayIsNullOrEmpty (TestReturnNullArray  ) );
  Assert ( ArrayIsNullOrEmpty (@()                  ) );
  Assert ( ArrayIsNullOrEmpty ($null                ) );
  Assert ( -not (ArrayIsNullOrEmpty @("aa")) );

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

  [String[]] $a = @(); Assert ($a -is [String[]]); # empty array has expected type

  [String] $s = $null; Assert ($null -ne $s -and $s -eq "" -and $s -is [String]); # string is never null

  [Int32] $n = 0; $null | ForEach-Object{ $n++; }; Assert ($n -gt 0); # pipelining with $null iterates at least once
  [Int32] $n = 0; @()   | ForEach-Object{ $n++; }; Assert ($n -eq 0); # empty array not iterates to pipelining

  # compare non-null array with null must be done by preceeding null
  [String[]] $a = @()  ; Assert        ( -not ($a -eq $null) ); # If we would use AssertIsFalse then: Die Argumenttransformation für den Parameter "cond" kann nicht verarbeitet werden. Der Wert "System.Object[]" kann nicht in den Typ "System.Boolean" konvertiert werden. Boolesche Parameter akzeptieren nur boolesche Werte oder Zahlen wie "$True", "$False", "1" oder "0".
  [String[]] $a = @()  ; Assert        ( -not ($a -ne $null) ); # Is something as a know BUG.
  [String[]] $a = $null; Assert        ( $a -eq $null );
  [String[]] $a = $null; AssertIsFalse ( $a -ne $null );
  [String[]] $a = @()  ; AssertIsFalse ( $null -eq $a );
  [String[]] $a = @()  ; Assert        ( $null -ne $a );
  [String[]] $a = $null; AssertIsFalse ( $null -ne $a );
  [String[]] $a = $null; Assert        ( $null -eq $a );

  [String] $myvar = "abc"; Assert ( "$myvar".Length -eq 3 ); # within double quotes parameters are replaced.
  Assert ( '$anyUnknownVar'.Length -gt 0 ); # within single quotes parameters were not replaced.

  # String builtin functions
  Assert ((2 + 3) -eq 5);
  Assert ([Math]::Min(-5,-9) -eq -9);
  Assert ("xyz".SubString(1,0) -eq "");
  Assert (("abc" -split ",").Count -eq 1 -and "abc,".Split(",").Count -eq 2 -and ",abc".Split(",").Count -eq 2);

  # Own functions
  AssertNotEmpty "this-string-is-not-empty" "test fail msg";
  Assert         (StringIsNullOrEmpty $null);
  Assert         (StringIsNullOrEmpty "");
  AssertIsFalse  (StringIsNullOrEmpty "abc");
  AssertIsFalse  (StringIsNotEmpty $null);
  AssertIsFalse  (StringIsNotEmpty "");
  #Assert         (StringIsNullOrWhiteSpace $null);
  #Assert         (StringIsNullOrWhiteSpace "");
  Assert         (StringIsNullOrWhiteSpace " \t");
  #AssertIsFalse  (StringIsNullOrWhiteSpace "abc");
  Assert         (StringIsInt32                      "123"       );
  Assert         (StringIsInt64                      "9111222333");
  Assert         ((StringAsInt32                     "123"       ) -eq 123       );
  Assert         ((StringAsInt64                     "9111222333") -eq 9111222333);
  Assert         ((StringLeft                        "abc" 2) -eq "ab" );
  Assert         ((StringLeft                        "abc" 5) -eq "abc");
  Assert         ((StringRight                       "abc" 2) -eq "bc" );
  Assert         ((StringRight                       "abc" 5) -eq "abc");
  Assert         ((StringRemoveRightNr               "abc" 2) -eq "a"  );
  Assert         ((StringRemoveRightNr               "abc" 5) -eq ""   );
  Assert         ((StringPadRight                    "abc" 5) -eq "abc  ");
  Assert         ((StringPadRight                    "abc" 7 $true) -eq "`"abc`"  ");
  Assert         ((StringPadRight                    "abc" 5 $false "x") -eq "abcxx");
  Assert         ((StringSplitIntoLines              "abc`ndef")[0] -eq "abc");
  Assert         ((StringSplitIntoLines              "abc`ndef")[1] -eq "def");
  Assert         ((StringReplaceNewlines             "abc`ndef") -eq "abc def");
  Assert         ((StringSplitToArray                "," "abc,def,,ghi" $true)[2] -eq "ghi");
  Assert         ((StringReplaceEmptyByTwoQuotes     "abc") -eq "abc");
  Assert         ((StringReplaceEmptyByTwoQuotes     "") -eq "`"`"");
  Assert         ((StringRemoveLeft                  "abc" "ab") -eq "c");
  Assert         ((StringRemoveRight                 "abc" "bc") -eq "a");
  Assert         ((StringRemoveOptEnclosingDblQuotes "`"abc`"") -eq "abc");
  Assert         ((StringArrayInsertIndent           @("abc","def") 2)[1] -eq "  def");
  Assert         ((StringArrayDistinct               @("abc","def","abc")).Count -eq 2);
  Assert         ((StringArrayConcat                 @("abc","def")) -eq "abc`r`ndef");
  Assert         ((StringArrayIsEqual $null      @("a")                 ) -eq $false);
  Assert         ((StringArrayIsEqual $null      @("")                  ) -eq $false);
  Assert         ((StringArrayIsEqual @()        @("a")                 ) -eq $false);
  Assert         ((StringArrayIsEqual $null      @()                    ) -eq $true );
  Assert         ((StringArrayIsEqual @()        $null                  ) -eq $true );
  Assert         ((StringArrayIsEqual @()        @()                    ) -eq $true );
  Assert         ((StringArrayIsEqual @("")      @("")                  ) -eq $true );
  Assert         ((StringArrayIsEqual @("a")     @("a")                 ) -eq $true );
  Assert         ((StringArrayIsEqual @("a","b") @("a")                 ) -eq $false);
  Assert         ((StringArrayIsEqual @("a","b") @("a","b")             ) -eq $true );
  Assert         ((StringArrayIsEqual @("a","b") @("b","a")             ) -eq $false);
  Assert         ((StringArrayIsEqual @("a","b") @("a","B")             ) -eq $false);
  Assert         ((StringArrayIsEqual @("a","b") @("a","B") $false $true) -eq $true );
  Assert         ((StringArrayIsEqual @("a","b") @("b","a") $true       ) -eq $true );
  Assert         ((StringArrayIsEqual @("a","b") @("b","c") $true       ) -eq $false);

  # todo StringFromException
  # todo StringCommandLineToArray

  Assert         ((StringNormalizeAsVersion ""                        ) -eq ""                       );
  Assert         ((StringNormalizeAsVersion "a"                       ) -eq "a"                      );
  Assert         ((StringNormalizeAsVersion "0"                       ) -eq "00000"                  );
  Assert         ((StringNormalizeAsVersion "a.0"                     ) -eq "a.00000"                );
  Assert         ((StringNormalizeAsVersion " b"                      ) -eq ""                       );
  Assert         ((StringNormalizeAsVersion "1.2 DescrText"           ) -eq "00001.00002"            );
  Assert         ((StringNormalizeAsVersion "12.3.40"                 ) -eq "00012.00003.00040"      );
  Assert         ((StringNormalizeAsVersion "12.3.beta.40.5 DescrText") -eq "00012.00003.beta.00040" );
  Assert         ((StringNormalizeAsVersion "V12.3"                   ) -eq "00012.00003"            );
  Assert         ((StringNormalizeAsVersion "v12.3"                   ) -eq "00012.00003"            );
  Assert         (StringCompareVersionIsMinimum "V1.20" "V1.3");
  Assert         ((Int32Clip -5 0 9) -eq 0 -and (Int32Clip 5 0 9) -eq 5 -and (Int32Clip 15 0 9) -eq 9);

  # todo DateTimeAsStringIso
  # todo DateTimeNowAsStringIso
  # todo DateTimeNowAsStringIsoDate
  # todo DateTimeNowAsStringIsoMonth
  # todo DateTimeNowAsStringIsoInMinutes

  Assert         ((DateTimeFromStringIso "2011-12-31"             ) -eq (Get-Date -Date "2011-12-31 00:00:00"    ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59"       ) -eq (Get-Date -Date "2011-12-31 23:59:00"    ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59"    ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59."   ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59.0"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.0"  ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59.9"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.9"  ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59.99" ) -eq (Get-Date -Date "2011-12-31 23:59:59.99" ));
  Assert         ((DateTimeFromStringIso "2011-12-31 23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert         ((DateTimeFromStringIso "2011-12-31T23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));

  # todo ArrayIsNullOrEmpty

  Assert         ((ByteArraysAreEqual @()               @()              ) -eq $true );
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01,0xFF)) -eq $true );
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x02,0xFF)) -eq $false);
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01     )) -eq $false);

  Assert         ((FsEntryGetAbsolutePath "") -eq "" );
  Assert         ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir") -eq "Dir1\Dir2");
  Assert         ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir" $true) -eq ".\Dir1\Dir2");
  Assert         ((FsEntryMakeRelative "C:\MyDir" "C:\MyDir\") -eq ".");

  OutProgress "Test expecting exceptions on compare string-array with null on right side";
  [Boolean] $isOk = $false;
  try{
     # if compare argument null would be on the left side then it would work successful
    [String[]] $a99 = @();
     [Boolean] $r = ($a99 -eq $null); # Throws: Der Wert "System.Object[]" kann nicht in den Typ "System.Boolean" konvertiert werden. Boolesche Parameter akzeptieren nur boolesche Werte oder Zahlen wie "$True", "$False", "1" oder "0".
  }catch{ $isOk = $true; }
  #Assert $isOk;
  if( -not $isOk ){
    OutProgress "  IsInteractive=$(ScriptIsProbablyInteractive); Trap=Enabled; Note: Exception was not throwed and catch block not reached. We found out this happens in batch only for unknown reason. If runing interactive then works ok. Analyse it later.";
  }

  OutProgress "Test expecting exceptions on compare empty-array with null on right side";
  [Boolean] $isOk = $false;
  try{
     # if compare argument null would be on the left side then it would work successful
     [Boolean] $r = @() -eq $null; # Throws: Der Wert "System.Object[]" kann nicht in den Typ "System.Boolean" konvertiert werden. Boolesche Parameter akzeptieren nur boolesche Werte oder Zahlen wie "$True", "$False", "1" oder "0".
  }catch{ $isOk = $true; }
  #Assert $isOk;
  if( -not $isOk ){
    OutProgress "  IsInteractive=$(ScriptIsProbablyInteractive); Trap=Enabled; Note: Exception was not throwed and catch block not reached. We found out this happens in batch only for unknown reason. If runing interactive then works ok. Analyse it later.";
  }

  OutProgress "Test expecting exceptions on assigning string to boolean";
  [Boolean] $isOk = $false;
  try{
    [Boolean] $r = "anystring"; # ArgumentTransformationMetadataException: Cannot convert value "System.String" to type "System.Boolean". Boolean parameters accept only Boolean values and numbers, such as $True, $False, 1 or 0.
  }catch{ $isOk = $true; }
  #Assert $isOk;
  if( -not $isOk ){
    OutProgress "  IsInteractive=$(ScriptIsProbablyInteractive); Trap=Enabled; Note: Exception was not throwed and catch block not reached. We found out this happens in batch only for unknown reason. If runing interactive then works ok. Analyse it later.";
  }

  Assert         ((ToolVs2019UserFolderGetLatestUsed -eq "") -or (ToolVs2019UserFolderGetLatestUsed.Contains("\\AppData\\Local\\Microsoft\\VisualStudio\\16.0")));

  OutProgress "ToolWin10PackageGetState of OpenSSH.Client: $(ToolWin10PackageGetState "OpenSSH.Client")"
  # ToolWin10PackageInstall "OpenSSH.Client"
  # ToolWin10PackageDeinstall "OpenSSH.Client"

  # OutProgress "Test when ignoring traps";
  # for later:
  # trap [Exception] { OutProgress "Ignored trap: $_"; continue; } # temporary ignore
  # # Count is for all classes defined when exceptions are ignored but otherwise it throws
  # Assert ( ($false   ).Count -eq 1 ); # Throws: Die Eigenschaft "Count" wurde für dieses Objekt nicht gefunden. Vergewissern Sie sich, dass die Eigenschaft vorhanden ist.
  # Assert ( (123      ).Count -eq 1 );
  # Assert ( ("ab"     ).Count -eq 1 );
  # Assert ( ($null    ).Count -eq 0 );
  # trap [Exception] { StdErrHandleExc $_; break; } # restore

  OutSuccess "Ok, done.";
}

MnLibCommonSelfTest;
StdInReadLine "Press enter to exit.";
