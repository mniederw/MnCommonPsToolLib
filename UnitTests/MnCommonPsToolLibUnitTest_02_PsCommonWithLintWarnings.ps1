#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_PsCommonWithLintWarnings(){
  OutProgress (ScriptGetCurrentFuncName);
  # compare non-null array with null must be done by putting null to the left side of the comparison operator
  #   Note: The github Lint-with-PSScriptAnalyser will output warning: PSPossibleIncorrectComparisonWithNull
  [String[]] $a = @()  ; Assert        ( -not ($a -eq $null) ); # If we would use AssertIsFalse then: Die Argumenttransformation für den Parameter "cond" kann nicht verarbeitet werden. Der Wert "System.Object[]" kann nicht in den Typ "System.Boolean" konvertiert werden. Boolesche Parameter akzeptieren nur boolesche Werte oder Zahlen wie "$True", "$False", "1" oder "0".
  [String[]] $a = @()  ; Assert        ( -not ($a -ne $null) ); # Is something as a know BUG.
  [String[]] $a = $null; Assert        ( $a -eq $null );
  [String[]] $a = $null; AssertIsFalse ( $a -ne $null );
  #
  OutVerbose "Test expecting exceptions on compare string-array with null on right side";
  [Boolean] $isOk = $false;
  try{
     # if compare argument null would be on the left side then it would work successful
     #   Note: The github Lint-with-PSScriptAnalyser will output warning: PSPossibleIncorrectComparisonWithNull
     [String[]] $a = @();
     [Boolean] $r = ($a -eq $null); # Throws: Der Wert "System.Object[]" kann nicht in den Typ "System.Boolean" konvertiert werden. Boolesche Parameter akzeptieren nur boolesche Werte oder Zahlen wie "$True", "$False", "1" oder "0".
  }catch{ $isOk = $true; }
  if( -not $isOk ){
    OutVerbose "  IsInteractive=$(ScriptIsProbablyInteractive); Trap=Enabled; Note: Exception was not throwed and catch block not reached. We found out this happens in batch only for unknown reason. If runing interactive then works ok. Analyse it later.";
  }
  #
  OutVerbose "Test expecting exceptions on compare empty-array with null on right side";
  [Boolean] $isOk = $false;
  try{
     # if compare argument null would be on the left side then it would work successful
     [Boolean] $r = @() -eq $null; # Throws: Der Wert "System.Object[]" kann nicht in den Typ "System.Boolean" konvertiert werden. Boolesche Parameter akzeptieren nur boolesche Werte oder Zahlen wie "$True", "$False", "1" oder "0".
  }catch{ $isOk = $true; }
  if( -not $isOk ){
    OutVerbose "  IsInteractive=$(ScriptIsProbablyInteractive); Trap=Enabled; Note: Exception was not throwed and catch block not reached. We found out this happens in batch only for unknown reason. If runing interactive then works ok. Analyse it later.";
  }
}
UnitTest_PsCommonWithLintWarnings;
