variable "scheduling_active" {
  description = "Activate or deactivate scheduling."
  type        = string
  default     = "Yes"
}

variable "scheduled_services" {
  description = "Scheduled Services."
  type        = string
  default     = "EC2"
}

variable "schedule_rds_clusters" {
  description = "Enable scheduling of Aurora clusters for RDS Service."
  type        = string
  default     = "No"
}

variable "create_rds_snapshot" {
  description = "Create snapshot before stopping RDS instances (does not apply to Aurora Clusters)."
  type        = string
  default     = "No"
}

variable "memory_size" {
  description = "Size of the Lambda function running the scheduler, increase size when processing large numbers of instances."
  type        = string
  default     = 128
}

variable "use_cloud_watch_metrics" {
  description = "Collect instance scheduling data using CloudWatch metrics."
  type        = string
  default     = "No"
}

variable "log_retention_days" {
  description = "Retention days for scheduler logs."
  type        = string
  default     = 30
}

variable "trace" {
  description = "Enable debug-level logging in CloudWatch logs."
  type        = string
  default     = "No"
}

variable "tag_name" {
  description = "Name of tag to use for associating instance schedule schemas with service instances."
  type        = string
  default     = "Schedule"
}

variable "default_timezone" {
  description = "Choose the default Time Zone. Default is 'UTC'."
  type        = string
  default     = "UTC"
}

variable "regions" {
  description = "List of regions in which instances should be scheduled, leave blank for current region only."
  type        = list(string)
}

variable "namespace" {
  description = "Provide unique identifier to differentiate between multiple solution deployments (No Spaces). Example: Dev"
  type        = string
}

variable "started_tags" {
  description = "Comma separated list of tag keys and values of the format key=value, key=value,... that are set on started instances. Leave blank to disable."
  type        = string
  default     = "InstanceScheduler-LastAction=Started By {scheduler} {year}/{month}/{day} {hour}:{minute}{timezone}, "
}

variable "stopped_tags" {
  description = "Comma separated list of tag keys and values of the format key=value, key=value,... that are set on stopped instances. Leave blank to disable."
  type        = string
  default     = "InstanceScheduler-LastAction=Stopped By {scheduler} {year}/{month}/{day} {hour}:{minute}{timezone}, "
}

variable "scheduler_frequency" {
  description = "Scheduler running frequency in minutes."
  type        = string
  default     = "5"
}

variable "schedule_lambda_account" {
  description = "Schedule instances in this account."
  type        = string
  default     = "Yes"
}