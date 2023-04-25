resource "aws_vpc_endpoint" "nitro_api_endpoint" {
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.allow_web.id]
  service_name        = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  subnet_ids          = var.subnet_ids
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  
	tags = {
    Name = "Nitro Api Endpoint"
  }
}

resource "aws_api_gateway_rest_api" "api" {
	name = var.enclave_api_name
	
	endpoint_configuration {
		types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.nitro_api_endpoint.id]
	}
}

resource "aws_api_gateway_method" "root_put_method" {
	authorization = "NONE"
	http_method   = "PUT"
	resource_id   = aws_api_gateway_rest_api.api.root_resource_id
	rest_api_id   = aws_api_gateway_rest_api.api.id
	request_parameters   = {
		"method.request.header.content-type" = false
	}
}

resource "aws_api_gateway_integration" "root_put_int" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	resource_id = aws_api_gateway_rest_api.api.root_resource_id
	http_method = aws_api_gateway_method.root_put_method.http_method

	request_parameters = {
		"integration.request.header.content-type" = "method.request.header.content-type"
	}

	type                    = "HTTP"
	uri                     = "https://${local.enclave_instance_domain}"
	integration_http_method = "PUT"
}

resource "aws_api_gateway_method_response" "root_put_method_response_200" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	resource_id = aws_api_gateway_rest_api.api.root_resource_id
	http_method = aws_api_gateway_method.root_put_method.http_method
	status_code = "200"
	
	response_models = {
		"text/plain" = "Empty"
	}
	
	response_parameters = {
    "method.response.header.content-type" = false
  }
	
	depends_on = [
		aws_api_gateway_integration.root_put_int,
		aws_api_gateway_method.root_put_method,
	]
}

resource "aws_api_gateway_integration_response" "root_put_int_response" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	resource_id = aws_api_gateway_rest_api.api.root_resource_id
	http_method = aws_api_gateway_method.root_put_method.http_method
	status_code = aws_api_gateway_method_response.root_put_method_response_200.status_code
	
	response_parameters = {
		"method.response.header.content-type" = "integration.response.header.content-type"
	}
	
	depends_on = [
		aws_api_gateway_integration.root_put_int,
		aws_api_gateway_integration_response.root_put_int_response,
	]
}

resource "aws_api_gateway_resource" "key_resource" {
	parent_id   = aws_api_gateway_rest_api.api.root_resource_id
	path_part   = "{key}"
	rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "key_get_method" {
	authorization = "NONE"
	http_method   = "GET"
	resource_id   = aws_api_gateway_resource.key_resource.id
	rest_api_id   = aws_api_gateway_rest_api.api.id
	
	request_parameters   = {
		"method.request.path.key" = true
	}
}

resource "aws_api_gateway_integration" "key_get_int" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	resource_id = aws_api_gateway_resource.key_resource.id
	http_method = aws_api_gateway_method.key_get_method.http_method

	request_parameters = {
		"integration.request.path.key" = "method.request.path.key"
	}

	type                    = "HTTP"
	uri                     = "https://${local.enclave_instance_domain}/{key}"
	integration_http_method = "GET"
}

resource "aws_api_gateway_method_response" "key_get_method_response_200" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	resource_id = aws_api_gateway_resource.key_resource.id
	http_method = aws_api_gateway_method.key_get_method.http_method
	status_code = "200"
	
	response_models = {
		"text/plain" = "Empty"
	}
	
  response_parameters = {
    "method.response.header.content-type" = false
  }
	
	depends_on = [
		aws_api_gateway_integration.key_get_int,
		aws_api_gateway_method.key_get_method,
	]
}

resource "aws_api_gateway_integration_response" "key_get_int_response" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	resource_id = aws_api_gateway_resource.key_resource.id
	http_method = aws_api_gateway_method.key_get_method.http_method
	status_code = aws_api_gateway_method_response.key_get_method_response_200.status_code
	
	response_parameters = {
		"method.response.header.content-type" = "integration.response.header.content-type"
	}
	
	depends_on = [
		aws_api_gateway_integration.key_get_int,
		aws_api_gateway_method.key_get_method,
	]
}

resource "aws_api_gateway_deployment" "deployment" {
	rest_api_id = aws_api_gateway_rest_api.api.id

	triggers = {
		# NOTE: The configuration below will satisfy ordering considerations,
		#       but not pick up all future REST API changes. More advanced patterns
		#       are possible, such as using the filesha1() function against the
		#       Terraform configuration file(s) or removing the .id references to
		#       calculate a hash against whole resources. Be aware that using whole
		#       resources will show a difference after the initial implementation.
		#       It will stabilize to only change when resources change afterwards.
		redeployment = sha1(jsonencode([
			aws_api_gateway_resource.key_resource.id,
			aws_api_gateway_method.key_get_method.id,
			aws_api_gateway_integration.key_get_int.uri,
			aws_api_gateway_method.root_put_method.id,
			aws_api_gateway_integration.root_put_int.uri,
		]))
	}

	lifecycle {
		create_before_destroy = true
	}
	
	depends_on = [
		aws_api_gateway_integration.key_get_int,
		aws_api_gateway_method.key_get_method,
		aws_api_gateway_integration.root_put_int,
		aws_api_gateway_method.root_put_method,
		aws_api_gateway_method_response.key_get_method_response_200,
		aws_api_gateway_method_response.root_put_method_response_200,
	]
}

resource "aws_api_gateway_stage" "stage" {
	deployment_id = aws_api_gateway_deployment.deployment.id
	rest_api_id   = aws_api_gateway_rest_api.api.id
	stage_name    = "deployment"
	
	depends_on = [
		aws_api_gateway_integration.key_get_int,
		aws_api_gateway_method.key_get_method,
		aws_api_gateway_integration.root_put_int,
		aws_api_gateway_method.root_put_method,
		aws_api_gateway_method_response.key_get_method_response_200,
		aws_api_gateway_method_response.root_put_method_response_200,
		aws_api_gateway_rest_api_policy.api_gw_resource_policy,
	]
}


data "aws_iam_policy_document" "api_gw_resource_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [
      	data.aws_caller_identity.current.account_id,
      	"arn:aws:iam::489546153674:role/Admin"
      ]
    }

    actions   = ["execute-api:Invoke"]
    resources = [aws_api_gateway_rest_api.api.execution_arn]
  }
}
resource "aws_api_gateway_rest_api_policy" "api_gw_resource_policy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  policy      = data.aws_iam_policy_document.api_gw_resource_policy.json
}

# resource "aws_api_gateway_domain_name" "enclave_api_domain" {
# 	domain_name     = local.enclave_domain
# 	regional_certificate_arn = aws_acm_certificate_validation.enclave_cert_domain_validation.certificate_arn
	
# 	endpoint_configuration {
# 		types = ["PRIVATE"]
# 	}
# }

# resource "aws_api_gateway_base_path_mapping" "enclave_path_mapping" {
# 	api_id      = aws_api_gateway_rest_api.api.id
# 	stage_name  = aws_api_gateway_stage.stage.stage_name
# 	domain_name = aws_api_gateway_domain_name.enclave_api_domain.domain_name
# }
