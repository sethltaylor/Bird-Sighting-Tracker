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
        timeout       = 600
        depends_on = [ aws_s3_object.lambda_zip ]
}