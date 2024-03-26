
output "bucket_name" {
  value = aws_s3_bucket.parlai.id
}

output "bucket_endpoint" {
  value = aws_s3_bucket.parlai.bucket_regional_domain_name
}

output "cdn_endpoint" {
  value = aws_cloudfront_distribution.cdn.domain_name
}