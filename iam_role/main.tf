locals {
  config = templatefile("${path.module}/aws_config.tpl", {
    role_arn        = aws_iam_role.role.arn,
    token_file_path = var.secret.sts_token_path,
  })

  config_secret = yamlencode({
    "apiVersion" : "v1",
    "kind" : "Secret",
    "metadata" : {
      "namespace" : var.secret.namespace,
      "name" : var.secret.name
    }
    "data" : {
      "credentials" : base64encode(local.config)
    }
  })
}

resource "aws_iam_role" "role" {
  name = "${var.prefix}-role"
  path = "/"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [for sa in var.service_accounts : {
      "Effect" : "Allow",
      "Principal" : {
        "Federated" : var.oidc_issuer.arn
      },
      "Action" : "sts:AssumeRoleWithWebIdentity",
      "Condition" : {
        "StringEquals" : {
          "${var.oidc_issuer.name}:sub" : "system:serviceaccount:${sa.namespace}:${sa.name}"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "role_policy" {
  name = "${var.prefix}-role-policy"
  role = aws_iam_role.role.id

  policy = var.policy
}
