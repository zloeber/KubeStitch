provider kubernetes {}

terraform {
  required_version = ">= 0.12"
}

provider "vault" {
  #version     = "=2.12.3"
  max_retries = 5
}