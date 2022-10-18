# Common powershell tool library - Parts for windows only

function ProcessGetNrOfCores                  (){ return [Int32] (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors; }
