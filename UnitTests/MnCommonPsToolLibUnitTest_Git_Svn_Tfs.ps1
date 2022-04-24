# Test module MnCommonPsToolLib

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function Test_Git_Svn_Tfs(){
  OutProgress (ScriptGetCurrentFuncName);
  # TODO:
  #   GitBuildLocalDirFromUrl              ( [String] $tarRootDir, [String] $urlAndOptionalBranch ){
  #                                          # Maps a root dir and a repo url with an optional sharp-char separated branch name
  #                                          # to a target repo dir which contains all url fragments below the hostname.
  #                                          # ex: (GitBuildLocalDirFromUrl "C:\WorkGit\" "https://github.com/mniederw/MnCommonPsToolLib")          == "C:\WorkGit\mniederw\MnCommonPsToolLib";
  #                                          # ex: (GitBuildLocalDirFromUrl "C:\WorkGit\" "https://github.com/mniederw/MnCommonPsToolLib#MyBranch") == "C:\WorkGit\mniederw\MnCommonPsToolLib#MyBranch";
  #   GitCmd                               ( [String] $cmd, [String] $tarRootDir, [String] $urlAndOptionalBranch, [Boolean] $errorAsWarning = $false ){
  #                                          # For commands:
  #                                          #   "Clone"       : Creates a full local copy of specified repo. Target dir must not exist.
  #                                          #                   Branch can be optionally specified, in that case it also will switch to this branch.
  #                                          #                   Default branch name is where the standard remote HEAD is pointing to, usually "master".
  #                                          #   "Fetch"       : Get all changes from specified repo to local repo but without touching current working files.
  #                                          #                   Target dir must exist. Branch in repo url can be optionally specified but no switching will be done.
  #                                          #   "Pull"        : First a Fetch and then it also merges current branch into current working files.
  #                                          #                   Target dir must exist. Branch in repo url can be optionally specified but no switching will be done.
  #                                          #   "CloneOrPull" : if target not exists then Clone otherwise Pull.
  #                                          #   "CloneOrFetch": if target not exists then Clone otherwise Fetch.
  #                                          #   "Reset"       : Reset-hard, loose all local changes. Same as delete folder and clone, but faster.
  #                                          #                   Target dir must exist. If branch is specified then it will switch to it, otherwise will switch to main (or master).
  #                                          # Target-Dir: see GitBuildLocalDirFromUrl.
  #                                          # The urlAndOptionalBranch defines a repo url optionally with a sharp-char separated branch name (allowed chars: A-Z,a-z,0-9,.,_,-).
  #                                          # We assert the no AutoCrLf is used.
  #                                          # Pull-No-Rebase: We generally use no-rebase for pull because commit history should not be modified.
  #                                          # ex: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib"
  #                                          # ex: GitCmd Clone "C:\WorkGit" "https://github.com/mniederw/MnCommonPsToolLib#MyBranch"
  #   GitShowUrl                           ( [String] $repoDir ){
  #   GitShowBranch                        ( [String] $repoDir ){
  #                                          # return current branch (example: "master").
  #   GitShowChanges                       ( [String] $repoDir ){
  #                                          # return changed, deleted and new files or dirs. Per entry one line prefixed with a change code.
  #   GitTortoiseCommit                    ( [String] $workDir, [String] $commitMessage = "" ){
  #   GitListCommitComments                ( [String] $tarDir, [String] $localRepoDir, [String] $fileExtension = ".tmp",
  #                                            [String] $prefix = "Log.", [Int32] $doOnlyIfOlderThanAgeInDays = 14 ){
  #                                          # Reads commit messages and changed files info from localRepoDir 
  #                                          # and overwrites it to two target files to target dir.
  #                                          # For building the filenames it takes the two last dir parts and writes the files with the names:
  #                                          # - Log.NameOfRepoParent.NameOfRepo.CommittedComments.tmp
  #                                          # - Log.NameOfRepoParent.NameOfRepo.CommittedChangedFiles.tmp
  #                                          # It is quite slow about 10 sec per repo, so it can be controlled by $doOnlyIfOlderThanAgeInDays.
  #                                          # In case of a git error it outputs it as warning.
  #                                          # ex: GitListCommitComments "C:\WorkGit\_CommitComments" "C:\WorkGit\mniederw\MnCommonPsToolLib"
  #   GitAssertAutoCrLfIsDisabled          (){ # use this before using git
  #   GitDisableAutoCrLf                   (){ # no output if nothing done.
  #   GitCloneOrPullUrls                   ( [String[]] $listOfRepoUrls, [String] $tarRootDirOfAllRepos, [Boolean] $errorAsWarning = $false ){
  #                                          # Works later multithreaded and errors are written out, collected and throwed at the end.
  #                                          # If you want single threaded then call it with only one item in the list.
  #   SvnEnvInfo :                         Add-Type -TypeDefinition "public struct SvnEnvInfo {public string Url; public string Path; public string RealmPattern; public string CachedAuthorizationFile; public string CachedAuthorizationUser; public string Revision; }";
  #                                          # ex: Url="https://myhost/svn/Work"; Path="D:\Work"; RealmPattern="https://myhost:443";
  #                                          # CachedAuthorizationFile="$env:APPDATA\Subversion\auth\svn.simple\25ff84926a354d51b4e93754a00064d6"; CachedAuthorizationUser="myuser"; Revision="1234"
  #   SvnExe                               (){ # Note: if certificate is not accepted then a pem file (for example lets-encrypt-r3.pem) can be added to file "$env:APPDATA\Subversion\servers"
  #   SvnEnvInfoGet                        ( [String] $workDir ){
  #                                          # Return SvnEnvInfo; no param is null.
  #   SvnGetDotSvnDir                      ( $workSubDir ){
  #                                          # Return absolute .svn dir up from given dir which must exists.
  #   SvnAuthorizationSave                ( [String] $workDir, [String] $user ){
  #                                          # If this part fails then you should clear authorization account in svn settings.
  #   SvnAuthorizationTryLoadFile          ( [String] $workDir, [String] $user ){
  #                                          # If work auth dir exists then copy content to svn cache dir.
  #   SvnCleanup                           ( [String] $workDir ){
  #                                          # Cleanup a previously failed checkout, update or commit operation.
  #   SvnStatus                            ( [String] $workDir, [Boolean] $showFiles ){
  #                                          # Return true if it has any pending changes, otherwise false.
  #                                          # Example: "M       D:\Work\..."
  #                                          # First char: Says if item was added, deleted, or otherwise changed
  #                                          #   ' ' no modifications
  #                                          #   'A' Added
  #                                          #   'C' Conflicted
  #   SvnRevert                            ( [String] $workDir, [String[]] $relativeRevertFsEntries ){
  #                                          # Undo the specified fs-entries if they have any pending change.
  #   SvnTortoiseCommit                    ( [String] $workDir ){
  #   SvnUpdate                            ( [String] $workDir, [String] $user ){
  #   SvnCheckoutAndUpdate                 ( [String] $workDir, [String] $url, [String] $user, [Boolean] $doUpdateOnly = $false, [String] $pw = "", [Boolean] $ignoreSslCheck = $false ){
  #                                          # Init working copy and get (init and update) last changes. If pw is empty then it uses svn-credential-cache.
  #                                          # If specified update-only then no url is nessessary but if given then it verifies it.
  #                                          # Note: we do not use svn-update because svn-checkout does the same (the difference is only the use of an url).
  #                                          # Note: sometimes often after 5-20 GB received there is a network problem which aborts svn-checkout,
  #                                          #   so if it is recognised as a known exception then it will automatically do a cleanup, wait for 30 sec and retry (max 100 times).
  #   SvnPreCommitCleanupRevertAndDelFiles ( [String] $workDir, [String[]] $relativeDelFsEntryPatterns, [String[]] $relativeRevertFsEntries ){
  #   SvnTortoiseCommitAndUpdate           ( [String] $workDir, [String] $svnUrl, [String] $svnUser, [Boolean] $ignoreIfHostNotReachable, [String] $pw = "" ){
  #                                          # Check svn dir, do svn cleanup, check svn user by asserting it matches previously used svn user, delete temporary files, svn commit (interactive), svn update.
  #                                          # If pw is empty then it takes it from svn-credential-cache.
  #   for future use: function SvnList ( [String] $svnUrlAndPath ) # flat list folder; Sometimes: svn: E170013: Unable to connect to a repository at URL '...' svn: E175003: The server at '...' does not support the HTTP/DAV protocol
  #   TfsExe                               (){ # return tfs executable
  #   TfsHelpWorkspaceInfo                 (){
  #   TfsShowAllWorkspaces                 ( [String] $url, [Boolean] $showPaths = $false, [Boolean] $currentMachineOnly = $false ){
  #                                          # from all users on all machines; normal output is a table but if showPaths is true then it outputs 12 lines per entry
  #                                          # ex: url=https://devops.mydomain.ch/MyTfsRoot
  #   TfsShowLocalCachedWorkspaces         (){ # works without access an url
  #   TfsHasLocalMachWorkspace             ( [String] $url ){ # we support only workspace name identic to computername
  #   TfsInitLocalWorkspaceIfNotDone       ( [String] $url, [String] $rootDir ){
  #   TfsDeleteLocalMachWorkspace          ( [String] $url ){ # we support only workspace name identic to computername
  #   TfsGetNewestNoOverwrite              ( [String] $wsdir, [String] $tfsPath, [String] $url ){ # ex: TfsGetNewestNoOverwrite C:\MyWorkspace\Src $/Src https://devops.mydomain.ch/MyTfsRoot
  #   TfsListOwnLocks                      ( [String] $wsdir, [String] $tfsPath ){
  #   TfsAssertNoLocksInDir                ( [String] $wsdir, [String] $tfsPath ){ # ex: "C:\MyWorkspace" "$/Src";
  #   TfsMergeDir                          ( [String] $wsdir, [String] $tfsPath, [String] $tfsTargetBranch ){
  #   TfsResolveMergeConflict              ( [String] $wsdir, [String] $tfsPath, [Boolean] $keepTargetAndNotTakeSource ){
  #   TfsCheckinDirWhenNoConflict          ( [String] $wsdir, [String] $tfsPath, [String] $comment, [Boolean] $handleErrorsAsWarnings ){
  #                                          # Return true if checkin was successful.
  #   TfsUndoAllLocksInDir                 ( [String] $dir ){ # Undo all locks below dir to cleanup a previous failed operation as from merging.
}
Test_Git_Svn_Tfs;
