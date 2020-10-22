resource vault_auth_backend kubernetes {
  type = "kubernetes"

  tune {
    max_lease_ttl      = "90000s"
    listing_visibility = "unauth"
  }
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
    name = "vaultagent"
    namespace = each.value
  }
  data = {
    "vault-agent-config.hcl" = data.template_file.vaultagent.rendered
  }
}