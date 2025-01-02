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
    retry_policy {
      maximum_event_age_in_seconds = 60
      maximum_retry_attempts       = 5
    }

    # dead_letter_config {
    #   arn = aws_sqs_queue.dead_letter_queue.arn
    # }
  }



  start_date = "2025-02-01T01:00:00Z"
  end_date   = "2030-01-01T01:00:00Z"

  flexible_time_window {
    mode = "OFF"
  }

  state = "DISABLED"
}

resource "aws_scheduler_schedule" "one_time" {
  name                         = "one-time-schedule"
  description                  = "A schedule that runs only once"
  schedule_expression          = "at(2025-02-01T01:00:00)"
  schedule_expression_timezone = "UTC"

  target {
    arn      = aws_lambda_function.lambda.arn
    role_arn = aws_iam_role.periodic_schedule.arn
    input = jsonencode({
      "message" = "One time schedule triggered"
    })
    retry_policy {
      maximum_event_age_in_seconds = 60
      maximum_retry_attempts       = 5
    }

    # dead_letter_config {
    #   arn = aws_sqs_queue.dead_letter_queue.arn
    # }
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

  # statement {
  #   actions = [
  #     "sqs:SendMessage"
  #   ]
  #   effect    = "Allow"
  #   resources = [aws_sqs_queue.dead_letter_queue.arn]
  # }
}
