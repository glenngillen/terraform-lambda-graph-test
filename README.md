# Terraform lambda plan/graph test

This isn't a real deployable app, for a start the zip files are empty, so don't use this expecting to get
a working infrastructure deployment. It's purely here to highlight a potential workflow with Terraform.

## Why?

An example approach of how to toggle what is managed based on variables, as an example is differing configuration based
on whether we're targeting a `dev` or `prod` deployment.

## How?

Take a look at `lambda_layer.tf`. There's a `local` varaible definition that specifies potential target environments. This is
working from an assumption that some environment-specific additional configuration might be useful later, and the provided value
(set via the `env` variable) could be used as a lookup to access this map. This extra detail isn't strictly necessary for this demo
though, the only thing we use is the `local.environments` value. The implementation here is to return a set of values that match whatever
is set in `var.env`. This demo will ultimately return a single set of either `["dev"]` or `["prod"]`. There is not requirement that this
be a set of 1, the rest of the logic would apply no matter how large the set is.

Next the `aws_lambda_layer_version` runs over the set using a `for_each`, and would deploy the relevant layer for each environment. In this
example it only adjusts the name of the layer, it could conceivably reference a different file source though. Specific on what should be different for each layer is left as an exercise for the reader.

Finally there is the `aws_lambda_function` definition within `lambda.tf`. The `layers` attribute on this resource will now include _all_ configured layers within it's definition. No more assumptions about deterministic ordering of definitions. No more graph showing two potential values.

## Usage

```bash
$ terraform plan -out=tfplan -var env=prod
$ terraform graph -plan=tfplan

digraph {
	compound = "true"
	newrank = "true"
	subgraph "root" {
		"[root] aws_iam_policy.logs" [label = "aws_iam_policy.logs", shape = "box"]
		"[root] aws_iam_policy.logs (expand)" [label = "aws_iam_policy.logs", shape = "box"]
		"[root] aws_iam_policy.xray" [label = "aws_iam_policy.xray", shape = "box"]
		"[root] aws_iam_policy.xray (expand)" [label = "aws_iam_policy.xray", shape = "box"]
		"[root] aws_iam_role.this" [label = "aws_iam_role.this", shape = "box"]
		"[root] aws_iam_role.this (expand)" [label = "aws_iam_role.this", shape = "box"]
		"[root] aws_iam_role_policy_attachment.logs" [label = "aws_iam_role_policy_attachment.logs", shape = "box"]
		"[root] aws_iam_role_policy_attachment.logs (expand)" [label = "aws_iam_role_policy_attachment.logs", shape = "box"]
		"[root] aws_iam_role_policy_attachment.xray" [label = "aws_iam_role_policy_attachment.xray", shape = "box"]
		"[root] aws_iam_role_policy_attachment.xray (expand)" [label = "aws_iam_role_policy_attachment.xray", shape = "box"]
		"[root] aws_lambda_function.this" [label = "aws_lambda_function.this", shape = "box"]
		"[root] aws_lambda_function.this (expand)" [label = "aws_lambda_function.this", shape = "box"]
		"[root] aws_lambda_layer_version.layers (expand)" [label = "aws_lambda_layer_version.layers", shape = "box"]
		"[root] aws_lambda_layer_version.layers[\"prod\"]" [label = "aws_lambda_layer_version.layers", shape = "box"]
		"[root] output.logs" [label = "output.logs", shape = "note"]
		"[root] provider[\"registry.terraform.io/hashicorp/aws\"]" [label = "provider[\"registry.terraform.io/hashicorp/aws\"]", shape = "diamond"]
		"[root] var.env" [label = "var.env", shape = "note"]
		"[root] aws_iam_policy.logs (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
		"[root] aws_iam_policy.logs" -> "[root] aws_iam_policy.logs (expand)"
		"[root] aws_iam_policy.xray (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
		"[root] aws_iam_policy.xray" -> "[root] aws_iam_policy.xray (expand)"
		"[root] aws_iam_role.this (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
		"[root] aws_iam_role.this" -> "[root] aws_iam_role.this (expand)"
		"[root] aws_iam_role_policy_attachment.logs (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
		"[root] aws_iam_role_policy_attachment.logs" -> "[root] aws_iam_policy.logs"
		"[root] aws_iam_role_policy_attachment.logs" -> "[root] aws_iam_role.this"
		"[root] aws_iam_role_policy_attachment.logs" -> "[root] aws_iam_role_policy_attachment.logs (expand)"
		"[root] aws_iam_role_policy_attachment.xray (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
		"[root] aws_iam_role_policy_attachment.xray" -> "[root] aws_iam_policy.xray"
		"[root] aws_iam_role_policy_attachment.xray" -> "[root] aws_iam_role.this"
		"[root] aws_iam_role_policy_attachment.xray" -> "[root] aws_iam_role_policy_attachment.xray (expand)"
		"[root] aws_lambda_function.this (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
		"[root] aws_lambda_function.this" -> "[root] aws_iam_role.this"
		"[root] aws_lambda_function.this" -> "[root] aws_lambda_function.this (expand)"
		"[root] aws_lambda_function.this" -> "[root] aws_lambda_layer_version.layers[\"prod\"]"
		"[root] aws_lambda_layer_version.layers (expand)" -> "[root] local.environments (expand)"
		"[root] aws_lambda_layer_version.layers (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
		"[root] aws_lambda_layer_version.layers[\"prod\"]" -> "[root] aws_lambda_layer_version.layers (expand)"
		"[root] local.environments (expand)" -> "[root] local.environment_config (expand)"
		"[root] local.environments (expand)" -> "[root] var.env"
		"[root] output.logs" -> "[root] aws_lambda_layer_version.layers[\"prod\"]"
		"[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_iam_role_policy_attachment.logs"
		"[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_iam_role_policy_attachment.xray"
		"[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_lambda_function.this"
		"[root] root" -> "[root] output.logs"
		"[root] root" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)"
	}
}
```