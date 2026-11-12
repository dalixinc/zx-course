@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM build.bat - build a ZX Spectrum tape and open it in Fuse.
REM
REM This script lives in windows-tools, next to pasmo, zmakebas
REM and Fuse. It finds those tools from its own folder, so you
REM can run it from the course folder, or from anywhere:
REM
REM   windows-tools\build.bat file.asm
REM
REM The tape is written next to the source file.
REM
REM An optional -n or nofuse anywhere on the line builds the
REM tape but does not start Fuse.
REM ============================================================

REM Paths to the tools, relative to this script's folder.
REM %~dp0 is the folder containing this .bat, with a trailing \.
set "TOOLDIR=%~dp0"
set "PASMO=%TOOLDIR%pasmo\pasmo.exe"
set "ZMAKEBAS=%TOOLDIR%zmakebas\zmakebas.exe"
set "FUSE=%TOOLDIR%fuse\fuse.exe"

REM ------------------------------------------------------------
REM Read the command line. Pull out -n / nofuse, and keep the
REM remaining arguments in P1, P2, P3, P4, in order.
REM ------------------------------------------------------------
set "NOFUSE=0"
set "P1="
set "P2="
set "P3="
set "P4="
set "COUNT=0"

:parse
if "%~1"=="" goto parsed
if /I "%~1"=="-n" (
    set "NOFUSE=1"
    shift
    goto parse
)
if /I "%~1"=="nofuse" (
    set "NOFUSE=1"
    shift
    goto parse
)
set /a COUNT+=1
if !COUNT!==1 set "P1=%~1"
if !COUNT!==2 set "P2=%~1"
if !COUNT!==3 set "P3=%~1"
if !COUNT!==4 set "P4=%~1"
if !COUNT! GTR 4 (
    echo Too many arguments.
    echo.
    goto usage
)
shift
goto parse

:parsed
if "%P1%"=="" goto usage

REM File names and extensions of the first two arguments.
for %%I in ("%P1%") do (
    set "FILE1=%%~fI"
    set "DIR1=%%~dpI"
    set "STEM1=%%~nI"
    set "EXT1=%%~xI"
)
set "EXT2="
if not "%P2%"=="" (
    for %%I in ("%P2%") do (
        set "FILE2=%%~fI"
        set "DIR2=%%~dpI"
        set "STEM2=%%~nI"
        set "EXT2=%%~xI"
    )
)

if /I "%EXT1%"==".asm" goto build_asm
if /I "%EXT1%"==".bas" (
    if /I "%EXT2%"==".asm" goto build_combined
    goto build_bas
)

echo I do not know how to build "%P1%"
echo Expected a .asm or .bas file, or a .bas driver followed by a .asm file.
echo.
goto usage

REM ------------------------------------------------------------
REM file.asm  -  pasmo --tapbas, then Fuse.
REM ------------------------------------------------------------
:build_asm
if not "%P2%"=="" (
    echo Unexpected extra argument: %P2%
    echo For a .asm file, the only optional argument is -n or nofuse.
    echo.
    goto usage
)
if not exist "%P1%" (
    echo File not found: %P1%
    exit /b 1
)
if not exist "%PASMO%" (
    echo pasmo.exe not found at:
    echo   %PASMO%
    exit /b 1
)

set "TAP=%DIR1%%STEM1%.tap"
REM Tape name: the source file's name, up to 10 characters.
REM Without --name, pasmo uses the output path, which can be a
REM long directory name and looks wrong on the Spectrum.
set "TAPNAME=%STEM1%"
set "TAPNAME=%TAPNAME:~0,10%"

echo Assembling with pasmo --tapbas:
echo   "%PASMO%" --tapbas --name %TAPNAME% "%P1%" "%TAP%"
"%PASMO%" --tapbas --name %TAPNAME% "%P1%" "%TAP%"
if errorlevel 1 (
    echo pasmo failed.
    exit /b 1
)
echo Wrote %TAP%
goto start_fuse

