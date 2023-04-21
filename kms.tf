data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ebs" {
	description = "KMS Key For EC2 Instance"
	key_usage   = "ENCRYPT_DECRYPT"
	is_enabled	= true

	enable_key_rotation			 = true
	customer_master_key_spec = "SYMMETRIC_DEFAULT"
	deletion_window_in_days  = 7
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/nitro-enclave-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

resource "aws_kms_key_policy" "example" {
  key_id = aws_kms_key.ebs.id
  policy = data.aws_iam_policy_document.kms_ebs_policy.json
}

data "aws_iam_policy_document" "kms_ebs_policy" {
	statement {
		sid = "Enable IAM User Permissions"
		
		principals {
			type = "AWS"
			identifiers = [
				data.aws_caller_identity.current.account_id
			]
		}

		actions = [
			"kms:*"
		]

		resources = [
			"*"
		]
	}
	
	statement {
		sid = "Allow access for Key Administrators"
		
		principals {
			type = "AWS"
			identifiers = [
				var.assume_role
			]
		}

		actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
		]

		resources = [
			"*"
		]
	}
	
	statement {
		sid = "Allow use of the key"
		
		principals {
			type = "AWS"
			identifiers = [
				aws_iam_role.enclave_instance_role.arn
			]
		}

		actions = [
			"kms:Encrypt",
			"kms:Decrypt",
			"kms:ReEncrypt*",
			"kms:GenerateDataKey*",
			"kms:DescribeKey"
		]

		resources = [
			"*"
		]
	}
	
	statement {
		sid = "Allow attachment of persistent resources"
		
		principals {
			type = "AWS"
			identifiers = [
				aws_iam_role.enclave_instance_role.arn
			]
		}

		actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
		]

		resources = [
			"*"
		]
		
		condition {
			test = "Bool"
			variable = "kms:GrantIsForAWSResource"
			
			values = [
				true
			]
		}
	}
}
