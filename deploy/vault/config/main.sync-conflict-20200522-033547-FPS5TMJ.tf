provider vault {
  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
}

## Vault backends
# resource vault_auth_backend github {
#   type = "github"

#   tune {
#     max_lease_ttl      = "90000s"
#     listing_visibility = "unauth"
#   }
# }

resource vault_auth_backend jwt {
  type = "jwt"

  tune {
    max_lease_ttl      = "90000s"
    listing_visibility = "unauth"
  }
}

resource vault_auth_backend kubernetes {
  type = "kubernetes"

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
