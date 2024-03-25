
resource "aws_s3_bucket" "parlai" {
  bucket = var.bucket_name

  tags = {
    Name = "Parl AI Website"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_access_block" {
  bucket = aws_s3_bucket.parlai.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "account" {}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.parlai.id
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = {
        "Sid" = "AllowCloudFrontServicePrincipalReadOnly",
        "Effect" = "Allow",
        "Principal" = {
            "Service" = "cloudfront.amazonaws.com"
        },
        "Action" = "s3:GetObject",
        "Resource" = "${aws_s3_bucket.parlai.arn}/*",
        "Condition" = {
            "StringEquals" = {
                "AWS:SourceArn" = "${aws_cloudfront_distribution.cdn.arn}"
            }
        }
    }
  })
}

output "bucket_name" {
  value = aws_s3_bucket.parlai.id
}

output "bucket_endpoint" {
  value = aws_s3_bucket.parlai.bucket_regional_domain_name
}


resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  custom_error_response {
    error_code = 403
    response_code = 403
    response_page_path = "/error.html"
  }

  custom_error_response {
    error_code = 404
    response_code = 404
    response_page_path = "/error.html"
  }


  origin {
    domain_name = aws_s3_bucket.parlai.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.parlai.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.parlai.bucket_regional_domain_name

    function_association {
    event_type = "viewer-request"
    function_arn = aws_cloudfront_function.redirect.arn
    }
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name = aws_s3_bucket.parlai.bucket_regional_domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

output "cdn_endpoint" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

resource "aws_cloudfront_function" "redirect" {
  name    = "redirect-for-s3"
  runtime = "cloudfront-js-2.0"
  comment = "Redirects to index.html in S3 subfolders"
  publish = true
  code    = file("./redirect.js")
}