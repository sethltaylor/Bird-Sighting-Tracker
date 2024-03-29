data "archive_file" "lambda_package" {
        type = "zip"
        source_dir = "${path.module}/../src/lambda/"
        output_path = "${path.module}/../src/lambda/recent_observations_lambda_deployment_package.zip"
        excludes = ["${path.module}/../src/lambda/recent_observations_lambda_deployment_package.zip"]
}

resource "aws_lambda_function" "recent_observations" {
        description = "Lambda function to handle recent bird observations"
        function_name = "recent_observations"
        s3_bucket = aws_s3_bucket.lambda_bucket.bucket
        s3_key = aws_s3_object.lambda_zip.key
        source_code_hash = data.archive_file.lambda_package.output_base64sha256
        role          = aws_iam_role.lambda_execution_role.arn
        runtime       = "python3.10"
        handler       = "recent_observations_lambda.lambda_handler"
        timeout       = 900
        depends_on = [ aws_s3_object.lambda_zip ]
}

resource "aws_cloudwatch_event_rule" "every_five_minute_daytime" {
        name = "every-five-minutes-daytime-rule"
        description = "Trigger every five minutes of every hour between 7am and 7pm local"
        schedule_expression = "cron(0/5 12-23 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
        rule = aws_cloudwatch_event_rule.every_five_minute_daytime.name
        target_id = "SendToLambda"
        arn = aws_lambda_function.recent_observations.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recent_observations.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minute_daytime.arn
}