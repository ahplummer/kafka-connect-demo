# These are required as TF_VAR_<varname> in your .env, and visible as envvars.
variable "REGION" {}
variable "S3_BUCKET" {}
variable "KINESIS_STREAM" {}

provider "aws" {
  region = var.REGION
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.S3_BUCKET
  acl    = "private"
  force_destroy = true
}

data "aws_caller_identity" "current" {}
resource "aws_iam_policy" "iam_policy" {
  name        = "firehosetestpolicy"
  path        = "/"
  description = "Firehose Test Policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucketMultipartUploads",
                "s3:AbortMultipartUpload",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "s3:ListBucket",
                "kinesis:DescribeStream",
                "s3:GetBucketLocation",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:s3:::4e2a8fdce6ba-sqltos3",
                "arn:aws:s3:::4e2a8fdce6ba-sqltos3/*",
                "arn:aws:kinesis:us-east-1:${data.aws_caller_identity.current.account_id}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
                "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${var.KINESIS_STREAM}:log-stream:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "kinesis:ListShards",
            "Resource": "arn:aws:kinesis:us-east-1:${data.aws_caller_identity.current.account_id}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        }
    ]
}
EOF
}

resource "aws_iam_role" "firehose_role" {
  name = "firehosetestrole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_policy_attachment" "firehose-attach" {
  name       = "firehoseattach"
  roles      = [aws_iam_role.firehose_role.name]
  policy_arn = aws_iam_policy.iam_policy.arn
}
resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = var.KINESIS_STREAM
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
    buffer_size = 1
    buffer_interval = 60
    cloudwatch_logging_options {
      enabled = true
      log_group_name = var.KINESIS_STREAM
      log_stream_name = var.KINESIS_STREAM
    }
  }
}