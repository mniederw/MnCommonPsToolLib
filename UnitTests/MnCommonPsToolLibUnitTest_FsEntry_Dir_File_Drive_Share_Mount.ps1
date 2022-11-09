#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_FsEntry_Dir_File_Drive_Share_Mount_PsDrive(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert         ((FsEntryGetAbsolutePath "") -eq "" );
  Assert         ((FsEntryMakeRelative "$HOME/MyDir/Dir1/Dir2" "$HOME/MyDir"      ).Replace("\","/") -eq   "Dir1/Dir2");
  Assert         ((FsEntryMakeRelative "$HOME/MyDir/Dir1/Dir2" "$HOME/MyDir" $true).Replace("\","/") -eq "./Dir1/Dir2");
  Assert         ((FsEntryMakeRelative "$HOME/MyDir"           "$HOME/MyDir/"     ) -eq ".");
  # TODO:
  #   DirSep                               ()
  #   FsEntryEsc                           ( [String] $fsentry )
  #   FsEntryGetAbsolutePath               ( [String] $fsEntry )
  #   FsEntryGetUncShare                   ( [String] $fsEntry )
  #   FsEntryMakeValidFileName             ( [String] $str )
  #   FsEntryMakeRelative                  ( [String] $fsEntry, [String] $belowDir, [Boolean] $prefixWithDotDir = $false )
  #   FsEntryHasTrailingDirSep             ( [String] $fsEntry )
  #   FsEntryRemoveTrailingDirSep          ( [String] $fsEntry )
  #   FsEntryMakeTrailingDirSep            ( [String] $fsEntry
  #   FsEntryJoinRelativePatterns          ( [String] $rootDir [String[]] $relativeFsEntriesPatternsSemicolonSeparated )
  #   FsEntryGetFileNameWithoutExt         ( [String] $fsEntry)
  #   FsEntryGetFileName                   ( [String] $fsEntry)
  #   FsEntryGetFileExtension              ( [String] $fsEntry
  #   FsEntryGetDrive                      ( [String] $fsEntry
  #   FsEntryIsDir                         ( [String] $fsEntry
  #   FsEntryGetParentDir                  ( [String] $fsEntry
  #   FsEntryExists                        ( [String] $fsEntry
  #   FsEntryNotExists                     ( [String] $fsEntry
  #   FsEntryAssertExists                  ( [String] $fsEntry,[String] $text = "Assertion failed" )
  #   FsEntryAssertNotExists               ( [String] $fsEntry [String] $text = "Assertion failed" )
  #   FsEntryGetLastModified               ( [String] $fsEntry )
  #   FsEntryNotExistsOrIsOlderThanNrDays  ( [String] $fsEntry, [Int32] $maxAgeInDays, [Int32] $maxAgeInHours = 0, [Int32] $maxAgeInMinutes = 0 ){
  #   FsEntryNotExistsOrIsOlderThanBeginOf ( [String] $fsEntry, [String] $beginOf ){ # more see: DateTimeGetBeginOf
  #   FsEntryExistsAndIsNewerThanBeginOf   ( [String] $fsEntry, [String] $beginOf ){ # more see: DateTimeGetBeginOf
  #   FsEntrySetAttributeReadOnly          ( [String] $fsEntry, [Boolean] $val ){ # use false for $val to make file writable
  #   FsEntryFindFlatSingleByPattern       ( [String] $fsEntryPattern, [Boolean] $allowNotFound = $false ){
  #   FsEntryFsInfoFullNameDirWithBackSlash( [System.IO.FileSystemInfo] $fsInfo ){ return [String] ($fsInfo.FullName+$(switch($fsInfo.PSIsContainer){($true){$(DirSep)}default{""}})); }
  #   FsEntryListAsFileSystemInfo          ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
  #   FsEntryListAsStringArray             ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
  #   FsEntryDelete                        ( [String] $fsEntry ){
  #   FsEntryDeleteToRecycleBin            ( [String] $fsEntry ){
  #   FsEntryRename                        ( [String] $fsEntryFrom, [String] $fsEntryTo ){
  #   FsEntryCreateSymLink                 ( [String] $newSymLink, [String] $fsEntryOrigin ){
  #   FsEntryCreateHardLink                ( [String] $newHardLink, [String] $fsEntryOrigin ){
  #   FsEntryCreateDirSymLink              ( [String] $symLinkDir, [String] $symLinkOriginDir ){
  #   FsEntryReportMeasureInfo             ( [String] $fsEntry ){ # Must exists, works recursive.
  #   FsEntryCreateParentDir               ( [String] $fsEntry ){ [String] $dir = FsEntryGetParentDir $fsEntry; DirCreate $dir; }
  #   FsEntryMoveByPatternToDir            ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $showProgress = $false ){ # Target dir must exists. pattern is non-recursive scanned.
  #   FsEntryCopyByPatternByOverwrite      ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $continueOnErr = $false ){
  #   FsEntryFindNotExistingVersionedName  ( [String] $fsEntry, [String] $ext = ".bck", [Int32] $maxNr = 9999 ){ # return ex: "C:\Dir\MyName.001.bck"
  #   FsEntryAclGet                        ( [String] $fsEntry ){
  #   FsEntryAclSetInheritance             ( [String] $fsEntry ){
  #   FsEntryAclRuleWrite                  ( [String] $modeSetAddOrDel, [String] $fsEntry, [System.Security.AccessControl.FileSystemAccessRule] $rule, [Boolean] $recursive = $false ){
  #   FsEntryTrySetOwner                   ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){
  #   FsEntryTrySetOwnerAndAclsIfNotSet    ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){
  #   FsEntryTryForceRenaming              ( [String] $fsEntry, [String] $extension ){
  #   FsEntryResetTs                       ( [String] $fsEntry, [Boolean] $recursive, [String] $tsInIsoFmt = "2000-01-01 00:00" ){
  #   FsEntryFindInParents                 ( [String] $fromFsEntry, [String] $searchFsEntryName ){
  #   DriveFreeSpace                       ( [String] $drive ){
  #   DirExists                            ( [String] $dir ){
  #   DirNotExists                         ( [String] $dir ){ return [Boolean] -not (DirExists $dir); }
  #   DirAssertExists                      ( [String] $dir, [String] $text = "Assertion" ){
  #   DirCreate                            ( [String] $dir ){
  #   DirCreateTemp                        ( [String] $prefix = "" ){ while($true){
  #   DirDelete                            ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
  #   DirDeleteContent                     ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
  #   DirDeleteIfIsEmpty                   ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
  #   DirCopyToParentDirByAddAndOverwrite  ( [String] $srcDir, [String] $tarParentDir ){
  #   FileGetSize                          ( [String] $file ){
  #   FileExists                           ( [String] $file ){ AssertNotEmpty $file "$(ScriptGetCurrentFunc):filename";
  #                                          [String] $f2 = FsEntryGetAbsolutePath $file; if( Test-Path -PathType Leaf -LiteralPath $f2 ){ return [Boolean] $true; }
  #   FileNotExists                        ( [String] $file ){
  #   FileAssertExists                     ( [String] $file ){
  #   FileExistsAndIsNewer                 ( [String] $ftar, [String] $fsrc ){
  #   FileNotExistsOrIsOlder               ( [String] $ftar, [String] $fsrc ){
  #   FileReadContentAsString              ( [String] $file, [String] $encodingIfNoBom = "Default" ){
  #   FileReadContentAsLines               ( [String] $file, [String] $encodingIfNoBom = "Default" ){
  #   FileReadJsonAsObject                 ( [String] $jsonFile ){
  #   FileWriteFromString                  ( [String] $file, [String] $content, [Boolean] $overwrite = $true, [String] $encoding = "UTF8" ){
  #   FileWriteFromLines                   ( [String] $file, [String[]] $lines, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){
  #   FileCreateEmpty                      ( [String] $file, [Boolean] $overwrite = $false, [Boolean] $quiet = $false ){
  #   FileAppendLineWithTs                 ( [String] $file, [String] $line ){ FileAppendLine $file $line $true; }
  #   FileAppendLine                       ( [String] $file, [String] $line, [Boolean] $tsPrefix = $false ){
  #   FileAppendLines                      ( [String] $file, [String[]] $lines ){
  #   FileGetTempFile                      (){ return [Object] [System.IO.Path]::GetTempFileName(); }
  #   FileDelTempFile                      ( [String] $file ){ if( (FileExists $file) ){
  #   FileReadEncoding                     ( [String] $file ){
  #   FileTouch                            ( [String] $file ){
  #   FileGetLastLines                     ( [String] $file, [Int32] $nrOfLines ){
  #   FileContentsAreEqual                 ( [String] $f1, [String] $f2, [Boolean] $allowSecondFileNotExists = $true ){ # first file must exist
  #   FileDelete                           ( [String] $file, [Boolean] $ignoreReadonly = $true, [Boolean] $ignoreAccessDenied = $false ){
  #   FileCopy                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){
  #   FileMove                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false ){
  #   FileGetHexStringOfHash128BitsMd5     ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "MD5"    $srcFile).Hash; }
  #   FileGetHexStringOfHash256BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA256" $srcFile).Hash; } # 2017-11 ps standard is SHA256, available are: SHA1;SHA256;SHA384;SHA512;MACTripleDES;MD5;RIPEMD160
  #   FileGetHexStringOfHash512BitsSha2    ( [String] $srcFile ){ return [String] (get-filehash -Algorithm "SHA512" $srcFile).Hash; } # 2017-12: this is our standard for ps
  #   FileUpdateItsHashSha2FileIfNessessary( [String] $srcFile ){
  #   FileNtfsAlternativeDataStreamAdd     ( [String] $srcFile, [String] $adsName, [String] $val ){
  #   FileNtfsAlternativeDataStreamDel     ( [String] $srcFile, [String] $adsName ){
  #   FileAdsDownloadedFromInternetAdd     ( [String] $srcFile ){
  #   FileAdsDownloadedFromInternetDel     ( [String] $srcFile ){
  #   DriveMapTypeToString                 ( [UInt32] $driveType ){
  #   DriveList                            (){
  #   ShareGetTypeName                     ( [UInt32] $typeNr ){
  #   ShareGetTypeNr                       ( [String] $typeName ){
  #   ShareExists                          ( [String] $shareName ){
  #   ShareListAll                         ( [String] $selectShareName = "" ){
  #   ShareLocksList                       ( [String] $path = "" ){
  #   ShareLocksClose                      ( [String] $path = "" ){
  #   ShareCreate                          ( [String] $shareName, [String] $dir, [String] $descr = "", [Int32] $nrOfAccessUsers = 25, [Boolean] $ignoreIfAlreadyExists = $true ){
  #   ShareRemove                          ( [String] $shareName ){ # no action if it not exists
  #   MountPointLocksListAll               (){
  #   MountPointListAll                    (){ # we define mountpoint as a share mapped to a local path
  #   MountPointGetByDrive                 ( [String] $drive ){ # return null if not found
  #   MountPointRemove                     ( [String] $drive, [String] $mountPoint = "", [Boolean] $suppressProgress = $false ){
  #   MountPointCreate                     ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $errorAsWarning = $false, [Boolean] $noPreLogMsg = $false ){
  #   PsDriveListAll                       (){
  #   PsDriveCreate                        ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null ){
}
Test_FsEntry_Dir_File_Drive_Share_Mount_PsDrive;
