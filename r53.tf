data "aws_route53_zone" "main" {
  name = var.domain
}

resource "aws_route53_zone" "private_zone" {
  name = var.domain

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "enclave_instance_record" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = local.enclave_instance_domain
  type    = "A"
  ttl     = "30"
  records = [aws_instance.enclave_instance.private_ip]
  
}

# resource "aws_route53_record" "enclave_record" {
#   name    = aws_api_gateway_domain_name.enclave_api_domain.domain_name
#   type    = "A"
#   zone_id = data.aws_route53_zone.main.zone_id

#   alias {
#     evaluate_target_health = true
#     name                   = aws_api_gateway_domain_name.enclave_api_domain.regional_domain_name
#     zone_id                = aws_api_gateway_domain_name.enclave_api_domain.regional_zone_id
#   }
# }
