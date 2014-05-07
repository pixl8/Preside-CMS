@echo off
set /p hostname=". Enter hostname to use (e.g. localhost.preside-tests):"
set rootdir=%~dp0
set webroot=%rootdir:\scripts\=%
set appcmd=%SystemRoot%\system32\inetsrv\appcmd
call %appcmd% add site /name:"%hostname%" /physicalPath:"%webroot%" /bindings:"http/*:80:%hostname%" >nul 2>&1
 if errorlevel 1 (goto somethingbadhappened)
echo .
echo . IIS Site created. Adding %hostname% to %SystemRoot%\system32\drivers\etc\hosts
echo .
echo .
echo. >> %SystemRoot%\system32\drivers\etc\hosts
echo 127.0.0.1 %hostname% >> %SystemRoot%\system32\drivers\etc\hosts
echo .
echo . Done.
goto end
:somethingbadhappened
echo .
echo . There was a problem creating the IIS site. Possible causes:
echo .
echo . 1. This batch file (or the command prompt) was not executed with Administrator permissions
echo . 2. The site already exists
echo .
echo . Ensure that the site, '%hostname%', does not already exist and that you run this script with administrator privileges.
echo .
goto end
:end
pause 