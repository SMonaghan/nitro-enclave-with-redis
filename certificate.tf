resource "aws_acm_certificate" "enclave_cert" {
  domain_name       = local.enclave_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "enclave_cert_domain_validation" {
  for_each = {
    for dvo in aws_acm_certificate.enclave_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "enclave_cert_domain_validation" {
  certificate_arn         = aws_acm_certificate.enclave_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.enclave_cert_domain_validation : record.fqdn]
}

resource "aws_acm_certificate" "enclave_instance_cert" {
  domain_name       = local.enclave_instance_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "enclave_instance_cert_domain_validation" {
  for_each = {
    for dvo in aws_acm_certificate.enclave_instance_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "enclave_instance_cert_domain_validation" {
  certificate_arn         = aws_acm_certificate.enclave_instance_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.enclave_instance_cert_domain_validation : record.fqdn]
}