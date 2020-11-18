output oidc_issuer_url {
  value = module.oidc.issuer.url
}

output files {
  value = [for f in keys(merge(local.secret_files, local.tls_files, local.authentication_files)) : "${path.module}/_output/${f}"]
}

output arns {
  value = [
    module.oidc.issuer.arn,
    module.oidc.s3_bucket_arn,

    module.iam_role_cred_minter_s3.arn,
    module.iam_role_image_registry.arn,
    module.iam_role_ingress.arn,
    module.iam_role_machine_api.arn,
    module.iam_role_ebs_csi_driver.arn,
  ]
}
