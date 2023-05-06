#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Stream(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
# StreamAllProperties                  (){ $input | Select-Object *; }
# StreamAllPropertyTypes               (){ $input | Get-Member -Type Property; }
# StreamFilterWhitespaceLines          (){ $input | Where-Object{ StringIsFilled $_ }; }
# StreamToNull                         (){ $input | Out-Null; }
# StreamToString                       (){ $input | Out-String -Width 999999999; }
# StreamToStringDelEmptyLeadAndTrLines (){ $input | Out-String -Width 999999999 | ForEach-Object{ $_ -replace "[ \f\t\v]]+\r\n","\r\n" -replace "^(\r\n)+","" -replace "(\r\n)+$","" }; }
# StreamToGridView                     (){ $input | Out-GridView -Title "TableData"; }
# StreamToCsvStrings                   (){ $input | ConvertTo-Csv -NoTypeInformation; }
#                                        # Note: For a simple string array as ex: @("one","two")|StreamToCsvStrings  it results with 3 lines "Length","3","3".
# StreamToJsonString                   (){ $input | ConvertTo-Json -Depth 100; }
# StreamToJsonCompressedString         (){ $input | ConvertTo-Json -Depth 100 -Compress; }
# StreamToXmlString                    (){ $input | ConvertTo-Xml -Depth 999999999 -As String -NoTypeInformation; }
# StreamToHtmlTableStrings             (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As Table; }
# StreamToHtmlListStrings              (){ $input | ConvertTo-Html -Title "TableData" -Body $null -As List; }
# StreamToListString                   (){ $input | Format-List -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
# StreamToFirstPropMultiColumnString   (){ $input | Format-Wide -AutoSize -ShowError | StreamToStringDelEmptyLeadAndTrLines; }
# StreamToCsvFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8BOM" ){
#                                        # If overwrite is false then nothing done if target already exists.
#                                        $input | Export-Csv -Force:$overwrite -NoClobber:$(-not $overwrite) -NoTypeInformation -Encoding $encoding -Path (FsEntryEsc $file); }
# StreamToXmlFile                      ( [String] $file, [Boolean] $overwrite = $false, [String] $encoding = "UTF8BOM" ){
#                                        # If overwrite is false then nothing done if target already exists.
#                                        $input | Export-Clixml -Force:$overwrite -NoClobber:$(-not $overwrite) -Depth 999999999 -Encoding $encoding -Path (FsEntryEsc $file); }
# StreamToDataRowsString               ( [String[]] $propertyNames = @() ){ # no header, only rows.
#                                        if( $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); }
#                                        $input | Format-Table -Wrap -Force -autosize -HideTableHeaders $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
# StreamToTableString                  ( [String[]] $propertyNames = @() ){
#                                        # Note: For a simple string array as ex: @("one","two")|StreamToTableString  it results with 4 lines "Length","------","     3","     3".
#                                        if( $propertyNames.Count -eq 0 ){ $propertyNames = @("*"); }
#                                        $input | Format-Table -Wrap -Force -autosize $propertyNames | StreamToStringDelEmptyLeadAndTrLines; }
# StreamToFile                         ( [String] $file, [Boolean] $overwrite = $true, [String] $encoding = "UTF8BOM" ){
#                                        # Will create path of file. overwrite does ignore readonly attribute.
#                                        OutProgress "WriteFile $file"; FsEntryCreateParentDir $file;
#                                        $input | Out-File -Force -NoClobber:$(-not $overwrite) -Encoding $encoding -LiteralPath $file; }
# StreamFromCsvStrings                 ( [Char] $delimiter = ',' ){ $input | ConvertFrom-Csv -Delimiter $delimiter; }
}
Test_Stream;
