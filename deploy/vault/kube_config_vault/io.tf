variable fqdn {
    default = "int.micro.svc"
}
variable vault_addr {
    default = "vault.${var.fqdn}"
}
variable pki_path {
    default = "pki"
}
variable service_account_name {
    default = "kubevault"
}
variable namespaces {
    type = list(string)
    default = ["default"]
}

output vault_agent {
    value = data.template_file.vaultagent.rendered
}