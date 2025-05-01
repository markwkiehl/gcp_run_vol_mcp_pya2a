@echo off
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

rem Cloud Storage bucket
echo GCP_GS_BUCKET: %GCP_GS_BUCKET%

echo GCP_GS_BUCKET_LOCATION: %GCP_GS_BUCKET_LOCATION%



echo.
echo This batch file will:
echo 1) Configure Google Cloud Storage with a new bucket "%GCP_GS_BUCKET%".
echo.
echo Press ENTER to continue, or CTRL-C to abort.
pause


rem NOTE: 	Buckets are tricky to work with in a batch file. 
rem 		What is implemented below works for the case when a bucket does and does not exist.

 

echo.
echo Creating the storage bucket gs://%GCP_GS_BUCKET%  (ignore errors if it already exists)..
@echo on
CALL gcloud storage buckets create gs://%GCP_GS_BUCKET% --project=%GCP_PROJ_ID% --location=%GCP_GS_BUCKET_LOCATION% --retention-period=1S
@echo off
rem echo ERRORLEVEL: %ERRORLEVEL%
rem If the bucket does not exist: ERRORLEVEL: 0
rem If the bucket already exists: ERRORLEVEL: 1
rem Do not try to manage ERRORLEVEL.


rem Delete the bucket objects within, but not the bucket.
rem Delete only the bucket contents, not the bucket: gcloud storage rm --recursive gs://%GCP_GS_BUCKET%/*.*
rem This command only deletes a bucket that is empty: gcloud storage buckets delete gs://%GCP_GS_BUCKET%
rem NOTE: The minimum retention policy will prevent deletion.
echo. 
echo.
echo Deleting any existing bucket contents, but not the bucket (ignore any errors)..
@echo on
CALL gcloud storage rm --recursive gs://%GCP_GS_BUCKET%/*.*
@echo off




echo.
echo.
echo You may use this command to see the contents of the bucket:  gcloud storage ls gs://%GCP_GS_BUCKET%




ENDLOCAL

echo.
echo This batch file %~n0%~x0 has ended normally (no errors).  
echo DO NOT repeat running this batch file - bucket names must be unique.
echo Next, execute the batch file "gcp_4_auth_apis_svc_act.bat".
