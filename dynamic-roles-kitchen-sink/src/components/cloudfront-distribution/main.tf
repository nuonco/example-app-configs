# CloudFront Distribution with Lambda Function URL as origin
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = "Dynamic roles kitchen sink - ${var.distribution_name}"
  default_root_object = ""
  price_class         = "PriceClass_100"

  origin {
    domain_name = local.lambda_origin_domain
    origin_id   = "lambda-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "lambda-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Accept", "Content-Type"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 3600
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "cloudfront_distribution"
  }
}

# Extract domain from Lambda function URL
locals {
  # Lambda function URL format: https://unique-id.lambda-url.region.on.aws/
  # We need to extract: unique-id.lambda-url.region.on.aws
  lambda_origin_domain = replace(var.lambda_function_url, "/^https?:\\/\\/([^\\/]+).*$/", "$1")
}
