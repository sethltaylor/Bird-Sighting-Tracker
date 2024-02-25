resource "aws_dynamodb_table" "recent_observation_table" {
    name = "RecentObservations"
    billing_mode = "PROVISIONED"
    read_capacity = 5
    write_capacity = 24
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

    attribute {
      name = "comName"
      type = "S"
    }

    attribute {
      name = "obsDt"
      type = "S"
    }
    
    ttl {
        attribute_name = "ttl"
        enabled = true 
    }

    global_secondary_index {
      name = "comName-obsDt-index"
      hash_key = "comName"
      range_key = "obsDt"
      projection_type = "ALL"
      read_capacity = 20
      write_capacity = 1
    }

    ##Removed for now because we aren't using autoscaling during testing. 
   # lifecycle {
    #ignore_changes = [read_capacity, write_capacity] #This policy is defined because future terraform apply would otherwise overwrite AWS autoscaling
  #}
}

### Removing autoscalling policies for now because reading/write testing is infrequent so policy always sets capacity to 1. 

# resource "aws_appautoscaling_target" "recent_observation_table_read_target" {
#   max_capacity       = var.recent_observation_table_read_capacity
#   min_capacity       = 1
#   resource_id        = "table/${aws_dynamodb_table.recent_observation_table.name}"
#   scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#   service_namespace  = "dynamodb"
# }

# resource "aws_appautoscaling_policy" "recent_observation_table_read_policy" {
#   name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.recent_observation_table_read_target.resource_id}"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.recent_observation_table_read_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.recent_observation_table_read_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.recent_observation_table_read_target.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }

#     target_value = 70.0
#   }
# }

# resource "aws_appautoscaling_target" "recent_observation_table_write_target" {
#   max_capacity       = var.recent_observation_table_write_capacity
#   min_capacity       = 1
#   resource_id        = "table/${aws_dynamodb_table.recent_observation_table.name}"
#   scalable_dimension = "dynamodb:table:WriteCapacityUnits"
#   service_namespace  = "dynamodb"
# }

# resource "aws_appautoscaling_policy" "recent_observation_table_policy" {
#   name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.recent_observation_table_write_target.resource_id}"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.recent_observation_table_write_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.recent_observation_table_write_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.recent_observation_table_write_target.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }

#     target_value = 70.0
#   }
# }