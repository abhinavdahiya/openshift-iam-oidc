output issuer {
  value = {
    name = aws_s3_bucket.discovery.bucket_domain_name,
    url  = local.issuer_url,
    arn  = aws_iam_openid_connect_provider.default.arn
  }
}

output signing_key_pem {
  value = tls_private_key.signing_key.private_key_pem
}
