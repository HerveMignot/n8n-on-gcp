# n8n Service Deployment on GCP Cloud Run with Persistent Storage

## Prerequisites

Before proceeding, please ensure you have the following:

- A Google Cloud account.
- The `gcloud` CLI installed and authenticated with your Google Cloud account.
- A Google Cloud project set up.
- And an Artifact Registry repository configured within that project (see below).

If you are new to GCP or `gcloud` CLI, Google provides extensive documentation to get you started.

Note: be sure to have a recent version of `gcloud` CLI installed, as the deployment is using CSI volumes for Cloud Run (early 2023). You can update your `gcloud` CLI with the following command: `gcloud components update`.

Shell scripts are used, consider using Git Bash on Windows if no Unix-like shell is installed on the environment.

Clone this project onto your environmment to customize setup parameters, as explained below.

### Configure a remote repository with GCP Artifact Registry

In order to deploy n8n docker image, you will need to use Artifact Registry and a _remote_ repository. Because n8n docker image is stored on n8n docker registry (`docker.n8n.io`), Cloud Run is unable to use directly an image from such registry. A _remote repository_ needs to be create with GCP Artifact Registry, pointing to n8n docker registry.

First activate Artifact Registry API:

```bash
gcloud services enable artifactregistry.googleapis.com --project <YOUR_PROJECT_ID>
```

Then create the remote reposity (make sure to use the same name, n8n-docker, as it is used in the deployment file for Cloud Run. Or adapt the deployment template, `deploy-template.yaml`, line describing the image of the container):

```bash
gcloud artifacts repositories create n8n-docker \
    --project=<YOUR_PROJECT_ID> \
    --repository-format=docker \
    --location=LOCATION \
    --description="n8n Docker Registry Copy" \
    --mode=remote-repository \
    --remote-repo-config-desc="n8n Docker Registry" \
    --disable-vulnerability-scanning \
    --remote-docker-repo=https://docker.n8n.io
```

Cloud Run will be able to use the n8n docker image that will be copied from n8n docker registry on the first time. No need to copy the image, this will be done automatically.


## Prepare information for deployment

The following parameters will be used to customize the deployment of the ChromaDB service on Cloud Run. Please review and prepare them for the deployment steps below.
| Parameter             | Description |
|-----------------------|-------------|
| `<YOUR_BUCKET_NAME>`  | The name of the Google Cloud Storage bucket where the n8n data will be stored. This bucket will be created in the next step. |
| `<REGION>`            | The region where the Google Cloud Storage bucket and the Cloud Run service will be deployed. Choose a region based on your requirements and the location of your users, e.g., `europe-west1` for the EU West region, `us-central1` for the US Central region. |
| `<YOUR_PROJECT_ID>`   | The ID of your Google Cloud project. You can find your project ID in the Google Cloud Console, under the project name or in the project settings page. |
| `<SERVICE_NAME>`      | The name of the Cloud Run service (e.g., `chroma`). |
| `<SERVICE_ACCOUNT>`   | The GCP service account to run the service. Usually, the default Compute Engine service account is used, which can be found on the Google Cloud project IAM page. However, it is a better security practice to have a dedicated service account created for the service. |


## Step 1: Create a Google Cloud Storage Bucket

First, create a dedicated GCS bucket for persistent storage of the n8n data. Replace `<YOUR_BUCKET_NAME>` with your desired bucket name, `<REGION>` with the region name (e.g., `europe-west1`), and `<YOUR_PROJECT_ID>` with your Google Cloud project ID.

```bash
gsutil mb -p <YOUR_PROJECT_ID> -l <REGION> gs://<YOUR_BUCKET_NAME>/
```

Replace `<REGION>` with the desired region for your bucket. For example, `europe-west1` for the EU West region, `us-central1` for the US Central region. This bucket will be used to store the n8n data, ensuring data persistence even if the Cloud Run service is scaled down or restarted.


## Step 2: Generate a custom Cloud Run yaml file

The script `generate_yaml.sh` is provided to generate a custom version of the Cloud Run yaml file with your specific bucket name and project ID.

We advise to copy this script to some `my_generate_yaml.sh` before editing this copy. This way the original file, `generate_yaml.sh`, is not modified.

```bash
cp generate_yaml.sh my_generate_yaml.sh
```

Edit the bash script to replace the following variables:
- `SERVICE_NAME`: name of the Cloud Run service (default: n8n)
- `SERVICE_ACCOUNT`: GCP service account to run the service (usually the default Compute Engine SA, get its name from the Google Cloud project IAM page)
- `SERVICE_REGION`: name of the region the service will be deployed to (example: europe-west1)
- `BUCKET_NAME`: name of the bucket created in Step 1
- `PROJECT_ID`: name of the GCP project where n8n is going to be deployed


## Step 3: Deploy the Cloud Run Service

Run gcloud command to deploy the service:
```bash
gcloud run services replace deploy.yaml --project <YOUR_PROJECT_ID>
```
Note: you can copy paste the second command from the output of the step 2 command.


## Step 4: Allow unauthenticated traffic on the service

Run gcloud command to allow unauthenticated traffic on the service.
```bash
gcloud run services add-iam-policy-binding <SERVICE_NAME> --member="allUsers" --role="roles/run.invoker" --region=<REGION> --project=<YOUR_PROJECT_ID>
```
Note: you can copy paste the second command from the output of the step 2 command.

Remark: it is not possible to instruct this traffic rule from the YAML file.

## Step 5: Check n8n is running fine

Open the n8n service URL in your browser, its URL has been output when step 3 is finishing. No need to add the port number like when running in local, n8n can be reached on then standard port (https).

Remark : the initial run is pretty long, n8n is setting up a lot of things.

Refer to n8n documentation to test the n8n service.
