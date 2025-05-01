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
rem echo CLOUDSDK_PYTHON: %CLOUDSDK_PYTHON%


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

echo GCP_REGION: %GCP_REGION%

rem Docker image names
echo GCP_IMAGE_PUB: %GCP_IMAGE%


rem Google Artifacts Registry repository
echo GCP_REPOSITORY: %GCP_REPOSITORY%

rem Google Run Jobs
echo GCP_RUN_JOB: %GCP_RUN_JOB%



echo.
echo This batch file will:
echo 1) Tag the Docker image "%GCP_IMAGE%".
echo 2) Create the Google Artifacts Repository "%GCP_REPOSITORY%" (delete if it already exists).
echo 3) Push the tagged image to the Artifact Registry named "%GCP_REPOSITORY%".
echo.
echo Press ENTER to continue, or CTRL-C to abort.
pause

echo.


rem Make sure a Dockerfile exists
IF NOT EXIST "%PATH_SCRIPT%Dockerfile" (
echo ERROR: File not found.  %PATH_SCRIPT%Dockerfile
EXIT /B
)


rem ----------------------------------------------------------------------

rem List the local Docker images
echo.
@echo on
CALL docker image ls
@echo off


echo.
echo To run the Docker image "%GCP_IMAGE%" in a Docker container locally:
echo docker run -it -e GCP_RUN_JOBS_REGION=%GCP_REGION% -v "%appdata%//gcloud"://root/.config/gcloud %GCP_IMAGE_SUB%:latest
echo.


rem Tag the local Docker image %GCP_IMAGE%
rem docker tag SOURCE-IMAGE LOCATION-docker.pkg.dev/PROJECT-ID/REPOSITORY/IMAGE:TAG
@echo on
CALL docker tag %GCP_IMAGE% %GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY%/%GCP_IMAGE%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%
	EXIT /B
)

rem ----------------------------------------------------------------------
rem Google Artifacts Repository

rem In order to manage the conflict where Docker images already exist in a repository
rem and we wish to upload a new file, the Google Artificts repository will be deleted (deletes the files).
rem Delete a repository
rem gcloud artifacts repositories delete REPOSITORY [--location=LOCATION] [--async]
echo.
echo Deleting the repository '%GCP_REPOSITORY%' and its files (if they exist).
echo Ignore any error messages.
@echo on
CALL gcloud artifacts repositories delete %GCP_REPOSITORY% --location=%GCP_REGION% --quiet
@echo off


rem Create a repository in Google Artifact Registry using the gcloud CLI (it may already exist)
rem gcloud artifacts repositories create REPOSITORY --repository-format=docker --location=LOCATION --description="A CUSTOM DESCRIPTION OF THE REPO"
echo.
@echo on
CALL gcloud artifacts repositories create %GCP_REPOSITORY% --repository-format=docker --location=%GCP_REGION% --description="%GCP_RUN_JOB% and Docker image"
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo Ignore the above error if the repository already exists. 
)


rem List repositories for the location and project
rem gcloud artifacts repositories list [--project=PROJECT] [--location=LOCATION]
@echo on
CALL gcloud artifacts repositories list --project=%GCP_PROJ_ID% --location=%GCP_REGION%
@echo off

rem Show information about a Google repository created
rem gcloud artifacts repositories describe <REPOSITORY> --location=LOCATION
echo.
@echo on
CALL gcloud artifacts repositories describe %GCP_REPOSITORY% --location=%GCP_REGION%
@echo off

rem ----------------------------------------------------------------------
rem Push the docker image to Google Artifact Registry
rem docker push LOCATION-docker.pkg.dev/PROJECT-ID/REPOSITORY/IMAGE
echo.
@echo on
CALL docker push %GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY%/%GCP_IMAGE%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: docker push %GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY%/%GCP_IMAGE%
	EXIT /B
)


rem List all files in a repository:
rem gcloud artifacts files list --repository=REPOSITORY --location=LOCATION
rem CALL gcloud artifacts files list --repository=%GCP_REPOSITORY% --location=%GCP_REGION%

rem List all files in a repository by tags
echo.
echo Docker images in Google Artifacts repository %GCP_REPOSITORY% %GCP_REGION% %GCP_PROJ_ID%
@echo on
rem gcloud artifacts docker images list LOCATION-docker.pkg.dev/PROJECT/REPOSITORY --include-tags
CALL gcloud artifacts docker images list %GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY% --include-tags
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%
	EXIT /B
)




ENDLOCAL

echo.
echo This batch file %~n0%~x0 has ended normally (no errors).  
echo You can repeat running this batch file as frequently as you need. 
echo Next execute the batch file "gcp_7_bucket_runsvc.bat".

