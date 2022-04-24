# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Sql(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   SqlGetCmdExe                         (){ # old style. It is recommended to use: SqlPerformFile
  #   SqlRunScriptFile                     ( [String] $sqlserver, [String] $sqlfile, [String] $outFile, [Boolean] $continueOnErr ){ # old style. It is recommended to use: SqlPerformFile
  #   SqlPerformFile                       ( [String] $connectionString, [String] $sqlFile, [String] $logFileToAppend = "", [Int32] $queryTimeoutInSec = 0, [Boolean] $showPrint = $true, [Boolean] $showRows = $true){
  #                                          # Print are given out in yellow by internal verbose option; rows are currently given out only in a simple csv style without headers.
  #                                          # ConnectString example: "Server=myInstance;Database=TempDB;Integrated Security=True;"  queryTimeoutInSec: 1..65535,0=endless;
  #   SqlPerformCmd                        ( [String] $connectionString, [String] $cmd, [Boolean] $showPrint = $false, [Int32] $queryTimeoutInSec = 0 ){
  #                                          # ConnectString example: "Server=myInstance;Database=TempDB;Integrated Security=True;"  queryTimeoutInSec: 1..65535, 0=endless;
  #                                          # cmd: semicolon separated commands, do not use GO, escape doublequotation marks, use bracketed identifiers [MyTable] instead of doublequotes.
  #   SqlGenerateFullDbSchemaFiles         ( [String] $logicalEnv, [String] $dbInstanceServerName, [String] $dbName, [String] $targetRootDir,
  #                                            [Boolean] $errorAsWarning = $false, [Boolean] $inclIfNotExists = $false,
  #                                            [Boolean] $inclDropStmts = $false, [Boolean] $inclDataAsInsertStmts = $false ){
  #                                          # Create all creation files for a specified sql server database with current user to a specified target directory which must not exists.
  #                                          # This includes tables (including unique indexes), indexes (non-unique), views, stored procedures, functions, roles, schemas, db-triggers and table-Triggers.
  #                                          # If a stored procedure, a function or a trigger is encrypted then a single line is put to its sql file indicating encrypted code cannot be dumped.
  #                                          # It creates file "DbInfo.dbname.out" with some db infos. In case of an error it creates file "DbInfo.dbname.err".
  #                                          # ex: SqlGenerateFullDbSchemaFiles "MyLogicEnvironment" "MySqlInstance" "MyDbName" "$env:TEMP\DumpFullDbSchemas"
}
Test_Sql;
