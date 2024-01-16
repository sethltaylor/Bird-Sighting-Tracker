output "recent_observations_table_name" {
    description = "Name of the recent observations DynamoDB table"
    value = aws_dynamodb_table.recent_observation_table.name
}

output "recent_observation_table_arn" {
    description = "ARN of the recent observations DynamoDB table"
    value = aws_dynamodb_table.recent_observation_table.arn
}