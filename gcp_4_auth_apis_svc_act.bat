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

echo GCP_REGION: %GCP_REGION%

echo GCP_USER: %GCP_USER%

SET GCP_SVC_ACT=%GCP_SVC_ACT_PREFIX%@%GCP_PROJ_ID%.iam.gserviceaccount.com
echo GCP_SVC_ACT: %GCP_SVC_ACT%

rem Cloud Storage bucket
echo GCP_GS_BUCKET: %GCP_GS_BUCKET%


echo.
echo This batch file will:
echo 1) Enable Google Artifact Registry API.
echo 2) Configure authentication to Artifact Registry for Docker.
echo 3) Enable Cloud Run API.
echo 4) Configure authentication to the service account "%GCP_SVC_ACT%" for Cloud Run.
echo 5) Update local Application Default Credentials (ADC).
echo 6) Configure authentication to the service account "%GCP_SVC_ACT%" for bucket "%GCP_GS_BUCKET%".
echo. 
echo Press ENTER to continue, or CTRL-C to abort.
pause
echo.




rem Enable Google Artifact Registry API 
CALL gcloud services enable artifactregistry.googleapis.com
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud services enable artifactregistry.googleapis.com
	EXIT /B
)

rem Enable containerscanning.googleapis.com  COST IS $1.56/day !!!!
rem CALL gcloud services enable containerscanning.googleapis.com
rem IF %ERRORLEVEL% NEQ 0 (
rem 	echo ERROR %ERRORLEVEL%: gcloud services enable containerscanning.googleapis.com
rem 	EXIT /B
rem )


rem Configure authentication to Artifact Registry for Docker
rem gcloud auth configure-docker LOCATION-docker.pkg.dev
rem NOTE: Another method that may work is:  gcloud auth configure-docker gcr.io
@echo on
CALL gcloud auth configure-docker %GCP_REGION%-docker.pkg.dev
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud auth configure-docker %GCP_REGION%-docker.pkg.dev
	EXIT /B
)

rem Grant the user-managed service account the roles required for Cloud Run Jobs & Scheduler Jobs
rem gcloud projects add-iam-policy-binding PROJECT_ID --member=serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com --role=roles/run.invoker
@echo on
CALL gcloud projects add-iam-policy-binding %GCP_PROJ_ID% --member=serviceAccount:%GCP_SVC_ACT% --role=roles/run.invoker
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud projects add-iam-policy-binding %GCP_PROJ_ID% --member=serviceAccount:%GCP_SVC_ACT% --role=roles/run.invoker
	EXIT /B
)

rem Enable the Cloud Run API
@echo on
CALL gcloud services enable run.googleapis.com
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: services enable run.googleapis.com
	EXIT /B
)




rem Grant a single role to a single principal for BUCKET
rem NOTE: Must create bucket before assigning permissions via add-iam-policy-binding
rem gcloud storage buckets add-iam-policy-binding gs://BUCKET --member=user:john.doe@example.com --role=roles/storage.objectCreator
@echo on
CALL gcloud storage buckets add-iam-policy-binding gs://%GCP_GS_BUCKET% --project=%GCP_PROJ_ID% --member=serviceAccount:%GCP_SVC_ACT% --role=roles/storage.objectCreator
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud storage buckets add-iam-policy-binding gs://%GCP_GS_BUCKET% --project=%GCP_PROJ_ID% --member=serviceAccount:%GCP_SVC_ACT% --role=roles/storage.objectCreator
	EXIT /B
)

rem Configure permissions needed to configure Cloud Storage volume mounts:
rem Cloud Run Jobs needs: roles/run.developer
rem Service account user: roles/iam.serviceAccountUser
rem To access the file and Cloud Storage bucket: roles/storage.admin
rem Reference link: https://cloud.google.com/run/docs/configuring/jobs/cloud-storage-volume-mounts#required-roles
@echo on
CALL gcloud projects add-iam-policy-binding %GCP_PROJ_ID% --member=serviceAccount:%GCP_SVC_ACT% --role=roles/run.developer
@echo off
IF %ERRORLEVEL% NEQ 0 (
	EXIT /B
)
@echo on
CALL gcloud projects add-iam-policy-binding %GCP_PROJ_ID% --member=serviceAccount:%GCP_SVC_ACT% --role=roles/iam.serviceAccountUser
@echo off
IF %ERRORLEVEL% NEQ 0 (
	EXIT /B
)
@echo on
CALL gcloud projects add-iam-policy-binding %GCP_PROJ_ID% --member=serviceAccount:%GCP_SVC_ACT% --role=roles/storage.admin
@echo off
IF %ERRORLEVEL% NEQ 0 (
	EXIT /B
)


rem -------------------------------------------------------------------------------------
rem Grant permissions to specific people by gmail address for the Google Cloud Run Service.
rem a6.024x23@gmail.com
rem vmoskal@smartcostinc.com
rem rich@marando-inc.com
rem gcloud run services add-iam-policy-binding YOUR_SERVICE_NAME --region=%GCP_REGION% --member=user:USER_GMAIL_ADDRESS --role=roles/run.invoker

rem -------------------------------------------------------------------------------------



rem Update local ADC
echo.
echo Google user %GCP_USER% must authorize the addition of the roles and enabled APIs.
echo You may close the browser when authorization is complete and then return to this window.
pause
@echo on
CALL gcloud auth application-default login --impersonate-service-account %GCP_SVC_ACT%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud auth application-default login --impersonate-service-account %GCP_SVC_ACT% 
	EXIT /B
)




ENDLOCAL

echo.
echo This batch file %~n0%~x0 has ended normally (no errors).  
echo Next, execute the batch file "gcp_5_docker_build.bat".
