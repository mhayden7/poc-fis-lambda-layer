# ------------------------------------------------------------------
# Bucket for FIS configs
# ------------------------------------------------------------------
resource "aws_s3_bucket" "fis_config" {
  bucket = "${var.config.account}-fis-config-${var.config.region}"
}

# ------------------------------------------------------------------
# Lambda Execution Role
# ------------------------------------------------------------------
data "aws_iam_policy_document" "fis_config_bucket_access" {
  statement {
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.fis_config.arn]
  }
  statement {
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.fis_config.arn}/*"]
  }
}

resource "aws_iam_policy" "fis_config_bucket_access" {
  name = "fis_config_bucket_access"
  policy = data.aws_iam_policy_document.fis_config_bucket_access.json
}

data "aws_iam_policy_document" "lambda_sts_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${var.config.region}:${var.config.account}:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name = "fis_lambda_logging"
  policy = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "fis_lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_sts_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_fis_config_access" {
  role = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.fis_config_bucket_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logging_access" {
  role = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# ------------------------------------------------------------------
# Get the FIS lambda layer ARN
# ------------------------------------------------------------------
data "aws_ssm_parameter" "fis_x86_64" {
  name = "/aws/service/fis/lambda-extension/AWS-FIS-extension-x86_64/1.x.x"
}

# ------------------------------------------------------------------
# Lambdas
# ------------------------------------------------------------------
resource "aws_lambda_function" "fis_python" {
  filename = "../python.zip"
  function_name = "fis_python"
  runtime = "python3.13"
  handler = "fis_python.lambda_handler"
  role = aws_iam_role.lambda_execution_role.arn
  source_code_hash = filebase64sha256("../python.zip")
  layers = [data.aws_ssm_parameter.fis_x86_64.value]
  environment {
    variables = {
      "AWS_FIS_CONFIGURATION_LOCATION": "${aws_s3_bucket.fis_config.arn}/fisconfigs/",
      "AWS_LAMBDA_EXEC_WRAPPER": "/opt/aws-fis/bootstrap"
    }
  }
}

resource "aws_lambda_function" "fis_nodejs" {
  filename = "../nodejs.zip"
  function_name = "fis_nodejs"
  runtime = "nodejs22.x"
  handler = "index.handler"
  role = aws_iam_role.lambda_execution_role.arn
  source_code_hash = filebase64sha256("../nodejs.zip")
  layers = [data.aws_ssm_parameter.fis_x86_64.value]
  environment {
    variables = {
      "AWS_FIS_CONFIGURATION_LOCATION": "${aws_s3_bucket.fis_config.arn}/fisconfigs/",
      "AWS_LAMBDA_EXEC_WRAPPER": "/opt/aws-fis/bootstrap"
    }
  }
}

resource "aws_lambda_function" "fis_dotnet" {
  filename = "../dotnet.zip"
  function_name = "fis_dotnet"
  runtime = "dotnet8"
  handler = "dotnet::dotnet.Function::FunctionHandler"
  role = aws_iam_role.lambda_execution_role.arn
  source_code_hash = filebase64sha256("../dotnet.zip")
  environment {
    variables = {
      "AWS_FIS_CONFIGURATION_LOCATION": "${aws_s3_bucket.fis_config.arn}/fisconfigs/",
      "AWS_LAMBDA_EXEC_WRAPPER": "/opt/aws-fis/bootstrap"
    }
  }
  layers = [data.aws_ssm_parameter.fis_x86_64.value]
}

# resource "aws_lambda_function" "fis_java" {
#   filename = "../fis_java-1.0.jar"
#   function_name = "fis_java"
#   runtime = "java21"
#   handler = "com.example.myproject.FISHandler::handleRequest"
#   role = aws_iam_role.lambda_execution_role.arn
#   source_code_hash = filebase64sha256("../fis_java-1.0.jar")
#   # layers = [data.aws_ssm_parameter.fis_x86_64.value]
#   # environment {
#   #   variables = {
#   #     "AWS_FIS_CONFIGURATION_LOCATION": "${aws_s3_bucket.fis_config.arn}/fisconfigs/",
#   #     "AWS_LAMBDA_EXEC_WRAPPER": "/opt/aws-fis/bootstrap"
#   #   }
#   # }
# }

# ------------------------------------------------------------------
# FIS Execution Role
# ------------------------------------------------------------------
data "aws_iam_policy_document" "fis_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["fis.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "fis_execution_role" {
  name = "fis_execution_role"
  assume_role_policy = data.aws_iam_policy_document.fis_assume_role.json
}

data "aws_iam_policy_document" "fis_execution_policy" {
  statement {
    effect = "Allow"
    actions = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.fis_config.arn}/*"]
  }
  statement {
    effect = "Allow"
    actions = ["lambda:GetFunction"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = ["tag:GetResources"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "fis_execution_policy" {
  name = "fis_execution_policy"
  policy = data.aws_iam_policy_document.fis_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "fis_execution_policy" {
  role = aws_iam_role.fis_execution_role.name
  policy_arn = aws_iam_policy.fis_execution_policy.arn
}

# # ------------------------------------------------------------------
# # FIS Experiment Template
# # ------------------------------------------------------------------
# resource "aws_fis_experiment_template" "lambda_layers_test" {
#   description = "lambda_layers_test"
#   role_arn = aws_iam_role.fis_execution_role.arn

#  stop_condition {
#   source = "none"
#  } 

#  action {
#   name = "break-lambdas"
#   action_id = "aws:lambda:invocation-error"
#   target {
#     key = "Functions"
#     value = "Function-Targets"
#   }
#   parameter {
#     key = "duration"
#     value = "PT3M"
#   }
#  }

#  target {
#   name = "Function-Targets"
#   resource_type = "aws:lambda:function" WILL HAVE TO DO DEPLOY VIA JSON ON AWS CLI :/ TF DOESN'T SUPPORT IT YET https://github.com/hashicorp/terraform-provider-aws/pull/42571
#   selection_mode = "ALL"
#   resource_tag {
#     key = "project"
#     value = var.config.project
#   }
#  }
# }