REM ------------------------------------------------------------
REM file.bas [NAME] [LINE]  -  zmakebas, then Fuse.
REM NAME is the name on the tape, at most 10 characters.
REM LINE is the auto-start line. Defaults: the file's name, 10.
REM ------------------------------------------------------------
:build_bas
if not exist "%P1%" (
    echo File not found: %P1%
    exit /b 1
)
if not exist "%ZMAKEBAS%" (
    echo zmakebas.exe not found at:
    echo   %ZMAKEBAS%
    exit /b 1
)

set "NAME=%STEM1%"
set "NAME=%NAME:~0,10%"
set "LINE=10"
if not "%P2%"=="" set "NAME=%P2%"
if not "%P3%"=="" set "LINE=%P3%"
REM In case a long NAME was given, cut it to the Spectrum's 10-character limit.
set "NAME=%NAME:~0,10%"

set "TAP=%DIR1%%STEM1%.tap"

echo Converting BASIC with zmakebas:
echo   "%ZMAKEBAS%" -a %LINE% -n %NAME% -o "%TAP%" "%P1%"
"%ZMAKEBAS%" -a %LINE% -n %NAME% -o "%TAP%" "%P1%"
if errorlevel 1 (
    echo zmakebas failed.
    exit /b 1
)
echo Wrote %TAP%  (tape name: %NAME%, auto-start: %LINE%)
goto start_fuse

REM ------------------------------------------------------------
REM driver.bas code.asm [NAME] [LINE]
REM
REM The BASIC driver is built with zmakebas. The machine code
REM is assembled with pasmo --tap (code only, no BASIC loader).
REM The two tapes are then joined with copy /b, driver first,
REM which is how step 5 of Chapter 3 builds step5-examples.tap:
REM the BASIC program runs, and its LOAD ""CODE loads the block
REM that follows it on the tape.
REM
REM Intermediate files, kept so you can inspect them:
REM   driver-driver.tap   the BASIC program alone
REM   code-code.tap       the machine code alone
REM The combined tape is driver.tap, next to the .bas file.
REM ------------------------------------------------------------
:build_combined
if not exist "%P1%" (
    echo File not found: %P1%
    exit /b 1
)
if not exist "%P2%" (
    echo File not found: %P2%
    exit /b 1
)
if not exist "%ZMAKEBAS%" (
    echo zmakebas.exe not found at:
    echo   %ZMAKEBAS%
    exit /b 1
)
if not exist "%PASMO%" (
    echo pasmo.exe not found at:
    echo   %PASMO%
    exit /b 1
)

set "NAME=%STEM1%"
set "NAME=%NAME:~0,10%"
set "LINE=10"
if not "%P3%"=="" set "NAME=%P3%"
if not "%P4%"=="" set "LINE=%P4%"
set "NAME=%NAME:~0,10%"

set "DRIVER_TAP=%DIR1%%STEM1%-driver.tap"
set "CODE_TAP=%DIR2%%STEM2%-code.tap"
set "TAP=%DIR1%%STEM1%.tap"
REM Tape name for the code block: the assembler file's name, up to 10 characters.
set "CODENAME=%STEM2%"
set "CODENAME=%CODENAME:~0,10%"

echo Assembling the machine code with pasmo --tap (no loader):
echo   "%PASMO%" --tap --name %CODENAME% "%P2%" "%CODE_TAP%"
"%PASMO%" --tap --name %CODENAME% "%P2%" "%CODE_TAP%"
if errorlevel 1 (
    echo pasmo failed.
    exit /b 1
)
echo Wrote %CODE_TAP%

echo Converting the BASIC driver with zmakebas:
echo   "%ZMAKEBAS%" -a %LINE% -n %NAME% -o "%DRIVER_TAP%" "%P1%"
"%ZMAKEBAS%" -a %LINE% -n %NAME% -o "%DRIVER_TAP%" "%P1%"
if errorlevel 1 (
    echo zmakebas failed.
    exit /b 1
)
echo Wrote %DRIVER_TAP%  (tape name: %NAME%, auto-start: %LINE%)

