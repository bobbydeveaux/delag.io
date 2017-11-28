# Request the Variables. Can be passed via ENV VARS.
variable "aws_region" {
    default = "eu-west-1"
}

variable "bucket_site" {
    default = "delag.io"
}

# Specify the provider and access details
provider "aws" {
    region     = "${var.aws_region}"
    version    = "1.3.0"
}

resource "aws_s3_bucket" "b" {
    bucket = "${var.bucket_site}"
    acl = "public-read"
    policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.bucket_site}/*",
      "Principal": "*"
    }
  ]
}
EOF

    website {
        index_document = "index.html"
        error_document = "index.html"
    }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.b.website_endpoint}"
    origin_id   = "myS3Origin"
    custom_origin_config {
      http_port = "80"
      https_port = "443"
      origin_protocol_policy =  "http-only"
      origin_ssl_protocols = ["TLSv1","TLSv1.1","TLSv1.2"]
    }
  }

  enabled             = true

  comment             = "New Bucket"
  default_root_object = "index.html"

  custom_error_response {
    error_code = "404"
    response_code = "200"
    response_page_path = "/index.html"
  }  

   custom_error_response {
    error_code = "403"
    response_code = "200"
    response_page_path = "/sorry.html"
  }  


  aliases = ["delag.io", "www.delag.io", "www.delagio.co.uk", "delagio.co.uk"] 

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "myS3Origin"
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["GB", "US"]
    }
  }
  
  tags {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:696293867939:certificate/0b5d6765-2709-4059-bfe5-6ae673b3a2a2"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}


data "aws_route53_zone" "primary" {
  name = "delag.io."
}

resource "aws_route53_record" "io_record" {
  zone_id = "Z1H2469EYHGG5M"
  name = "delag.io"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_io_record" {
  zone_id = "Z1H2469EYHGG5M"
  name = "www.delag.io"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "couk_record" {
  zone_id = "Z1DM2QQWY851MM"
  name = "delagio.co.uk"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_couk_record" {
  zone_id = "Z1DM2QQWY851MM"
  name = "www.delagio.co.uk"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}


