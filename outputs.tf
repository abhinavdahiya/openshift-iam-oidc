output oidc_issuer_url {
  value = module.oidc.issuer.url
}

output files {
  value = [for f in keys(merge(local.secret_files, local.tls_files, local.authentication_files)) : "${path.module}/_output/${f}"]
}
