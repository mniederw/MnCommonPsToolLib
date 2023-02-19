#!/usr/bin/env pwsh

# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Tool(){
  OutProgress (ScriptGetCurrentFuncName);
  if( ! OsIsWindows ){ OutProgress "Not running on windows, so bypass test."; return; }
  Assert         (((ToolVs2019UserFolderGetLatestUsed) -eq "") -or ((ToolVs2019UserFolderGetLatestUsed).Contains("\\AppData\\Local\\Microsoft\\VisualStudio\\16.0")));
  # TODO:
  #   ToolTailFile                         ( [String] $file ){ OutProgress "Show tail of file until ctrl-c is entered"; Get-Content -Wait $file; }
  #   ToolRdpConnect                       ( [String] $rdpfile, [String] $mstscOptions = "" ){
  #                                          # Some mstsc options: /edit /admin  (use /edit temporary to set password in .rdp file)
  #                                        }
  #   ToolHibernateModeEnable              (){
  #   ToolHibernateModeDisable             (){
  #   ToolActualizeHostsFileByMaster       ( [String] $srcHostsFile ){
  #   ToolAddLineToConfigFile              ( [String] $file, [String] $line, [String] $encoding = "UTF8" ){ # if file not exists or line not found case sensitive in file then the line is appended
  #   ToolCreate7zip                       ( [String] $srcDirOrFile, [String] $tar7zipFile ){ # target must end with 7z. uses 7z.exe in path or in "C:/Program Files/7-Zip/"
  #   ToolUnzip                            ( [String] $srcZipFile, [String] $tarDir ){ # tarDir is created if it not exists, no overwriting, requires DotNetFX4.5.
  #   ToolCreateLnkIfNotExists             ( [Boolean] $forceRecreate, [String] $workDir, [String] $lnkFile, [String] $srcFile, [String[]] $arguments = @(),
  #                                            [Boolean] $runElevated = $false, [Boolean] $ignoreIfSrcFileNotExists = $false ){
  #                                          # ex: ToolCreateLnkIfNotExists $false "" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\LinkToNotepad.lnk" "C:\Windows\notepad.exe";
  #                                          # ex: ToolCreateLnkIfNotExists $false "" "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\LinkToNotepad.lnk" "C:\Windows\notepad.exe";
  #                                          # If $forceRecreate is false and target lnkfile already exists then it does nothing.
  #   ToolCreateMenuLinksByMenuItemRefFile ( [String] $targetMenuRootDir, [String] $sourceDir,
  #                                          [String] $srcFileExtMenuLink    = ".menulink.txt",
  #                                          [String] $srcFileExtMenuLinkOpt = ".menulinkoptional.txt" ){
  #                                          # Create menu entries based on menu-item-linkfiles below a dir.
  #                                          # - targetMenuRootDir      : target start menu folder, example: "$env:APPDATA\Microsoft\Windows\Start Menu\Apps"
  #                                          # - sourceDir              : Used to finds all files below sourceDir with the extension (ex: ".menulink.txt").
  #                                          #                            For each of these files it will create a menu item below the target menu root dir.
  #                                          # - srcFileExtMenuLink     : Extension for mandatory menu linkfiles. The containing referenced command (in general an executable) must exist.
  #                                          # - $srcFileExtMenuLinkOpt : Extension for optional  menu linkfiles. Menu item is created only if the containing referenced executable will exist.
  #                                          # The name of the target menu item (ex: "Manufactor ProgramName V1") will be taken from the name
  #                                          #   of the menu-item-linkfile (ex: ...\Manufactor ProgramName V1.menulink.txt) without the extension (ex: ".menulink.txt")
  #                                          #   and the sub menu folder will be taken from the relative location of the menu-item-linkfile below the sourceDir.
  #                                          # The command for the target menu will be taken from the first line (ex: "D:\MyApps\Manufactor ProgramName\AnyProgram.exe")
  #                                          #   of the content of the menu-item-linkfile.
  #                                          # If target lnkfile already exists it does nothing.
  #                                          # Example: ToolCreateMenuLinksByMenuItemRefFile "$env:APPDATA\Microsoft\Windows\Start Menu\Apps" "D:\MyApps" ".menulink.txt";
  #   ToolSignDotNetAssembly               ( [String] $keySnk, [String] $srcDllOrExe, [String] $tarDllOrExe, [Boolean] $overwrite = $false ){
  #                                          # Note: Generate a key: sn.exe -k mykey.snk
  #   ToolGithubApiListOrgRepos            ( [String] $org, [System.Management.Automation.PSCredential] $cred = $null ){
  #                                          # List all repos (ordered by archived and url) from an org on github.
  #                                          # If user and its Personal-Access-Token PAT instead of password is specified then not only public
  #                                          # but also private repos are listed.
  #   ToolGithubApiAssertValidRepoUrl      ( [String] $repoUrl ){
  #                                          # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
  #   ToolGithubApiDownloadLatestReleaseDir( [String] $repoUrl ){
  #                                          # Creates a unique temp dir, downloads zip, return folder of extracted zip; You should remove dir after usage.
  #                                          # Latest release is the most recent non-prerelease, non-draft release, sorted by its last commit-date.
  #                                          # Example repoUrl="https://github.com/mniederw/MnCommonPsToolLib/"
  #   ToolSetAssocFileExtToCmd             ( [String[]] $fileExtensions, [String] $cmd, [String] $ftype = "", [Boolean] $assertPrgExists = $false ){
  #                                          # Sets the association of a file extension to a command by overwriting it.
  #                                          # FileExtensions: must begin with a dot, must not content blanks or commas,
  #                                          #   if it is only a dot then it is used for files without a file ext.
  #                                          # Cmd: if it is empty then association is deleted.
  #                                          #  Can contain variables as %SystemRoot% which will be replaced at runtime.
  #                                          #   If cmd does not begin with embedded double quotes then it is interpreted as a full path to an executable
  #                                          #   otherwise it uses the cmd as it is.
  #                                          # Ftype: Is a group of file extensions. If it not yet exists then a default will be created
  #                                          #   in the style {extWithoutDot}file (ex: ps1file).
  #                                          # AssertPrgExists: You can assert that the program in the command must exist but note that
  #                                          #   variables enclosed in % char cannot be expanded because these are not powershell variables.
  #                                          # ex: ToolSetAssocFileExtToCmd @(".log",".out") "$env:SystemRoot\System32\notepad.exe" "" $true;
  #                                          # ex: ToolSetAssocFileExtToCmd ".log"           "$env:SystemRoot\System32\notepad.exe";
  #                                          # ex: ToolSetAssocFileExtToCmd ".log"           "%SystemRoot%\System32\notepad.exe" "txtfile";
  #                                          # ex: ToolSetAssocFileExtToCmd ".out"           "`"C:\Any.exe`" `"%1`" -xy";
  #                                          # ex: ToolSetAssocFileExtToCmd ".out" "";
  #   ToolVs2019UserFolderGetLatestUsed    (){
  #                                          # return the current visual studio 2019 config folder or empty string if it not exits.
  #                                          # example: "$env:LOCALAPPDATA\Microsoft\VisualStudio\16.0_d70392ef\"
  #   ToolWin10PackageGetState             ( [String] $packageName ){ # ex: for "OpenSSH.Client" return "Installed","NotPresent".
  #   ToolWin10PackageInstall              ( [String] $packageName ){ # ex: "OpenSSH.Client"
  #   ToolWin10PackageDeinstall            ( [String] $packageName ){
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
}
Test_Tool;
