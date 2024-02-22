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

variable "public_subnet_cidr" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.0.1.0/24"]
}

variable "azs" {
  type = list(string)
  description = "Availability Zones"
  default = [ "us-east-1a" ]
}