terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"  
}

resource "aws_dynamodb_table" "recent-observation-table" {
    name = "RecentObservations"
    billing_mode = "PROVISIONED"
    read_capacity = 25
    write_capacity = 25
    hash_key = "speciesCode"
    range_key = "obsDt"

    attribute {
        name = "speciesCode"
        type = "S"
    }

    attribute{
        name = "obsDt"
        type = "S"
    }
}