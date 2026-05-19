@echo off
chcp 65001 >nul
TITLE MemForge QEMU Boot
cd /d "%~dp0"

SET QEMU_DIR=C:\Users\User\Desktop\RAM_chek\RAM_chek\qemu
SET QEMU_BIN=%QEMU_DIR%\qemu-system-x86_64.exe
SET CODE=%QEMU_DIR%\share\edk2-x86_64-code.fd
SET VARS_SRC=%QEMU_DIR%\share\edk2-i386-vars.fd
SET VARS=%~dp0qemu_vars.fd

IF NOT EXIST "%QEMU_BIN%" ( ECHO [ERROR] no qemu ^& PAUSE ^& EXIT /B 1 )
IF NOT EXIST "%CODE%"     ( ECHO [ERROR] no code.fd ^& PAUSE ^& EXIT /B 1 )
IF NOT EXIST "%VARS_SRC%" ( ECHO [ERROR] no vars.fd ^& PAUSE ^& EXIT /B 1 )

REM Make a writable copy of vars (pflash needs read+write target).
IF NOT EXIST "%VARS%" COPY /Y "%VARS_SRC%" "%VARS%" >nul

ECHO QEMU:  %QEMU_BIN%
ECHO CODE:  %CODE%
ECHO VARS:  %VARS%
ECHO DISK:  fat:rw:%~dp0
ECHO.
ECHO Launching QEMU...
ECHO.

"%QEMU_BIN%" ^
    -drive if=pflash,format=raw,readonly=on,file="%CODE%" ^
    -drive if=pflash,format=raw,file="%VARS%" ^
    -drive format=raw,file=fat:rw:"%~dp0." ^
    -m 2G -smp 2 -cpu max -net none > qemu_run.log 2>&1
SET RC=%ERRORLEVEL%

ECHO QEMU exited with code %RC%.
ECHO --- qemu_run.log ---
TYPE qemu_run.log
PAUSE
