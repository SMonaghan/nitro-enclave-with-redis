output "working_name_command" {
	value = "aws kms encrypt --plaintext $(echo -n 'Kim Diaz'|base64) --key-id ${aws_kms_key.nitro.arn}"
}

output "put_command" {
	value = "curl -X PUT 'https://lookup.summit.journalctl.xyz' -d $(aws kms encrypt --plaintext $(echo -n '{\"Kim Diazd\":\"value\"}'|base64) --key-id ${aws_kms_key.nitro.arn} --query 'CiphertextBlob' --output text) -H 'Content-Type: text/plain'"
}

output "not_working_name_command" {
	value = "aws kms encrypt --plaintext $(echo -n 'Kim Diazd'|base64) --key-id  ${aws_kms_key.nitro.arn}"
}

output "domain" {
	value = local.enclave_domain
}