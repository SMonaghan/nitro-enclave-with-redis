data "aws_iam_policy_document" "instance_assume_role_policy" {
	statement {
		actions = ["sts:AssumeRole"]

		principals {
			type        = "Service"
			identifiers = ["ec2.amazonaws.com"]
		}
	}
}

data "local_file" "enclave_acm_config" {
  filename = "${path.module}/enclave-acm.json"
  
  depends_on = [null_resource.instance_role_enclave_cert_registration]
}

data "aws_iam_policy_document" "nitro_acm_policy" {
	statement {
		actions = ["s3:GetObject"]
		resources = [
			"arn:aws:s3:::${jsondecode(data.local_file.enclave_acm_config.content)["CertificateS3BucketName"]}/*"
		]
	}
	
	statement {
		actions = ["kms:Decrypt"]
		resources = [
			"arn:aws:kms:${data.aws_region.current.name}:*:key/${jsondecode(data.local_file.enclave_acm_config.content)["EncryptionKmsKeyId"]}"
		]
	}
	
	statement {
		actions = ["iam:GetRole"]
		resources = [
			aws_iam_role.enclave_instance_role.arn
		]
	}
	depends_on = [null_resource.instance_role_enclave_cert_registration]
}

data "aws_iam_policy_document" "nitro_lookup_service_policy" {
	statement {
		actions = ["s3:GetObject"]
		resources = [
			"arn:aws:s3:::${aws_s3_bucket.bucket.id}/nitro-lookup/*"
		]
	}
	
	statement {
		actions = ["ecr:*"]
		resources = [
			"*"
		]
	}
	
	statement {
		actions = [
			"s3:GetObject",
			"s3:ListBucket"
		]
		resources = [
			"arn:aws:s3:::${aws_s3_bucket.bucket.id}/nitro-lookup/*",
			"arn:aws:s3:::${aws_s3_bucket.bucket.id}"
		]
		condition {
			test     = "StringLike"
      variable = "s3:ResourceAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
		}
	}
}

resource "aws_iam_policy" "nitro_acm_policy" {
	name_prefix = "nitro_acm_policy-"
	policy			= data.aws_iam_policy_document.nitro_acm_policy.json
}

resource "aws_iam_policy" "nitro_lookup_service_policy" {
	name_prefix = "nitro_lookup_service_policy-"
	policy			= data.aws_iam_policy_document.nitro_lookup_service_policy.json
}

data "aws_iam_policy" "admin_policy" {
	name = "AdministratorAccess"
}

data "aws_iam_policy" "ssm_managed_instance_core" {
	name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "enclave_instance_role" {
	name_prefix         = "EnclavePOCRole-"
	assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_nito_acm_policy" {
  role       = aws_iam_role.enclave_instance_role.name
  policy_arn = aws_iam_policy.nitro_acm_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_nitro_lookup_service_policy" {
  role       = aws_iam_role.enclave_instance_role.name
  policy_arn = aws_iam_policy.nitro_lookup_service_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_ssm_managed_instance_core_policy" {
  role       = aws_iam_role.enclave_instance_role.name
  policy_arn = data.aws_iam_policy.ssm_managed_instance_core.arn
}

# resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
#   role       = aws_iam_role.enclave_instance_role.name
#   policy_arn = data.aws_iam_policy.admin_policy.arn
# }

resource "aws_iam_instance_profile" "enclave_instance_profile" {
	name_prefix = "EnclavePOCInstanceProfile-"
	role = aws_iam_role.enclave_instance_role.name
}