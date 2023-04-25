# Once Terraform accepts ssm parameters as the image_id for launch templates, this can be removed
# data "aws_ssm_parameter" "ami_id" {
# 	name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
# 	# name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
# }

resource "aws_security_group" "allow_web" {
	name_prefix = "allow_web_enclave_"
	description = "Allow web requests to enclave api"
	vpc_id      = var.vpc_id

	ingress {
		description      = "TLS from anywhere"
		from_port        = 443
		to_port          = 443
		protocol         = "tcp"
		cidr_blocks      = ["0.0.0.0/0"]
	}
	
	ingress {
		description      = "${local.server_port} from anywhere"
		from_port        = 80
		to_port          = 80
		protocol         = "tcp"
		cidr_blocks      = ["0.0.0.0/0"]
	}

	# egress {
	# 	from_port        = 0
	# 	to_port          = 0
	# 	protocol         = "-1"
	# 	security_groups = aws_security_group.instance_allow_web.id
	# }

	tags = {
		Name = "allow_web_enclave"
	}
}

resource "aws_security_group_rule" "allow_connection_to_enclave_instance" {
	type      = "egress"
	from_port = 443
	to_port   = 443
	protocol  = "-1"
	security_group_id = aws_security_group.allow_web.id
	
	source_security_group_id = aws_security_group.instance_allow_web.id
}

resource "aws_security_group" "instance_allow_web" {
	name_prefix = "instance_allow_web_enclave_"
	description = "Allow web requests to enclave server"
	vpc_id      = var.vpc_id

	ingress {
		description     = "HTTPS from Web Security Group"
		from_port       = 443
		to_port         = 443
		protocol        = "tcp"
		security_groups = [aws_security_group.allow_web.id]
	}
	
	ingress {
		description     = "HTTP Connection Web Security Group"
		from_port       = 80
		to_port         = 80
		protocol        = "tcp"
		security_groups = [aws_security_group.allow_web.id]
	}
	
	ingress {
		from_port   = 443
		to_port     = 443
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port       = 443
		to_port         = 443
		protocol        = "tcp"
		prefix_list_ids = [data.aws_vpc_endpoint.s3.prefix_list_id]
	}
	
	# egress {
	# 	from_port   = 443
	# 	to_port     = 443
	# 	protocol    = "tcp"
	# 	cidr_blocks = ["0.0.0.0/0"]
	# }

	tags = {
		Name = "instance_allow_web_enclave"
	}
}

resource "aws_launch_template" "enclave_lt" {
	name_prefix = "enclave_ec2"

	block_device_mappings {
		device_name = "/dev/xvda"

		ebs {
			volume_size = 10
			encrypted		= true
			kms_key_id	= aws_kms_key.ebs.arn
			
			delete_on_termination = true
		}
	}
	
	block_device_mappings {
		device_name = local.volume_mount

		ebs {
			volume_size = 20
			encrypted 	= true
			kms_key_id	= aws_kms_key.ebs.arn
			
			delete_on_termination = true
		}
	}
	
	ebs_optimized = true

	iam_instance_profile {
		name = aws_iam_instance_profile.enclave_instance_profile.name
	}

	# This should eventually be replaced with an ssm parameter
	image_id = "resolve:ssm:${local.ami}" #data.aws_ssm_parameter.ami_id.value

	instance_initiated_shutdown_behavior = "terminate"

	# instance_type = "m6i.xlarge"
	instance_type = local.instance_type

	network_interfaces {
		associate_public_ip_address = true
		security_groups   = [
			aws_security_group.instance_allow_web.id,
			aws_security_group.allow_web.id,
			aws_security_group.endpoint_sg.id
		]
	}

	tag_specifications {
		resource_type = "instance"

		tags = {
			Name = "enclave-instance"
		}
	}
	
	enclave_options {
		enabled = true
	}
	
	user_data = base64encode(data.template_file.user_data.rendered)

}

data "template_file" "user_data" {
	template = "${file("${path.module}/run.sh.tpl")}"
	vars = {
		s3_bucket        = aws_s3_bucket.bucket.id
		s3_prefix        = local.s3_prefix
		volume_mount     = local.volume_mount
		nitro_lookup_dir = local.nitro_lookup_dir
		local_port			 = local.server_port
		certificate_arn	 = aws_acm_certificate_validation.enclave_instance_cert_domain_validation.certificate_arn
		
		enclave_instance_domain = local.enclave_instance_domain
	}
}

resource "aws_instance" "enclave_instance" {
	launch_template {
		id      = aws_launch_template.enclave_lt.id
		version = "$Latest"
	}
	
	subnet_id = var.subnet_ids[1]
	
	tags = {
		Name = "Enclave Test"
	}
	
	user_data = data.template_file.user_data.rendered
	
	user_data_replace_on_change = true
	
	depends_on = [
		aws_s3_object.enclave_file,
		aws_vpc_endpoint.ssm,
		aws_vpc_endpoint.ssmmessages,
		aws_vpc_endpoint.ec2messages,
		aws_security_group_rule.allow_connection_to_enclave_instance
	]
	
	lifecycle {
		create_before_destroy = true
		
		replace_triggered_by = [
			null_resource.generate_enclave,
			aws_s3_object.enclave_file,
			aws_launch_template.enclave_lt
		]
	}
}

resource "null_resource" "instance_role_enclave_cert_registration" {
	triggers = {
		region					= data.aws_region.current.name
		certificate_arn	= aws_acm_certificate_validation.enclave_instance_cert_domain_validation.certificate_arn
		instance_role 	= aws_iam_role.enclave_instance_role.arn
		assume_role			= var.assume_role
		# test						= uuid()
	}

	provisioner "local-exec" {
		when				= create
		interpreter = ["/bin/sh", "-c"]
		environment = {
			AWS_DEFAULT_REGION = self.triggers.region
		}
		command = <<EOF
set -e
$(aws sts assume-role --role-arn ${self.triggers.assume_role} --role-session-name terraform_run_associate_enclave_cert --query 'Credentials.[`export#AWS_ACCESS_KEY_ID=`,AccessKeyId,`#AWS_SECRET_ACCESS_KEY=`,SecretAccessKey,`#AWS_SESSION_TOKEN=`,SessionToken]' --output text | sed $'s/\t//g' | sed 's/#/ /g')

aws ec2 associate-enclave-certificate-iam-role \
	--region ${self.triggers.region} \
	--certificate-arn ${self.triggers.certificate_arn} \
	--role-arn ${self.triggers.instance_role} > ${path.module}/enclave-acm.json

EOF
	}
	
	provisioner "local-exec" {
		when				= destroy
		interpreter = ["/bin/sh", "-c"]
		environment = {
			AWS_DEFAULT_REGION = self.triggers.region
		}
		command = <<EOF
set -e
$(aws sts assume-role --role-arn ${self.triggers.assume_role} --role-session-name terraform_run_associate_enclave_cert --query 'Credentials.[`export#AWS_ACCESS_KEY_ID=`,AccessKeyId,`#AWS_SECRET_ACCESS_KEY=`,SecretAccessKey,`#AWS_SESSION_TOKEN=`,SessionToken]' --output text | sed $'s/\t//g' | sed 's/#/ /g')

aws ec2 disassociate-enclave-certificate-iam-role \
	--region ${self.triggers.region} \
	--certificate-arn ${self.triggers.certificate_arn} \
	--role-arn ${self.triggers.instance_role}

EOF
	}
}
