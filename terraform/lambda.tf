resource "aws_lambda_function" "recent_observations" {
        function_name = "recent_observations"
        filename      = aws_s3_object.lambda_zip.id
        source_code_hash = filebase64("${path.module}/src/lambda/recent_observations_lambda_deployment_package.zip")
        role          = aws_iam_role.lambda_execution_role.arn
        runtime       = "python3.10"
        handler       = "recent_observations_lambda.lambda_handler"
        timeout       = 10
}