# gcp_run_vol_mcp_pya2a

Full article with details available at this public link: https://medium.com/@markwkiehl/deploy-your-custom-mcp-ai-tool-to-cloud-run-a4d443821e67


## Deploy Your Custom MCP AI Tool to Cloud Run

A complete working example of how to create a Model Context Protocol (MCP) compliant AI tool and then deploy it to Cloud Run as a scalable, accessible service that anyone can use.

Everything you need to build and run a custom MCD deployed to Google Cloud Run. Included are two Python scripts, one for creating the MCD, and another for locally accessing the MCD in Google Cloud Run. Additionally, I am providing batch files for Windows OS (can be adapted to bash) that you can simply run in sequence to perform all of the Google Cloud Platform (GCP) configurations necessary to deploy the Cloud Run Service. All you need is a personal Google account (email) with billing enabled to use the Google Cloud Platform. You should be able to deploy your Cloud Run Service within the Google Free Tier Limits.

## QuickStart
If you are familiar with Python, Google CLI, and Docker, and already use GCP, then you can build and run my demo application in a few minutes. See further in the article for any details below that you need help with.

- Install Python, Google CLI & SDK, and Docker.
- Download a copy of the GitHub repository contents to an empty folder in your PC. Expand the contents in this folder. This folder will become a Python virtual environment.
- Login to or create a Google user account. From the Google Admin Console, configure billing.
- Edit the file gcp_constants.bat YOU MUST UPDATE THIS FILE at a minimum with your own Google account email address (GCP_USER), and your Google Cloud Billing Account No (GCP_BILLING_ACCOUNT). If you are not located in the USA, then you may want to update the GCP_REGION and GCP_GS_BUCKET_LOCATION (See Geography & Regions).
- Open up a Windows OS command prompt window and navigate to the folder where you downloaded the GitHub contents to. Sequentially execute each of the batch files: gcp_1_venv.bat, gcp_2_proj.bat, … gcp_7_bucket_runsvc.bat. IMPORTANT: The last batch file gcp_7_bucket_runsvc.bat will output the URL for the Cloud Run Service. You need to copy that URL and update test_mcp.py.
- Edit the script test_mcp.py with the URL for the Cloud Run Service created by gcp_7_bucket_runsvc.bat. If you didn’t catch it in the output, then go to Google Cloud Run Console and the URL will be shown under the ‘Services’ tab. Click on the service and the URL will be visible in the console.
- Run the script test_mcp.py.


