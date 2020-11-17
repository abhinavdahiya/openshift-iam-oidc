locals {
  issuer_url = "https://${aws_s3_bucket.discovery.bucket_domain_name}"

  discovery_json = jsonencode({
    "issuer" : local.issuer_url,
    "jwks_uri" : "${local.issuer_url}/keys.json",
    "authorization_endpoint" : "urn:kubernetes:programmatic_authorization",
    "response_types_supported" : [
      "id_token"
    ],
    "subject_types_supported" : [
      "public"
    ],
    "id_token_signing_alg_values_supported" : [
      "RS256"
    ],
    "claims_supported" : [
      "sub",
      "iss"
    ]
  })
}

resource "aws_s3_bucket" "discovery" {
  bucket = "${var.infra_id}-oidc-discovery"
  acl    = "public-read"

  tags = var.tags
}

resource "aws_s3_bucket_object" "discovery_json" {
  key     = ".well-known/openid-configuration"
  bucket  = aws_s3_bucket.discovery.id
  content = local.discovery_json

  acl = "public-read"
}

resource "aws_s3_bucket_object" "keys_json" {
  key    = "keys.json"
  bucket = aws_s3_bucket.discovery.id
  source = "${path.module}/keys.json"

  acl = "public-read"
}

resource "aws_iam_openid_connect_provider" "default" {
  url = local.issuer_url

  client_id_list = [
    "openshift",
  ]

  thumbprint_list = [
    "a9d53002e97e00e043244f3d170d6f4c414104fd" # root CA thumbprint for s3 (DigiCert)
  ]
}

resource "tls_private_key" "signing_key" {
  algorithm = "RSA"
}

resource "local_file" "signing_key_public_pem" {
  content  = tls_private_key.signing_key.public_key_pem
  filename = "${path.module}/signing_key_public.pem"
}

resource "null_resource" "pre-flight" {
  triggers = {
    fingerprint = tls_private_key.signing_key.public_key_fingerprint_md5
  }

  provisioner "local-exec" {
    command     = "go run generate.go -key ../../${path.module}/signing_key_public.pem > ../../${path.module}/keys.json"
    working_dir = "./scripts/json_web_key/"
  }

  depends_on = [local_file.signing_key_public_pem]
}
