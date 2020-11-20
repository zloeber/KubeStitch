module vault_engine_pki {
  source = "./vault_engine_pki"
  fqdn = "int.micro.svc"
}

module vault_engine_kube {
  source = "./vault_engine_kube"
  fqdn = "int.micro.svc"
}

module kube_config_vault {
  source = "./kube_config_vault"
  namespaces = ["default", "vault"]
}

output vaultagent {
  value = module.cluster_config.vaultagent
}