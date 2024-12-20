#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_FsEntry_Dir_File(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert         ((FsEntryGetAbsolutePath "") -eq "" );
  Assert         ((FsEntryMakeRelative "$HOME/MyDir/Dir1/File" "$HOME/MyDir/"      ).Replace("\","/") -eq   "Dir1/File");
  Assert         ((FsEntryMakeRelative "$HOME/MyDir/Dir1/File" "$HOME/MyDir/" $true).Replace("\","/") -eq "./Dir1/File");
  Assert         ((FsEntryMakeRelative "$HOME/MyDir/File"      "$HOME/MyDir/"      ).Replace("\","/") -eq "File");
  Assert         ((FsEntryMakeRelative "$HOME/MyDir/"          "$HOME/MyDir/"      ).Replace("\","/") -eq "./");
  #
  Assert ((FsEntryEsc "aa[bb]cc?dd*ee``ff") -eq "aa``[bb``]cc``?dd``*ee``ff");
  #
  Assert ((FsEntryUnifyDirSep "$HOME\MyDir/MyFile.txt") -eq $(switch((OsIsWindows)){($true){"$HOME\MyDir\MyFile.txt"}($false){"$HOME/MyDir/MyFile.txt"}}));
  #
  function Test_FsEntryGetAbsolutePath(){
    Assert ((FsEntryGetAbsolutePath "$HOME\MyDir\MyFile.txt") -eq $(switch((OsIsWindows)){($true){"$HOME\MyDir\MyFile.txt"}($false){"$HOME/MyDir/MyFile.txt"}}));
    Assert ((FsEntryGetAbsolutePath "$HOME/MyDir/MyFile.txt") -eq $(switch((OsIsWindows)){($true){"$HOME\MyDir\MyFile.txt"}($false){"$HOME/MyDir/MyFile.txt"}}));
    Assert ((FsEntryGetAbsolutePath "$HOME/MyDir/"          ) -eq $(switch((OsIsWindows)){($true){"$HOME\MyDir\"          }($false){"$HOME/MyDir/"          }}));
    Assert ((FsEntryGetAbsolutePath "$HOME/MyDir"           ) -eq $(switch((OsIsWindows)){($true){"$HOME\MyDir"           }($false){"$HOME/MyDir"           }}));
    Assert ((FsEntryGetAbsolutePath "//MyDomain/MyShare"    ) -eq $(switch((OsIsWindows)){($true){"\\MyDomain\MyShare"    }($false){"//MyDomain/MyShare"    }}));
    Assert ((FsEntryGetAbsolutePath "//MyDomain/MyShare/"   ) -eq $(switch((OsIsWindows)){($true){"\\MyDomain\MyShare\"   }($false){"//MyDomain/MyShare/"   }}));
    Assert ((FsEntryGetAbsolutePath "//MyDomain/MyShare/f"  ) -eq $(switch((OsIsWindows)){($true){"\\MyDomain\MyShare\f"  }($false){"//MyDomain/MyShare/f"  }}));
    Push-Location "$HOME/";
    Assert ((FsEntryGetAbsolutePath "."                      ) -eq $(switch((OsIsWindows)){($true){"$HOME"                }($false){"$HOME"                 }}));
    Assert ((FsEntryGetAbsolutePath "./"                     ) -eq $(switch((OsIsWindows)){($true){"$HOME\"               }($false){"$HOME/"                }}));
    Assert ((FsEntryGetAbsolutePath "./."                    ) -eq $(switch((OsIsWindows)){($true){"$HOME"                }($false){"$HOME"                 }}));
    Assert ((FsEntryGetAbsolutePath "././"                   ) -eq $(switch((OsIsWindows)){($true){"$HOME\"               }($false){"$HOME/"                }}));
    Assert ((FsEntryGetAbsolutePath "./d/"                   ) -eq $(switch((OsIsWindows)){($true){"$HOME\d\"             }($false){"$HOME/d/"              }}));
    Assert ((FsEntryGetAbsolutePath "./f"                    ) -eq $(switch((OsIsWindows)){($true){"$HOME\f"              }($false){"$HOME/f"               }}));
    Pop-Location;
  } Test_FsEntryGetAbsolutePath;
  #
  # TODO: FsEntryGetUncShare                   ( [String] $fsEntry )
  #
  # TODO: FsEntryMakeValidFileName             ( [String] $str )
  #
  # TODO: FsEntryMakeRelative                  ( [String] $fsEntry, [String] $belowDir, [Boolean] $prefixWithDotDir = $false )
  #
  # TODO: FsEntryHasTrailingDirSep             ( [String] $fsEntry )
  #
  # TODO: FsEntryAssertHasTrailingDirSep
  #
  # TODO: FsEntryRemoveTrailingDirSep          ( [String] $fsEntry )
  #
  # TODO: FsEntryMakeTrailingDirSep            ( [String] $fsEntry
  #
  # TODO: FsEntryJoinRelativePatterns          ( [String] $rootDir [String[]] $relativeFsEntriesPatternsSemicolonSeparated )
  #
  # TODO: FsEntryPathIsEqual
  #
  # TODO: FsEntryGetFileNameWithoutExt         ( [String] $fsEntry)
  #
  # TODO: FsEntryGetFileName                   ( [String] $fsEntry)
  #
  # TODO: FsEntryGetFileExtension              ( [String] $fsEntry
  #
  # TODO: FsEntryGetDrive                      ( [String] $fsEntry
  #
  # TODO: FsEntryIsDir                         ( [String] $fsEntry
  #
  # TODO: FsEntryGetParentDir                  ( [String] $fsEntry
  #
  # TODO: FsEntryExists                        ( [String] $fsEntry
  #
  # TODO: FsEntryNotExists                     ( [String] $fsEntry
  #
  # TODO: FsEntryAssertExists                  ( [String] $fsEntry,[String] $text = "Assertion failed" )
  #
  # TODO: FsEntryAssertNotExists               ( [String] $fsEntry [String] $text = "Assertion failed" )
  #
  # TODO: FsEntryGetLastModified               ( [String] $fsEntry )
  #
  # TODO: FsEntryNotExistsOrIsOlderThanNrDays  ( [String] $fsEntry, [Int32] $maxAgeInDays, [Int32] $maxAgeInHours = 0, [Int32] $maxAgeInMinutes = 0 )
  #
  # TODO: FsEntryNotExistsOrIsOlderThanBeginOf ( [String] $fsEntry, [String] $beginOf ) # more see: DateTimeGetBeginOf
  #
  # TODO: FsEntryExistsAndIsNewerThanBeginOf   ( [String] $fsEntry, [String] $beginOf ) # more see: DateTimeGetBeginOf
  #
  # TODO: FsEntrySetAttributeReadOnly          ( [String] $fsEntry, [Boolean] $val ) # use false for $val to make file writable
  #
  # TODO: FsEntryFindFlatSingleByPattern       ( [String] $fsEntryPattern, [Boolean] $allowNotFound = $false )
  #
  # TODO: FsEntryFsInfoFullNameDirWithBackSlash( [System.IO.FileSystemInfo] $fsInfo ) return [String] ($fsInfo.FullName+$(switch($fsInfo.PSIsContainer){($true){$(DirSep)}default{""}}));
  #
  # TODO: FsEntryListAsFileSystemInfo          ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false )
  #
  # TODO: FsEntryListAsStringArray             ( [String] $fsEntryPattern, [Boolean] $recursive = $true, [Boolean] $includeDirs = $true, [Boolean] $includeFiles = $true, [Boolean] $inclTopDir = $false )
  #
  # TODO: FsEntryDelete                        ( [String] $fsEntry )
  #
  # TODO: FsEntryDeleteToRecycleBin            ( [String] $fsEntry )
  #
  # TODO: FsEntryRename                        ( [String] $fsEntryFrom, [String] $fsEntryTo )
  #
  # TODO: FsEntryCreateSymLink                 ( [String] $newSymLink, [String] $fsEntryOrigin )
  #
  # TODO: FsEntryCreateHardLink                ( [String] $newHardLink, [String] $fsEntryOrigin )
  #
  # TODO: FsEntryCreateDirSymLink              ( [String] $symLinkDir, [String] $symLinkOriginDir )
  #
  # TODO: FsEntryIsSymLink [String] $fsEntry
  #
  # TODO: FsEntryReportMeasureInfo             ( [String] $fsEntry ) # Must exists, works recursive.
  #
  # TODO: FsEntryCreateParentDir               ( [String] $fsEntry )
  #
  # TODO: FsEntryMoveByPatternToDir            ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $showProgress = $false ) # Target dir must exists. pattern is non-recursive scanned.
  #
  # TODO: FsEntryCopyByPatternByOverwrite      ( [String] $fsEntryPattern, [String] $targetDir, [Boolean] $continueOnErr = $false )
  #
  # TODO: FsEntryFindNotExistingVersionedName  ( [String] $fsEntry, [String] $ext = ".bck", [Int32] $maxNr = 9999 ) # return Example: "C:\Dir\MyName.001.bck"
  #
  # TODO: FsEntryAclGet                        ( [String] $fsEntry )
  #
  # TODO: FsEntryAclSetInheritance             ( [String] $fsEntry )
  #
  # TODO: FsEntryAclRuleWrite                  ( [String] $modeSetAddOrDel, [String] $fsEntry, [System.Security.AccessControl.FileSystemAccessRule] $rule, [Boolean] $recursive = $false )
  #
  # TODO: FsEntryTrySetOwner                   ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false )
  #
  # TODO: FsEntryTrySetOwnerAndAclsIfNotSet    ( [String] $fsEntry, [System.Security.Principal.IdentityReference] $account, [Boolean] $recursive = $false )
  #
  # TODO: FsEntryTryForceRenaming              ( [String] $fsEntry, [String] $extension )
  #
  # TODO: FsEntryResetTs                       ( [String] $fsEntry, [Boolean] $recursive, [String] $tsInIsoFmt = "2000-01-01 00:00" )
  #
  # TODO: FsEntryFindInParents                 ( [String] $fromFsEntry, [String] $searchFsEntryName )
  #
  # TODO: FsEntryGetSize
  #
  # TODO: DriveFreeSpace                       ( [String] $drive )
  #
  Assert ((DirSep) -eq $(switch((OsIsWindows)){($true){"\"}($false){"/"}}));
  #
  # TODO: DirExists                            ( [String] $dir )
  #
  # TODO: DirNotExists                         ( [String] $dir ) return [Boolean] -not (DirExists $dir); }
  #
  # TODO: DirAssertExists                      ( [String] $dir, [String] $text = "Assertion" )
  #
  # TODO: DirCreate                            ( [String] $dir )
  #
  [String] $tmpDir = DirCreateTemp "MnPrefix"; DirDelete $tmpDir;
  #
  # TODO: DirDeleteContent                     ( [String] $dir, [Boolean] $ignoreReadonly = $true )
  #
  # TODO: DirDeleteIfIsEmpty                   ( [String] $dir, [Boolean] $ignoreReadonly = $true )
  #
  # TODO: DirCopyToParentDirByAddAndOverwrite  ( [String] $srcDir, [String] $tarParentDir )
  #
  # TODO: FileGetSize                          ( [String] $file )
  #
  # TODO: FileExists                           ( [String] $file )
  #
  # TODO: FileNotExists                        ( [String] $file )
  #
  # TODO: FileAssertExists                     ( [String] $file )
  #
  # TODO: FileExistsAndIsNewer                 ( [String] $ftar, [String] $fsrc )
  #
  # TODO: FileNotExistsOrIsOlder               ( [String] $ftar, [String] $fsrc )
  #
  function Test_FileReadContentAsString(){
    [String] $src = FileGetTempFile;
    [String] $text0 = "ä`r`nöü";
    [String] $text2 = "ä$([Environment]::NewLine)öü";
    [String] $text4 = switch(OsIsWindows){($true){$text2}($false){$text0}};
    OutProgress "Test_FileReadContentAsString beg";
    function WriteText( [String] $enc ){ FileWriteFromString $src $text0 $true $enc; }
    function ReadText ( [String] $enc ){ [String] $s = (FileReadContentAsString $src $enc) -replace "`r",'CR' -replace "`n",'LF'; OutProgress "Text : `"$s`""; }
    #
    WriteText "UTF8BOM"; ReadText "Default";                                       Assert ((FileReadContentAsString $src "Default") -eq $text0);
    WriteText "UTF8BOM"; ReadText "UTF8"   ;                                       Assert ((FileReadContentAsString $src "UTF8"   ) -eq $text0);
    WriteText "Default"; ReadText "Default";                                       Assert ((FileReadContentAsString $src "Default") -eq $text4);
    WriteText "Default"; ReadText "UTF8"   ; if( -not (ProcessIsLesserEqualPs5) ){ Assert ((FileReadContentAsString $src "UTF8"   ) -eq $text4); } # TODO fails in ps5, text is "�CRLF��"
    if( -not (ProcessIsLesserEqualPs5) ){ # TODO write UTF8 in ps5 currently not implemented
      WriteText "UTF8"   ; ReadText "Default";                                       Assert ((FileReadContentAsString $src "Default") -eq $text0);
      WriteText "UTF8"   ; ReadText "UTF8"   ;                                       Assert ((FileReadContentAsString $src "UTF8"   ) -eq $text0);
    }
    OutProgress "Test_FileReadContentAsString end";
  } Test_FileReadContentAsString;
  #
  function Test_FileReadContentAsLines(){
    [String] $content = "Hello`n World`n";
    [String] $tmp = (FileGetTempFile);
    Assert ((@()+(FileReadContentAsLines $tmp "UTF8")).Count -eq 0);
    FileWriteFromString $tmp $content $true;
    Assert ((FileReadContentAsLines $tmp "UTF8").Count -eq 2);
    FileDelTempFile $tmp;
  } Test_FileReadContentAsLines;
  #
  # TODO: FileReadJsonAsObject                 ( [String] $jsonFile )
  #
  function Test_FileWriteFromString(){
    [String] $content = "Hello`n World`n";
    [String] $tmpFile0 = (FileGetTempFile); # empty 0 Bytes NonBOM
    [String] $tmpFile2 = (FileGetTempFile); FileWriteFromString $tmpFile2 ""       $true; # UTF8BOM 3 bytes
    [String] $tmpFile3 = (FileGetTempFile); FileWriteFromString $tmpFile3 $content $true;
    [String] $tmpFile4 = (FileGetTempFile); FileWriteFromString $tmpFile4 $content $true;
    Assert (FileContentsAreEqual $tmpFile3 $tmpFile4);
    Assert (-not (FileContentsAreEqual $tmpFile0 "$([System.IO.Path]::GetTempPath())/unexistingFile.txt"));
    Assert (-not (FileContentsAreEqual $tmpFile0 $tmpFile2));
    if( -not (ProcessIsLesserEqualPs5) ){ # TODO in ps5 it fails    
      [String] $tmpFile1 = (FileGetTempFile); FileWriteFromString $tmpFile1 ""       $true "UTF8"; # 0 bytes
      [String] $tmpFile5 = (FileGetTempFile) ;FileWriteFromString $tmpFile5 $content $true "UTF8";
      Assert (FileContentsAreEqual $tmpFile0 $tmpFile1);
      Assert (-not (FileContentsAreEqual $tmpFile3 $tmpFile5));
      FileDelTempFile $tmpFile1;
      FileDelTempFile $tmpFile5;
    }
    FileDelTempFile $tmpFile0;
    FileDelTempFile $tmpFile2;
    FileDelTempFile $tmpFile3;
    FileDelTempFile $tmpFile4;
  } Test_FileWriteFromString;
  #
  # TODO: FileWriteFromLines                   ( [String] $file, [String[]] $lines, [Boolean] $overwrite = $false, [String] $encoding = "UTF8BOM" )
  #
  # TODO: FileCreateEmpty                      ( [String] $file, [Boolean] $overwrite = $false, [Boolean] $quiet = $false, [String] $encoding = "UTF8BOM" )
  #
  # TODO: FileAppendLineWithTs                 ( [String] $file, [String] $line ) FileAppendLine $file $line $true; }
  #
  # TODO: FileAppendLine                       ( [String] $file, [String] $line, [Boolean] $tsPrefix = $false, [String] $encoding = "UTF8BOM" )
  #
  # TODO: FileAppendLines                      ( [String] $file, [String[]] $lines, [String] $encoding = "UTF8BOM" )
  #
  # TODO: FileGetTempFile                      () return [Object] [System.IO.Path]::GetTempFileName(); }
  #
  # TODO: FileDelTempFile                      ( [String] $file ) if( (FileExists $file) )
  #
  # TODO: FileReadEncoding                     ( [String] $file )
  #
  # TODO: FileTouch                            ( [String] $file )
  #
  # TODO: FileGetLastLines                     ( [String] $file, [Int32] $nrOfLines )
  #
  function Test_FileContentsAreEqual(){
    [String] $content = "Hello`n World`n";
    [String] $tmpFile1 = (FileGetTempFile); # empty 0 Bytes NonBOM
    [String] $tmpFile3 = (FileGetTempFile); FileWriteFromString $tmpFile3 ""       $true; # 3 Bytes UTF8BOM
    [String] $tmpFile5 = (FileGetTempFile); FileWriteFromString $tmpFile5 $content $true "UTF8BOM";
    Assert (-not (FileContentsAreEqual $tmpFile1 "$([System.IO.Path]::GetTempPath())/unexistingFile.magic823621875349817636534.txt"));
    Assert (-not (FileContentsAreEqual $tmpFile1 $tmpFile3));
    if( -not (ProcessIsLesserEqualPs5) ){ # TODO in ps5 it fails    
      [String] $tmpFile2 = (FileGetTempFile); FileWriteFromString $tmpFile2 ""       $true "UTF8" ;# empty 0 Bytes NonBOM
      [String] $tmpFile4 = (FileGetTempFile); FileWriteFromString $tmpFile4 $content $true "UTF8";
      Assert (      FileContentsAreEqual $tmpFile1 $tmpFile2);
      Assert (-not (FileContentsAreEqual $tmpFile1 $tmpFile4));
      Assert (-not (FileContentsAreEqual $tmpFile4 $tmpFile5));
      FileDelTempFile $tmpFile2;
      FileDelTempFile $tmpFile4;
    }
    FileDelTempFile $tmpFile1;
    FileDelTempFile $tmpFile3;
    FileDelTempFile $tmpFile5;
  } Test_FileContentsAreEqual;
  #
  # TODO: FileDelete                           ( [String] $file, [Boolean] $ignoreReadonly = $true, [Boolean] $ignoreAccessDenied = $false )
  #
  # TODO: FileCopy                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false )
  #
  # TODO: FileMove                             ( [String] $srcFile, [String] $tarFile, [Boolean] $overwrite = $false )
  #
  function Test_FileSyncContent(){
    [String] $content = "Hello`n World`n";
    [String] $tmpFile1 = (FileGetTempFile); FileWriteFromString $tmpFile1 $content $true;
    [String] $tmpFile2 = (FileGetTempFile);
    Assert (-not (FileContentsAreEqual $tmpFile1 $tmpFile2));
    FileSyncContent $tmpFile1 $tmpFile2;
    Assert (FileContentsAreEqual $tmpFile1 $tmpFile2);
    FileWriteFromString $tmpFile2 "newContent" $true;
    Assert (-not (FileContentsAreEqual $tmpFile1 $tmpFile2));
    FileSyncContent $tmpFile1 $tmpFile2;
    Assert (FileContentsAreEqual $tmpFile1 $tmpFile2);
    FileDelTempFile $tmpFile1;
    FileDelTempFile $tmpFile2;
  } Test_FileSyncContent;
  #
  # TODO: FileGetHexStringOfHash128BitsMd5     ( [String] $srcFile )
  #
  # TODO: FileGetHexStringOfHash256BitsSha2    ( [String] $srcFile )
  #
  # TODO: FileGetHexStringOfHash512BitsSha2    ( [String] $srcFile )
  #
  # TODO: FileUpdateItsHashSha2FileIfNessessary( [String] $srcFile )
  #
}
UnitTest_FsEntry_Dir_File;
