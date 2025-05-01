@echo off
cls
echo %~n0%~x0   version 0.0.0
echo.

rem Created by Mechatronic Solutions LLC
rem Mark W Kiehl
rem
rem LICENSE: MIT


rem Batch files: https://steve-jansen.github.io/guides/windows-batch-scripting/
rem Batch files: https://tutorialreference.com/batch-scripting/batch-script-tutorial
rem Scripting Google CLI:  https://cloud.google.com/sdk/docs/scripting-gcloud

rem Verify that CLOUDSDK_PYTHON has already been set permanently for the user by gcp_part1.bat
IF NOT EXIST "%CLOUDSDK_PYTHON%" (
echo ERROR: CLOUDSDK_PYTHON path not found.  %CLOUDSDK_PYTHON%
echo Did you previously run gcp_part1.bat ?
EXIT /B
)


rem Make sure GOOGLE_APPLICATION_CREDENTIALS is not set so that Google ADC flow will work properly.
IF NOT "%GOOGLE_APPLICATION_CREDENTIALS%"=="" (
echo .
echo ERROR: GOOGLE_APPLICATION_CREDENTIALS has been set!
echo GOOGLE_APPLICATION_CREDENTIALS=%GOOGLE_APPLICATION_CREDENTIALS%
echo The environment variable GOOGLE_APPLICATION_CREDENTIALS must NOT be set in order to allow Google ADC to work properly.
echo Press RETURN to unset GOOGLE_APPLICATION_CREDENTIALS, CTRL-C to abort. 
pause
@echo on
SET GOOGLE_APPLICATION_CREDENTIALS=
CALL SETX GOOGLE_APPLICATION_CREDENTIALS ""
@echo off
echo Restart this file %~n0%~x0
EXIT /B
)



SETLOCAL

rem Define the working folder to Google Cloud CLI (gcloud) | Google Cloud SDK Shell
rem derived from the USERPROFILE environment variable.
rem This requires that the Google CLI/SKD has already been installed.
SET PATH_GCLOUD=%USERPROFILE%\AppData\Local\Google\Cloud SDK
IF NOT EXIST "%PATH_GCLOUD%\." (
	echo ERROR: PATH_GCLOUD path not found.  %PATH_GCLOUD%
	echo Did you install Google CLI / SKD? 
	EXIT /B
)
rem echo PATH_GCLOUD: %PATH_GCLOUD%

rem The current working directory for this script should be the same as the Python virtual environment for this project.
SET PATH_SCRIPT=%~dp0
rem echo PATH_SCRIPT: %PATH_SCRIPT%


echo.
echo PROJECT LOCAL VARIABLES:
echo.


rem import the GCP project constants from file gcp_constants.bat
if EXIST "gcp_constants.bat" (
  for /F "tokens=*" %%I in (gcp_constants.bat) do set %%I
) ELSE (
  echo ERROR: unable to find gcp_constants.bat
  EXIT /B
)


rem ----------------------------------------------------------------------
rem Show the project variables related to this task

rem set the Google Cloud Platform Project ID
echo GCP_PROJ_ID: %GCP_PROJ_ID%

rem Python version
echo GCP_PYTHON_VERSION: %GCP_PYTHON_VERSION%

rem Python script filename
echo PYTHON_FILENAME: %PYTHON_FILENAME%

rem Docker image names
echo GCP_IMAGE: %GCP_IMAGE%


echo.
echo This batch file will build a Docker image named %GCP_IMAGE% from a Dockerfile 
echo configured with the Python file "%PYTHON_FILENAME%" and for Python version %GCP_PYTHON_VERSION%.
echo The Python virtual environment requirements.txt file will be rebuilt from the current installed
echo Python libraries and used by the Docker file.  
echo. 
echo IMPORTANT: 
echo 1) Make sure the Docker Engine is running (Docker Desktop for Windows)
echo 2) You must edit the file "Dockerfile" and at the end after "CMD" make sure the Python filename is correct.
echo.
echo Press ENTER to continue, or CTRL-C to abort.
pause

echo.


rem Define the path to the Python virtual environment Scripts folder.
rem PATH_SCRIPT already defined previously and is the path to this batch file.
SET PATH_VENV_SCRIPTS=%PATH_SCRIPT%Scripts
echo PATH_VENV_SCRIPTS: %PATH_VENV_SCRIPTS%
IF NOT EXIST "%PATH_VENV_SCRIPTS%\." (
	echo ERROR: PATH_VENV_SCRIPTS path not found.  %PATH_VENV_SCRIPTS%
	EXIT /B
)

rem Update the requirements.txt file with the currently install Python libraries for the virtual environment. 
rem Since PIP is called from a batch file, it is necessary to modify the redirect of the standard output.
rem This redirection modification is the 1> where the 1 specifies STDOUT.  
rem Other solutions other than using pip freeze are:  pipregs or pigar    

rem delete the requirements.txt file if it exists
IF EXIST "%PATH_SCRIPT%requirements.txt" (
	CALL del requirements.txt /Q
)

rem Build the requirements.txt file
echo Rebuilding the Python package installation list requirements.txt ..
@echo on
CALL "%PATH_VENV_SCRIPTS%\pip3.exe" freeze 1> requirements.txt
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: 
	EXIT /B
)

rem Make sure the requirements.txt file exists.
IF NOT EXIST "%PATH_SCRIPT%requirements.txt" (
	echo ERROR: File not found.  %PATH_SCRIPT%requirements.txt
	EXIT /B
)



rem Make sure a Dockerfile exists
IF NOT EXIST "%PATH_SCRIPT%Dockerfile" (
echo ERROR: File not found.  %PATH_SCRIPT%Dockerfile
EXIT /B
)


rem Build the Docker image %GCP_IMAGE%
rem Docker doesn't script well and causes termination of the batch file.
rem For this reason, only the build command is executed in this batch file.
rem The docker build command below takes two arguments, one for the Python version,
rem and another for the Python script filename. 
rem NOTE: ARG or ENV substitution is not supported by the CMD command in Dockerfile.  Must update the script filename in Dockerfile. 
echo Building Docker image %GCP_IMAGE% ..
@echo on
CALL docker build --build-arg PY_VER=%GCP_PYTHON_VERSION% -t %GCP_IMAGE% .
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo Is the Docker Engine Running (Windows Docker Desktop)?
	echo ERROR %ERRORLEVEL%: 
	EXIT /B
)

echo.
echo You can locally test running the Docker image with one of the following commands:
echo docker run -it -p 8080:8080 -v "%appdata%\\gcloud"://root/.config/gcloud %GCP_IMAGE%:latest
echo OR
echo docker run -it -p 8080:8080 -v "%appdata%\\gcloud\\application_default_credentials.json"://root/.config/gcloud/application_default_credentials.json %GCP_IMAGE%:latest
echo.
echo Option -v bind volume mounts the Google SDK folder
echo Option -i keeps STDIN open even if not attached 
echo Option -t allocates a pseudo-TTY
echo Option -p 8080:8080 exposes the port 8080
echo.
echo Then open your browser to this URL: http://localhost:8080/
echo.



ENDLOCAL

echo.
echo This batch file %~n0%~x0 has ended normally (no errors).  
echo You can repeat running this batch file as frequently as you wish.
echo Next, execute the batch file "gcp_6_docker_push".
