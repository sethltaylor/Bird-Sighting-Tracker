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

resource "aws_dynamodb_table" "recent_observation_table" {
    name = "RecentObservations"
    billing_mode = "PROVISIONED"
    read_capacity = var.recent_observation_table_read_capacity
    write_capacity = var.recent_observation_table_write_capacity
    hash_key = "subId"
    range_key = "speciesCode"

 

    attribute{
        name = "subId"
        type = "S"
    }

    attribute {
        name = "speciesCode"
        type = "S"
    }

    ttl {
        attribute_name = "ttl"
        enabled = true 
    }

    lifecycle {
    ignore_changes = [read_capacity, write_capacity] #This policy is defined because future terraform apply would otherwise overwrite AWS autoscaling
  }
}

resource "aws_appautoscaling_target" "recent_observation_table_read_target" {
  max_capacity       = var.recent_observation_table_read_capacity
  min_capacity       = 1
  resource_id        = "table/${aws_dynamodb_table.recent_observation_table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "recent_observation_table_read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.recent_observation_table_read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.recent_observation_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.recent_observation_table_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.recent_observation_table_read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 70.0
  }
}

resource "aws_appautoscaling_target" "recent_observation_table_write_target" {
  max_capacity       = var.recent_observation_table_write_capacity
  min_capacity       = 1
  resource_id        = "table/${aws_dynamodb_table.recent_observation_table.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "recent_observation_table_policy" {
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.recent_observation_table_write_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.recent_observation_table_write_target.resource_id
  scalable_dimension = aws_appautoscaling_target.recent_observation_table_write_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.recent_observation_table_write_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = 70.0
  }
}