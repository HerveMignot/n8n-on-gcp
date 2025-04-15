#!/bin/bash

# Define variables to be replaced in the template
export SERVICE_NAME="n8n"
export SERVICE_ACCOUNT="sa@developer.gserviceaccount.com"
export SERVICE_REGION="europe-west1"
export BUCKET_NAME="bucketname4storage"

# Optionally, set the following variables
export MIN_INSTANCES=0  # Set to 1 to keep the service always on

# Set GCP projet id
export PROJECT_ID="project-id"

# Set N8N Environment Varaibles
export N8N_PROTOCOL="https"
export N8N_HOST="n8n.yourdomain.tld"
export N8N_URL="${N8N_PROTOCOL}://${N8N_HOST}"

# Replace variables in the template file
envsubst < deploy-template.yaml > tmp/deploy.yaml

# Now you can use the deploy.yaml file for your deployment
# Authentication is managed by ChromaDB, so no need to authenticate with gcloud
echo Use the following command to deploy the service:
echo    gcloud run services replace tmp/deploy.yaml --project "$PROJECT_ID"
echo then allow authenticated access:
echo    gcloud run services add-iam-policy-binding $SERVICE_NAME --member="allUsers" --role="roles/run.invoker" --region=$SERVICE_REGION --project=$PROJECT_ID