' MAKE_USB_D.vbs — runs MAKE_USB_D.bat with admin rights via ShellExecute "runas".
' Single UAC prompt; opens cmd window with /k so the user sees the result.
Set sh  = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")
script = fso.GetParentFolderName(WScript.ScriptFullName) & "\MAKE_USB_D.bat"
sh.ShellExecute "cmd.exe", "/k """ & script & """", "", "runas", 1
