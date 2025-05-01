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

rem set GCP_REGION=us-east4
echo GCP_REGION: %GCP_REGION%

rem SET GCP_USER=username@gmail.com
echo GCP_USER: %GCP_USER%

rem SET GCP_SVC_ACT=svc-act-pubsub@%GCP_PROJ_ID%.iam.gserviceaccount.com
SET GCP_SVC_ACT=%GCP_SVC_ACT_PREFIX%@%GCP_PROJ_ID%.iam.gserviceaccount.com
echo GCP_SVC_ACT: %GCP_SVC_ACT%


rem Google Run Jobs
echo GCP_RUN_JOB: %GCP_RUN_JOB%

rem Google Run Jobs mount volume name
echo GCP_RUN_JOB_VOL_NAME: %GCP_RUN_JOB_VOL_NAME%

rem Google Run Jobs mount volume path
echo GCP_RUN_JOB_VOL_MT_PATH: %GCP_RUN_JOB_VOL_MT_PATH%

rem Google Storage Bucket
echo GCP_GS_BUCKET: %GCP_GS_BUCKET%  (gs://%GCP_GS_BUCKET%)

rem Google Storage Bucket location
echo GCP_GS_BUCKET_LOCATION: %GCP_GS_BUCKET_LOCATION%

rem Google Storage Bucket min retention period
echo GCP_GS_BUCKET_MIN_RETENTION: %GCP_GS_BUCKET_MIN_RETENTION%



rem ----------------------------------------------------------------------


echo.
echo This batch file will:
echo 1) Create the Google Run Service "%GCP_RUN_JOB%" from the Docker image "%GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY%/%GCP_IMAGE%:latest".
echo 2) Mount the bucket "%GCP_GS_BUCKET%" to the Cloud Run Service "%GCP_RUN_JOB%" as a Volume Mount named "%GCP_RUN_JOB_VOL_NAME%" with path "%GCP_RUN_JOB_VOL_MT_PATH%".
echo 3) Run the Google Cloud Run Jobs "%GCP_RUN_JOB%".

echo. 
echo Review all of the local variable assignments shown above carefully. 
echo Press ENTER to continue, or CTRL-C to abort.
pause

echo.


rem ----------------------------------------------------------------------
rem Google Cloud Jobs


rem Delete the Cloud Run Service if they exist
rem gcloud run jobs delete JOB_NAME --region=REGION --quiet
echo.
echo Deleting any existing Cloud Run Services named %GCP_RUN_JOB%  (ignore any errors).
@echo on
CALL gcloud run services delete %GCP_RUN_JOB% --region=%GCP_REGION% --quiet
@echo off
echo Ignore any errors above.


rem Deploy the Cloud Run Service from the Docker image in the Artifact Registry (repository).
rem The argument --allow-unauthenticated makes the Cloud Run publicly accessible.
rem Defaults are: --cpu=1  --memory=512 MiB
rem For 4.0 CPU, memory must be between 2Gi and 16Gi inclusive.
rem gcloud run deploy [run service name] --image=[docker image name] --region=[region] --allow-unauthenticated
rem --no-allow-unauthenticated		--allow-unauthenticated
rem CALL gcloud run deploy %GCP_RUN_JOB% --image=%GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY%/%GCP_IMAGE%:latest --region=%GCP_REGION% --cpu=4 --memory=8Gi --concurrency=80 --allow-unauthenticated
rem CALL gcloud run deploy %GCP_RUN_JOB% --image=%GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY%/%GCP_IMAGE%:latest --region=%GCP_REGION% --allow-unauthenticated
rem CALL gcloud run deploy %GCP_RUN_JOB% --image=%GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY%/%GCP_IMAGE%:latest --region=%GCP_REGION% --allow-unauthenticated --cpu=4 --memory=3Gi --concurrency=80
@echo on
CALL gcloud run deploy %GCP_RUN_JOB% --image=%GCP_REGION%-docker.pkg.dev/%GCP_PROJ_ID%/%GCP_REPOSITORY%/%GCP_IMAGE%:latest --region=%GCP_REGION% --allow-unauthenticated
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: 
	EXIT /B
)



rem List the Cloud Run Services by JOB URI
echo.
echo Google Run Services:
rem CALL gcloud run jobs list
CALL gcloud run services list --region=us-east4 --uri



rem ----------------------------------------------------------------------
rem Cloud Storage Bucket & Update Cloud Run Job with Volume Mount to Bucket



rem Show details about the BUCKET
echo.
echo Cloud Storage Bucket %GCP_GS_BUCKET%:
@echo on
CALL gcloud storage buckets describe gs://%GCP_GS_BUCKET%
@echo off



rem Assign the BUCKET to the Google Run Services as a mount volume
rem gcloud run services update JOB --add-volume name=VOLUME_NAME,type=cloud-storage,bucket=BUCKET_NAME --add-volume-mount volume=VOLUME_NAME,mount-path=MOUNT_PATH --region=REGION
@echo on
CALL gcloud run services update %GCP_RUN_JOB% --add-volume name=%GCP_RUN_JOB_VOL_NAME%,type=cloud-storage,bucket=%GCP_GS_BUCKET% --add-volume-mount volume=%GCP_RUN_JOB_VOL_NAME%,mount-path=%GCP_RUN_JOB_VOL_MT_PATH% --region=%GCP_REGION%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud run services update %GCP_RUN_JOB% --add-volume name=%GCP_RUN_JOB_VOL_NAME%,type=cloud-storage,bucket=%GCP_GS_BUCKET% --add-volume-mount volume=%GCP_RUN_JOB_VOL_NAME%,mount-path=%GCP_RUN_JOB_VOL_MT_PATH% --region=%GCP_REGION%
	EXIT /B
)


rem Show the bucket file contents
echo.
echo Show the bucket file contents with the command: 
@echo on
CALL gcloud storage ls gs://%GCP_GS_BUCKET%
@echo off


rem Show the bucket contents with the Cloud Console URL
echo.
echo Show the bucket file contents in the Cloud Console with the URL: https://console.cloud.google.com/storage/browser/%GCP_GS_BUCKET%?project=%GCP_PROJ_ID%
echo.


rem Show a list of the Cloud Run Services
rem gcloud run services list --region=us-east4
@echo on
CALL gcloud run services list --region=%GCP_REGION%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud run services list --region=%GCP_REGION%
	EXIT /B
)


rem Get the URL for the Cloud Run Service
rem gcloud run services describe SERVICE_NAME --region=REGION --format 'value(status.url)'
@echo off
echo.
echo You can access the Flask app running as a Cloud Run Service by copying and pasting
echo the following URL into a browser:
CALL gcloud run services describe %GCP_RUN_JOB% --region=%GCP_REGION% --format "value(status.url)"
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud run services describe %GCP_RUN_JOB% --region=%GCP_REGION% --format "value(status.url)"
	EXIT /B
)


echo .
rem gcloud run services describe YOUR_SERVICE_NAME --region YOUR_REGION
@echo on
CALL gcloud run services describe %GCP_RUN_JOB% --region=%GCP_REGION%
@echo off


echo.
echo You can delete the Cloud Run Service with the command:
echo gcloud run services delete %GCP_RUN_JOB% --region=%GCP_REGION% --quiet




ENDLOCAL

echo.
echo This batch file %~n0%~x0 has ended normally (no errors).  
echo You can repeat running this batch file as frequently as you wish.
echo.
echo The next batch file to run is gcp_8_auth_users.
