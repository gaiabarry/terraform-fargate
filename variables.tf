variable "aws_region" {
  default = "us-east-2"
}

variable "app_image" {
  default     = "nginx"
}

variable "fargate_cpu" {
  description = "1 vCPU = 1024 CPU units"
  default     = "256"
}

variable "fargate_memory" {
  description = "MiB"
  default     = "512"
}

variable "log_group" {
  default = "gaia-log"
}