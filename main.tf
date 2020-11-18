terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.15.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "3.0.0"
    }
  }
}

provider "aws" {
  region = var.region

  ignore_tags {
    keys = ["openshift_creationDate"]
  }
}

module "oidc" {
  source   = "./oidc"
  infra_id = var.infra_id
  tags     = var.tags
}

module "iam_role_cred_minter_s3" {
  source      = "./iam_role"
  prefix      = "${var.infra_id}-cred-minter-s3"
  tags        = var.tags
  oidc_issuer = module.oidc.issuer

  service_accounts = [
    { namespace = "openshift-cloud-credential-operator", name = "cloud-credential-operator" }
  ]
  secret = { namespace = "openshift-cloud-credential-operator", name = "cloud-credential-operator-s3-creds", sts_token_path = "/var/run/secrets/openshift/serviceaccount/token" }
  policy = file("./iam_role/iam_role_policy/cred_minter_s3.json")
}

module "iam_role_image_registry" {
  source      = "./iam_role"
  prefix      = "${var.infra_id}-image-registry"
  tags        = var.tags
  oidc_issuer = module.oidc.issuer

  service_accounts = [
    { namespace = "openshift-image-registry", name = "cluster-image-registry-operator" },
    { namespace = "openshift-image-registry", name = "registry" }
  ]
  secret = { namespace = "openshift-image-registry", name = "installer-cloud-credentials", sts_token_path = "/var/run/secrets/openshift/serviceaccount/token" }
  policy = file("./iam_role/iam_role_policy/image_registry_operator.json")
}

module "iam_role_ingress" {
  source      = "./iam_role"
  prefix      = "${var.infra_id}-ingress"
  tags        = var.tags
  oidc_issuer = module.oidc.issuer

  service_accounts = [
    { namespace = "openshift-ingress-operator", name = "ingress-operator" }
  ]
  secret = { namespace = "openshift-ingress-operator", name = "cloud-credentials", sts_token_path = "/var/run/secrets/openshift/serviceaccount/token" }
  policy = file("./iam_role/iam_role_policy/ingress_operator.json")
}

module "iam_role_machine_api" {
  source      = "./iam_role"
  prefix      = "${var.infra_id}-machine-api"
  tags        = var.tags
  oidc_issuer = module.oidc.issuer

  service_accounts = [
    { namespace = "openshift-machine-api", name = "machine-api-controllers" }
  ]
  secret = { namespace = "openshift-machine-api", name = "aws-cloud-credentials", sts_token_path = "/var/run/secrets/openshift/serviceaccount/token" }
  policy = file("./iam_role/iam_role_policy/machine_api_operator.json")
}

module "iam_role_ebs_csi_driver" {
  source      = "./iam_role"
  prefix      = "${var.infra_id}-ebs-csi-driver"
  tags        = var.tags
  oidc_issuer = module.oidc.issuer

  service_accounts = [
    { namespace = "openshift-cluster-csi-drivers", name = "aws-ebs-csi-driver-operator" },
    { namespace = "openshift-cluster-csi-drivers", name = "aws-ebs-csi-driver-controller-sa" }
  ]
  secret = { namespace = "openshift-cluster-csi-drivers", name = "ebs-cloud-credentials", sts_token_path = "/var/run/secrets/openshift/serviceaccount/token" }
  policy = file("./iam_role/iam_role_policy/ebs_csi_driver_operator.json")
}


locals {
  secret_files = {
    "manifests/secret-credentials-cred-minter-s3.yaml" : module.iam_role_cred_minter_s3.secret,
    "manifests/secret-credentials-image-registry.yaml" : module.iam_role_image_registry.secret,
    "manifests/secret-credentials-ingress.yaml" : module.iam_role_ingress.secret,
    "manifests/secret-credentials-machine-api.yaml" : module.iam_role_machine_api.secret,
    "manifests/secret-credentials-ebs-csi-driver.yaml" : module.iam_role_ebs_csi_driver.secret,
  }

  tls_files = {
    "tls/bound-service-account-signing-key.key" : module.oidc.signing_key_pem
  }

  authentication_files = {
    "manifests/cluster-authentication-02-config.yaml" : yamlencode({
      "apiVersion" : "config.openshift.io/v1",
      "kind" : "Authentication",
      "metadata" : {
        "name" : "cluster"
      }
      "spec" : {
        "serviceAccountIssuer" : module.oidc.issuer.url
      }
    })
  }
}

resource "local_file" "credential_secrets" {
  for_each = merge(local.secret_files, local.tls_files, local.authentication_files)
  content  = each.value
  filename = "${path.module}/_output/${each.key}"
}
