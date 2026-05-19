@echo off
REM MemForge USB writer for D:. Run via WRITE_USB_D_AS_ADMIN.vbs.
chcp 65001 >nul
TITLE MemForge -- write USB (D:)
cd /d "%~dp0"
SET TGT=D:

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERROR] Not running as administrator.
    PAUSE
    EXIT /B 1
)

ECHO ====================================================
ECHO   MemForge USB writer  ^|  Target: %TGT%
ECHO   Source:  %~dp0
ECHO ====================================================

IF /I "%TGT%"=="%~d0" GOTO :err_same
IF /I "%TGT%"=="C:" GOTO :err_c
IF NOT EXIST %TGT%\ GOTO :err_missing

ECHO.
ECHO [1/2] Quick-formatting %TGT% as FAT32 (label MEMFORGE)...
format %TGT% /FS:FAT32 /Q /V:MEMFORGE /Y
IF %ERRORLEVEL% NEQ 0 GOTO :err_format

ECHO.
ECHO [2/2] Copying files via robocopy...
robocopy "%~dp0." %TGT%\ /E /R:1 /W:1 /XD build dist __pycache__ REPORTS .git /XF __test_write.txt APPLY_PROFILE.py APPLY_PROFILE.bat APPLY_PROFILE.sh
IF %ERRORLEVEL% GEQ 8 GOTO :err_copy

ECHO.
ECHO ====================================================
ECHO   DONE. USB %TGT% is bootable.
ECHO ====================================================
PAUSE
EXIT /B 0

:err_same
ECHO [ERROR] Target equals source drive %~d0. Aborting.
PAUSE
EXIT /B 1

:err_c
ECHO [ERROR] Target is C:. Hard refusing.
PAUSE
EXIT /B 1

:err_missing
ECHO [ERROR] Drive %TGT% not present.
PAUSE
EXIT /B 1

:err_format
ECHO [ERROR] format failed.
PAUSE
EXIT /B 1

:err_copy
ECHO [ERROR] robocopy failed.
PAUSE
EXIT /B 1
