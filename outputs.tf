output "working_name_command" {
	value = "aws kms encrypt --plaintext $(echo -n 'Kim Diaz'|base64) --key-id  ${aws_kms_key.nitro.arn}"
}

output "not_working_name_command" {
	value = "aws kms encrypt --plaintext $(echo -n 'Kim Diazd'|base64) --key-id  ${aws_kms_key.nitro.arn}"
}

output "domain" {
	value = local.enclave_domain
}