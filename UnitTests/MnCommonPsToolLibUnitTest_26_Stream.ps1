#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Stream(){
  OutProgress (ScriptGetCurrentFuncName);
  [String] $nl = [Environment]::NewLine;
  [String] $nlInPs5 = switch(ProcessIsLesserEqualPs5){($true){"$nl"}($false){""}};
  [Object] $obj = @(
      [PSCustomObject]@{ Name = "John"; Age = 42 }
    , [PSCustomObject]@{ Name = "Ägid"; Age = 40 }
  );
  $f = FileGetTempFile;
  #
  OutProgress "StreamAllProperties"                  ; $obj | StreamAllProperties ;
  OutProgress "StreamAllPropertyTypes"               ; $obj | StreamAllPropertyTypes ;
  OutProgress "StreamFilterWhitespaceLines"          ; $obj | StreamFilterWhitespaceLines ;
  OutProgress "StreamToNull"                         ; $obj | StreamToNull ;
  OutProgress "StreamToString"                       ; $obj | StreamToString ;
  OutProgress "StreamToStringDelEmptyLeadAndTrLines" ; $obj | StreamToStringDelEmptyLeadAndTrLines ;
  OutProgress "StreamToCsvStrings"                   ; $obj | StreamToCsvStrings ;
  OutProgress "StreamToJsonString"                   ; $obj | StreamToJsonString ;
  OutProgress "StreamToJsonCompressedString"         ; $obj | StreamToJsonCompressedString ;
  OutProgress "StreamToXmlString"                    ; $obj | StreamToXmlString ;
  OutProgress "StreamToHtmlTableStrings"             ; $obj | StreamToHtmlTableStrings ;
  OutProgress "StreamToHtmlListStrings"              ; $obj | StreamToHtmlListStrings ;
  OutProgress "StreamToListString"                   ; $obj | StreamToListString ;
  # TODO: Seems to run endless:   OutProgress "StreamToFirstPropMultiColumnString"   ; $obj | StreamToFirstPropMultiColumnString ;
  OutProgress "StreamToDataRowsString"               ; $obj | StreamToDataRowsString ;
  OutProgress "StreamToTableString"                  ; $obj | StreamToTableString ;
    # TODO @()            | StreamToTableString *;
    # TODO @( "aa", "bb") | StreamToTableString *;
    # TODO @( "")         | StreamToTableString *;
    # TODO ""             | StreamToTableString *;
    # TODO $null          | StreamToTableString *;
    # TODO Get-Process    | Select-Object -First 2 | StreamToTableString Id,ProcessName;
  OutProgress "StreamFromCsvStrings"                 ; $obj | StreamFromCsvStrings ;
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){  OutProgress "StreamToGridView"                     ; $obj | StreamToGridView ; }
  if( -not (ProcessIsLesserEqualPs5) ){ # TODO: later remove this if. Used as long as we get: FileWriteFromLines with UTF8 (NO-BOM) on PS5.1 or lower is not yet implemented.
    OutProgress "StreamToCsvFile"                      ; $obj | StreamToCsvFile $f $true; # "UTF8BOM"
      Assert ((FileReadContentAsString $f "Default") -eq "`"Name`",`"Age`"$nl`"John`",`"42`"$nl`"Ägid`",`"40`"$nl");
    OutProgress "StreamToCsvFile"                      ; $obj | StreamToCsvFile $f $true "UTF8BOM" -forceLf:$true;
      Assert ((FileReadContentAsString $f "Default") -eq "`"Name`",`"Age`"`n`"John`",`"42`"`n`"Ägid`",`"40`"`n");
  }
  OutProgress "StreamToXmlFile"                      ; $obj | StreamToXmlFile $f $true; # "UTF8BOM"
    Assert ((FileReadContentAsString $f "Default") -eq "<Objs Version=`"1.1.0.1`" xmlns=`"http://schemas.microsoft.com/powershell/2004/04`">$nl  <Obj RefId=`"0`">$nl    <TN RefId=`"0`">$nl      <T>System.Management.Automation.PSCustomObject</T>$nl      <T>System.Object</T>$nl    </TN>$nl    <MS>$nl      <S N=`"Name`">John</S>$nl      <I32 N=`"Age`">42</I32>$nl    </MS>$nl  </Obj>$nl  <Obj RefId=`"1`">$nl    <TNRef RefId=`"0`" />$nl    <MS>$nl      <S N=`"Name`">Ägid</S>$nl      <I32 N=`"Age`">40</I32>$nl    </MS>$nl  </Obj>$nl</Objs>" );
  OutProgress "StreamToFile"                         ; $obj | StreamToFile    $f $true; # "UTF8BOM"
    Assert ((FileReadContentAsString $f "Default") -eq "${nl}Name Age$nl---- ---${nl}John  42${nl}Ägid  40$nl$nl$nlInPs5");
  #
  FileDelTempFile $f;
}
UnitTest_Stream;
