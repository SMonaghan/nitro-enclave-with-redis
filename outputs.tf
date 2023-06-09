output "working_name_command" {
	value = "curl -XGET https://lookup.summit.journalctl.xyz/$(aws kms encrypt --plaintext $(echo -n 'Kim Diaz'|base64) --key-id ${aws_kms_alias.nitro.name} --query 'CiphertextBlob' --output text) -H 'Content-Type: text/plain'"
}

output "put_command" {
	value = "curl -XPUT 'https://lookup.summit.journalctl.xyz' -d $(aws kms encrypt --plaintext $(echo -n '{\"Kim Diazd\":\"value\"}'|base64) --key-id ${aws_kms_key.nitro.arn} --query 'CiphertextBlob' --output text) -H 'Content-Type: text/plain'"
}

output "not_working_name_command" {
	value = "curl -XGET https://lookup.summit.journalctl.xyz/$(aws kms encrypt --plaintext $(echo -n 'Kim Diazd'|base64) --key-id ${aws_kms_alias.nitro.name} --query 'CiphertextBlob' --output text) -H 'Content-Type: text/plain'"
}
