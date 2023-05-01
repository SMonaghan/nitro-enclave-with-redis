variable "enclave_api_name" {
	type		= string
	default = "enclave-api"
}

variable "domain" {
	type = string
}

variable "region" {
	type = string
	default = "us-east-1"
}

variable "assume_role" {
    type = string
}