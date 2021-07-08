output ca_cert {
  value = aws_acm_certificate.ca
  sensitive = true
}
