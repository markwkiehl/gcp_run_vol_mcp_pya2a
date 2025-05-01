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

rem set the Google Cloud Platform Project ID
echo GCP_PROJ_ID: %GCP_PROJ_ID%

rem set GCP_REGION=us-east4
echo GCP_REGION: %GCP_REGION%

rem SET GCP_USER=username@gmail.com
echo GCP_USER: %GCP_USER%

rem SET GCP_SVC_ACT=svc-act-pubsub@%GCP_PROJ_ID%.iam.gserviceaccount.com
SET GCP_SVC_ACT=%GCP_SVC_ACT_PREFIX%@%GCP_PROJ_ID%.iam.gserviceaccount.com
echo GCP_SVC_ACT: %GCP_SVC_ACT%

rem https://console.cloud.google.com/billing
rem Edit the billing account number below to be your Google Billing Account No:
rem SET GCP_BILLING_ACCOUNT=0X0X0X-0X0X0X-0X0X0X
echo GCP_BILLING_ACCOUNT: %GCP_BILLING_ACCOUNT%

rem ----------------------------------------------------------------------


echo.
echo This batch file will:
echo 1) Setup a new GCP Project with the above settings.  
echo 2) Link the Google Cloud Billing Account No. %GCP_BILLING_ACCOUNT% to the project %GCP_PROJ_ID%.
echo 3) Create the user-manged service account %GCP_SVC_ACT% 
echo.
echo Press ENTER to continue, or CTRL-C to abort.
pause


echo.
echo. Existing default gcloud configuration:
CALL gcloud config list


rem Login to Google
echo.
echo Google user %GCP_USER% must login.
echo You may close the browser when authorization is complete and then return to this window.
pause
@echo on
CALL gcloud auth login
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud auth login
	EXIT /B
)


rem Create a new project and enable cloudapis.googleapis.com during creation. 
rem gcloud projects create PROJECT --enable-cloud-apis
echo.
@echo on
CALL gcloud projects create %GCP_PROJ_ID% --enable-cloud-apis
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud projects create %GCP_PROJ_ID% --enable-cloud-apis
	EXIT /B
)

echo.
echo Below is a list of projects for the user %GCP_USER%.
echo (Ignore "WARNING: Your active project does not match the quota project.." 
echo  this will be resolved later).
@echo on
CALL gcloud projects list
@echo off


rem Assign a new default project
rem gcloud config set project PROJECT
@echo off
CALL gcloud config set project %GCP_PROJ_ID%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud config set project %GCP_PROJ_ID%
	EXIT /B
)

@echo off
CALL gcloud config list
@echo off


rem Add the role: serviceusage.serviceUsageConsumer to the user %GCP_USER%
@echo on
CALL gcloud projects add-iam-policy-binding %GCP_PROJ_ID% --member=user:%GCP_USER% --role=roles/serviceusage.serviceUsageConsumer
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud projects add-iam-policy-binding %GCP_PROJ_ID% --member=user:%GCP_USER% --role=roles/serviceusage.serviceUsageConsumer
	EXIT /B
)


rem Enable the Cloud Resource Manager API
rem (cloudapis.googleapis.com  enabled during project creation)
@echo on
CALL gcloud services enable cloudresourcemanager.googleapis.com --project=%GCP_PROJ_ID%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud services enable cloudresourcemanager.googleapis.com --project=%GCP_PROJ_ID%
	EXIT /B
)


rem Authenticate as a user to the Google Cloud Client Libraries 
rem gcloud auth application-default login
echo.
echo Google user %GCP_USER% must authorize the addition of the roles and enabled APIs.
echo You may close the browser when authorization is complete and then return to this window.
pause
@echo on
CALL gcloud auth application-default login
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud services enable cloudresourcemanager.googleapis.com --project=%GCP_PROJ_ID%
	EXIT /B
)


