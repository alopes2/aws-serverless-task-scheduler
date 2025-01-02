resource "aws_scheduler_schedule" "periodic" {
  name                = "periodic-schedule"
  description         = "A schedule that runs every minute"
  schedule_expression = "rate(1 minute)" // You coude also use cron(0/1 * * * ? *)
  target {
    arn      = aws_lambda_function.lambda.arn
    role_arn = aws_iam_role.periodic_schedule.arn
    input = jsonencode({
      "message" = "Periodic schedule trigger this lambda"
    })
  }
  flexible_time_window {
    mode = "OFF"
  }
}

resource "aws_iam_role" "periodic_schedule" {
  name               = "schedule_role"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}

resource "aws_iam_role_policy" "periodic_schedule_role_policy" {
  role   = aws_iam_role.periodic_schedule.name
  policy = data.aws_iam_policy_document.periodic_schedule_policies.json
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "periodic_schedule_policies" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    effect    = "Allow"
    resources = [aws_lambda_function.lambda.arn]
  }
}
