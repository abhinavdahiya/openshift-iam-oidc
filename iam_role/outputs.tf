output arn {
  value = aws_iam_role.role.arn
}

output secret {
  value = local.config_secret
}
