resource "aws_dynamodb_table" "recent_observation_table" {
    name = "RecentObservations"
    billing_mode = "PROVISIONED"
    read_capacity = 5
    write_capacity = 15
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
      projection_type = "INCLUDE"
      non_key_attributes = ["howMany", "lat", "lng","locName"]
      read_capacity = 20
      write_capacity = 10
    }
}