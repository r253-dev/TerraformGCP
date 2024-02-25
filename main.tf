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
