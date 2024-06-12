#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_Win_Tool(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! (OsIsWindows) ){ OutProgress "Not running on windows, so bypass test."; return; }
    # if( "TEST_THIS_IS_NOT_NESSESSARY" -eq "" ){
  # TODO:
#   windows: ToolGitTortoiseCommit                    ( [String] $workDir, [String] $commitMessage = "" ){
  #   ToolRdpConnect                       ( [String] $rdpfile, [String] $mstscOptions = "" ){
  #                                          # Some mstsc options: /edit /admin  (use /edit temporary to set password in .rdp file)
  #                                        }
  #   ToolHibernateModeEnable              (){
  #   ToolHibernateModeDisable             (){
  #   ToolActualizeHostsFileByMaster       ( [String] $srcHostsFile ){
  #   ToolCreateLnkIfNotExists             ( [Boolean] $forceRecreate, [String] $workDir, [String] $lnkFile, [String] $srcFile, [String[]] $arguments = @(),
  #                                            [Boolean] $runElevated = $false, [Boolean] $ignoreIfSrcFileNotExists = $false ){
  #                                          # Example: ToolCreateLnkIfNotExists $false "" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\LinkToNotepad.lnk" "C:\Windows\notepad.exe";
  #                                          # Example: ToolCreateLnkIfNotExists $false "" "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\LinkToNotepad.lnk" "C:\Windows\notepad.exe";
  #                                          # If $forceRecreate is false and target lnkfile already exists then it does nothing.
  #   ToolCreateMenuLinksByMenuItemRefFile ( [String] $targetMenuRootDir, [String] $sourceDir,
  #                                          [String] $srcFileExtMenuLink    = ".menulink.txt",
  #                                          [String] $srcFileExtMenuLinkOpt = ".menulinkoptional.txt" ){
  #                                          # Create menu entries based on menu-item-linkfiles below a dir.
  #                                          # - targetMenuRootDir      : target start menu folder, example: "$env:APPDATA\Microsoft\Windows\Start Menu\Apps"
  #                                          # - sourceDir              : Used to finds all files below sourceDir with the extension (example: ".menulink.txt").
  #                                          #                            For each of these files it will create a menu item below the target menu root dir.
  #                                          # - srcFileExtMenuLink     : Extension for mandatory menu linkfiles. The containing referenced command (in general an executable) must exist.
  #                                          # - $srcFileExtMenuLinkOpt : Extension for optional  menu linkfiles. Menu item is created only if the containing referenced executable will exist.
  #                                          # The name of the target menu item (example: "Manufactor ProgramName V1") will be taken from the name
  #                                          #   of the menu-item-linkfile (example: ...\Manufactor ProgramName V1.menulink.txt) without the extension (example: ".menulink.txt")
  #                                          #   and the sub menu folder will be taken from the relative location of the menu-item-linkfile below the sourceDir.
  #                                          # The command for the target menu will be taken from the first line (example: "D:\MyApps\Manufactor ProgramName\AnyProgram.exe")
  #                                          #   of the content of the menu-item-linkfile.
  #                                          # If target lnkfile already exists it does nothing.
  #                                          # Example: ToolCreateMenuLinksByMenuItemRefFile "$env:APPDATA\Microsoft\Windows\Start Menu\Apps" "D:\MyApps" ".menulink.txt";
  #   ToolSignDotNetAssembly               ( [String] $keySnk, [String] $srcDllOrExe, [String] $tarDllOrExe, [Boolean] $overwrite = $false ){
  #                                          # Note: Generate a key: sn.exe -k mykey.snk
  #   ToolSetAssocFileExtToCmd             ( [String[]] $fileExtensions, [String] $cmd, [String] $ftype = "", [Boolean] $assertPrgExists = $false ){
  #                                          # Sets the association of a file extension to a command by overwriting it.
  #                                          # FileExtensions: must begin with a dot, must not content blanks or commas,
  #                                          #   if it is only a dot then it is used for files without a file ext.
  #                                          # Cmd: if it is empty then association is deleted.
  #                                          #  Can contain variables as %SystemRoot% which will be replaced at runtime.
  #                                          #   If cmd does not begin with embedded double quotes then it is interpreted as a full path to an executable
  #                                          #   otherwise it uses the cmd as it is.
  #                                          # Ftype: Is a group of file extensions. If it not yet exists then a default will be created
  #                                          #   in the style {extWithoutDot}file (example: ps1file).
  #                                          # AssertPrgExists: You can assert that the program in the command must exist but note that
  #                                          #   variables enclosed in % char cannot be expanded because these are not powershell variables.
  #                                          # Example: ToolSetAssocFileExtToCmd @(".log",".out") "$env:SystemRoot\System32\notepad.exe" "" $true;
  #                                          # Example: ToolSetAssocFileExtToCmd ".log"           "$env:SystemRoot\System32\notepad.exe";
  #                                          # Example: ToolSetAssocFileExtToCmd ".log"           "%SystemRoot%\System32\notepad.exe" "txtfile";
  #                                          # Example: ToolSetAssocFileExtToCmd ".out"           "`"C:\Any.exe`" `"%1`" -xy";
  #                                          # Example: ToolSetAssocFileExtToCmd ".out" "";
  Assert         (((ToolVsUserFolderGetLatestUsed) -eq "") -or ((ToolVsUserFolderGetLatestUsed).Contains("\\AppData\\Local\\Microsoft\\VisualStudio\\16.0")) -or ((ToolVsUserFolderGetLatestUsed).Contains("\\AppData\\Local\\Microsoft\\VisualStudio\\17.0")));
  #   ToolOsWindowsResetSystemFileIntegrity(){ # uses about 4 min
  #   ToolPerformFileUpdateAndIsActualized ( [String] $targetFile, [String] $url, [Boolean] $requireElevatedAdminMode = $false,
  #                                            [Boolean] $doWaitIfFailed = $false, [String] $additionalOkUpdMsg = "",
  #                                            [Boolean] $assertFilePreviouslyExists = $true, [Boolean] $performPing = $true ){
  #                                          # Check if target file exists, checking wether host is reachable by ping, downloads the file, check for differences,
  #                                          # check for admin mode, overwriting the file and a success message is given out.
  #                                          # Otherwise if it failed it will output a warning message and optionally wait for pressing enter key.
  #                                          # It returns true if the file is now actualized.
  #                                          # Note: if not in elevated admin mode and if it is required then it will download file twice,
  #                                          #   once to check for differences and once after switching to elevated admin mode.
  #                                          # Example: ToolPerformFileUpdateAndIsActualized "C:\Temp\a.psm1" "https://raw.githubusercontent.com/mniederw/MnCommonPsToolLib/master/MnCommonPsToolLib/MnCommonPsToolLib.psm1" $true $true "Please restart" $false $true;

  if( -not (ProcessIsRunningInElevatedAdminMode) ){ OutProgress "Not running in elevated mode, so bypass test."; return; }
  OutProgress "ToolWin10PackageGetState of OpenSSH.Client: $(ToolWin10PackageGetState "OpenSSH.Client") ";
  if( "TEST_DISCARDED_BECAUSE_CHANGES_SYSTEM" -eq "" ){ ToolWin10PackageInstall   "OpenSSH.Client"; }
  if( "TEST_DISCARDED_BECAUSE_CHANGES_SYSTEM" -eq "" ){ ToolWin10PackageDeinstall "OpenSSH.Client"; }
}
UnitTest_Win_Tool;
