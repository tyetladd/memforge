@echo off
REM Auto-installer for QEMU + boot test of the MemForge USB.
REM Uses winget (built into Windows 10 1809+ / Windows 11).
chcp 65001 >nul
TITLE MemForge -- install QEMU and boot test
cd /d "%~dp0"

ECHO ==================================================
ECHO   Step 1/3: check for winget
ECHO ==================================================
where winget >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERROR] winget not found. Update Windows or install
    ECHO         "App Installer" from Microsoft Store, then re-run.
    PAUSE
    EXIT /B 1
)

ECHO.
ECHO ==================================================
ECHO   Step 2/3: install QEMU (UAC will prompt -- click Yes)
ECHO ==================================================
where qemu-system-x86_64 >nul 2>nul
IF %ERRORLEVEL% EQU 0 (
    ECHO   QEMU already installed -- skipping.
) ELSE (
    winget install --id qemu.qemu --accept-package-agreements --accept-source-agreements
    IF %ERRORLEVEL% NEQ 0 (
        ECHO [ERROR] QEMU install failed.
        PAUSE
        EXIT /B 1
    )
    REM Refresh PATH for this session.
    SET "PATH=%PATH%;C:\Program Files\qemu"
)

ECHO.
ECHO ==================================================
  Step 3/3: boot the USB in QEMU/UEFI
ECHO ==================================================
CALL "%~dp0BOOT_IN_QEMU.bat"
