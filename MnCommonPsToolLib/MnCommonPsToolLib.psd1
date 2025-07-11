﻿# Module manifest for module 'MnCommonPsToolLib'

@{
  RootModule             = 'MnCommonPsToolLib.psm1';
  GUID                   = 'b0d61b3d-cd52-4b36-82e1-df89c8476128';
  Author                 = 'Marc Niederwieser';
  CompanyName            = 'Private, Marc Niederwieser, Switzerland.';
  Copyright              = 'Copyright © by Marc Niederwieser, Switzerland, 2013-2025. Licensed under GPL3.';
  Description            = 'Common Powershell Tool Library for PS5.1 and PS7 and works on multiplatforms (Windows, Linux and OSX)';
  PowerShellVersion      = '5.1'; # minimum version
  VariablesToExport      = '*';
  DotNetFrameworkVersion = '4.0';
  ClrVersion             = '4.0';
  ProcessorArchitecture  = 'None';
  FunctionsToExport      = @('*');
  CmdletsToExport        = @();
  AliasesToExport        = @();
  NestedModules          = @();
  CompatiblePSEditions   = @();
  RequiredModules        = @();
  PowerShellHostName     = '';
  PowerShellHostVersion  = '';
  PrivateData = @{
    PSData = @{
      Tags                       = @( 'MN', 'Common', 'Tool', 'Library', 'multiplatform' )
      LicenseUri                 = 'https://github.com/mniederw/MnCommonPsToolLib/blob/main/LICENSE_GPL3.txt'
      ProjectUri                 = 'https://github.com/mniederw/MnCommonPsToolLib'
      RequireLicenseAcceptance   = $false
      ExternalModuleDependencies = @()
      ReleaseNotes               = ''
      IconUri                    = ''
      Prerelease                 = ''
    }
  }
  #HelpInfoURI            = '';

  ModuleVersion          = '7.98';

  <#
  Releasenotes
  ------------

  Major version will reflect breaking changes, minor identifies extensions and third number identifies urgent bugfixes.
  Breaking changes are usually removed deprecated functions or changed behaviours.

  2025-07-03  V7.98  Add GitBranchExists, GitAddAll, GitCommit, GitPush.
  2025-07-02  V7.97  Extend ToolWingetInstallPackage.
  2025-07-02  V7.96  Extend 7zip to create also a zip. Improve ToolWinGetCleanLine, ToolWingetInstallPackage, ToolWingetUninstallPackage. Add dquotes to output of fsentries.
  2025-07-02  V7.95  Add GithubBranchExists, GithubBranchDelete. Improved ProcessStart by either return full string or full output to throwed error.
  2025-06-18  V7.94  Improve ToolWinGetCleanLine, ToolWinGetSetup, ToolWingetListUpgradablePackages, ToolWingetUpdateInstalledPackages.
  2025-06-18  V7.93  Add Doc. Improve FileReadEncoding, RegistryImportFile.
  2025-05-23  V7.92  Add Doc. Improve GitMerge.
  2025-05-20  V7.91  Extend and rename ToolEvalVsCodeExec to ToolEvalExecForVsCode. Add FileFindFirstExisting, ToolEvalExecForWindsurf.
  2025-05-18  V7.90  Extend Install.
  2025-05-07  V7.89  Add AllUsersMenuStartupDir, Improve ToolInstallNuPckMgrAndCommonPsGalMo.
  2025-04-02  V7.88  Add ServiceDisable.
  2025-03-07  V7.87  Add GitInitGlobalConfig, Improve ToolInstallNuPckMgrAndCommonPsGalMo.
  2025-02-23  V7.86  Add StringArrayGetMaxItemLength, ToolWingetListUpgradablePackages. Adapt ToolWinGetSetup. Improve ToolWingetListInstalledPackages, ToolWingetUpdateInstalledPackages, ToolWingetInstallPackage, ToolWingetUninstallPackage.
  2025-02-20  V7.85  Improve MnCommonPsToolLibSelfUpdate.
  2025-02-19  V7.84  Improve mt behaviour for GitCloneOrPullUrls. Add NetRequestStatusCode.
  2025-02-16  V7.83  Improve ToolWinGetSetup, ToolWingetInstallPackage.
  2025-02-10  V7.82  Fix ToolWingetListInstalledPackages. Improve ToolInstallNuPckMgrAndCommonPsGalMo.
  2025-02-09  V7.81  Improve ToolInstallNuPckMgrAndCommonPsGalMo, ToolWinGetCleanLine. Fix OutError, OutWarning.
  2025-02-05  V7.80  Improve install nuget. Improve StreamToTableString, ToolWingetInstallPackage.
  2025-02-04  V7.79  Suppress warning. Improve FsEntryListAsFileSystemInfo Rename FsEntryFsInfoFullNameDirWithBackSlash to FsEntryFsInfoFullNameDirWithTrailDSep. Prepare for default utf8. Modify install nuget.
  2025-01-05  V7.78  Improve NetDownloadSite.
  2025-01-02  V7.77  DirNotExists allow empty string; Extend ProcessStart. Improve OsWindowsRegRunDisable.
  2024-12-26  V7.76  Fix CreateUser.
  2024-12-26  V7.75  Set utf8. Improve winget output filter.
  2024-12-26  V7.74  Doc PSWindowsUpdate. Fix OsWinCreateUser.
  2024-12-20  V7.73  Add ToolFileNormalizeNewline. Extend StreamToCsvFile. Fix FileWriteFromString. Fixing UTF8BOM problems. Remove default arg from FileReadContentAsString, FileReadContentAsLines. Overflow args default to false.
  2024-11-29  V7.72  Improve GitShowBranch, ToolWinGetSetup. Added ToolWingetUpdateInstalledPackages.
  2024-11-28  V7.71  Doc. Improve ToolWinGetSetup, ToolWingetInstallPackage, ToolWingetUninstallPackage, ToolWingetListInstalledPackages. Deprecate ProcessListInstalledAppx. Add OsWindowsAppxListInstalled, OsIsWin11OrHigher.
  2024-10-06  V7.70  Add FsEntryGetAttribute, FsEntrySetAttribute. Improve ConsoleSetGuiProperties.
  2024-09-09  V7.69  Add OsWindowsUpdateEnableNonOsAppUpdates, OsWindowsUpdatePackagesShowPending, OsWindowsUpdatePerform. Improve output lines.
  2024-09-08  V7.68  Extend Doc. Fix Installer by using NoProfile for Get-ExecutionPolicy. Add OsWinCreateUser, ToolWinGetSetup, ToolWingetInstallPackage, ToolWingetUninstallPackage, ToolWingetListInstalledPackages.
  2024-08-26  V7.67  Fix DriveFreeSpace.
  2024-08-18  V7.66  Fix FsEntryGetAbsolutePath, FsEntryListAsFileSystemInfo, DriveFreeSpace. Deprecate SvnExe. Extend OsWindowsRegRunDisable.
  2024-08-13  V7.65  Added ProcessStartByArray, ProcessStartByCmdLine. OsWindowsPackageListInstalled, OsWindowsPackageUninstall, OsWindowsRegRunDisable. Extend Doc. Improve ToolInstallNuPckMgrAndCommonPsGalMo, TaskIsDisabled, OsWindowsPackageUninstall.
  2024-08-10  V7.64  Extend Doc.
  2024-08-08  V7.63  Extend Install options. Use portable username and computername. Improve linux portability.
  2024-08-06  V7.62  Extend Install with option InstallAlternative.
  2024-07-16  V7.61  Fix Self-Update.
  2024-07-14  V7.60  Extend Doc. Move Releasenotes.
  2024-07-11  V7.59  Add NetConvertMacToIPv6byEUI64.
  2024-06-20  V7.58  Change git pull to origin and assert remote-name and url.
  2024-06-12  V7.57  Add yml doc. Add ToolVsUserFolderGetLatestUsed. ToolVs2019UserFolderGetLatestUsed is deprecated.
  2024-04-30  V7.56  Fix StringSplitToArray and extend its unittest.
  2024-04-11  V7.55  Fix ToolSignDotNetAssembly , installer.
  2024-03-25  V7.54  Add FsEntryRelativeMakeTrailingDirSep.
  2024-03-16  V7.53  Improve Assertions. Improve update modules. Fix FsEntryGetAbsolutePath. Unify trap block.
  2024-03-13  V7.52  Add functions. Add ToolFindOppositeProfileFromPs5orPs7, ToolAddToProfileIfFullPathNotEmpty, FileSyncContent. Extend InfoAboutComputerOverview. Fix some array null problems.
  2024-03-10  V7.51  Change OutProgress. Deprecated OutStringInColor, OutSuccess. Unify function names.
  2024-03-09  V7.50  Fix ProcessStart.
  2024-03-07  V7.49  Added ToolNpmFilterIgnorableInstallMessages.
  2024-03-01  V7.48  Reorg Unittests.
  2024-02-27  V7.47  Improve AssertRcIsOk, Unittests. Change yml.
  2024-02-25  V7.46  Fix ProcessStart. Fix some script analyser warnings. Deprecated ModeNoWaitForEnterAtEnd, StdOutBegMsgCareInteractiveMode, StdOutEndMsgCareInteractiveMode. Improve script analyser. Replace some Write-Host. Move some functions to windows part.
  2024-02-22  V7.45  Add FsEntryUnifyDirSep, StringExistsInStringArray, ProcessEnvVarPathAdd, ProcessEnvVarList, ToolManuallyDownloadAndInstallProg. Fix ProcessRefreshEnvVars. Improve ToolCreateLnkIfNotExists, MnCommonPsToolLibSelfUpdate.
  2024-02-16  V7.44  Expects always a dir separator for specifying dirs (currently only a warning, later it throws), Update FsEntryMakeTrailingDirSep, FsEntryGetParentDir. Deprecated FsEntryIsEqual (use FsEntryPathIsEqual).
  2024-02-11  V7.43  Fix GitAssertAutoCrLfIsDisabled, Update Doc.
  2024-02-07  V7.42  Add ProcessRefreshEnvVars.
  2024-02-04  V7.41  Add GitBranchList, StringRemoveLeftNr.
  2024-02-02  V7.40  Fix GitSetGlobalVar, GitDisableAutoCrLf.
  2024-02-02  V7.39  Fix and doc GitAssertAutoCrLfIsDisabled.
  2024-01-30  V7.38  Fix GithubMergeOpenPr.
  2024-01-30  V7.37  Add OsPathSeparator. Improve Installer.
  2024-01-28  V7.36  Improve GitShowBranch.
  2024-01-21  V7.35  Add GithubMergeOpenPr.
  2024-01-21  V7.34  Improve GitCloneOrPullUrls, fix git-restore, modify GitCloneOrPull, extend Doc, make NetPingHostIsConnectable portable, modify FileContentsAreEqual, modify SqlGetCmdExe.
  2024-01-19  V7.33  Extend ToolSignDotNetAssembly, extend GitCmd, extend Doc.
  2023-12-28  V7.32  Improve NetDownloadFile by using wget2.
  2023-12-03  V7.31  Make ConsoleSetGuiProperties portable for linux. Improve install for linux.
  2023-11-13  V7.30  Improve DateTimeFromStringIso, Fix portability issues in DateTimeFromStringOrDateTimeValue, ToolGithubApiDownloadLatestReleaseDir. Add Unittests.
  2023-11-12  V7.29  Fix StringSplitToArray and extend its unittest.
  2023-11-01  V7.28  Add ToolListBranchCommit. Extend ProcessEnvVarSet by traceCmd.
  2023-10-21  V7.27  Add FsEntryGetSize, unify using computername var.
  2023-09-05  V7.26  Improve GitGetBranch. Fix OsIsWinScreenLocked. Added DateTimeFromStringOrDateTimeValue.
  2023-07-07  V7.25  Improve ForEachParallel. Extend Install.ps1 for linux. Improve Import-Module handling. Fix OutStopTranscript.
  2023-07-11  V7.24  Fix OutStartTranscriptInTempDir, remove gh update notification, improve gh action.
  2023-06-09  V7.23  Add RegistryKeyGetOwnerAsString, Improve RegistryKeySetOwner.
  2023-05-08  V7.22  Specialize encoding from UTF8 to UTF8BOM for StreamToCsvFile, StreamToXmlFile, StreamToFile, FileWriteFromString, FileWriteFromLines, FileCreateEmpty, FileAppendLine, FileAppendLines, ToolAddLineToConfigFile.
  2023-05-02  V7.21  Fix AssertRcIsOk.
  2023-05-01  V7.20  Fix SvnRevert, fix ProcessStart, extend ToolInstallNuPckMgrAndCommonPsGalMo, extend OutStartTranscriptInTempDir.
  2023-04-13  V7.19  Fix OutStartTranscriptInTempDir.
  2023-03-13  V7.18  Add FsEntryIsEqual. Fix NetDownloadFileByCurl. Doc ProcessStart, Extend InfoGetInstalledDotNetVersion.
  2023-03-09  V7.17  Add retry in NetDownloadFileByCurl. Improve InstallEnablePowerShellToUnrestrictedRequiresAdminRights.
  2023-03-08  V7.16  Fix ProcessListInstalledAppx for PS7. Add StreamToStringIndented.
  2023-03-05  V7.15  Fix FsEntryTrySetOwnerAndAclsIfNotSet.
  2023-03-02  V7.14  Fix ProcessRestartInElevatedAdminMode for pwsh.
  2023-02-28  V7.13  Extend yml, fix InfoAboutComputerOverview. Improve OsIsWindows. Add ProcessIsLesserEqualPs5, ProcessPsExecutable. Make portable: ProcessIsRunningInElevatedAdminMode.
  2023-02-19  V7.12  Extend ToolInstallNuPckMgrAndCommonPsGalMo. Added OsIsWindows. Doc PSModulePath. Fix MnCommonPsToolLibSelfUpdate.
  2023-02-01  V7.11  Extend SvnCheckoutAndUpdate, Improve Install.ps1 for pwsh, extend EnablePowerShell-bat-file for pwsh.
  2023-01-02  V7.10  Fix name ToolRdpConnect.
  2023-01-02  V7.09  Fix MnCommonPsToolLibSelfUpdate.
  2022-12-12  V7.08  Improve GitAssertAutoCrLfIsDisabled, fix GitSetGlobalVar.
  2022-12-08  V7.07  Added ToolInstallNuPckMgrAndCommonPsGalMo. Fix MnCommonPsToolLibSelfUpdate.
  2022-12-07  V7.06  Fix tfs url.
  2022-12-04  V7.05  Extend ToolCreateLnkIfNotExists by icon files, Added GetSetGlobalVar.
  2022-11-25  V7.04  Improve tfs get.
  2022-11-08  V7.03  Convert all to UTF8-BOM, improve github action.
  2022-11-07  V7.02  Move non portable functions to MnCommonPsToolLib_Windows.ps1, fixed tests
  2022-10-17  V7.00  MakePortable Wmi to Cim, ServiceListExistings returntype from [System.Management.ManagementObject[]] to [CimInstance[]],
                     InfoAboutSystemInfo, InfoAboutExistingShares.
                     Remove deprecated: GitCloneOrFetchOrPull, GitCloneOrFetchIgnoreError, GitCloneOrPullIgnoreError, ToolTfsInitLocalWorkspaceIfNotDone,
                     FsEntryHasTrailingBackslash, FsEntryRemoveTrailingBackslash, FsEntryMakeTrailingBackslash.
                     Removed ShareListAllByWmi, ShareCreateByWmi, ShareRemoveByWmi.
                     Fixed returntype of ServiceListExistingsAsStringArray, ProcessListRunningsAsStringArray.

  2022-10-04  V6.28  Added DateTimeNowAsStringIsoYear, make compatible: Test-Connection.
  2022-09-18  V6.27  Added FsEntryIsSymLink.
  2022-08-08  V6.26  Improved GithubCreatePullRequest.
  2022-08-07  V6.25  Improved ProcessStart, GithubListPullRequests, GithubCreatePullRequest. Added GitShowRepo
  2022-08-07  V6.24  Added GitSwitch, GitAdd, GithubAuthStatus, GithubCreatePullRequest. Improved GitShowBranch. Extended github workflow.
  2022-08-02  V6.23  Improved DirCreateTemp, Added GitMerge. Improved AssertRcIsOk.
  2022-07-16  V6.22  Fixed RegistryImportFile.
  2022-07-13  V6.21  Extended OutStartTranscriptInTempDir.
  2022-07-04  V6.20  Added ToolInstallOrUpdate. Fixed TfsInitLocalWorkspaceIfNotDone.
  2022-06-23  V6.19  Improved error handling. Added shebang.
  2022-06-16  V6.18  Improved OutStartTranscriptInTempDir by returning logfile filepath.
  2022-06-15  V6.17  Improved output of exception messages.
  2022-05-22  V6.16  Fixed git log warnings.
  2022-05-09  V6.15  Fixed using Write-Host.
  2022-04-19  V6.14  Fixed ProcessStart. Fixed StringIsNullOrWhiteSpace to StringIsFilled.
                     ToolTfsInitLocalWorkspaceIfNotDone deprecated and replaced by TfsInitLocalWorkspaceIfNotDone.
                     Refactored unit tests.
  2022-04-18  V6.13  Fixed ProcessStart. Improve GitCmd. Extended GitTortoiseCommit. Added GitShowUrl, StreamFromCsvStrings, StreamToFile.
  2022-04-12  V6.12  Fixed GitListCommitComments.
  2022-04-12  V6.11  Improvee UnitTest, console properties. Added TestAll.ps1.
  2022-04-09  V6.10  Improved download logging, updated doc, Added OutStartTranscriptInTempDir. Switch to Write-Output.
  2022-04-08  V6.09  Improved ProcessRemoveAllAlias.
  2022-04-04  V6.08  Added StringArrayContains, StringArrayDblQuoteItems, ProcessRemoveAllAlias, ToolAddLineToConfigFile. Extended ProcessStart for ps1 files.
  2022-03-20  V6.07  Unified warning messages, modify 7zip tool, make usage of dir-separator more portable.
                     Deprecated FsEntryHasTrailingBackslash, FsEntryRemoveTrailingBackslash, FsEntryMakeTrailingBackslash.
  2022-03-08  V6.06  Added git reset. Declare as deprecated: GitCloneOrFetchOrPull, GitCloneOrFetchIgnoreError, GitCloneOrPullIgnoreError.
  2022-02-23  V6.05  Simplified array usage, fixed UnitTest.
  2022-01-31  V6.04  Added comment.
  2021-12-19  V6.03  Parallelize GitCloneOrPullUrls.
  2021-12-19  V6.02  Fixed NetDownloadFile setting Tls. Added Unittest to github workflow.
  2021-12-18  V6.01  Fixed some lint warnings as using Write-Output. Added ScriptAnalyser tool. Extended Workflow.
  2021-12-17  V6.00  Removed deprecated FsEntryMakeAbsolutePath, from GitCloneOrPullUrls removed param onErrorContinueWithOthers. Improve ForEachParallel.
                     Removed deprecated StdOutRedLine.

  2021-12-16  V5.46  Improved FileDelete exc-handling.
  2021-12-16  V5.45  Improved Doc NetDownloadFileByCurl.
  2021-12-08  V5.44  Improved Doc ToolCreateMenuLinksByMenuItemRefFile.
  2021-11-07  V5.43  Added Doc, Added ToolOsWindowsResetSystemFileIntegrity.
  2021-10-22  V5.42  Added ProcessGetNrOfCores, ProcessListRunningsFormatted, ProcessCloseMainWindow.
  2021-10-05  V5.41  Improved retry handling of SvnCheckoutAndUpdate.
  2021-10-04  V5.40  Replaced quotes by doublequotes.
  2021-10-01  V5.39  Added DirNotExists.
  2021-10-01  V5.38  Added DateTimeGetBeginOf, FsEntryNotExistsOrIsOlderThanBeginOf, FsEntryExistsAndIsNewerThanBeginOf.
  2021-10-01  V5.37  Changed output type of ToolWin10Package.
  2021-09-30  V5.36  Added ToolWin10PackageGetState, ToolWin10PackageInstall, ToolWin10PackageDeinstall.
  2021-09-28  V5.35  Added ToolVs2019UserFolderGetLatestUsed, unified releasenote comments.
  2021-07-25  V5.34  Fixed lint issues, added github action.
  2021-05-06  V5.33  Extended ServiceStop.
  2021-01-05  V5.32  Added exc info, Adding installation and uninstallation for both 32 and 64 bit environments.
  2020-12-07  V5.31  Added OsPsModule functions.
  2020-11-27  V5.30  Added retry in CredentialReadFromFile when pw changed.
  2020-11-15  V5.29  Doc NetDownloadFile.
  2020-11-15  V5.28  Improved warning of git log.
  2020-11-13  V5.27  Added ToolActualizeHostsFileByMaster.
  2020-11-03  V5.26  Added FsEntryGetUncShare, extend FsEntryNotExistsOrIsOlderThanNrDays.
  2020-11-01  V5.24  Fixed default arg.
  2020-10-19  V5.23  Added git --no-rebase.
  2020-10-05  V5.22  Fixed null problems for arrays. Extend unitest. Added return type of functions.
  2020-10-01  V5.21  Added StringNormalizeAsVersion, moved unittest, fixed null for arrays.
  2020-10-01  V5.20  Fixed RegistryPrivRuleToString.
  2020-09-23  V5.19  Unified usage without aliases.
  2020-09-09  V5.18  Added PrivFsRuleCreateByString, PrivAclFsRightsToString, PrivAclFsRightsFromString, PrivAclRegRightsToString. Fix FsEntryListAsFileSystemInfo.
  2020-08-09  V5.13  Added GitShowBranch, GitShowChanges. Fix ProcessStart.
  2020-07-30  V5.12  Added Doc.
  2020-07-28  V5.11  Improved tfs functions.
  2020-07-16  V5.10  Deprecated FsEntryMakeAbsolutePath. Extend tfs-path. Added FsEntryFindInParents, StringRemoveOptEnclosingDblQuotes, Tfs-functions.
  2020-07-15  V5.09  Added GitCloneOrPullUrls.
  2020-07-06  V5.08  Added GitAssertAutoCrLfIsDisabled, GitDisableAutoCrLf.
  2020-05-01  V5.07  Added StringArrayIsEqual.
  2020-04-25  V5.06  Added Doc.
  2020-04-17  V5.05  Improved NetDownloadSite for utf8. NetUrlUnescape.
  2020-04-14  V5.04  Improved git-pull.
  2020-04-10  V5.03  Added ProcessEnvVarGet, ProcessEnvVarGet, OsWindowsFeatureDoInstall, OsWindowsFeatureDoUninstall, NetDownloadIsSuccessful.
  2020-04-06  V5.02  Extended DirAssertExists, improve ShareCreate.
  2020-03-02  V5.01  Changed ShareListAllByWmi caption to Description.
  2020-02-25  V5.00  Changed and simplifyed ShareListAll, ShareCreate, ShareRemove, ShareListAll. Add ShareExists, ShareListAllByWmi, ShareRemoveByWmi, ShareCreateByWmi, ShareLocksList, ShareLocksClose.

  2020-02-18  V4.11  Improved ConsoleSetGuiProperties, tf options.
  2020-02-15  V4.10  Added ToolGithubApiDownloadLatestReleaseDir, ToolUnzip, fix FsEntryMoveByPatternToDir.
  2020-02-13  V4.09  Added HelpListOfAllExportedCommands, extend wget comment. improved ProcessRestartInElevatedAdminMode, MnCommonPsToolLibSelfUpdate, ToolPerformFileUpdateAndIsActualized.
  2020-01-14  V4.08  Added StringRemoveLeft.
  2019-12-04  V4.07  Extended tfs path.
  2019-11-15  V4.06  Added ToolSetAssocFileExtToCmd, simplify word-count.
  2019-11-11  V4.05  Extended GitCmd by branch. Extended GitBuildLocalDirFromUrl by branch.
  2019-10-16  V4.04  Fixed FsEntryGetAbsolutePath drive not found. Fix RegistryKeySetAclRule. Improve checkings in RegistryKeyGetSubkey, handle 404 in NetDownloadFile and NetDownloadFileByCurl.
  2019-09-04  V4.03  Improved FsEntryListAsFileSystemInfo for unauthorized.
  2019-08-31  V4.02  Extended exc msg, improve get credentials, added OutError. StdOutRedLine is now deprecated.
  2019-08-20  V4.01  Fixed exc msg.
  2019-08-18  V4.00  Improved get-sql-db-schema, fixed optional menu link file of ToolCreateMenuLinksByMenuItemRefFile, reg key priv methods, replaced RegistryKeySetOwnerForced by RegistryKeySetOwner;
                     Renamed RegistryKeySetAccessRule by RegistryKeySetAclRule, rename RegistryKeySetAcl by RegistryKeySetAclRight.

  2019-05-11  V3.04  Extended FsEntryFindFlatSingleByPattern, extend TfsCheckinDirWhenNoConflict, added StdInAskAndAssertExpectedAnswer,
                     do ConsoleSetGuiProperties only once per shell, added StringIsInt32/64, StringAsInt32/64.
  2019-05-06  V3.03  Set doublequotes instead of quotes in log strings, improve svn changes detections for committing, git pull used time, fix console buffer sizes.
  2019-04-29  V3.02  Added tfs functions.
  2019-04-21  V3.01  Added progress to reg functions, fix RegistrySetValue, fix createlnk for filenames with brackets, git-pull ok if repo hs no content, add log for git.
  2019-03-23  V3.00  Changed ProcessStart return string instead of string array and remove outToProgress param,
                     Replaced StringReplaceNewlinesBySpaces by StringReplaceNewlines(with space as default arg), improve git pull.

  2019-02-22  V2.00  Removed unused var ModeDisallowElevation, replace var CurrentMonthIsoString by function DateTimeNowAsStringIsoMonth(),
                     new ConsoleSetPos, refactor MnCommonPsToolLibSelfUpdate by using github release, removed ToolPerformFileUpdateAndIsActualized.

  2019-01-16  V1.32  Added SqlGenerateFullDbSchemaFiles, add check, care gitstderr as out.
  2019-01-06  V1.29  Added doc, InfoGetInstalledDotNetVersion, rename SvnCommitAndGet to SvnTortoiseCommitAndUpdate, rename SvnCommit to SvnTortoiseCommit,
                     Improved ProcessStart, rename RdpConnect to ToolRdpConnect, rename WgetDownloadSite to NetDownloadSite,
                     Renamed PsWebRequestLastModifiedFailSafe to NetWebRequestLastModifiedFailSafe, rename PsDownloadFile to NetDownloadFile,
                     Renamed PsDownloadToString to NetDownloadToString, rename CurlDownloadFile to NetDownloadFileByCurl,
                     Renamed CurlDownloadToString to NetDownloadToStringByCurl.
  2018-12-30  V1.28  Improved download exc, add encoding as param for FileReadContent functions,
                     Renamed from CredentialGetPasswordTextFromCred to CredentialGetPassword, new CredentialGetUsername,
                     Renamed CredentialReadFromParamOrInput to CredentialCreate.
  2018-12-16  V1.27  Suppressed import-module warnings, improve ToolCreateLnkIfNotExists, rename FsEntryPrivAclAsString to PrivAclAsString,
                     Renamed PrivFsSecurityHasFullControl to PrivAclHasFullControl, new: FsEntryCreateSymLink, FsEntryCreateHardLink, CredentialReadUserFromFile.
  2018-12-16  V1.26  Added doc.
  2018-10-08  V1.25  Improved git logging, add ProcessStart.
  2018-09-27  V1.24  Fixed FsEntryMakeRelative for equal dirs.
  2018-09-26  V1.23  Fixed logfile of SqlPerformFile.
  2018-09-26  V1.22  Improved logging of SqlPerformFile.
  2018-09-26  V1.21  Improved FsEntryMakeRelative.
  2018-09-26  V1.20  Added ScriptImportModuleIfNotDone, SqlPerformFile.
  2018-09-07  V1.19  Removed deprecated: DirExistsAssert (use DirAssertExists instead), DateTimeFromStringAsFormat (use DateTimeFromStringIso instead),
                     DateTimeAsStringForFileName (use DateTimeNowAsStringIso instead), fix DateTimeFromStringIso formats;
                     Added FsEntryFsInfoFullNameDirWithBackSlash, FsEntryResetTs. Ignore Import err. Use ps module sqlserver instead sqlps and now with connectstring.
  2018-09-06  V1.18  Added ConsoleSetGuiProperties, GetExtension.
  2018-08-14  V1.17  Fixed git err msg.
  2018-08-07  V1.16  Added tool for sign assemblies, DirCreateTemp.
  2018-07-26  V1.15  Improved handling of git, improve createLnk, ads functions, add doc.
  2018-03-26  V1.14  Added ToolTailFile, FsEntryDeleteToRecycleBin.
  2018-02-23  V1.13  Renamed deprecated DateTime* functions, new FsEntryGetLastModified, improve PsDownload, fixed DateTimeAsStringIso.
  2018-02-14  V1.12  Added StdInAskForBoolean. DirExistsAssert is deprecated, use DirAssertExists instead.
  2018-02-06  V1.11  Extended functions, fix FsEntryGetFileName.
  2018-01-18  V1.10  Added HelpListOfAllModules, version var, improve ForEachParallel, improve log file names.
  2018-01-09  V1.09  Unified error messages, improved elevation, PsDownloadFile.
  2017-12-30  V1.08  Improved RemoveSmb, renamed SvnCheckout to SvnCheckoutAndUpdate and implement retry.
  2017-12-16  V1.07  Fixed WgetDownloadSite.
  2017-12-02  V1.06  Improved self-update hash handling, improve touch.
  2017-11-22  V1.05  Extended functions, improved self-update by hash.
  2017-10-22  V1.04  Extended functions, improve FileContentsAreEqual, self-update.
  2017-10-10  V1.03  Extended functions.
  2017-09-08  V1.02  Extended by jobs, parallel.
  2017-08-11  V1.01  Updated.
  2017-06-25  V1.00  Published as open source to github.
  #>
}
