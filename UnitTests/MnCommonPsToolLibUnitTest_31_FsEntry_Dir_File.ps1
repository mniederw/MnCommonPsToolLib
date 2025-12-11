#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_FsEntry_Dir_File(){
  OutProgress (ScriptGetCurrentFuncName);
  function AssertFsEntryIsEqualForCurrentOs ( [String] $fsEntry, [String] $fsEntryConvertedToOsAndExpected ){
    Assert ($fsEntry -eq (FsEntryUnifyDirSep $fsEntryConvertedToOsAndExpected));
  }
  #
  #[String] $sep = switch((OsIsWindows)){($true){"\"}($false){"/"}}; # currently not yet used
  [String] $notExistingDir  = "$HOME/MyDir/AnyNonExistingFile_uzwqyaxs/";
  [String] $notExistingFile = "$HOME/MyDir/AnyNonExistingFile_uzwqyaxs";
  #
  Assert ((FsEntryEsc "aa[bb]cc?dd*ee``ff") -eq "aa``[bb``]cc``?dd``*ee``ff");
  #
  AssertFsEntryIsEqualForCurrentOs (FsEntryUnifyDirSep "$HOME\MyDir\MyFile.txt") "$HOME/MyDir/MyFile.txt"; # test AssertFsEntryIsEqualForCurrentOs
  #
  function Test_FsEntryGetAbsolutePath(){
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath ""                      ) ""                      ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "$HOME\MyDir\MyFile.txt") "$HOME/MyDir/MyFile.txt";
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "$HOME/MyDir/MyFile.txt") "$HOME/MyDir/MyFile.txt";
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "$HOME/MyDir/"          ) "$HOME/MyDir/"          ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "$HOME/MyDir"           ) "$HOME/MyDir"           ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "//MyDomain/MyShare"    ) "//MyDomain/MyShare"    ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "//MyDomain/MyShare/"   ) "//MyDomain/MyShare/"   ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "//MyDomain/MyShare/f"  ) "//MyDomain/MyShare/f"  ;
    Push-Location "$HOME/";
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "."                     ) "$HOME"                 ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "./"                    ) "$HOME/"                ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "./."                   ) "$HOME"                 ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "././"                  ) "$HOME/"                ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "./d/"                  ) "$HOME/d/"              ;
    AssertFsEntryIsEqualForCurrentOs (FsEntryGetAbsolutePath "./f"                   ) "$HOME/f"               ;
    Pop-Location;
  } Test_FsEntryGetAbsolutePath;
  #
  AssertFsEntryIsEqualForCurrentOs (FsEntryGetUncShare "//MyHost/MyShare/MyDir/") "//MyHost/MyShare/";
  #
  Assert (FsEntryHasRootPath "/any" );
  Assert (FsEntryHasRootPath "//any" );
  Assert (FsEntryHasRootPath "\any" );
  Assert (FsEntryHasRootPath "\\any" );
  Assert ( ((OsIsWindows) -and (FsEntryHasRootPath "C:/any")) -or (-not (OsIsWindows) -and -not (FsEntryHasRootPath "C:/any")) );
  Assert ( ((OsIsWindows) -and (FsEntryHasRootPath "C:\any")) -or (-not (OsIsWindows) -and -not (FsEntryHasRootPath "C:\any")) );
  #
  AssertEqual (FsEntryMakeValidFileName ""           ) ""           ;
  AssertEqual (FsEntryMakeValidFileName "abc.txt"    ) "abc.txt"    ;
  AssertEqual (FsEntryMakeValidFileName "dir/abc.txt") "dir_abc.txt";
  [String] $expect = switch((OsIsWindows)){
    ($true) { "doublequote(_) lessthan(_) greaterthan(_) pipe(_) backspace(_) null(_) tab(_) others(␦____)"; }
    default { "doublequote(`") lessthan(<) greaterthan(>) pipe(|) backspace(`b) null(_) tab(`t) others(␦*`?_\)"; }
  };
  AssertEqual (FsEntryMakeValidFileName "doublequote(`") lessthan(`<) greaterthan(`>) pipe(`|) backspace(`b) null(`0) tab(`t) others(␦*`?/\)") $expect;
  #
  AssertFsEntryIsEqualForCurrentOs (FsEntryMakeRelative "$HOME/MyDir/Dir1/File" "$HOME/MyDir/"      )   "Dir1/File";
  AssertFsEntryIsEqualForCurrentOs (FsEntryMakeRelative "$HOME/MyDir/Dir1/File" "$HOME/MyDir/" $true) "./Dir1/File";
  AssertFsEntryIsEqualForCurrentOs (FsEntryMakeRelative "$HOME/MyDir/File"      "$HOME/MyDir/"      ) "File"       ;
  AssertFsEntryIsEqualForCurrentOs (FsEntryMakeRelative "$HOME/MyDir/"          "$HOME/MyDir/"      ) "./"         ;
  #
  Assert ((FsEntryHasTrailingDirSep "$HOME/MyDir/") -eq $true );
  Assert ((FsEntryHasTrailingDirSep "$HOME/MyDir\") -eq $true );
  Assert ((FsEntryHasTrailingDirSep "$HOME/MyDir" ) -eq $false);
  #
  FsEntryAssertHasTrailingDirSep "$HOME/MyDir/";
  FsEntryAssertHasTrailingDirSep "$HOME/MyDir\";
  #
  if( OsIsWindows ){
    AssertFsEntryIsEqualForCurrentOs (FsEntryRemoveTrailingDirSep "C:/") "C:"; # TODO on macos this fails, find a solution
  }
  AssertFsEntryIsEqualForCurrentOs (FsEntryRemoveTrailingDirSep "$HOME/MyDir"  ) "$HOME/MyDir";
  AssertFsEntryIsEqualForCurrentOs (FsEntryRemoveTrailingDirSep "$HOME/MyDir/" ) "$HOME/MyDir";
  AssertFsEntryIsEqualForCurrentOs (FsEntryRemoveTrailingDirSep "$HOME/MyDir//") "$HOME/MyDir";
  #
  AssertFsEntryIsEqualForCurrentOs (FsEntryMakeTrailingDirSep "$HOME/MyDir"  ) "$HOME/MyDir/";
  AssertFsEntryIsEqualForCurrentOs (FsEntryMakeTrailingDirSep "$HOME/MyDir/" ) "$HOME/MyDir/";
  AssertFsEntryIsEqualForCurrentOs (FsEntryMakeTrailingDirSep "$HOME/MyDir//") "$HOME/MyDir/";
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
  # TODO: FsEntryFsInfoFullNameDirWithTrailDSep( [System.IO.FileSystemInfo] $fsInfo ) return [String] ($fsInfo.FullName+$(switch($fsInfo.PSIsContainer){($true){$(DirSep)}default{""}}));
  #
  function Test_FsEntryListAsFileSystemInfo(){
    [String]$d = FsEntryUnifyToSlashes (FsEntryRemoveTrailingDirSep (DirCreateTemp));
    #
    function StrArrToStr( [String[]] $a ){
      return [String] (($a | FsEntrySort | Where-Object{$null -ne $_} | ForEach-Object{ (StringRemoveLeft (FsEntryUnifyToSlashes $_) $d); }) -join ";");
    }
    function FseArrToStr( [System.IO.FileSystemInfo[]] $a ){
      return [String] (StrArrToStr ($a | Where-Object{$null -ne $_} | ForEach-Object{ FsEntryFsInfoFullNameDirWithTrailDSep $_; }));
    }
    #         "$d/";
    #         "$d/d1/";
    #         "$d/d1/d1/";
    FileTouch "$d/d1/d1/f1.txt";
    FileTouch "$d/d1/d1/f2.txt";
    #         "$d/d1/d2/";
    FileTouch "$d/d1/d2/f1.txt";
    FileTouch "$d/d1/d2/f2.txt";
    FileTouch "$d/d1/f1.txt";
    FileTouch "$d/d1/f2.txt";
    #         "$d/d2/";
    #         "$d/d2/d1/";
    FileTouch "$d/d2/d1/f1.txt";
    FileTouch "$d/d2/d1/f2.txt";
    #         "$d/d2/d2/";
    FileTouch "$d/d2/d2/f1.txt";
    FileTouch "$d/d2/d2/f2.txt";
    #         "$d/d2/d3/";
    FileTouch "$d/d2/d3/f1.txt";
    FileTouch "$d/d2/d3/f2.txt";
    FileTouch "$d/d2/f1.txt";
    FileTouch "$d/d2/f2.txt";
    FileTouch "$d/f1.txt";
    FileTouch "$d/f2.txt";
    # FsEntryListAsFileSystemInfo simple test
    Assert (FsEntryListAsFileSystemInfo "$d" | ForEach-Object{ FsEntryFsInfoFullNameDirWithTrailDSep $_; }).Count -gt 10;
    # test non-recursive
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false $notExistingFile   )) "";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false $notExistingDir    )) "";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d"               )) "/d1/;/d2/;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/"              )) "/d1/;/d2/;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/*"             )) "/d1/;/d2/;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/*/"            )) "/d1/;/d2/;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/**"            )) "/d1/;/d2/;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/*/*"           )) "/d1/d1/;/d1/d2/;/d1/f1.txt;/d1/f2.txt;/d2/d1/;/d2/d2/;/d2/d3/;/d2/f1.txt;/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d*"            )) "/d1/;/d2/";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d*/"           )) "/d1/;/d2/";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d?"            )) "/d1/;/d2/";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d?/"           )) "/d1/;/d2/";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d?/*"          )) "/d1/d1/;/d1/d2/;/d1/f1.txt;/d1/f2.txt;/d2/d1/;/d2/d2/;/d2/d3/;/d2/f1.txt;/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/d?"         )) "/d1/d1/;/d1/d2/";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/d?/"        )) "/d1/d1/;/d1/d2/";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/d?/*"       )) "/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/*1*/"       )) "/d1/d1/;/d1/f1.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/d2"         )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/d2/"        )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/d2/*"       )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/d2/*/"      )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/d2/*/*"     )) "";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/f1.txt"     )) "/d1/f1.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/*/f1.txt"   )) "/d1/d1/f1.txt;/d1/d2/f1.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d/d1/*/*/f1.txt" )) "";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d"  -includeDirs:$true  -includeFiles:$true )) "/d1/;/d2/;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d"  -includeDirs:$true  -includeFiles:$false)) "/d1/;/d2/";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d"  -includeDirs:$false -includeFiles:$true )) "/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "$d"  -includeDirs:$false -includeFiles:$false)) "";
    Push-Location "$d/"; AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "./f1.txt"    )) "/f1.txt"   ; Pop-Location;
    Push-Location "$d/"; AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false   "f1.txt"    )) "/f1.txt"   ; Pop-Location;
    Push-Location "$d/"; AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false "./d1/f1.txt" )) "/d1/f1.txt"; Pop-Location;
    Push-Location "$d/"; AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo -recursive:$false   "d1/f1.txt" )) "/d1/f1.txt"; Pop-Location;
    # test recursive
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo $notExistingFile   )) "";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo $notExistingDir    )) "";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d"               )) "/d1/;/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;/d2/;/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/"              )) "/d1/;/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;/d2/;/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/*"             )) "/d1/;/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;/d2/;/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/*/"            )) "/d1/;/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;/d2/;/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/**"            )) "/d1/;/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;/d2/;/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/*/*"           )) (    "/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;"+  "/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt;/f1.txt;/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d*"            )) (    "/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;"+  "/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d*/"           )) (    "/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;"+  "/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d?"            )) (    "/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;"+  "/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d?/"           )) (    "/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;"+  "/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d?/*"          )) (    "/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;"+  "/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/d?"         )) (             "/d1/d1/f1.txt;/d1/d1/f2.txt;"+     "/d1/d2/f1.txt;/d1/d2/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/d?/"        )) (             "/d1/d1/f1.txt;/d1/d1/f2.txt;"+     "/d1/d2/f1.txt;/d1/d2/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/d?/*"       )) (             "/d1/d1/f1.txt;/d1/d1/f2.txt;"+     "/d1/d2/f1.txt;/d1/d2/f2.txt");
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/*1*/"       )) (     "/d1/d1/;/d1/d1/f1.txt;"+                   "/d1/d2/f1.txt;/d1/f1.txt"   );
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/d2"         )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/d2/"        )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/d2/*"       )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/d2/*/"      )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/d2/*/*"     )) "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/f1.txt"     )) "/d1/d1/f1.txt;/d1/d2/f1.txt;/d1/f1.txt"
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/*/f1.txt"   )) "/d1/d1/f1.txt;/d1/d2/f1.txt;/d1/f1.txt"
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d/d1/*/*/f1.txt" )) "/d1/d1/f1.txt;/d1/d2/f1.txt"
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d"  -includeDirs:$true  -includeFiles:$true )) "/d1/;/d1/d1/;/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;/d2/;/d2/d1/;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d"  -includeDirs:$true  -includeFiles:$false)) "/d1/;/d1/d1/;/d1/d2/;/d2/;/d2/d1/;/d2/d2/;/d2/d3/";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d"  -includeDirs:$false -includeFiles:$true )) "/d1/d1/f1.txt;/d1/d1/f2.txt;/d1/d2/f1.txt;/d1/d2/f2.txt;/d1/f1.txt;/d1/f2.txt;/d2/d1/f1.txt;/d2/d1/f2.txt;/d2/d2/f1.txt;/d2/d2/f2.txt;/d2/d3/f1.txt;/d2/d3/f2.txt;/d2/f1.txt;/d2/f2.txt;/f1.txt;/f2.txt";
    AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "$d"  -includeDirs:$false -includeFiles:$false)) "";
    Push-Location "$d/"; AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "./f1.txt"    )) "/d1/d1/f1.txt;/d1/d2/f1.txt;/d1/f1.txt;/d2/d1/f1.txt;/d2/d2/f1.txt;/d2/d3/f1.txt;/d2/f1.txt;/f1.txt"; Pop-Location;
    Push-Location "$d/"; AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo   "f1.txt"    )) "/d1/d1/f1.txt;/d1/d2/f1.txt;/d1/f1.txt;/d2/d1/f1.txt;/d2/d2/f1.txt;/d2/d3/f1.txt;/d2/f1.txt;/f1.txt"; Pop-Location;
    Push-Location "$d/"; AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo "./d1/f1.txt" )) "/d1/d1/f1.txt;/d1/d2/f1.txt;/d1/f1.txt"                                                             ; Pop-Location;
    Push-Location "$d/"; AssertEqual (FseArrToStr (FsEntryListAsFileSystemInfo   "d1/f1.txt" )) "/d1/d1/f1.txt;/d1/d2/f1.txt;/d1/f1.txt"                                                             ; Pop-Location;
    # Test FsEntryListAsStringArray
    AssertEqual (StrArrToStr (FsEntryListAsStringArray "$d/d1/d2/" -recursive:$false))                     "/d1/d2/f1.txt;/d1/d2/f2.txt";
    AssertEqual (StrArrToStr (FsEntryListAsStringArray "$d/*"      -recursive:$true -includeFiles:$false)) "/d1/;/d1/d1/;/d1/d2/;/d2/;/d2/d1/;/d2/d2/;/d2/d3/";
    # TODO some performance relevant tests for later
    #   if( OsIsWindows ){ Assert ( (FsEntryListAsFileSystemInfo "$env:SystemRoot/explorer.exe"                      ).Count -gt 1); } #  C:\Windows\SysWOW64\explorer.exe;C:\Windows\WinSxS\amd64_microsoft-windows-explorer_31bf3856ad364e35_10.0.22621.5983_none_316c1953f574dbce\f\explorer.exe;...;
    #   if( OsIsWindows ){ Assert ( (FsEntryListAsFileSystemInfo "$env:SystemRoot/explorer.exe/"                     ).Count -eq 1); }
    #   if( OsIsWindows ){ Assert ( (FsEntryListAsFileSystemInfo "$env:SystemRoot/explorer.exe"  -includeDirs:$false ).Count -eq 1); }
    #   if( OsIsWindows ){ Assert ( (FsEntryListAsFileSystemInfo "$env:SystemRoot/explorer.exe"  -includeFiles:$false).Count -eq 0); }
    #   if( OsIsWindows ){ Assert ( (FsEntryListAsFileSystemInfo "$env:SystemRoot/explo*.exe"                        ).Count -gt 1); }
    #   if( OsIsWindows ){ Assert ( (FsEntryListAsFileSystemInfo "$env:SystemRoot/explo*.exe/"                       ).Count -gt 1); }
    #   if( OsIsWindows ){ Assert ( (FsEntryListAsFileSystemInfo "C:/Window*/explorer.exe"                           ).Count -eq 1); }
    #
    DirDelete "$d/";
  } Test_FsEntryListAsFileSystemInfo;
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
  Assert ((DirExists "") -eq $false);
  Assert ((DirExists $notExistingDir) -eq $false);
  Assert ((DirExists $(switch((OsIsWindows)){($true){"C:\Windows\"}($false){"/home/"}})) -eq $true); # $env:SystemRoot
  #
  Assert ((DirNotExists ""));
  Assert ((DirNotExists $notExistingDir));
  Assert ((DirNotExists $(switch((OsIsWindows)){($true){"C:\Windows\"}($false){"/home/"}})) -eq $false); # $env:SystemRoot
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
    [String] $text1 = "ä$([Environment]::NewLine)öü";
    [String] $text2 = switch(OsIsWindows){($true){$text1}($false){$text0}};
    OutProgress "Test_FileReadContentAsString beg";
    function WriteText( [String] $enc ){ FileWriteFromString $src $text0 $true $enc; }
    function ReadText ( [String] $enc ){ [String] $s = (FileReadContentAsString $src $enc) -replace "`r",'CR' -replace "`n",'LF'; OutProgress "Text : `"$s`""; }
    #
    WriteText "UTF8BOM"; ReadText "Default";                                       Assert ((FileReadContentAsString $src "Default") -eq $text0);
    WriteText "UTF8BOM"; ReadText "UTF8"   ;                                       Assert ((FileReadContentAsString $src "UTF8"   ) -eq $text0);
    WriteText "Default"; ReadText "Default";                                       Assert ((FileReadContentAsString $src "Default") -eq $text2);
    WriteText "Default"; ReadText "UTF8"   ; if( -not (ProcessIsLesserEqualPs5) ){ Assert ((FileReadContentAsString $src "UTF8"   ) -eq $text2); } # TODO fails in ps5, text is "�CRLF��"
    if( -not (ProcessIsLesserEqualPs5) ){
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
  # TODO: FileDelTempFile                      ( [String] $file ) if( FileExists $file )
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
  function Test_FileDelete(){
    [String] $tmpFile1 = (FileGetTempFile); FileWriteFromString $tmpFile1 "Hello`n World`n" $true;
    Assert (FileExists $tmpFile1);
    FileDelete $tmpFile1 -ignoreReadonly:$true -ignoreAccessDenied:$false;
    Assert (FileNotExists $tmpFile1);
  } Test_FileDelete;
  #
  function Test_FileCopy(){
    [String] $tmpFile1 = (FileGetTempFile); FileWriteFromString $tmpFile1 "Hello`n World`n" $true;
    [String] $tmpFile2 = (FileGetTempFile); FileWriteFromString $tmpFile2 "Hello`n World2`n" $true;
    FileCopy $tmpFile1 $tmpFile2 -overwrite:$true;
    Assert (FileContentsAreEqual $tmpFile1 $tmpFile2);
    FileDelTempFile $tmpFile1;
    FileDelTempFile $tmpFile2;
  } Test_FileCopy;
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
  { [String] $tmpFile1 = (FileGetTempFile); FileWriteFromString $tmpFile1 "abc" $true "UTF8"; Assert ((FileGetHexStringOfHash128BitsMd5  $tmpFile1) -eq "900150983CD24FB0D6963F7D28E17F72"); }
  #
  { [String] $tmpFile1 = (FileGetTempFile); FileWriteFromString $tmpFile1 "abc" $true "UTF8"; Assert ((FileGetHexStringOfHash256BitsSha2 $tmpFile1) -eq "BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD"); }
  #
  { [String] $tmpFile1 = (FileGetTempFile); FileWriteFromString $tmpFile1 "abc" $true "UTF8"; Assert ((FileGetHexStringOfHash512BitsSha2 $tmpFile1) -eq "DDAF35A193617ABACC417349AE20413112E6FA4E89A97EA20A9EEEE64B55D39A2192992A274FC1A836BA3C23A3FEEBBD454D4423643CE80E2A9AC94FA54CA49F"); }
  #
  # TODO: FileUpdateItsHashSha2FileIfNessessary ( [String] $srcFile )
  #
}
UnitTest_FsEntry_Dir_File;
