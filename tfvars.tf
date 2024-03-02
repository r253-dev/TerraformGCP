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
variable "artifact_registry_repository_development" {
  default = "nest-development"
}
variable "artifact_registry_repository_production" {
  default = "nest-production"
}
