@echo off
REM Write the MemForge USB onto a target removable drive.
REM 1) Lists removable drives.
REM 2) Asks for target drive letter.
REM 3) Shows what will be erased and waits for explicit YES.
REM 4) Quick-formats target as FAT32.
REM 5) robocopy of all files except build/dist/__pycache__/REPORTS.
chcp 65001 >nul
TITLE MemForge -- write USB
cd /d "%~dp0"

ECHO ====================================================
ECHO   MemForge USB writer
ECHO   Source: %~dp0
ECHO ====================================================
ECHO.
ECHO Removable drives currently attached:
wmic logicaldisk where "DriveType=2" get DeviceID,VolumeName,FreeSpace,Size /format:table
ECHO.
SET /P TARGET="Enter target drive letter (e.g. E): "
IF "%TARGET%"=="" (
    ECHO No drive entered. Aborting.
    PAUSE
    EXIT /B 1
)
SET TARGET=%TARGET:~0,1%
SET TGT=%TARGET%:

IF /I "%TGT%"=="%~d0" (
    ECHO [ERROR] Target equals source drive %~d0. Refusing to erase source.
    PAUSE
    EXIT /B 1
)
IF /I "%TGT%"=="C:" (
    ECHO [ERROR] Target is C:. Hard refusing.
    PAUSE
    EXIT /B 1
)
IF NOT EXIST %TGT%\ (
    ECHO [ERROR] Drive %TGT% not found.
    PAUSE
    EXIT /B 1
)

FOR /F "skip=1 tokens=*" %%I IN (^wmic logicaldisk where "DeviceID=^%TGT%^" get DriveType^) DO (
    SET DTYPE=%%I
    GOTO :got_dtype
)
:got_dtype
FOR /F "tokens=*" %%X IN ("%DTYPE%") DO SET DTYPE=%%X
IF NOT "%DTYPE%"=="2" (
    ECHO [ERROR] %TGT% is not a removable drive (DriveType=%DTYPE%).
    ECHO         Aborting to protect non-USB volumes.
    PAUSE
    EXIT /B 1
)

ECHO.
ECHO ----------------------------------------------------
ECHO   ABOUT TO ERASE EVERYTHING ON %TGT%
ECHO ----------------------------------------------------
DIR /A:-D %TGT%\ 2^>nul ^| FINDSTR /R "[0-9]" ^| FINDSTR /V "Directory"
ECHO ----------------------------------------------------
ECHO.
SET /P CONFIRM="Type YES to format %TGT% as FAT32 and write MemForge: "
IF /I NOT "%CONFIRM%"=="YES" (
    ECHO Confirmation not given. Aborting.
    PAUSE
    EXIT /B 1
)

ECHO.
ECHO [1/2] Quick-formatting %TGT% as FAT32 ^(label MEMFORGE^)...
format %TGT% /FS:FAT32 /Q /V:MEMFORGE /Y
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERROR] format failed. UAC denied? Drive in use?
    PAUSE
    EXIT /B 1
)

ECHO.
ECHO [2/2] Copying files (excluding build artefacts)...
robocopy "%~dp0." "%TGT%\" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS ^
    /XD build dist __pycache__ REPORTS ^
    /XF __test_write.txt APPLY_PROFILE.py APPLY_PROFILE.bat APPLY_PROFILE.sh
IF %ERRORLEVEL% GEQ 8 (
    ECHO [ERROR] robocopy failed.
    PAUSE
    EXIT /B 1
)

ECHO.
ECHO ====================================================
ECHO   DONE. USB %TGT% is bootable.
ECHO   Insert into target PC, set USB boot in BIOS,
ECHO   disable Secure Boot. See BIOS_SETUP.md.
ECHO ====================================================
PAUSE
