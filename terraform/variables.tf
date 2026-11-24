variable "aws_region" {
  description = "AWS region for the pilot stack"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short lowercase project identifier"
  type        = string
  default     = "image-platform"
}

variable "lambda_timeout" {
  description = "Image processing timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory_size" {
  description = "Image processing Lambda memory in MB"
  type        = number
  default     = 1024
}

variable "notification_email" {
  description = "Optional email endpoint for SNS subscription; leave empty to disable"
  type        = string
  default     = ""
}
