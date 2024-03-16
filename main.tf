provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}

resource "google_secret_manager_secret" "database_development" {
  secret_id = "database_development"

  labels = {
    label = "development"
  }

  replication {
    user_managed {
      replicas {
        location = "asia-northeast2"
      }
    }
  }
}

resource "google_secret_manager_secret" "db_host_development" {
  secret_id = "db_host_development"

  labels = {
    label = "development"
  }

  replication {
    user_managed {
      replicas {
        location = "asia-northeast2"
      }
    }
  }
}
resource "google_secret_manager_secret_version" "db_host_development" {
  secret = google_secret_manager_secret.db_host_development.id

  secret_data = google_sql_database_instance.default.private_ip_address
}

resource "google_secret_manager_secret" "db_user_development" {
  secret_id = "db_user_development"

  labels = {
    label = "development"
  }

  replication {
    user_managed {
      replicas {
        location = "asia-northeast2"
      }
    }
  }
}

resource "google_secret_manager_secret" "db_pass_development" {
  secret_id = "db_pass_development"

  labels = {
    label = "development"
  }

  replication {
    user_managed {
      replicas {
        location = "asia-northeast2"
      }
    }
  }
}

resource "google_secret_manager_secret" "database_production" {
  secret_id = "database_production"

  labels = {
    label = "production"
  }

  replication {
    user_managed {
      replicas {
        location = "asia-northeast2"
      }
    }
  }
}

resource "google_secret_manager_secret" "db_host_production" {
  secret_id = "db_host_production"

  labels = {
    label = "production"
  }

  replication {
    user_managed {
      replicas {
        location = "asia-northeast2"
      }
    }
  }
}
resource "google_secret_manager_secret_version" "db_host_production" {
  secret = google_secret_manager_secret.db_host_production.id

  secret_data = google_sql_database_instance.default.private_ip_address
}

resource "google_secret_manager_secret" "db_user_production" {
  secret_id = "db_user_production"

  labels = {
    label = "production"
  }

  replication {
    user_managed {
      replicas {
        location = "asia-northeast2"
      }
    }
  }
}

resource "google_secret_manager_secret" "db_pass_production" {
  secret_id = "db_pass_production"

  labels = {
    label = "production"
  }

  replication {
    user_managed {
      replicas {
        location = "asia-northeast2"
      }
    }
  }
}

# VPC
resource "google_compute_network" "development_app_network" {
  project                 = var.project
  name                    = "vpc-dev-app"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}
resource "google_compute_network" "production_app_network" {
  project                 = var.project
  name                    = "vpc-prod-app"
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
resource "google_compute_subnetwork" "production" {
  project       = var.project
  region        = var.region
  network       = google_compute_network.production_app_network.id
  name          = "prod"
  ip_cidr_range = "192.168.1.0/24"
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

# Cloud SQL
resource "google_sql_database_instance" "default" {
  project             = var.project
  region              = var.region
  name                = var.cloud_sql_instance
  database_version    = "MYSQL_8_0"
  root_password       = "password"
  deletion_protection = false
  settings {
    tier                  = "db-f1-micro" # development, production: db-custom-1-3840
    disk_type             = "PD_HDD"
    disk_size             = 10
    disk_autoresize       = true
    disk_autoresize_limit = 50
    availability_type     = "ZONAL" # development
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.development_app_network.id
    }
  }
}
resource "google_sql_database" "development" {
  project   = var.project
  name      = var.cloud_sql_database_development
  instance  = google_sql_database_instance.default.name
  charset   = "utf8mb4"
  collation = "utf8mb4_general_ci"
}
resource "google_sql_user" "development" {
  instance = google_sql_database_instance.default.name
  name     = var.cloud_sql_database_development
  password = var.cloud_sql_database_development
}
resource "google_sql_database" "production" {
  project   = var.project
  name      = var.cloud_sql_database_production
  instance  = google_sql_database_instance.default.name
  charset   = "utf8mb4"
  collation = "utf8mb4_general_ci"
}
resource "google_sql_user" "production" {
  instance = google_sql_database_instance.default.name
  name     = var.cloud_sql_database_production
  password = var.cloud_sql_database_production
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
        env {
          name = "DB_HOST"
          value_from {
            secret_key_ref {
              key  = "latest"
              name = google_secret_manager_secret.db_host_development.secret_id
            }
          }
        }
        env {
          name = "DATABASE"
          value_from {
            secret_key_ref {
              key  = "latest"
              name = google_secret_manager_secret.database_development.secret_id
            }
          }
        }
        env {
          name = "DB_USER"
          value_from {
            secret_key_ref {
              key  = "latest"
              name = google_secret_manager_secret.db_user_development.secret_id
            }
          }
        }
        env {
          name = "DB_PASS"
          value_from {
            secret_key_ref {
              key  = "latest"
              name = google_secret_manager_secret.db_pass_development.secret_id
            }
          }
        }
      }
    }
    metadata {
      annotations = {
        "run.googleapis.com/network-interfaces" = jsonencode([{
          network    = google_compute_network.development_app_network.name
          subnetwork = google_compute_subnetwork.development.name
        }])
        "run.googleapis.com/vpc-access-egress" = "private-ranges-only"
        # 指定しないとdiffに出てくるので仕方なく指定
        "run.googleapis.com/client-name"       = "gcloud"
        "run.googleapis.com/client-version"    = "466.0.0"
        "run.googleapis.com/startup-cpu-boost" = false
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
        env {
          name = "DB_HOST"
          value_from {
            secret_key_ref {
              key  = "latest"
              name = google_secret_manager_secret.db_host_production.secret_id
            }
          }
        }
        env {
          name = "DATABASE"
          value_from {
            secret_key_ref {
              key  = "latest"
              name = google_secret_manager_secret.database_production.secret_id
            }
          }
        }
        env {
          name = "DB_USER"
          value_from {
            secret_key_ref {
              key  = "latest"
              name = google_secret_manager_secret.db_user_production.secret_id
            }
          }
        }
        env {
          name = "DB_PASS"
          value_from {
            secret_key_ref {
              key  = "latest"
              name = google_secret_manager_secret.db_pass_production.secret_id
            }
          }
        }
      }
    }
    metadata {
      annotations = {
        "run.googleapis.com/network-interfaces" = jsonencode([{
          network    = google_compute_network.development_app_network.name
          subnetwork = google_compute_subnetwork.development.name
        }])
        "run.googleapis.com/vpc-access-egress" = "private-ranges-only"
        # 指定しないとdiffに出てくるので仕方なく指定
        "run.googleapis.com/client-name"       = "gcloud"
        "run.googleapis.com/client-version"    = "466.0.0"
        "run.googleapis.com/startup-cpu-boost" = false
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
