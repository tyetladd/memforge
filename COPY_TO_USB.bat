@echo off
REM Simple copy to D:. NO format, NO admin checks. You format manually.
REM Just copies what is needed for boot + analyzer. Idempotent (overwrites).
chcp 65001 >nul
TITLE Copy MemForge to D:
cd /d "%~dp0"

IF NOT EXIST D:\ (
    ECHO [ERROR] D: not present.
    PAUSE
    EXIT /B 1
)
IF NOT EXIST "%~dp0MemForge2.efi" (
    ECHO [ERROR] MemForge2.efi missing in source.
    PAUSE
    EXIT /B 1
)

ECHO Copying to D:\ ...

IF NOT EXIST D:\EFI\BOOT\ MKDIR D:\EFI\BOOT >nul
COPY /Y "%~dp0MemForge2.efi"            D:\EFI\BOOT\BOOTX64.EFI >nul
COPY /Y "%~dp0MemForge2.efi"            D:\
COPY /Y "%~dp0quantai.ini"              D:\
COPY /Y "%~dp0BIOS_SETUP.md"            D:\
COPY /Y "%~dp0RUN_ANALYZER.bat"         D:\
COPY /Y "%~dp0RUN_ANALYZER.sh"          D:\
COPY /Y "%~dp0LogAnalyzerGUI.exe"       D:\
COPY /Y "%~dp0LogAnalyzerGUI.py"        D:\
COPY /Y "%~dp0LogAnalyzerGUI_Linux.bin" D:\

IF NOT EXIST D:\AI_DIAGNOSTIC\ MKDIR D:\AI_DIAGNOSTIC >nul
XCOPY /E /Y /Q "%~dp0AI_DIAGNOSTIC\*" D:\AI_DIAGNOSTIC\ >nul

ECHO.
ECHO ====================================================
ECHO   Done. D:\EFI\BOOT\BOOTX64.EFI = MemForge2.efi
ECHO   Safely eject D: before unplugging.
ECHO ====================================================
PAUSE
