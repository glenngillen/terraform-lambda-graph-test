resource "aws_iam_role" "this" {
  name = "lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "xray" {
  name = "lambda-xray"
  path = "/service-role/xray-daemon/"
  description = "IAM policy to allow services to write data to X-Ray"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "xray:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "logs" {
  name = "lambda-cloudwatch"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "logs" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.logs.arn
}
resource "aws_iam_role_policy_attachment" "xray" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.xray.arn
}
resource "aws_lambda_function" "this" {
  filename      = "fakelambda.zip"
  function_name = "lambda-demo"
  role          = aws_iam_role.this.arn
  layers        = [for env, layer in aws_lambda_layer_version.layers: layer.arn]
  handler       = "index.handler"
  runtime       = "ruby2.7"
  tracing_config {
    mode = "Active"
  }
}