resource "null_resource" "generate_base_image" {
	triggers = {
		base_image_name = local.base_image_name
	}

	provisioner "local-exec" {
		when				= create
		interpreter = ["/bin/sh", "-c"]
		command = "docker build https://raw.githubusercontent.com/aws-samples/aws-nitro-enclaves-workshop/main/resources/code/getting-started/Dockerfile -t '${self.triggers.base_image_name}'"
	}
	
	provisioner "local-exec" {
		when				= destroy
		interpreter = ["/bin/sh", "-c"]
		command = "docker rmi ${self.triggers.base_image_name}"
	}
}

resource "null_resource" "generate_enclave" {
	triggers = {
		region				= data.aws_region.current.name
		account_id		= data.aws_caller_identity.current.account_id
		enclave_port	= local.enclave_port
		files_dir			= local.files_dir
		generated_dir = local.generated_dir
		assume_role		= var.assume_role
		enclave_file	= local.enclave_file
		enclave_name	= local.enclave_name
		kms_key_id		= aws_kms_key.nitro.id
		docker_file 	= file("${local.files_dir}/Dockerfile")
		server_py			= file("${local.files_dir}/server.py")
		run_sh				= file("${local.files_dir}/run.sh")
		redis_conf		= file("${local.files_dir}/redis.conf")
		
		base_image_name	= local.base_image_name
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
mkdir -p ${self.triggers.generated_dir}

docker build ${self.triggers.files_dir} -t ${self.triggers.enclave_name} --build-arg server_port=${self.triggers.enclave_port} --build-arg kms_key_id=${self.triggers.kms_key_id} --build-arg base_image_name=${self.triggers.base_image_name}  
nitro-cli build-enclave --docker-uri ${self.triggers.enclave_name}:latest --output-file ${self.triggers.generated_dir}/${self.triggers.enclave_file} > ${self.triggers.generated_dir}/nitro_hash.json
EOF
	}
	
	provisioner "local-exec" {
		when				= destroy
		interpreter = ["/bin/sh", "-c"]
		command = "rm -rf ${self.triggers.generated_dir}"
	}
	
	depends_on = [
		null_resource.generate_base_image
	]
}
