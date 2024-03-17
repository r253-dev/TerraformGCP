variable "credentials" {
  default = "./credentials/terraform.json"
}
variable "project" {
  default = "r253-dev"
}
variable "region" {
  # Osaka
  default = "asia-northeast2"
}
variable "zone" {
  default = "asia-northeast2-c"
}
variable "cloud_run_service_name_development" {
  default = "nest-development"
}
variable "cloud_run_service_name_production" {
  default = "nest-production"
}
variable "cloud_sql_instance" {
  default = "nest"
}
variable "cloud_sql_database_development" {
  default = "nest_development"
}
variable "cloud_sql_database_production" {
  default = "nest_production"
}
variable "artifact_registry_repository_development" {
  default = "nest-development"
}
variable "artifact_registry_repository_production" {
  default = "nest-production"
}
