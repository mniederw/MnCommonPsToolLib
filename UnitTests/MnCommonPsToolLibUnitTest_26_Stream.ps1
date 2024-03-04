#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Stream(){
  OutProgress (ScriptGetCurrentFuncName);
  [Object] $obj = @("ab","","cd");
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
  OutProgress "StreamToFirstPropMultiColumnString"   ; $obj | StreamToFirstPropMultiColumnString ;
  OutProgress "StreamToDataRowsString"               ; $obj | StreamToDataRowsString ;
  OutProgress "StreamToTableString"                  ; $obj | StreamToTableString ;
  OutProgress "StreamFromCsvStrings"                 ; $obj | StreamFromCsvStrings ;
  if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){  OutProgress "StreamToGridView"                     ; $obj | StreamToGridView ; }
  $f = FileGetTempFile;
  OutProgress "StreamToCsvFile"                      ; $obj | StreamToCsvFile $f $true;
  OutProgress "StreamToXmlFile"                      ; $obj | StreamToXmlFile $f $true ;
  OutProgress "StreamToFile"                         ; $obj | StreamToFile $f $true;
  FileDelTempFile $f;
}
UnitTest_Stream;
