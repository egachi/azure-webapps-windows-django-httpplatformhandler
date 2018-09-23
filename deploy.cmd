@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script
:: Version: 1.0.8
:: ----------------------

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------
:Deployment
echo Handling python deployment.
  SET PYTHON_VER=3.6.4
  SET PYTHON_EXE=D:\home\python364x86\python.exe
  SET PYTHON_ENV_MODULE=virtualenv

:: 1. KuduSync
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_SOURCE%{SitePath}" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
  IF !ERRORLEVEL! NEQ 0 goto error
)

IF NOT EXIST "%DEPLOYMENT_TARGET%\requirements.txt" goto postPython
IF EXIST "%DEPLOYMENT_TARGET%\.skipPythonDeployment" goto postPython

echo Detected requirements.txt.  You can skip Python specific steps with a .skipPythonDeployment file.

:: 2. Install packages
echo Pip install requirements.
"%PYTHON_EXE%" -m pip install --upgrade -r requirements.txt
IF !ERRORLEVEL! NEQ 0 goto error

popd

:postPython

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.