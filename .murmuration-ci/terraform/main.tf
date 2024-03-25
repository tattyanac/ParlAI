
resource "aws_s3_bucket" "parlai" {
  bucket = var.bucket_name

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
  bucket = aws_s3_bucket.parlai.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.parlai.arn}/*"
        ]
      }
    ]
  })
}

output "bucket_name" {
  value = aws_s3_bucket.parlai.id
}

output "bucket_endpoint" {
  value = aws_s3_bucket_website_configuration.parlai_website.website_endpoint
}


resource "aws_cloudfront_distribution" "distribution" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket_website_configuration.parlai_website.website_endpoint
    origin_id   = aws_s3_bucket_website_configuration.parlai_website.website_endpoint

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 10
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
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
    target_origin_id       = aws_s3_bucket_website_configuration.parlai_website.website_endpoint
  }
}

output "cdn_endpoint" {
  value = aws_cloudfront_distribution.distribution.domain_name
}