data "aws_iam_policy_document" "lambda_assume_role_policy"{
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_execution_policy"{
  statement {
    effect = "Allow"
    actions = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:us-east-1:851725613770:parameter/EBIRD_API_KEY"]
  }

  statement {
    effect = "Allow"
    actions = ["dynamodb:BatchWriteItem"]
    resources = [aws_dynamodb_table.recent_observation_table.arn]
  }

  statement {
    effect = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.recent_obs_keys_bucket.arn}/*"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {  
  name = "lambda_execution_role"  
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy" "lambda_execution_policy" {  
  name = "lambda_execution_policy"  
  description= "Permissions for parameters store and writing to dynamodb"
  policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}
