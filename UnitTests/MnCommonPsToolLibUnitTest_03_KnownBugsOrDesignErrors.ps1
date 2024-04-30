#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_KnowBugsOrDesignErrors(){
  OutProgress (ScriptGetCurrentFuncName);
  # Known bugs are descripted at the bottom of MnCommonPsToolLib.psm1 file in comments.
  # Some of them are showed here in pure powershell without requiring any library.
  #
  [Boolean] $processIsLesserEqualPs5 = ($PSVersionTable.PSVersion.Major -le 5); Write-Output "Current-PS-Version: $($PSVersionTable.PSVersion.Major)";
  #
  #
  # String.Split(String) works wrongly in PS5 because it internally calls wrongly String.Split(Char[])
  [String] $splitRes = "abc".Split("cx");
  if( (     $processIsLesserEqualPs5 -and $splitRes -eq "ab ") -or
      (-not $processIsLesserEqualPs5 -and $splitRes -eq "abc") ){
    Write-Output "Works as expected (in PS5 wrong, in PS7 correct).";
  }else{ throw [Exception] "Unexpected"; }
  #
  #
  # Variable or function argument of type String is never $null, if $null is assigned then always empty is stored.
  [String] $s; $s = $null; Assert ($null -ne $s); Assert ($s -eq "");
  # But if type String is within a struct then it can be null.
  Add-Type -TypeDefinition "public struct MyStruct {public string MyVar;}"; Assert( $null -eq (New-Object MyStruct).MyVar );
  # And the string variable is null IF IT IS RUNNING IN A SCRIPT in ps5or7, if running interactive then it is not null:
  [String] $s = @() | Where-Object{ $false }; Assert ($null -ne $a);
  #
  #
  # GetFullPath() works not with the current dir but with the working dir where powershell was started for example when running as administrator.
  #     http://stackoverflow.com/questions/4071775/why-is-powershell-resolving-paths-from-home-instead-of-the-current-directory/4072205
  #     powershell.exe         ;
  #                              Get-Location                                 # Example: $HOME
  #                              Write-Output hi > .\a.tmp   ;
  #                              [System.IO.Path]::GetFullPath(".\a.tmp")     # is correct "$HOME\a.tmp"
  #     powershell.exe as Admin;
  #                              Get-Location                                 # Example: C:\WINDOWS\System32
  #                              Set-Location $HOME;
  #                              [System.IO.Path]::GetFullPath(".\a.tmp")     # is wrong   "C:\WINDOWS\System32\a.tmp"
  #                              [System.IO.Directory]::GetCurrentDirectory() # is         "C:\WINDOWS\System32"
  #                              (get-location).Path                          # is         "$HOME"
  #                              Resolve-Path .\a.tmp                         # is correct "$HOME\a.tmp"
  #                              (Get-Item -Path ".\a.tmp" -Verbose).FullName # is correct "$HOME\a.tmp"
  #     Possible reasons: PS can have a regkey as current location. GetFullPath works with [System.IO.Directory]::GetCurrentDirectory().
  #     Recommendation: do not use [System.IO.Path]::GetFullPath, use Resolve-Path.
  #
  #
  # ForEach-Object iterates at lease once with $null in pipeline:
  #     see http://stackoverflow.com/questions/4356758/how-to-handle-null-in-the-pipeline
  #     $null | ForEach-Object{ Write-Output "ok reached, at least one iteration in pipeline with $null has been done." }
  #     But:  @() | ForEach-Object{ Write-Output "NOT OK, reached this unexpected." }
  #     Workaround if array variable can be null, then use:
  #       $null | Where-Object{$null -ne $_} | ForEach-Object{ Write-Output "NOT OK, reached this unexpected." }
  #     Alternative:
  #       $null | ForEach-Object -Begin{if($null -eq $_){continue}} -Process {do your stuff here}
  #     Recommendation: Pipelines which use only Select-Object, ForEach-Object and Sort-Object to produce a output for console or logfiles are ignorable
  #       but for others you should avoid side effects in pipelines by always using: |Where-Object{$null -ne $_}
  #
  #
  # Compare empty array with $null:
  #       [String[]] $a = @(); if( $a -is [String[]] ){ Write-Output "ok reached, var of expected type." };
  #       if(    $a.count -eq 0   ){        Write-Output "Ok reached, count can be used."; }
  #       if(      ($null -eq $a) ){;}else{ Write-Output "Ok reached, empty array is not a null array."; }
  #       if(      ($null -ne $a) ){        Write-Output "Ok reached, empty array is not a null array."; }
  #       if( -not ($null -eq $a) ){        Write-Output "Ok reached, empty array is not a null array."; }
  #       if( -not ($null -ne $a) ){        Write-Output "Ok reached, empty array is not a null array."; }
  #       [Boolean] $r = @() -eq $null; # this throws: Cannot convert value "System.Object[]" to type "System.Boolean"!
  #       Conclusion: This behaviour is an absolute DESIGN-ERROR, this makes it very hard to handle with empty or null arrays!
  #
  #
  # A powershell function returning an empty array is compatible with returning $null.
  #     But nevertheless it is essential wether it returns an empty array or null because
  #     when adding the result of the call to an empty array then it results in count =0 or =1.
  #     see https://stackoverflow.com/questions/18476634/powershell-doesnt-return-an-empty-array-as-an-array
  #       function ReturnEmptyArray(){ return [String[]] @(); }
  #       function ReturnNullArray(){ return [String[]] $null; }
  #       if( $null -eq (ReturnEmptyArray) ){ Write-Output "ok reached, function return empty array which is equal to null"; }
  #       if( $null -eq (ReturnNullArray)  ){ Write-Output "ok reached, function return null  array which is equal to null"; }
  #       if( (@()+(ReturnEmptyArray                          )).Count -eq 0 ){ Write-Output "ok reached, function return empty array which counts as 0"; }
  #       if( (@()+(ReturnNullArray                           )).Count -eq 1 ){ Write-Output "ok reached, function return null array which counts as one element"; }
  #       if( (@()+(ReturnNullArray|Where-Object{$null -ne $_})).Count -eq 0 ){ Write-Output "ok reached, function return null but converted to empty array"; }
  #     Recommendation: After a call of a function which returns an array then add an empty array.
  #       If its possible that a function can returns null instead of an empty array then also use (|Where-Object{$null -ne $_}).
  #       Never add null to an empty empty array a null array!
  #
  #
  # Empty array in pipeline is converted to $null:
  #       [String[]] $a = (([String[]]@()) | Where-Object{$null -ne $_});
  #       if( $null -eq $a ){ Write-Output "ok reached, var is null." };
  #     Recommendation: After pipelining add an empty array.
  #       [String[]] $a = (@()+(@()|Where-Object{$null -ne $_})); Assert ($null -ne $a);
  #
  #
  # Variable name conflict: ... | ForEach-Object{ [String[]] $a = $_; ... }; [Array] $a = ...;
  #     Can result in:  SessionStateUnauthorizedAccessException: Cannot overwrite variable a because the variable has been optimized.
  #       Try using the New-Variable or Set-Variable cmdlet (without any aliases),
  #       or dot-source the command that you are using to set the variable.
  #     Recommendation: Rename one of the variables.
  #
  #
  # Good behaviour: DotNet functions as Split() can return empty arrays instead of return $null:
  #       [String[]] $a = "".Split(";",[System.StringSplitOptions]::RemoveEmptyEntries); if( $a.Count -eq 0 ){ Write-Output "Ok, array-is-empty"; }
  #     But the PS5 version has a bug:
  #       [String] $s = "abc".Split("cx"); if( $s -eq "abc" ){ Write-Output "Ok, correct."; }else{ Write-Output "Result='$s' is wrong. We know it happens in PS5, Current-PS-Version: $($PSVersionTable.PSVersion.Major)"; }
  #
  #
  # Exceptions are always catched within Pipeline Expression statement and instead of expecting the throw it returns $null:
  #     [Object[]] $a = @( "a", "b" ) | Select-Object -Property @{Name="Field1";Expression={$_}} |
  #       Select-Object -Property Field1,
  #       @{Name="Field2";Expression={if($_.Field1 -eq "a" ){ "is_a"; }else{ throw [Exception] "This exc is ignored and instead of throwing up the stack the result of the Expression statement is $null."; } }};
  #     $a[0].Field2 -eq "is_a" -and $null -eq $a[1].Field2;  # this is true
  #     $a | ForEach-Object{ if( $null -eq $_.Field2 ){ throw [Exception] "Field2 is null"; } } # this does the throw
  #     Recommendation: After creation of the list do iterate through it and assert non-null values
  #       or redo the expression within a ForEach-Object loop to get correct throwed message.
  #
  #
  # String without comparison as condition:
  Assert ( "anystring" ); Assert ( "$false" );
  #
  #
  # PS 5/7 is poisoning the current scope by its aliases. See also comments on: ProcessRemoveAllAlias.
  #     List all aliases by: alias; For example: Alias curl -> Invoke-WebRequest ; Alias wget -> Invoke-WebRequest ; Alias diff -> Compare-Object ;
  #     If we really want to call the curl executable than this is a mess.
  #     We strongly recommend to add to your ps5 $PROFILE (Example: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1) at least the line:
  #       Remove-Item -Force "Alias:curl" -ErrorAction SilentlyContinue; Remove-Item -Force "Alias:wget" -ErrorAction SilentlyContinue;
  #     Alternative: If you want to use curl and have to bypass the curl alias you need to do the following:
  #     [String] $curlPath = "$(get-command -CommandType Application curl -ErrorAction SilentlyContinue | Select -First 1 | ForEach-Object{ $_.Source })";
  #
  #
  # Automatically added folders (2023-02):
  #     - ps7: %USERPROFILE%\Documents\PowerShell\Modules\         location for current users for any modules
  #     - ps5: %USERPROFILE%\Documents\WindowsPowerShell\Modules\  location for current users for any modules
  #     - ps7: %ProgramW6432%\PowerShell\Modules\                  location for all     users for any modules (ps7 and up, multiplatform)
  #     - ps7: %ProgramW6432%\powershell\7\Modules\                location for all     users for any modules (ps7 only  , multiplatform)
  #     - ps5: %ProgramW6432%\WindowsPowerShell\Modules\           location for all     users for any modules (ps5 and up) and             64bit environment (Example: "C:\Program Files")
  #     - ps5: %ProgramFiles(x86)%\WindowsPowerShell\Modules\      location for all     users for any modules (ps5 and up) and             32bit environment (Example: "C:\Program Files (x86")
  #     - ps5: %ProgramFiles%\WindowsPowerShell\Modules\           location for all     users for any modules (ps5 and up) and current 64/32 bit environment (Example: "C:\Program Files (x86)" or "C:\Program Files")
  #
  #
  # Not automatically added but currently strongly recommended additional folder:
  #     - %SystemRoot%\System32\WindowsPowerShell\v1.0\Modules\    location for windows modules for all users (ps5 and up)
  #       In future if ps7 can completely replace ps5 then we can remove this folder.
  #
  #
  # Type Mismatch: A function returns a string array: If it returns a single element (=string) then it does not return a string array but the string:
  function ReturnStringArrayWithOneString1(){ return [String[]] @("abc"); } Assert (ReturnStringArrayWithOneString1)[0] -eq "a";
  # This is a DESIGN ERROR, a string should not be given when we requested for a string array.
  # Even the alternative with using OutputType keyword does not solve this behaviour:
  function ReturnStringArrayWithOneString2 { [OutputType([string[]])] Param( [String] $s ); return [string[]]@("abc"); } Assert ((ReturnStringArrayWithOneString2)[0] -eq "a");
  #
  #
}
UnitTest_KnowBugsOrDesignErrors;
