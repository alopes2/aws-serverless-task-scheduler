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

resource "aws_iam_role" "create_schedule" {
  name               = "create-schedule-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "create_schedule_policies" {
  role   = aws_iam_role.create_schedule.name
  policy = data.aws_iam_policy_document.create_schedule_policies.json
}

resource "aws_lambda_function" "create_schedule" {
  filename      = data.archive_file.archive.output_path
  function_name = "create-schedule"
  role          = aws_iam_role.create_schedule.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  environment {
    variables = {
      TARGET_ARN = aws_lambda_function.lambda.arn
      ROLE_ARN   = aws_iam_role.periodic_schedule.arn # Ideally we'd like to have a dedicated role for this
      # DEAD_LETTER_ARN = aws_sqs_queue.dead_letter_queue.arn
    }
  }
}

data "aws_iam_policy_document" "create_schedule_policies" {
  source_policy_documents = [data.aws_iam_policy_document.policies.json]
  statement {
    effect = "Allow"
    actions = [
      "scheduler:CreateSchedule",
    ]

    resources = ["*"]
  }
}
