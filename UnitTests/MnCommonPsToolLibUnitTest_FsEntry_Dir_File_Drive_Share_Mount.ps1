#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_FsEntry_Dir_File_Drive_Share_Mount_PsDrive(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert         ((FsEntryGetAbsolutePath "") -eq "" );
  Assert         ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir") -eq "Dir1\Dir2");
  Assert         ((FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir" $true) -eq ".\Dir1\Dir2");
  Assert         ((FsEntryMakeRelative "C:\MyDir" "C:\MyDir\") -eq ".");
  # TODO:
  #   DirSep                               (){ return [Char] [IO.Path]::DirectorySeparatorChar; }
  #   FsEntryEsc                           ( [String] $fsentry ){ AssertNotEmpty $fsentry "file-system-entry"; # Escaping is not nessessary if a command supports -LiteralPath.
  #   FsEntryGetAbsolutePath               ( [String] $fsEntry ){ # works without IO, so no check to file system; does not change a trailing backslash. Return empty for empty input.
  #                                          # Note: We cannot use (Resolve-Path -LiteralPath $fsEntry) because it will throw if path not exists,
  #                                          # see http://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist
  #   FsEntryGetUncShare                   ( [String] $fsEntry ){ # return "\\host\sharename\" of a given unc path, return empty string if fs entry is not an unc path
  #   FsEntryMakeValidFileName             ( [String] $str ){
  #   FsEntryMakeRelative                  ( [String] $fsEntry, [String] $belowDir, [Boolean] $prefixWithDotDir = $false ){
  #                                          # Works without IO to file system; if $fsEntry is not equal or below dir then it throws;
  #                                          # if fs-entry is equal the below-dir then it returns a dot;
  #                                          # a trailing backslash of the fs entry is not changed;
  #                                          # trailing backslashes for belowDir are not nessessary. ex: "Dir1\Dir2" -eq (FsEntryMakeRelative "C:\MyDir\Dir1\Dir2" "C:\MyDir");
  #   FsEntryHasTrailingDirSep             ( [String] $fsEntry ){ return [Boolean] ($fsEntry.EndsWith("\") -or $fsEntry.EndsWith("/")); }
  #   FsEntryRemoveTrailingDirSep          ( [String] $fsEntry ){ [String] $r = $fsEntry;
  #   FsEntryMakeTrailingDirSep            ( [String] $fsEntry ){
  #   FsEntryJoinRelativePatterns          ( [String] $rootDir, [String[]] $relativeFsEntriesPatternsSemicolonSeparated ){
  #                                          # Create an array ex: @( "c:\myroot\bin\", "c:\myroot\obj\", "c:\myroot\*.tmp", ... ) from input as @( "bin\;obj\;", ";*.tmp;*.suo", ".\dir\d1?\", ".\dir\file*.txt");
  #                                          # If an fs entry specifies a dir patterns then it must be specified by a trailing backslash.
  #   FsEntryGetFileNameWithoutExt         ( [String] $fsEntry ){
  #   FsEntryGetFileName                   ( [String] $fsEntry ){
  #   FsEntryGetFileExtension              ( [String] $fsEntry ){
  #   FsEntryGetDrive                      ( [String] $fsEntry ){ # ex: "C:"
  #   FsEntryIsDir                         ( [String] $fsEntry ){ return [Boolean] (Get-Item -Force -LiteralPath $fsEntry).PSIsContainer; } # empty string not allowed
  #   FsEntryGetParentDir                  ( [String] $fsEntry ){ # Returned path does not contain trailing backslash; for c:\ or \\mach\share it return "";
  #   FsEntryExists                        ( [String] $fsEntry ){
  #   FsEntryNotExists                     ( [String] $fsEntry ){
  #   FsEntryAssertExists                  ( [String] $fsEntry, [String] $text = "Assertion failed" ){
  #   FsEntryAssertNotExists               ( [String] $fsEntry, [String] $text = "Assertion failed" ){
  #   FsEntryGetLastModified               ( [String] $fsEntry ){
  #   FsEntryNotExistsOrIsOlderThanNrDays  ( [String] $fsEntry, [Int32] $maxAgeInDays, [Int32] $maxAgeInHours = 0, [Int32] $maxAgeInMinutes = 0 ){
  #   FsEntryNotExistsOrIsOlderThanBeginOf ( [String] $fsEntry, [String] $beginOf ){ # more see: DateTimeGetBeginOf
  #   FsEntryExistsAndIsNewerThanBeginOf   ( [String] $fsEntry, [String] $beginOf ){ # more see: DateTimeGetBeginOf
  #   FsEntrySetAttributeReadOnly          ( [String] $fsEntry, [Boolean] $val ){ # use false for $val to make file writable
  #   FsEntryFindFlatSingleByPattern       ( [String] $fsEntryPattern, [Boolean] $allowNotFound = $false ){
  #                                          # it throws if file not found or more than one file exists. if allowNotFound is true then if return empty if not found.
  #   FsEntryFsInfoFullNameDirWithBackSlash( [System.IO.FileSystemInfo] $fsInfo ){ return [String] ($fsInfo.FullName+$(switch($fsInfo.PSIsContainer){($true){$(DirSep)}default{""}})); }
  #   FsEntryListAsFileSystemInfo          ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
  #                                          # List entries specified by a pattern, which applies to files and directories and which can contain wildards (*,?).
  #                                          # Internally it uses Get-Item and Get-ChildItem.
  #                                          # If inclTopDir is true (and includeDirs is true and no wildcards are used and so a single dir is specified) then the dir itself is included.
  #                                          # Examples for fsEntryPattern: "C:\*.tmp", ".\dir\*.tmp", "dir\te?*.tmp", "*\dir\*.tmp", "dir\*", "bin\".
  #                                          # Output is unsorted. Ignores case and access denied conditions. If not found an entry then an empty array is returned.
  #                                          # It works with absolute or relative paths. A leading ".\" for relative paths is optional.
  #                                          # If recursive is specified then it applies pattern matching of last specified part (.\*.tmp;.\Bin\) in each sub dir.
  #                                          # Wildcards on parent dir parts are also allowed ("dir*\*.tmp","*\*.tmp").
  #                                          # It work as intuitive as possible, but here are more detail specifications:
  #                                          #   If no wildcards are used then behaviour is the following:
  #                                          #     In non-recursive mode and if pattern matches a file (".\f.txt") then it is listed,
  #                                          #     and if pattern matches a dir (".\dir") its content is listed flat.
  #                                          #     In recursive mode the last backslash separated part of the pattern ("f.txt" or "dir") is searched in two steps,
  #                                          #     first if it matches a file (".\f.txt") then it is listed, and if matches a dir (".\dir") then its content is listed deeply,
  #                                          #     second if pattern was not yet found then it searches for it recursively and lists the found entries but even if it is a dir then its content is not listed.
  #                                          # Trailing backslashes:  Are handled in powershell quite curious:
  #                                          #   In non-recursive mode they are handled as they are not present, so files are also matched ("*\myfile\").
  #                                          #   In recursive mode they wrongly match only files and not directories ("*\myfile\") and
  #                                          #   so parent dir parts (".\*\dir\" or "d1\dir\") would not be found for unknown reasons.
  #                                          #   Very strange is that (CD "D:\tmp"; CD "C:"; Get-Item "D:";) does not list D:\ but it lists the current directory of that drive.
  #                                          #   So we interpret a trailing backslash as it would not be present with the exception that
  #                                          #     If pattern contains a trailing backslash then pattern "\*\" will be replaced by ("\.\").
  #                                          #   If pattern is a drive as "C:" then a trailing backslash is added to avoid the unexpected listing of current dir of that drive.
  #   FsEntryListAsStringArray             ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false ){
  #                                          # Output of directories will have a trailing backslash. more see FsEntryListAsFileSystemInfo.
  #   FsEntryDelete                        ( [String] $fsEntry ){
  #   FsEntryDeleteToRecycleBin            ( [String] $fsEntry ){
  #   FsEntryRename                        ( [String] $fsEntryFrom, [String] $fsEntryTo ){
  #                                          # for files or dirs, relative or absolute, origin must exists, directory parts must be identic.
  #   FsEntryCreateSymLink                 ( [String] $newSymLink, [String] $fsEntryOrigin ){
  #                                          # (junctions (=~symlinksToDirs) do not) (https://superuser.com/questions/104845/permission-to-make-symbolic-links-in-windows-7/105381).
  #   FsEntryCreateHardLink                ( [String] $newHardLink, [String] $fsEntryOrigin ){
  #                                          # for files or dirs, origin must exists, it requires elevated rights.
  #   FsEntryCreateDirSymLink              ( [String] $symLinkDir, [String] $symLinkOriginDir ){
  #                                          # Creates junctions which are symlinks to dirs with some slightly other behaviour around privileges and local/remote usage.
  #   FsEntryReportMeasureInfo             ( [String] $fsEntry ){ # Must exists, works recursive.
  #   FsEntryCreateParentDir               ( [String] $fsEntry ){ [String] $dir = FsEntryGetParentDir $fsEntry; DirCreate $dir; }
  #   FsEntryMoveByPatternToDir            ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $showProgress = $false ){ # Target dir must exists. pattern is non-recursive scanned.
  #   FsEntryCopyByPatternByOverwrite      ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $continueOnErr = $false ){
  #   FsEntryFindNotExistingVersionedName  ( [String] $fsEntry, [String] $ext = ".bck", [Int32] $maxNr = 9999 ){ # return ex: "C:\Dir\MyName.001.bck"
  #   FsEntryAclGet                        ( [String] $fsEntry ){
  #   FsEntryAclSetInheritance             ( [String] $fsEntry ){
  #   FsEntryAclRuleWrite                  ( [String] $modeSetAddOrDel, [String] $fsEntry, [System.Security.AccessControl.FileSystemAccessRule] $rule, [Boolean] $recursive = $false ){
  #                                          # $modeSetAddOrDel = "Set", "Add", "Del".
  #   FsEntryTrySetOwner                   ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){
  #                                          # usually account is (PrivGetGroupAdministrators)
  #   FsEntryTrySetOwnerAndAclsIfNotSet    ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false ){
  #                                          # usually account is (PrivGetGroupAdministrators)
  #   FsEntryTryForceRenaming              ( [String] $fsEntry, [String] $extension ){
  #   FsEntryResetTs                       ( [String] $fsEntry, [Boolean] $recursive, [String] $tsInIsoFmt = "2000-01-01 00:00" ){
  #                                          # Overwrite LastWriteTime, CreationTime and LastAccessTime. Drive ts cannot be changed and so are ignored. Used for example to anonymize ts.
  #   FsEntryFindInParents                 ( [String] $fromFsEntry, [String] $searchFsEntryName ){
  #                                          # From an fsEntry scan its parent dir upwards to root until a search name has been found.
  #                                          # Return full path of found fs entry or empty string if not found.
  #   DriveFreeSpace                       ( [String] $drive ){
  #   DirExists                            ( [String] $dir ){
  #   DirNotExists                         ( [String] $dir ){ return [Boolean] -not (DirExists $dir); }
  #   DirAssertExists                      ( [String] $dir, [String] $text = "Assertion" ){
  #   DirCreate                            ( [String] $dir ){
  #   DirCreateTemp                        ( [String] $prefix = "" ){ while($true){
  #   DirDelete                            ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
  #                                          # Remove dir recursively if it exists, be careful when using this.
  #   DirDeleteContent                     ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
  #                                          # remove dir content if it exists, be careful when using this.
  #   DirDeleteIfIsEmpty                   ( [String] $dir, [Boolean] $ignoreReadonly = $true ){
  #   DirCopyToParentDirByAddAndOverwrite  ( [String] $srcDir, [String] $tarParentDir ){
  #   FileGetSize                          ( [String] $file ){
  #   FileExists                           ( [String] $file ){ AssertNotEmpty $file "$(ScriptGetCurrentFunc):filename";
  #                                          [String] $f2 = FsEntryGetAbsolutePath $file; if( Test-Path -PathType Leaf -LiteralPath $f2 ){ return [Boolean] $true; }
  #                                          # Note: Known bug: Test-Path does not work for hidden and system files, so we need an additional check.
  #                                          # Note2: The following would not works on vista and win7-with-ps2: [String] $d = Split-Path $f2; return [Boolean] ([System.IO.Directory]::EnumerateFiles($d) -contains $f2);
  #   FileNotExists                        ( [String] $file ){
  #   FileAssertExists                     ( [String] $file ){
  #   FileExistsAndIsNewer                 ( [String] $ftar, [String] $fsrc ){
  #   FileNotExistsOrIsOlder               ( [String] $ftar, [String] $fsrc ){
  #   FileReadContentAsString              ( [String] $file, [String] $encodingIfNoBom = "Default" ){
  #   FileReadContentAsLines               ( [String] $file, [String] $encodingIfNoBom = "Default" ){
  #                                          # Note: if BOM exists then this is taken. Otherwise often use "UTF8".
  #   FileReadJsonAsObject                 ( [String] $jsonFile ){
  #   FileWriteFromString                  ( [String] $file, [String] $content, [Boolean] $overwrite = $true, [String] $encoding = "UTF8" ){
  #                                          # Will create path of file. overwrite does ignore readonly attribute.
  #   FileWriteFromLines                   ( [String] $file, [String[]] $lines, [Boolean] $overwrite = $false, [String] $encoding = "UTF8" ){
  #   FileCreateEmpty                      ( [String] $file, [Boolean] $overwrite = $false, [Boolean] $quiet = $false ){
  #   FileAppendLineWithTs                 ( [String] $file, [String] $line ){ FileAppendLine $file $line $true; }
  #   FileAppendLine                       ( [String] $file, [String] $line, [Boolean] $tsPrefix = $false ){
  #   FileAppendLines                      ( [String] $file, [String[]] $lines ){
  #   FileGetTempFile                      (){ return [Object] [System.IO.Path]::GetTempFileName(); }
  #   FileDelTempFile                      ( [String] $file ){ if( (FileExists $file) ){
  #   FileReadEncoding                     ( [String] $file ){
  #                                          # read BOM = Byte order mark.
  #   FileTouch                            ( [String] $file ){
  #   FileGetLastLines                     ( [String] $file, [Int32] $nrOfLines ){
  #   FileContentsAreEqual                 ( [String] $f1, [String] $f2, [Boolean] $allowSecondFileNotExists = $true ){ # first file must exist
  #   FileDelete                           ( [String] $file, [Boolean] $ignoreReadonly = $true, [Boolean] $ignoreAccessDenied = $false ){
  #                                          # for hidden files it is also required to set ignoreReadonly=true.
  #                                          # In case the file is used by another process it waits some time between a retries.
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
  #                                          # uses newer module SmbShare
  #   ShareListAllByWmi                    ( [String] $selectShareName = "" ){
  #                                          # As ShareListAll but uses older wmi and not newer module SmbShare
  #   ShareLocksList                       ( [String] $path = "" ){
  #                                          # list currenty read or readwrite locked open files of a share, requires elevated admin mode
  #   ShareLocksClose                      ( [String] $path = "" ){
  #                                          # closes locks, ex: $path="D:\Transfer\" or $path="D:\Transfer\MyFile.txt"
  #   ShareCreate                          ( [String] $shareName, [String] $dir, [String] $descr = "", [Int32] $nrOfAccessUsers = 25, [Boolean] $ignoreIfAlreadyExists = $true ){
  #   ShareCreateByWmi                     ( [String] $shareName, [String] $dir, [String] $descr = "", [Int32] $nrOfAccessUsers = 25, [Boolean] $ignoreIfAlreadyExists = $true ){
  #   ShareRemove                          ( [String] $shareName ){ # no action if it not exists
  #   ShareRemoveByWmi                     ( [String] $shareName ){
  #   MountPointLocksListAll               (){
  #   MountPointListAll                    (){ # we define mountpoint as a share mapped to a local path
  #   MountPointGetByDrive                 ( [String] $drive ){ # return null if not found
  #   MountPointRemove                     ( [String] $drive, [String] $mountPoint = "", [Boolean] $suppressProgress = $false ){
  #                                          # Also remove PsDrive; drive can be empty then mountPoint must be given
  #   MountPointCreate                     ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null, [Boolean] $errorAsWarning = $false, [Boolean] $noPreLogMsg = $false ){
  #                                          # ex: MountPointCreate "S:" "\\localhost\Transfer" (CredentialCreate "user1" "mypw")
  #                                          # $noPreLogMsg is usually true if mount points are called parallel when order of output strings is not sequentially
  #   PsDriveListAll                       (){
  #   PsDriveCreate                        ( [String] $drive, [String] $mountPoint, [System.Management.Automation.PSCredential] $cred = $null ){
}
Test_FsEntry_Dir_File_Drive_Share_Mount_PsDrive;
