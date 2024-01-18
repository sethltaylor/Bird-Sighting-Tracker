resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-bird-tracker"
}

resource "aws_s3_bucket_ownership_controls" "terraform_state_ownership" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "terraform_state_acl" {
    depends_on = [ aws_s3_bucket_ownership_controls.terraform_state_ownership ]
    bucket = aws_s3_bucket.terraform_state.bucket
    acl = "private"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform_locks_bird_tracker"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-bird-tracker"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform_locks_bird_tracker"
  }
}