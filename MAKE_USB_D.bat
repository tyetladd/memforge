@echo off
REM MAKE_USB_D.bat — format D: and write MemForge USB with v0.3 as default boot.
REM Run via MAKE_USB_D.vbs (single UAC prompt).
chcp 65001 >nul
TITLE MemForge - make bootable USB (D:)
cd /d "%~dp0"
SET TGT=D:

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERROR] Not running as administrator. Use MAKE_USB_D.vbs.
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
IF NOT EXIST "%~dp0MemForge2.efi" GOTO :err_no_efi

ECHO.
ECHO [1/3] Quick-formatting %TGT% as FAT32 (label MEMFORGE)...
format %TGT% /FS:FAT32 /Q /V:MEMFORGE /Y
IF %ERRORLEVEL% NEQ 0 GOTO :err_format

ECHO.
ECHO [2/3] Copying files via robocopy...
robocopy "%~dp0." %TGT%\ /E /R:1 /W:1 /XD build dist __pycache__ REPORTS .git /XF __test_write.txt APPLY_PROFILE.py APPLY_PROFILE.bat APPLY_PROFILE.sh MAKE_USB_D.bat MAKE_USB_D.vbs WRITE_USB.bat WRITE_USB_D.bat WRITE_USB_D_AS_ADMIN.vbs MemForge2.src.c MemForge2.mp.h
IF %ERRORLEVEL% GEQ 8 GOTO :err_copy

ECHO.
ECHO [3/3] Setting MemForge2.efi as default UEFI boot...
IF NOT EXIST %TGT%\EFI\BOOT\ MKDIR %TGT%\EFI\BOOT
COPY /Y "%~dp0MemForge2.efi" %TGT%\EFI\BOOT\BOOTX64.EFI
IF %ERRORLEVEL% NEQ 0 GOTO :err_boot

REM Also keep the original QuantAI binary as fallback choice
IF EXIST "%~dp0QuantAI.efi" COPY /Y "%~dp0QuantAI.efi" %TGT%\EFI\BOOT\QuantAI-old.efi >nul

ECHO.
ECHO ====================================================
ECHO   DONE.
ECHO   USB %TGT% is bootable, MemForge2 v0.3 = default.
ECHO   Safely eject D: before unplugging.
ECHO ====================================================
PAUSE
EXIT /B 0

:err_same
ECHO [ERROR] Target equals source drive %~d0.
PAUSE
EXIT /B 1
:err_c
ECHO [ERROR] Target is C:. Refusing.
PAUSE
EXIT /B 1
:err_missing
ECHO [ERROR] Drive %TGT% not present.
PAUSE
EXIT /B 1
:err_no_efi
ECHO [ERROR] MemForge2.efi not found in %~dp0.
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
:err_boot
ECHO [ERROR] copying boot loader failed.
PAUSE
EXIT /B 1
