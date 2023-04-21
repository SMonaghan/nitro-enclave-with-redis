data "aws_iam_policy_document" "ecr_repository_policy" {
	statement {
		sid	= "ImportImages"
		actions = [
			"ecr:BatchImportUpstreamImage",
			"ecr:CreateRepository"
		]
		resources = [
			"arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/ecr-public/*"
		]
		principals {
			type        = "AWS"
			identifiers = [aws_iam_role.enclave_instance_role.arn]
		}
	}
}

resource "aws_ecr_registry_policy" "ecr_repository_policy" {
  policy = data.aws_iam_policy_document.ecr_repository_policy.json
}

resource "aws_ecr_pull_through_cache_rule" "ecr_redis_cache" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}