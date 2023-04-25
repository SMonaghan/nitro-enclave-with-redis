terraform {
  required_providers {
		aws = {
		  source  = "hashicorp/aws"
			version = "~> 4.63.0"
		}
  }
}

locals {
	architecture		 = "x86_64"
	ami							 = lookup({"x86_64" = local.ami_ssm_x86, "arm" = local.ami_ssm_arm}, local.architecture)
	ami_ssm_x86 		 = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
	ami_ssm_arm 		 = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
	files_dir				 = "${path.module}/files"
	generated_dir		 = "${path.module}/generated_files"
	file_names			 = fileset(local.files_dir, "*")
	s3_prefix				 = "nitro-lookup"
  volume_mount		 = "/dev/sdd"
  nitro_lookup_dir = "/etc/nitro-lookup"
  server_port			 = 8080
  enclave_port		 = 5005
  enclave_domain	 = "lookup.${var.domain}"
  enclave_name		 = "secure-channel-example"
  enclave_file		 = "${local.enclave_name}.eif"
  instance_type		 = lookup({(local.ami_ssm_arm) = "m6g.2xlarge", (local.ami_ssm_x86) = "m6i.2xlarge"}, local.ami)
  
  enclave_instance_domain	= "enclave-instance.${var.domain}"
}

data "aws_region" "current" {}