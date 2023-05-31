variable "enclave_api_name" {
	type		= string
	default = "enclave-api"
}

variable "architecture" {
	type		= string
	default = "x86_64"
	
	validation {
		condition     = lower(var.architecture) == "x86_64" || lower(var.architecture) == "arm"
		error_message = "The architecture must either be x86_64 or arm"
	}
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