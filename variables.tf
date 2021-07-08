variable "exec_mode" {
  default = "self_signed"
}

variable "algorithm" {
  default = "RSA"
}

variable "validity_period_hours" {
  default = 867000
  # 10 days
}

variable "early_renewal_hours" {
  default = 86700
  # One day
}

variable "allowed_uses_ca" {
  default = [
    "cert_signing",
    "crl_signing"
  ]
}

variable allowed_uses_common {
  default = [
    "key_encipherment",
    "digital_signature"
  ]
}

variable "subject" {
  type = object({
    common_name         = string
    organization        = string
    country             = string
    locality            = string
    organizational_unit = string
    postal_code         = string
    province            = string
  })
  default = {
    common_name = "cn"
    organization = "acme"
    country             = ""
    locality            = ""
    organizational_unit = ""
    postal_code         = ""
    province            = ""
  }
}

