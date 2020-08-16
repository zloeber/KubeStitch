resource vault_auth_backend jwt {
  type = "jwt"

  tune {
    max_lease_ttl      = "90000s"
    listing_visibility = "unauth"
  }
}



resource vault_auth_backend userpass {
  type = "userpass"

  tune {
    max_lease_ttl      = "90000s"
    listing_visibility = "unauth"
  }
}

###
resource vault_auth_backend kubernetes {
  type = "kubernetes"

  tune {
    max_lease_ttl      = "90000s"
    listing_visibility = "unauth"
  }
}

## Configuring PKI resources on Vault
resource vault_pki_secret_backend pki {
  path                  = "pki"
  max_lease_ttl_seconds = "315360000"
}

resource vault_pki_secret_backend_root_cert pki {
  backend            = vault_pki_secret_backend.pki.path
  type               = "exported"
  format             = "pem_bundle"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 2048
  common_name        = var.fqdn
  ttl                = "315360000"
}

resource vault_pki_secret_backend pki_int {
  path                  = "pki_int"
  max_lease_ttl_seconds = "157680000"
}

resource vault_pki_secret_backend_intermediate_cert_request pki_int {
  backend     = vault_pki_secret_backend.pki_int.path
  type        = "exported"
  common_name = var.fqdn
}

resource vault_pki_secret_backend_root_sign_intermediate pki {
  backend = vault_pki_secret_backend.pki.path
  csr         = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr
  common_name = var.fqdn
  ttl         = "157680000"
  format      = "pem_bundle"
}

resource vault_pki_secret_backend_intermediate_set_signed pki_int {
  backend = vault_pki_secret_backend.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki.certificate
}

data vault_policy_document kubevault_certs {
  rule {
    path         = "pki_int/sign/kubevault"
    capabilities = ["read", "update", "list", "delete"]
    description  = "allow kubevault to sign certs"
  }
  rule {
    path         = "pki_int/issue/kubevault"
    capabilities = ["read", "update", "list", "delete"]
    description  = "allow kubevault to issue certs"
  }
}
resource vault_policy kubevault_certs {
  name   = "kubevault_certs"
  policy = data.vault_policy_document.kubevault_certs.hcl
}

resource vault_pki_secret_backend_role kubevault {
  backend          = vault_pki_secret_backend.pki_int.path
  name             = var.name
  ttl              = 86400
  allow_any_name   = "true"
  allow_subdomains = "true"
  generate_lease   = "true"
}

resource kubernetes_service_account certs {
  metadata {
    name = var.name
  }
}

resource vault_pki_secret_backend_config_urls config_urls_root {
  backend                 = vault_pki_secret_backend.pki.path
  issuing_certificates    = ["http://vault.${var.fqdn}/v1/pki/ca"]
  crl_distribution_points = ["http://vault.${var.fqdn}/v1/pki/crl"]
}

resource vault_pki_secret_backend_config_urls config_urls_int {
  backend                 = vault_pki_secret_backend.pki_int.path
  issuing_certificates    = ["http://vault.${var.fqdn}/v1/pki_int/ca"]
  crl_distribution_points = ["http://vault.${var.fqdn}/v1/pki_int/crl"]
}
resource vault_kubernetes_auth_backend_role cert_manager {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = var.name
  bound_service_account_names      = [ kubernetes_service_account.certs.metadata.0.name ]
  bound_service_account_namespaces = var.namespaces
  token_policies                   = [ vault_policy.kubevault_certs.name ]
  ttl                              = 86400
}

data template_file vaultagent {
  template = "${file("${path.module}/vaultagent.tpl")}"
  vars = {
    name = var.name
    role = var.name
    kvpath = "kv"
  }
}

resource kubernetes_config_map vaultagent {
  for_each = toset(var.namespaces)
  metadata {
    name = "${var.name}-vaultagent"
    namespace = each.value
  }
  data = {
    "vault-agent-config.hcl" = data.template_file.vaultagent.rendered
  }
}