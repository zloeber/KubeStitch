
module cluster_config {
  source = "./config"
  fqdn = "int.micro.svc"
  namespaces = ["default", "vault"]
}

output vaultagent {
  value = module.cluster_config.vaultagent
}