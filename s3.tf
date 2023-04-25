resource "aws_s3_bucket" "bucket" {
	bucket_prefix = "enclave-poc-bucket-"
}

data "template_file" "nitro_lookup_file" {
	for_each = local.file_names

	template = file("${path.module}/files/${each.value}")
	vars = {
		s3_prefix				 = local.s3_prefix
		nitro_lookup_dir = local.nitro_lookup_dir
		enclave_port		 = 5005
		server_port			 = local.server_port
		account_id			 = data.aws_caller_identity.current.account_id
		enclave_name		 = local.enclave_name
		enclave_file		 = local.enclave_file
	}
}

resource "aws_s3_object" "enclave_files" {
	for_each = local.file_names

	bucket				 = aws_s3_bucket.bucket.id
	key				     = "${local.s3_prefix}/${each.value}"
	content_base64 = base64encode(data.template_file.nitro_lookup_file[each.value].rendered)
}

resource "aws_s3_object" "enclave_file" {
	bucket = aws_s3_bucket.bucket.id
	key		 = "${local.s3_prefix}/${local.enclave_file}"
	source = "${local.generated_dir}/${local.enclave_file}"
	
	depends_on = [
		null_resource.generate_enclave
	]
	
	lifecycle {
		replace_triggered_by = [
			null_resource.generate_enclave
		]
	}
}