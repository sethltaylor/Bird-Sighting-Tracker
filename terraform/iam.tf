#Lambda
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
    actions = ["s3:*"]
    resources = ["arn:aws:s3:::*"]
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

#ECS Task Execution
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role_policy.json}"
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#ECS Task Role - Should give the container permissions to S3 and DynamoDB

resource "aws_iam_role" "BirdTrackerTaskRole" {
  name               = "BirdTrackerTaskRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role_policy.json}"
}

data "aws_iam_policy_document" "bird_tracker_task_role_policy"{
  statement {
    effect = "Allow"
    actions = ["dynamodb:*"]
    resources = [ aws_dynamodb_table.recent_observation_table.arn,
      "${aws_dynamodb_table.recent_observation_table.arn}/index/comName-obsDt-index"]
  }


  statement {
    effect = "Allow"
    actions = ["s3:*"]
    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_role_policy_attachment" "bird_tracker_task_role_attachment" {
  role = aws_iam_role.BirdTrackerTaskRole.name
  policy_arn = aws_iam_policy.bird_tracker_task_policy.arn
}

resource "aws_iam_policy" "bird_tracker_task_policy" {  
  name = "bird_tracker_task_policy"  
  description= "Permissions for S3 and DynamoDb"
  policy = data.aws_iam_policy_document.bird_tracker_task_role_policy.json
}

#ECS EC2 Role

resource "aws_iam_instance_profile" "ecs" {
  name = "ecs-ec2-cluster"
  role = aws_iam_role.ecs.name
}

resource "aws_iam_role" "ecs" {
  name               = "ecs-ec2-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_attach" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}