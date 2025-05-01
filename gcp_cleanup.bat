@echo off
cls
echo %~n0%~x0
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
rem Edit the project variables below

rem set the Google Cloud Platform Project ID
echo GCP_PROJ_ID: %GCP_PROJ_ID%

rem Cloud Storage bucket
echo GCP_GS_BUCKET: %GCP_GS_BUCKET%

echo GCP_GS_BUCKET_LOCATION: %GCP_GS_BUCKET_LOCATION%



echo.
echo This batch file will delete the project '%GCP_PROJ_ID%', causing everything associated
echo with the project except the billing account and Cloud Storage Bucket to be deleted.
echo The Cloud Storage Bucket gs://%GCP_GS_BUCKET% will then be deleted.
echo.
echo WARNING:  You cannot use the same Project ID again!!! (that is why versioning the name is recommended).
echo Make sure to edit the variable "GCP_PROJ_ID" in the file gcp_constants.bat if you wish to build the project again.
echo WARNING: You cannot use the same bucket name of "%GCP_GS_BUCKET%" again later.  
echo Revise the variable "GCP_GS_BUCKET" in gcp_constants.bat
echo.
echo Press ENTER to continue, or CTRL-C to abort so you can edit this file '%~n0%~x0'.
pause

rem Show projects
@echo on
CALL gcloud projects list
@echo off
echo.


rem Delete the project
@echo on
CALL gcloud projects delete %GCP_PROJ_ID% --quiet
@echo off
echo.


rem Show projects
@echo on
CALL gcloud projects list
@echo off
echo.


rem Delete the Cloud Storage Bucket
@echo on
CALL gcloud storage rm --recursive gs://%GCP_GS_BUCKET%
@echo off


ENDLOCAL


echo This batch file has ended normally (no errors).  
