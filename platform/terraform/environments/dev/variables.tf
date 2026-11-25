variable "aws_region" {
  description = "AWS region for the lab."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "enterprise-cloud-upgrade"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "availability_zones" {
  description = "Two AZs in the selected region."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}
