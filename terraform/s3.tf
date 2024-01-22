resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "recent-observations-lambda"
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket_ownership" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket_acl" {
    depends_on = [ aws_s3_bucket_ownership_controls.lambda_bucket_ownership ]
    bucket = aws_s3_bucket.lambda_bucket.bucket
    acl = "private"
}


resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "recent_observations_lambda_deployment_package.zip"
  source = "${path.module}/src/lambda/recent_observations_lambda_deployment_package.zip"
}
