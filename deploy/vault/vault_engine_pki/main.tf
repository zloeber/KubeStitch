## Configuring PKI resources on Vault
resource vault_pki_secret_backend pki {
  path                  = var.path
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
  path                  = "${var.pki_path}_int"
  max_lease_ttl_seconds = "157680000"
}

resource vault_pki_secret_backend_intermediate_cert_request pki_int {
  backend     = vault_pki_secret_backend.pki_int.path
  type        = "exported"
  common_name = "${var.pki_path} Root CA"
}

resource vault_pki_secret_backend_root_sign_intermediate pki {
  backend = vault_pki_secret_backend.pki.path
  csr         = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr
  common_name = "${var.pki_path} Signing"
  ttl         = "157680000"
  format      = "pem_bundle"
}

resource vault_pki_secret_backend_intermediate_set_signed pki_int {
  backend = vault_pki_secret_backend.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki.certificate
}

resource vault_pki_secret_backend_role pki_int {
  backend          = vault_pki_secret_backend.pki_int.path
  name             = "${var.pki_path}_int"
  ttl              = 86400
  allow_any_name   = "true"
  allow_subdomains = "true"
  generate_lease   = "true"
}

resource vault_pki_secret_backend_config_urls config_urls_root {
  backend                 = vault_pki_secret_backend.pki.path
  issuing_certificates    = ["http://${var.vault_addr}/v1/${var.pki_path}/ca"]
  crl_distribution_points = ["http://${var.vault_addr}/v1/${var.pki_path}/crl"]
}

resource vault_pki_secret_backend_config_urls config_urls_int {
  backend                 = vault_pki_secret_backend.pki_int.path
  issuing_certificates    = ["http://${var.vault_addr}/v1/${var.pki_path}_int/ca"]
  crl_distribution_points = ["http://${var.vault_addr}/v1/${var.pki_path}_int/crl"]
}

