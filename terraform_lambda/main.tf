provider "aws" {
  region = "sa-east-1"
}


# DynamoDB Table

resource "aws_dynamodb_table" "todo_table" {
  name         = "todo-list-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }
}

#
# IAM Role para Lambda
# 
resource "aws_iam_role" "lambda_api_role" {
  name = "lambda_api_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}


# Lambda Functions

resource "aws_lambda_function" "create_list_lambda" {
  function_name    = "create_list_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}

resource "aws_lambda_function" "get_lists_lambda" {
  function_name    = "get_lists_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "get_lists.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/get_lists.zip"
  source_code_hash = filebase64sha256("${path.module}/get_lists.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}

resource "aws_lambda_function" "update_list_lambda" {
  function_name    = "update_list_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "update_list.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/update_list.zip"
  source_code_hash = filebase64sha256("${path.module}/update_list.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}

resource "aws_lambda_function" "create_item_lambda" {
  function_name    = "create_item_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "create_item.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/create_item.zip"
  source_code_hash = filebase64sha256("${path.module}/create_item.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}

resource "aws_lambda_function" "get_item_lambda" {
  function_name    = "get_item_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "get_item.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/get_item.zip"
  source_code_hash = filebase64sha256("${path.module}/get_item.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}


resource "aws_lambda_function" "update_item_lambda" {
  function_name    = "update_item_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "update_item.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/update_item.zip"  # arquivo zip da lambda update_item
  source_code_hash = filebase64sha256("${path.module}/update_item.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}


# Módulo Cognito

module "cognito" {
  source = "./modules/cognito"
}


# Módulo API Gateway

module "api_gateway" {
  source = "./modules/api_gateway"

  uri_create_task         = aws_lambda_function.create_list_lambda.arn
  uri_list_tasks          = aws_lambda_function.get_lists_lambda.arn
  uri_update_task         = aws_lambda_function.update_list_lambda.arn
  uri_create_item         = aws_lambda_function.create_item_lambda.arn
  uri_list_items          = aws_lambda_function.get_item_lambda.arn
  uri_update_item         = aws_lambda_function.update_item_lambda.arn    # nova URI update item

  create_list_lambda_name = aws_lambda_function.create_list_lambda.function_name
  get_lists_lambda_name   = aws_lambda_function.get_lists_lambda.function_name
  update_list_lambda_name = aws_lambda_function.update_list_lambda.function_name
  create_item_lambda_name = aws_lambda_function.create_item_lambda.function_name
  list_items_lambda_name  = aws_lambda_function.get_item_lambda.function_name
  update_item_lambda_name = aws_lambda_function.update_item_lambda.function_name   # nova var

  cognito_user_pool_arn   = module.cognito.user_pool_arn
  redeployment_trigger    = timestamp()
  stage_name              = "prod"
  region                  = "sa-east-1"
}


# Outputs

output "cognito_user_pool_client_id" {
  description = "ID do Cliente do User Pool do Cognito para usar na autenticação."
  value       = module.cognito.cognito_user_pool_client_id
}

