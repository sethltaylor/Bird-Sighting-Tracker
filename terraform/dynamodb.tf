resource "aws_dynamodb_table" "recent_observation_table" {
    name = "RecentObservations"
    billing_mode = "PROVISIONED"
    read_capacity = var.recent_observation_table_read_capacity
    write_capacity = var.recent_observation_table_write_capacity
    hash_key = "comName"
    range_key = "subId"

    attribute{
        name = "subId"
        type = "S"
    }

    attribute {
      name = "comName"
      type = "S"
    }
    
    ttl {
        attribute_name = "ttl"
        enabled = true 
    }
}