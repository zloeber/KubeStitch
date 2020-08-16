variable fqdn {
    default = "int.micro.svc"
}
variable name {
    default = "kubevault"
}
variable namespaces {
    type = list(string)
    default = []
}

output vaultagent {
    value = data.template_file.vaultagent.rendered
}