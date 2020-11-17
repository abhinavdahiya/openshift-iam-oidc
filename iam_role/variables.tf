variable tags {
  type    = map(string)
  default = {}
}

variable prefix {
  type = string
}

variable oidc_issuer {
  type = object({
    name = string
    arn  = string
  })
}

variable service_accounts {
  type = list(object({
    namespace = string
    name      = string
  }))
}

variable policy {
  type = string
}

variable secret {
  type = object({
    namespace      = string
    name           = string
    sts_token_path = string
  })
}
