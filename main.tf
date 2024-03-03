provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}

# VPC
resource "google_compute_network" "development_app_network" {
  project                 = var.project
  name                    = "vpc-dev-app"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnet1
resource "google_compute_subnetwork" "development" {
  project       = var.project
  region        = var.region
  network       = google_compute_network.development_app_network.id
  name          = "dev"
  ip_cidr_range = "192.168.0.0/24"
}

# Service Networking
resource "google_compute_global_address" "google_private_ip_range" {
  project       = var.project
  network       = google_compute_network.development_app_network.id
  name          = "google-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
}
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.development_app_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google_private_ip_range.name]
}

# service account for github actions deploy
resource "google_service_account" "github_actions" {
  account_id   = "github-actions"
  display_name = "GitHub Actions (NestJS - Cloud Run)"
}
resource "google_project_iam_binding" "github_actions_run_admin" {
  project = var.project
  role    = "roles/run.admin"
  members = [
    "serviceAccount:${google_service_account.github_actions.email}",
  ]
}
resource "google_project_iam_binding" "github_actions_artifact_registry" {
  project = var.project
  role    = "roles/artifactregistry.writer"
  members = [
    "serviceAccount:${google_service_account.github_actions.email}",
  ]
}
resource "google_project_iam_binding" "github_actions_service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.github_actions.email}",
  ]
}
resource "google_project_iam_binding" "github_actions_iam_workload_identity_user" {
  project = var.project
  role    = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${google_service_account.github_actions.email}",
  ]
}

# Artifact Registry; Development
resource "google_artifact_registry_repository" "development" {
  project       = var.project
  location      = var.region
  repository_id = var.artifact_registry_repository_development
  format        = "DOCKER"
}
# Cloud Run; Development
resource "google_cloud_run_service" "cloudrun_service_development" {
  project  = var.project
  location = var.region
  name     = var.artifact_registry_repository_development

  template {
    spec {
      timeout_seconds = 30
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.development.repository_id}/${var.artifact_registry_repository_development}"
        # image = "us-docker.pkg.dev/cloudrun/container/hello"
        env {
          name  = "NODE_ENV"
          value = "development"
        }
        env {
          name  = "SERVICE_SITE_URL"
          value = "https://dev.react.r253.dev/"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}
# no Auth; Development
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "noauth_development" {
  location = google_cloud_run_service.cloudrun_service_development.location
  project  = google_cloud_run_service.cloudrun_service_development.project
  service  = google_cloud_run_service.cloudrun_service_development.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

# Artifact Registry; Production
resource "google_artifact_registry_repository" "production" {
  project       = var.project
  location      = var.region
  repository_id = var.artifact_registry_repository_production
  format        = "DOCKER"
}
# Cloud Run; Production
resource "google_cloud_run_service" "cloudrun_service_production" {
  project  = var.project
  location = var.region
  name     = var.artifact_registry_repository_production

  template {
    spec {
      timeout_seconds = 30
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.production.repository_id}/${var.artifact_registry_repository_production}"
        # image = "us-docker.pkg.dev/cloudrun/container/hello"
        env {
          name  = "NODE_ENV"
          value = "production"
        }
        env {
          name  = "SERVICE_SITE_URL"
          value = "https://react.r253.dev/"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}
# no Auth; Production
resource "google_cloud_run_service_iam_policy" "noauth_production" {
  location = google_cloud_run_service.cloudrun_service_production.location
  project  = google_cloud_run_service.cloudrun_service_production.project
  service  = google_cloud_run_service.cloudrun_service_production.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
