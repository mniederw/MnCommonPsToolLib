# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function MnLibCommonSelfTest(){ # perform some tests
  OutInfo "MnCommonPsToolLibUnitTest";
  [String] $myvar = "abc"; Assert ( "$myvar".Length -eq 3 ); # within double quotes parameters are replaced.
  Assert ( '$anyUnknownVar'.Length -gt 0 ); # within single quotes parameters were not replaced.
  Assert ((2 + 3) -eq 5);
  Assert ([Math]::Min(-5,-9) -eq -9);
  Assert ("xyz".substring(1,0) -eq "");
  Assert ((DateTimeFromStringIso "2011-12-31"             ) -eq (Get-Date -Date "2011-12-31 00:00:00"    ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59"       ) -eq (Get-Date -Date "2011-12-31 23:59:00"    ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59"    ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59."   ) -eq (Get-Date -Date "2011-12-31 23:59:59"    ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59.0"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.0"  ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59.9"  ) -eq (Get-Date -Date "2011-12-31 23:59:59.9"  ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59.99" ) -eq (Get-Date -Date "2011-12-31 23:59:59.99" ));
  Assert ((DateTimeFromStringIso "2011-12-31 23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert ((DateTimeFromStringIso "2011-12-31T23:59:59.999") -eq (Get-Date -Date "2011-12-31 23:59:59.999"));
  Assert (("abc" -split ",").Count -eq 1 -and "abc,".Split(",").Count -eq 2 -and ",abc".Split(",").Count -eq 2);
  Assert ((ByteArraysAreEqual @()               @()              ) -eq $true );
  Assert ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01,0xFF)) -eq $true );
  Assert ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x02,0xFF)) -eq $false);
  Assert ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01     )) -eq $false);
  Assert ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir") -eq "Dir1\Dir2");
  Assert ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir" $true) -eq ".\Dir1\Dir2");
  Assert ((FsEntryMakeRelative "C:\MyDir" "C:\MyDir\") -eq ".");
  Assert ((Int32Clip -5 0 9) -eq 0 -and (Int32Clip 5 0 9) -eq 5 -and (Int32Clip 15 0 9) -eq 9);
  Assert ((StringRemoveRight "abc" "c") -eq "ab");
  Assert ((StringLeft          "abc" 5) -eq "abc" -and (StringLeft          "abc" 2) -eq "ab");
  Assert ((StringRight         "abc" 5) -eq "abc" -and (StringRight         "abc" 2) -eq "bc");
  Assert ((StringRemoveRightNr "abc" 5) -eq ""    -and (StringRemoveRightNr "abc" 1) -eq "ab");
  Assert (( StringArrayIsEqual $null      @("a")                 ) -eq $false);
  Assert (( StringArrayIsEqual $null      @("")                  ) -eq $false);
  Assert (( StringArrayIsEqual @()        @("a")                 ) -eq $false);
  Assert (( StringArrayIsEqual $null      @()                    ) -eq $true );
  Assert (( StringArrayIsEqual @()        $null                  ) -eq $true );
  Assert (( StringArrayIsEqual @()        @()                    ) -eq $true );
  Assert (( StringArrayIsEqual @("")      @("")                  ) -eq $true );
  Assert (( StringArrayIsEqual @("a")     @("a")                 ) -eq $true );
  Assert (( StringArrayIsEqual @("a","b") @("a")                 ) -eq $false);
  Assert (( StringArrayIsEqual @("a","b") @("a","b")             ) -eq $true );
  Assert (( StringArrayIsEqual @("a","b") @("b","a")             ) -eq $false);
  Assert (( StringArrayIsEqual @("a","b") @("a","B")             ) -eq $false);
  Assert (( StringArrayIsEqual @("a","b") @("a","B") $false $true) -eq $true );
  Assert (( StringArrayIsEqual @("a","b") @("b","a") $true       ) -eq $true );
  Assert (( StringArrayIsEqual @("a","b") @("b","c") $true       ) -eq $false);
  AssertNotEmpty "this-string-is-not-empty" "test fail msg";
  Assert ((StringNormalizeAsVersion ""                        ) -eq ""                       );
  Assert ((StringNormalizeAsVersion "a"                       ) -eq "a"                      ); 
  Assert ((StringNormalizeAsVersion "0"                       ) -eq "00000"                  );
  Assert ((StringNormalizeAsVersion "a.0"                     ) -eq "a.00000"                );
  Assert ((StringNormalizeAsVersion " b"                      ) -eq ""                       );
  Assert ((StringNormalizeAsVersion "1.2 DescrText"           ) -eq "00001.00002"            );
  Assert ((StringNormalizeAsVersion "12.3.40"                 ) -eq "00012.00003.00040"      );
  Assert ((StringNormalizeAsVersion "12.3.beta.40.5 DescrText") -eq "00012.00003.beta.00040" );
  Assert ((StringNormalizeAsVersion "V12.3"                   ) -eq "00012.00003"            );
  Assert ((StringNormalizeAsVersion "v12.3"                   ) -eq "00012.00003"            );
  Assert (StringCompareVersionIsMinimum "V1.20" "V1.3");
  OutSuccess "Ok, done.";
}

MnLibCommonSelfTest;
StdInReadLine "Press enter to exit.";
