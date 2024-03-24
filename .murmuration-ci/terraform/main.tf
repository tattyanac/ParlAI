

data "aws_ssm_parameter" "s3_static_website" {
  name = "s3_static_website"
}

resource "aws_s3_bucket" "parlai" {
  bucket = data.aws_ssm_parameter.s3_static_website.value

  tags = {
    Name = "Parl AI Website"
  }
}

resource "aws_s3_bucket_website_configuration" "parlai_website" {
  bucket = aws_s3_bucket.parlai.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_access_block" {
  bucket = aws_s3_bucket.parlai.id
  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket     = aws_s3_bucket.parlai.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicReadGetObject",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${aws_s3_bucket.parlai.arn}/*"
        }
      ]
    }
  )
}

output "bucket_name" {
  value = aws_s3_bucket.parlai.id
}

output "bucket_endpoint" {
  value = aws_s3_bucket.parlai.website_endpoint
}