rem Update or add a quota project in application default credentials (ADC).
rem A quota project is a Google Cloud Project that will be used for billing and quota limits.
rem gcloud auth application-default set-quota-project PROJECT
@echo on
CALL gcloud auth application-default set-quota-project %GCP_PROJ_ID%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud auth application-default set-quota-project %GCP_PROJ_ID% 
	EXIT /B
)



rem List Google Cloud CLI properties for the currently active configuration 
@echo on
CALL gcloud config list
@echo off


rem Make sure billing is configured
@echo on
CALL gcloud billing accounts list
@echo off


rem list the projects linked to a billing account
@echo on
CALL gcloud billing projects list --billing-account=%GCP_BILLING_ACCOUNT%
@echo off


rem Link a project to a billing account
@echo on
CALL gcloud billing projects link %GCP_PROJ_ID% --billing-account=%GCP_BILLING_ACCOUNT%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud billing projects link %GCP_PROJ_ID% --billing-account=%GCP_BILLING_ACCOUNT% 
	EXIT /B
)

rem list the projects linked to a billing account
@echo on
CALL gcloud billing projects list --billing-account=%GCP_BILLING_ACCOUNT%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud billing projects list --billing-account=%GCP_BILLING_ACCOUNT% 
	EXIT /B
)


rem Enable IAM and Service Account Credentials APIs
@echo on
CALL gcloud services enable iam.googleapis.com iamcredentials.googleapis.com --project=%GCP_PROJ_ID%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%: gcloud services enable iam.googleapis.com iamcredentials.googleapis.com --project=%GCP_PROJ_ID%
	EXIT /B
)


rem List enabled API services  (note that Google enables many by default)
echo.
echo Enabled API services for the default project (Google enables many by default):
@echo on
CALL gcloud services list
@echo off

rem The next command will verify that the PROJECT has been set as the default
echo.
echo. The project %GCP_PROJ_ID% and the 'account' should be assigned values:
@echo on
CALL gcloud config list
@echo off

rem List credentialed accounts
@echo on
CALL gcloud auth list
@echo off

rem List the IAM roles for a project
echo.
echo List of IAM roles for a project:
@echo on
CALL gcloud projects get-iam-policy %GCP_PROJ_ID%
@echo off

rem Create a user-managed service account
CALL gcloud iam service-accounts create %GCP_SVC_ACT_PREFIX% --description="Service account for Pub/Sub" --display-name="%GCP_SVC_ACT_PREFIX%"
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%
	EXIT /B
)

rem List all service accounts for a project
echo.
echo Service accounts for project %GCP_PROJ_ID%:
@echo on
CALL gcloud iam service-accounts list --project=%GCP_PROJ_ID%
@echo off
echo.

rem Grant the role 'roles/iam.serviceAccountTokenCreator' to the user
@echo on
CALL gcloud projects add-iam-policy-binding %GCP_PROJ_ID% --member=user:%GCP_USER% --role=roles/iam.serviceAccountTokenCreator
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL% 
	EXIT /B
)

rem Allow the service account to impersonate the user account
@echo on
CALL gcloud iam service-accounts add-iam-policy-binding %GCP_SVC_ACT% --member=user:%GCP_USER% --role=roles/iam.serviceAccountTokenCreator
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%
	EXIT /B
)


rem View the roles for the project
echo.
@echo on
CALL gcloud projects get-iam-policy %GCP_PROJ_ID%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%
	EXIT /B
)

rem Update local ADC / user-managed service account impersonation
echo.
echo Google user %GCP_USER% must authorize the addition of the roles and enabled APIs.
echo You may close the browser when authorization is complete and then return to this window.
pause
@echo on
CALL gcloud auth application-default login --impersonate-service-account %GCP_SVC_ACT%
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%
	EXIT /B
)

rem Make sure the Google components are updated
@echo on
CALL gcloud components update
@echo off
IF %ERRORLEVEL% NEQ 0 (
	echo ERROR %ERRORLEVEL%
	EXIT /B
)

ENDLOCAL

echo.
echo This batch file %~n0%~x0 has ended normally (no errors).  
echo You may continue with batch file "gcp_3_bucket.bat".