echo Joining the tapes, driver first, then code:
echo   copy /b "%DRIVER_TAP%"+"%CODE_TAP%" "%TAP%"
copy /b "%DRIVER_TAP%"+"%CODE_TAP%" "%TAP%" >nul
if errorlevel 1 (
    echo copy /b failed. The combined tape was not written.
    exit /b 1
)
echo Wrote %TAP%
goto start_fuse

REM ------------------------------------------------------------
REM Start Fuse with the tape we just wrote, unless nofuse was
REM given. Fuse 1.6.0 treats a .tap on the command line as a
REM file to open. Auto-load is on by default, so the phantom
REM typist types LOAD "" (or LOAD "" CODE) and the program
REM starts. --machine 48 keeps us on the 48K Spectrum the
REM course uses, even if Fuse last ran as a 128K.
REM ------------------------------------------------------------
:start_fuse
if "%NOFUSE%"=="1" (
    echo Skipping Fuse, nofuse was set.
    exit /b 0
)
if not exist "%FUSE%" (
    echo fuse.exe not found at:
    echo   %FUSE%
    echo The tape was written, but Fuse could not be started.
    exit /b 1
)
if not exist "%TAP%" (
    echo Tape not found: %TAP%
    exit /b 1
)

REM FUSE_FLAGS is optional extra arguments, for example
REM set FUSE_FLAGS=--no-sound  on a machine with no audio device.
REM --graphics-filter 4x is four times normal size. Fuse 1.6.0's
REM official manual (fuse/fuse.html) lists Quadruple size (4x) for
REM the Win32 UI. FUSE_FLAGS is passed after it, so extra options
REM still work.
echo Starting Fuse:
echo   "%FUSE%" --machine 48 --auto-load --graphics-filter 4x %FUSE_FLAGS% "%TAP%"
start "" "%FUSE%" --machine 48 --auto-load --graphics-filter 4x %FUSE_FLAGS% "%TAP%"
exit /b 0

REM ------------------------------------------------------------
:usage
echo Build a ZX Spectrum tape and optionally open it in Fuse.
echo.
echo Usage:
echo   windows-tools\build.bat file.asm
echo       Assemble with pasmo --tapbas to file.tap, then open it in Fuse.
echo       The tape has a short BASIC loader around the code.
echo.
echo   windows-tools\build.bat file.bas [NAME] [LINE]
echo       Convert with zmakebas to file.tap, then open it in Fuse.
echo       NAME is the program name stored on the tape, which LOAD shows
echo       as "Program: NAME". It can be at most 10 characters. If you
echo       leave it out, it defaults to the file's name, also cut to 10
echo       characters.
echo       LINE is the auto-run line, the same idea as SAVE "x" LINE 10.
echo       After LOAD, the program RUNs from that line. Default: 10.
echo.
echo   windows-tools\build.bat driver.bas code.asm [NAME] [LINE]
echo       Build a BASIC driver with zmakebas, assemble the code with
echo       pasmo --tap (code only, no loader), and join them with
echo       copy /b into driver.tap (driver first, then code). The two
echo       halves are kept as driver-driver.tap and code-code.tap.
echo       Then open the combined tape in Fuse. NAME and LINE apply to
echo       the BASIC driver, as above.
echo.
echo   Add -n or nofuse anywhere on the line to build without opening Fuse.
echo.
echo The tape is written next to the source file. Fuse is started at
echo four times normal size (--graphics-filter 4x). Set FUSE_FLAGS for
echo extra Fuse options, for example FUSE_FLAGS=--no-sound.
echo.
echo Run this from the course folder, or from anywhere. The tools are
echo found next to this script, in windows-tools.
exit /b 1
