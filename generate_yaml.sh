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
# To be used with Cloud Run Custom Domains
N8N_PROTOCOL="https"
N8N_HOST="n8n.yourdomain.tld"
N8N_URL="${N8N_PROTOCOL}://${N8N_HOST}"

# Check if all required variables are set
if [[ -z "$N8N_URL" || -z "$N8N_PROTOCOL" || -z "$N8N_HOST" ]]; then
  N8N_ENV=""
else
  # Define the text template
  TEMPLATE='
        - name: WEBHOOK_URL
          value: ${N8N_URL}
        - name: N8N_PROTOCOL
          value: ${N8N_PROTOCOL}
        - name: N8N_HOST
          value: ${N8N_HOST}'

  # Replace placeholders with actual values
  eval "N8N_ENV=\"$TEMPLATE\""
fi

# Export the variable
export N8N_ENV

# Replace variables in the template file
envsubst < deploy-template.yaml > deploy.yaml

# Now you can use the deploy.yaml file for your deployment
# Authentication is managed by ChromaDB, so no need to authenticate with gcloud
echo Use the following command to deploy the service:
echo    gcloud run services replace deploy.yaml --project "$PROJECT_ID"
echo then allow authenticated access:
echo    gcloud run services add-iam-policy-binding $SERVICE_NAME --member="allUsers" --role="roles/run.invoker" --region=$SERVICE_REGION --project=$PROJECT_ID