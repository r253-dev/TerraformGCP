## Prepare(only once)

### Create a new Project

if you don't have a GCP project, create a new project.

### Enable APIs

Enable the following APIs in the project.

[Compute Engine API](https://console.cloud.google.com/apis/library/compute.googleapis.com)
[Cloud Resource Manager API](https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com)
[Service Networking API](https://console.cloud.google.com/apis/library/servicenetworking.googleapis.com)
[Cloud Run API](https://console.cloud.google.com/apis/library/run.googleapis.com)
[Identity and Access Management (IAM) API](https://console.cloud.google.com/apis/library/iam.googleapis.com)
[Cloud SQL Admin API](https://console.cloud.google.com/apis/library/sqladmin.googleapis.com)

[Serverless VPC Access API](https://console.cloud.google.com/marketplace/product/google/vpcaccess.googleapis.com)
[Cloud Build API](https://console.cloud.google.com/apis/library/cloudbuild.googleapis.com)

### Create a Service Account

Create a new service account.

1. Go to the [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page and select the project.
2. Click Create Service Account.
   1. service account name: terraform
   2. service account id: terraform
   3. role: Owner

## Installation

### Authentication

1. Go to the [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page and select the project.
2. click the service account you created.
3. download the key file.
   1. click the service account
   2. click the `Key` tab
   3. click `Add Key` and select `create new key`
      1. select `JSON` and click `Create`
4. rename the key file to `terraform.json` and move it to the `credentials` directory.

## Usage

```bash
terraform plan
terraform apply
```
