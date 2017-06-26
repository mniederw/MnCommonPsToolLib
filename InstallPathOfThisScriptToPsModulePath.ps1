
# Do not change the following line, it is a powershell statement and not a comment!
#Requires -Version 3.0

Write-Host "Install ps module by adding the folder of this script to the ps module path.";

[String] $dir = $PSScriptRoot;
[String] $var = "PSModulePath";
[String] $pa = [Environment]::GetEnvironmentVariable($var, "Machine");

Write-Host -ForegroundColor DarkGray "Folder to install: '$dir' ";
Write-Host -ForegroundColor DarkGray "Current value of environment system variable $var is: '$pa' ";
if( $pa.Split(";") -contains $dir ){
  Write-Host -ForegroundColor Green "Ok, already installed, nothing done. Press enter to exit. ";
}else{
  # requires elevated admin mode
  if( -not (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) ){
    [String[]] $cmd = @( (ScriptGetTopCaller) );
    Write-Host -ForegroundColor DarkGray  "Not running in elevated administrator mode so elevate current script and exit: $cmd";
    Start-Process -Verb "RunAs" -FilePath "powershell.exe" -ArgumentList "& `"$cmd`" ";
    [Environment]::Exit("0");
    throw [Exception] "Exit done, but it did not work, so it throws now an exception.";
  }
  Write-Host -ForegroundColor DarkGray "Change environment system variable $var by appending '$dir'. ";
  [String] $newValue = ($pa.Split(";") -join ";") + ";$dir";
  [Environment]::SetEnvironmentVariable($var, $newValue, "Machine");
  Write-Host -ForegroundColor Green "Ok, done. Press enter to exit. ";
}
Read-Host;
