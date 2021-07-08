locals {
  algorithm           = var.algorithm == "RSA" ? var.algorithm : "ECDSA"
  self_signed         = var.exec_mode == "self_signed" ? 1 : 0
  acm_pca_signed      = local.self_signed == 0 ? 1 : 0
  allowed_uses_server = concat(var.allowed_uses_common, [
    "server_auth"] )
  allowed_uses_client = concat(var.allowed_uses_common, [
    "client_auth"])

  subject = merge(var.subject, {
    country             = ""
    locality            = ""
    organizational_unit = ""
    postal_code         = ""
    province            = ""
  })
}

# CA Cert - There is no ICA here :-)
resource "tls_private_key" "ca" {
  count     = local.self_signed
  algorithm = local.algorithm
}

resource "tls_self_signed_cert" "ca_self_signed" {
  count                 = local.self_signed
  key_algorithm         = local.algorithm
  private_key_pem       = join("", tls_private_key.ca.*.private_key_pem)
  validity_period_hours = var.validity_period_hours
  early_renewal_hours   = var.early_renewal_hours
  is_ca_certificate     = true

  subject {
    common_name         = local.subject.common_name
    country             = local.subject.country
    locality            = local.subject.locality
    organization        = local.subject.organization
    organizational_unit = local.subject.organizational_unit
    postal_code         = local.subject.postal_code
    province            = local.subject.province
  }

  allowed_uses = var.allowed_uses_ca
}

resource "aws_acm_certificate" "ca" {
  count            = local.self_signed
  private_key      = join("", tls_private_key.ca.*.private_key_pem)
  certificate_body = join("", tls_self_signed_cert.ca_self_signed.*.cert_pem)
}

# Server Cert
resource tls_private_key server {
  count     = local.self_signed
  algorithm = local.algorithm
}

resource tls_cert_request server_request {
  count           = local.self_signed
  key_algorithm   = local.algorithm
  private_key_pem = join("", tls_private_key.server.*.private_key_pem)
  subject {
    common_name         = "${local.subject.common_name}.server}"
    country             = local.subject.country
    locality            = local.subject.locality
    organization        = local.subject.organization
    organizational_unit = local.subject.organizational_unit
    postal_code         = local.subject.postal_code
    province            = local.subject.province
  }
}

resource tls_locally_signed_cert server_signed {
  count                 = local.self_signed
  allowed_uses          = local.allowed_uses_server
  ca_cert_pem           = join("", tls_self_signed_cert.ca_self_signed.*.cert_pem)
  ca_key_algorithm      = local.algorithm
  ca_private_key_pem    = join("", tls_private_key.ca.*.private_key_pem)
  cert_request_pem      = join("", tls_cert_request.server_request.*.cert_request_pem)
  validity_period_hours = var.validity_period_hours
  early_renewal_hours   = var.early_renewal_hours
}

resource "aws_acm_certificate" "server" {
  private_key       = join("", tls_private_key.server.*.private_key_pem)
  certificate_body  = join("", tls_locally_signed_cert.server_signed.*.cert_pem)
  certificate_chain = join("", tls_self_signed_cert.ca_self_signed.*.cert_pem)
}

# Client Cert
resource tls_private_key client {
  count     = local.self_signed
  algorithm = local.algorithm
}

resource tls_cert_request client_request {
  count           = local.self_signed
  key_algorithm   = local.algorithm
  private_key_pem = join("", tls_private_key.client.*.private_key_pem)
  subject {
    common_name         = "${local.subject.common_name}.client}"
    country             = local.subject.country
    locality            = local.subject.locality
    organization        = local.subject.organization
    organizational_unit = local.subject.organizational_unit
    postal_code         = local.subject.postal_code
    province            = local.subject.province
  }
}

resource tls_locally_signed_cert client_signed {
  count                 = local.self_signed
  allowed_uses          = local.allowed_uses_client
  ca_cert_pem           = join("", tls_self_signed_cert.ca_self_signed.*.cert_pem)
  ca_key_algorithm      = local.algorithm
  ca_private_key_pem    = join("", tls_private_key.ca.*.private_key_pem)
  cert_request_pem      = join("", tls_cert_request.client_request.*.cert_request_pem)
  validity_period_hours = var.validity_period_hours
  early_renewal_hours   = var.early_renewal_hours
}

resource "aws_acm_certificate" "client" {
  private_key       = join("", tls_private_key.client.*.private_key_pem)
  certificate_body  = join("", tls_locally_signed_cert.client_signed.*.cert_pem)
  certificate_chain = join("", tls_self_signed_cert.ca_self_signed.*.cert_pem)
}