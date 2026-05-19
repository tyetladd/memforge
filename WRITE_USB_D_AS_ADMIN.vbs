' Launch WRITE_USB_D.bat with admin rights via ShellExecute "runas".
' Single UAC prompt, no PowerShell. Survives paths with spaces.
Set sh = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")
script = fso.GetParentFolderName(WScript.ScriptFullName) & "\WRITE_USB_D.bat"
sh.ShellExecute "cmd.exe", "/k """ & script & """", "", "runas", 1
