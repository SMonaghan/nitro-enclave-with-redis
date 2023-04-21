terraform {
  required_providers {
		aws = {
		  source  = "hashicorp/aws"
			version = "~> 4.63.0"
		}
  }
}

locals {
	file_names			 = fileset("${path.module}/files/", "*")
	s3_prefix				 = "nitro-lookup"
  volume_mount		 = "/dev/sdd"
  nitro_lookup_dir = "/etc/nitro-lookup"
  server_port			 = 8080
  enclave_domain	 = "lookup.${var.domain}"
  
  enclave_instance_domain	= "enclave-instance.${var.domain}"
}

data "aws_region" "current" {}