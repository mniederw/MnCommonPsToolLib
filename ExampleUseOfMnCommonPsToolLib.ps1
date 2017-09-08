# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; 
Set-StrictMode -Version Latest; 
trap [Exception] { StdErrHandleExc $_; break; }



function TestParallel {
  (0..12) |ForEachParallel { echo "Nr: $_"; sleep 1; }
  (0..5) | ForEachParallel -MaxThreads 2 { echo "Nr: $_"; sleep ((Get-Random -Minimum 0 -Maximum 15) / 10); };
}

function TestJobs {
  OutInfo "Test asynchronous jobs";
  $job = JobStart { param( $s ); return [String] $s; } "my argument";
  Sleep 1;
  [String] $res = JobWaitForEnd $job.Id;
  OutProgress "Output: '$res'";
  Assert ($res -eq "my argument");
}

function MnLibCommonSelfTest{
  Assert ((2 + 3) -eq 5);
  Assert ([Math]::Min(-5,-9) -eq -9);
  Assert ("xyz".substring(1,0) -eq "");
  Assert ((DateTimeFromStringAsFormat "2011-12-31"         ) -eq (Get-Date -Date "2011-12-31 00:00:00"));
  Assert ((DateTimeFromStringAsFormat "2011-12-31_23_59"   ) -eq (Get-Date -Date "2011-12-31 23:59:00"));
  Assert ((DateTimeFromStringAsFormat "2011-12-31_23_59_59") -eq (Get-Date -Date "2011-12-31 23:59:59"));
  Assert (("abc" -split ",").Count -eq 1 -and "abc,".Split(",").Count -eq 2 -and ",abc".Split(",").Count -eq 2);
}


OutInfo "hello world";
OutProgress "working";
TestJobs;
TestParallel;
MnLibCommonSelfTest;
StdInReadLine "Press enter to exit.";
