#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Sql(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
  # TODO: SqlGetCmdExe                 ()
  # TODO: SqlRunScriptFile             ( [String] $sqlserver, [String] $sqlfile, [String] $outFile, [Boolean] $continueOnErr )
  # TODO: SqlPerformFile               ( [String] $connectionString, [String] $sqlFile, [String] $logFileToAppend = "", [Int32] $queryTimeoutInSec = 0, [Boolean] $showPrint = $true, [Boolean] $showRows = $true)
  # TODO: SqlPerformCmd                ( [String] $connectionString, [String] $cmd, [Boolean] $showPrint = $false, [Int32] $queryTimeoutInSec = 0 )
  # TODO: SqlGenerateFullDbSchemaFiles ( [String] $logicalEnv, [String] $dbInstanceServerName, [String] $dbName, [String] $targetRootDir,
  #                                    [Boolean] $errorAsWarning = $false, [Boolean] $inclIfNotExists = $false,
  #                                    [Boolean] $inclDropStmts = $false, [Boolean] $inclDataAsInsertStmts = $false )
  # if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){
}
UnitTest_Win_Sql;
