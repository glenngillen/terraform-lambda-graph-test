locals {
  environment_config = {
    "dev": {
      "some": "dev"
      "specific": "details"
    }
    "prod": {
      "some": "prod"
      "specific": "details"
    }
  }
  environments = toset([for env, config in local.environment_config: env if env == var.env])
}
resource "aws_lambda_layer_version" "layers" {
  for_each = local.environments
  filename            = "fakelayer.zip"
  layer_name          = "demo-layer-${each.value}"
  compatible_runtimes = ["ruby2.7"]
}
output "logs" {
  value = aws_lambda_layer_version.layers
}