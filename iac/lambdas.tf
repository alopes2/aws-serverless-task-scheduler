resource "aws_iam_role" "schedule_handler" {
  name               = "schedule-handler-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "schedule_handler_policies" {
  role   = aws_iam_role.schedule_handler.name
  policy = data.aws_iam_policy_document.policies.json
}

resource "aws_lambda_function" "lambda" {
  filename      = data.archive_file.archive.output_path
  function_name = "schedule-handler"
  role          = aws_iam_role.schedule_handler.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"
}

data "archive_file" "archive" {
  type        = "zip"
  source_dir  = "lambda_init_code"
  output_path = "function_payload.zip"
}

data "aws_iam_policy_document" "assume_role" {

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

  }
}

data "aws_iam_policy_document" "policies" {
  statement {
    effect = "Allow"
    sid    = "LogToCloudwatch"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}
