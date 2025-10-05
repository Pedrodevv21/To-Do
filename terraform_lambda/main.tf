terraform {
  backend "s3" {
    bucket  = "terraform-state-pedrodevv"
    key     = "terraform/estado.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "sa-east-1" # ajuste para sua região
}

# DynamoDB Table
resource "aws_dynamodb_table" "todo_table" {
  name         = "todo-list-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }
}


# S3 Bucket para armazenar o código da Lambda

resource "aws_s3_bucket" "todo_bucket" {
  bucket = "todo-list-bucket-${random_id.bucket_id.hex}"

  tags = {
    Name = "todo-bucket"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}


# IAM Role para Lambda

resource "aws_iam_role" "lambda_api_role" {
  name = "lambda_api_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


# Policy básica para a Lambda

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permissão para acessar DynamoDB
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}


# Lambda Function (Create List)

resource "aws_lambda_function" "create_list_lambda" {
  function_name = "create_list_lambda"
  role          = aws_iam_role.lambda_api_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}
# 1. API REST
resource "aws_api_gateway_rest_api" "todo_api" {
  name        = "todo-api"
  description = "API REST para Lambda todo"
}

# 2. Resource (caminho /create)
resource "aws_api_gateway_resource" "create_resource" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "create"
}

# 3. Método POST no /create
resource "aws_api_gateway_method" "post_create" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.create_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# 4. Integração da Lambda com o método POST /create
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.create_resource.id
  http_method             = aws_api_gateway_method.post_create.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_list_lambda.invoke_arn
}

# 5. Permissão para API Gateway invocar a Lambda
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_list_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}//"
}

# Deployment da API — considera todas as integrações (create, get_lists, update_list)
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,       # POST /create
    aws_api_gateway_integration.get_lists_integration,    # GET /lists
    aws_api_gateway_integration.update_list_integration   # PUT /list
  ]

  rest_api_id = aws_api_gateway_rest_api.todo_api.id
}
# Stage 'prod' — publica a deployment acima
resource "aws_api_gateway_stage" "prod_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}
resource "aws_lambda_function" "get_lists_lambda" {
  function_name = "get_lists_lambda"
  role          = aws_iam_role.lambda_api_role.arn
  handler       = "get_lists.lambda_handler"
  runtime       = "python3.9"

  filename         = "${path.module}/get_lists.zip"
  source_code_hash = filebase64sha256("${path.module}/get_lists.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}

resource "aws_api_gateway_resource" "lists_resource" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "lists"
}

resource "aws_api_gateway_method" "get_lists" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.lists_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_lists_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.lists_resource.id
  http_method             = aws_api_gateway_method.get_lists.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_lists_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_get_lists_permission" {
  statement_id  = "AllowAPIGatewayInvokeGetLists"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_lists_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}//"
}
resource "aws_lambda_function" "update_list_lambda" {
  function_name = "update_list_lambda"
  role          = aws_iam_role.lambda_api_role.arn
  handler       = "update_list.lambda_handler"
  runtime       = "python3.9"

  filename         = "${path.module}/update_list.zip"
  source_code_hash = filebase64sha256("${path.module}/update_list.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}
resource "aws_api_gateway_resource" "list_resource" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "list"
}
resource "aws_api_gateway_method" "put_list" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.list_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "update_list_integration" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.list_resource.id
  http_method             = aws_api_gateway_method.put_list.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.update_list_lambda.invoke_arn
}
resource "aws_lambda_permission" "apigw_update_list_permission" {
  statement_id  = "AllowAPIGatewayInvokeUpdateList"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_list_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}
module "api_gateway" {
  source = "./modules/api_gateway"

  uri_create_task        = aws_lambda_function.create_list_lambda.arn
  uri_list_tasks         = aws_lambda_function.get_lists_lambda.arn
  uri_update_task        = aws_lambda_function.update_list_lambda.arn

  create_list_lambda_name  = aws_lambda_function.create_list_lambda.function_name
  get_lists_lambda_name    = aws_lambda_function.get_lists_lambda.function_name
  update_list_lambda_name  = aws_lambda_function.update_list_lambda.function_name

  stage_name = "prod"
  region     = "sa-east-1"
}


