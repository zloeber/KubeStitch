provider vault {
  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
}

provider kubernetes {
  
}

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

resource vault_kubernetes_auth_backend_role cert-manager {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "kubernetes-app"
  bound_service_account_names      = ["${kubernetes_service_account.cert-manager-sa.metadata.0.name}"]
  bound_service_account_namespaces = ["${var.fruits_namespace}"]
  policies                         = ["${vault_policy.kubeapp-certs.name}"]
  ttl                              = 86400
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
  common_name        = "testlab.local"
  ttl                = "315360000"
}

resource vault_pki_secret_backend pki_int {
  path                  = "pki_int"
  max_lease_ttl_seconds = "157680000"
}

resource vault_pki_secret_backend_intermediate_cert_request pki_int {
  backend     = vault_pki_secret_backend.pki_int.path
  type        = "exported"
  common_name = "testlab.local"
}

resource vault_pki_secret_backend_root_sign_intermediate pki {
  backend = vault_pki_secret_backend.pki.path
  csr         = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr
  common_name = "testlab.local"
  ttl         = "157680000"
  format      = "pem_bundle"
}

resource vault_pki_secret_backend_intermediate_set_signed pki_int {
  backend = vault_pki_secret_backend.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki.certificate
}

resource vault_pki_secret_backend_role kubeapp {
  backend        = vault_pki_secret_backend.pki_int.path
  name           = "kubeapp"
  ttl            = 86400
  allow_any_name = "true"
  allow_subdomains = "true"
  generate_lease = "true"
}

resource vault_pki_secret_backend_config_urls config_urls_root {
  backend                 = vault_pki_secret_backend.pki.path
  issuing_certificates    = ["http://${var.vault_addr}/v1/pki/ca"]
  crl_distribution_points = ["http://${var.vault_addr}/v1/pki/crl"]
}

resource vault_pki_secret_backend_config_urls config_urls_int {
  backend                 = vault_pki_secret_backend.pki_int.path
  issuing_certificates    = ["http://${var.vault_addr}/v1/pki_int/ca"]
  crl_distribution_points = ["http://${var.vault_addr}/v1/pki_int/crl"]
}

resource vault_policy kubeapp-certs {
  name = "kubeapp-certs"

  policy = <<EOT
path "pki_int/sign/kubeapp" {
  capabilities = ["read", "update", "list", "delete"]
}

path "pki_int/issue/kubeapp" {
  capabilities = ["read", "update", "list", "delete"]
}
EOT
}
