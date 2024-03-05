#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_String(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert         (StringIsNullOrEmpty                $null);
  Assert         (StringIsNullOrEmpty                "");
  AssertIsFalse  (StringIsNullOrEmpty                "abc");
  AssertIsFalse  (StringIsNotEmpty                   $null);
  AssertIsFalse  (StringIsNotEmpty                   "");
  AssertIsFalse  (StringIsFilled                     $null);
  AssertIsFalse  (StringIsFilled                     "");
  AssertIsFalse  (StringIsFilled                     " `r");
  Assert         (StringIsFilled                     "abc");
  Assert         (StringIsInt32                      "123"       );
  Assert         (StringIsInt64                      "9111222333");
  Assert         ((StringAsInt32                     "123"       )                 -eq 123         );
  Assert         ((StringAsInt64                     "9111222333")                 -eq 9111222333  );
  Assert         ((StringLeft                        "abc" 2)                      -eq "ab"        );
  Assert         ((StringLeft                        "abc" 5)                      -eq "abc"       );
  Assert         ((StringRight                       "abc" 2)                      -eq "bc"        );
  Assert         ((StringRight                       "abc" 5)                      -eq "abc"       );
  Assert         ((StringRemoveRightNr               "abc" 2)                      -eq "a"         );
  Assert         ((StringRemoveRightNr               "abc" 5)                      -eq ""          );
  Assert         ((StringRemoveLeftNr                "abc" 2)                      -eq "c"         );
  Assert         ((StringPadRight                    "abc" 5)                      -eq "abc  "     );
  Assert         ((StringPadRight                    "abc" 7 $true)                -eq "`"abc`"  " );
  Assert         ((StringPadRight                    "abc" 5 $false "x")           -eq "abcxx"     );
  Assert         ((StringSplitIntoLines              "abc`ndef")[0]                -eq "abc"       );
  Assert         ((StringSplitIntoLines              "abc`ndef")[1]                -eq "def"       );
  Assert         ((StringReplaceNewlines             "abc`ndef")                   -eq "abc def"   );
  Assert         ((StringSplitToArray                ","  "abc,def,,ghi" $true)[2] -eq "ghi"       );
  Assert         ((StringSplitToArray                ","  "ab,de")[0]              -eq "ab"        );
  Assert         ((StringSplitToArray                "xy" "abcde")[0]              -eq "a"         ); # note: returns string which is a know ps bug.
  Assert         (([String[]](StringSplitToArray     "xy" "abcde"))[0]             -eq "abcde"     );
  Assert         (([String[]](StringSplitToArray     "C"  "abcde"))[0]             -eq "abcde"     );
  Assert         ((StringSplitToArray                ","  "ab,,d"       ).Count    -eq 2           );
  Assert         ((StringSplitToArray                ","  "ab,,d" $false).Count    -eq 3           );
  Assert         ((StringReplaceEmptyByTwoQuotes     "abc")                        -eq "abc"       );
  Assert         ((StringReplaceEmptyByTwoQuotes     "")                           -eq "`"`""      );
  Assert         ((StringRemoveLeft                  "abc" "ab")                   -eq "c"         );
  Assert         ((StringRemoveRight                 "abc" "bc")                   -eq "a"         );
  Assert         ((StringRemoveOptEnclosingDblQuotes "`"abc`"")                    -eq "abc"       );
  Assert         ((StringArrayInsertIndent           @("abc","def") 2)[1]          -eq "  def"     );
  Assert         ((StringMakeNonNull                 $null)                        -eq ""          );
  Assert         ((StringExistsInStringArray         "Ab" @("ab","cd"))            -eq $false      );
  Assert         ((StringExistsInStringArray         "Ab" @("Ab","cd"))            -eq $true       );
  Assert         ((StringArrayInsertIndent           @("ab","cd") 2)[0]            -eq "  ab"      );
  Assert         ((StringArrayDistinct               @("abc","def","abc")).Count   -eq 2           );
  Assert         ((StringArrayConcat                 @("abc","def"))               -eq ("abc"+[Environment]::NewLine+"def"));
  Assert         ((StringArrayContains               @("a","b") "a")               -eq $true       );
  Assert         ((StringArrayContains               @("a","b") "A")               -eq $false      );
  Assert         ((StringArrayContains               @("a","b") "x")               -eq $false      );
  Assert         ((StringArrayIsEqual                $null      @("a")                 ) -eq $false);
  Assert         ((StringArrayIsEqual                $null      @("")                  ) -eq $false);
  Assert         ((StringArrayIsEqual                @()        @("a")                 ) -eq $false);
  Assert         ((StringArrayIsEqual                $null      @()                    ) -eq $true );
  Assert         ((StringArrayIsEqual                @()        $null                  ) -eq $true );
  Assert         ((StringArrayIsEqual                @()        @()                    ) -eq $true );
  Assert         ((StringArrayIsEqual                @("")      @("")                  ) -eq $true );
  Assert         ((StringArrayIsEqual                @("a")     @("a")                 ) -eq $true );
  Assert         ((StringArrayIsEqual                @("a","b") @("a")                 ) -eq $false);
  Assert         ((StringArrayIsEqual                @("a","b") @("a","b")             ) -eq $true );
  Assert         ((StringArrayIsEqual                @("a","b") @("b","a")             ) -eq $false);
  Assert         ((StringArrayIsEqual                @("a","b") @("a","B")             ) -eq $false);
  Assert         ((StringArrayIsEqual                @("a","b") @("a","B") $false $true) -eq $true );
  Assert         ((StringArrayIsEqual                @("a","b") @("b","a") $true       ) -eq $true );
  Assert         ((StringArrayIsEqual                @("a","b") @("b","c") $true       ) -eq $false);
  Assert         ([String](StringArrayDblQuoteItems  @("a","b")                        ) -eq [String]@("`"a`"","`"b`""));
  Assert         ((StringNormalizeAsVersion          ""                       ) -eq ""                       );
  Assert         ((StringNormalizeAsVersion          "a"                      ) -eq "a"                      );
  Assert         ((StringNormalizeAsVersion          "0"                      ) -eq "00000"                  );
  Assert         ((StringNormalizeAsVersion          "a.0"                    ) -eq "a.00000"                );
  Assert         ((StringNormalizeAsVersion          " b"                     ) -eq ""                       );
  Assert         ((StringNormalizeAsVersion          "1.2 DescrText"          ) -eq "00001.00002"            );
  Assert         ((StringNormalizeAsVersion          "12.3.40"                ) -eq "00012.00003.00040"      );
  Assert         ((StringNormalizeAsVersion          "12.3.beta.40.5 DescrTxt") -eq "00012.00003.beta.00040" );
  Assert         ((StringNormalizeAsVersion          "V12.3"                  ) -eq "00012.00003"            );
  Assert         ((StringNormalizeAsVersion          "v12.3"                  ) -eq "00012.00003"            );
  Assert         ((StringCompareVersionIsMinimum     "V1.20" "V1.3")            -eq $true);
  Assert         ((StringCompareVersionIsMinimum     "V1.3"  "V1.3")            -eq $true);
  Assert         ((StringCompareVersionIsMinimum     "V1.1"  "V1.3")            -eq $false);
  #
  function CreateExcWithData() { $e = New-Object -TypeName Exception -ArgumentList "Test"; $e.Data.Add("DataKey1","DataValue1"); return $e; }
  Assert         (StringFromException (CreateExcWithData)).Contains("DataValue1");
  #
  try{ throw [Exception] "Test"; }catch{ Assert (StringFromErrorRecord $_).StartsWith("Exception: Test"); }
  Assert         ((StringCommandLineToArray "p1 `"p2 with spaces and contains `"`" doublequotes`"")[1] -eq "p2 with spaces and contains `" doublequotes");
}
UnitTest_String;
