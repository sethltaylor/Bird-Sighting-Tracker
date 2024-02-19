resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "recent-observations-lambda"
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket_ownership" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket_acl" {
    depends_on = [ aws_s3_bucket_ownership_controls.lambda_bucket_ownership ]
    bucket = aws_s3_bucket.lambda_bucket.bucket
    acl = "private"
}

resource "aws_s3_bucket_versioning" "lambda_versioning" {
  bucket = aws_s3_bucket.lambda_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "recent_observations_lambda_deployment_package.zip"
  source = data.archive_file.lambda_package.output_path
  etag = filemd5(data.archive_file.lambda_package.output_path)
  depends_on = [data.archive_file.lambda_package]
}

resource "aws_s3_bucket" "recent_obs_keys_bucket" {
  bucket = "recent-observations-keys"
}

resource "aws_s3_bucket_ownership_controls" "keys_bucket_ownership" {
  bucket = aws_s3_bucket.recent_obs_keys_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "keys_bucket_acl" {
    depends_on = [ aws_s3_bucket_ownership_controls.keys_bucket_ownership ]
    bucket = aws_s3_bucket.recent_obs_keys_bucket.bucket
    acl = "private"
}

resource "aws_s3_bucket_versioning" "keys_versioning" {
  bucket = aws_s3_bucket.recent_obs_keys_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}