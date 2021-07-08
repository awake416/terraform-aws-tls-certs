output ca_cert_arn {
  value = join("", aws_acm_certificate.ca.*.arn)
}

output server_cert_arn {
  value = aws_acm_certificate.server.arn
}

output client_cert_arn {
  value = aws_acm_certificate.client.arn
}