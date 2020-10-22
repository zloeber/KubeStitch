variable fqdn {
    default = "int.micro.svc"
}
variable vault_addr {
    default = "vault.${var.fqdn}"
}
variable pki_path {
    default = "pki"
}
