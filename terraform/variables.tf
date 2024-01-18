variable "recent_observation_table_read_capacity" {
  description = "Read capacity for recent observations DynamoDB table."
  type        = number
  default     = 25
}

variable "recent_observation_table_write_capacity" {
  description = "Write capacity for recent observations DynamoDB table."
  type        = number
  default     = 25
}