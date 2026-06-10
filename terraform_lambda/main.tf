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

# IAM Role para Lambda
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

# Políticas de execução básica e acesso a DynamoDB e SQS
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_access" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}


#  Fila SQS
resource "aws_sqs_queue" "request_queue" {
  name = "user-request-queue"
}


# 🔹 Lambda post_request (SQS)
resource "aws_lambda_function" "post_request_lambda" {
  function_name    = "post_request_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "post_request.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/post_request.zip"
  source_code_hash = filebase64sha256("${path.module}/post_request.zip")

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.request_queue.id
    }
  }
}


#  Lambda get_request (SQS)

resource "aws_lambda_function" "get_request_lambda" {
  function_name    = "get_request_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "get_request.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/get_request.zip"
  source_code_hash = filebase64sha256("${path.module}/get_request.zip")

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.request_queue.id
    }
  }
}


# Outras Lambdas existentes
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
  filename         = "${path.module}/update_item.zip"
  source_code_hash = filebase64sha256("${path.module}/update_item.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}

resource "aws_lambda_function" "delete_item_lambda" {
  function_name    = "delete_item_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "delete_item.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/delete_item.zip"
  source_code_hash = filebase64sha256("${path.module}/delete_item.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}

resource "aws_lambda_function" "get_list_by_id_lambda" {
  function_name    = "get_list_by_id_lambda"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "get_list_by_id.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/get_list_by_id.zip"
  source_code_hash = filebase64sha256("${path.module}/get_list_by_id.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todo_table.name
    }
  }
}


# Cognito Module
module "cognito" {
  source = "./modules/cognito"
}

# =====================================
# API Gateway Module
# =====================================
module "api_gateway" {
  source = "./modules/api_gateway"

  uri_create_task            = aws_lambda_function.create_list_lambda.arn
  uri_list_tasks             = aws_lambda_function.get_lists_lambda.arn
  uri_update_task            = aws_lambda_function.update_list_lambda.arn
  uri_create_item            = aws_lambda_function.create_item_lambda.arn
  uri_list_items             = aws_lambda_function.get_item_lambda.arn
  uri_update_item            = aws_lambda_function.update_item_lambda.arn
  uri_get_list_by_id         = aws_lambda_function.get_list_by_id_lambda.arn
  uri_delete_item            = aws_lambda_function.delete_item_lambda.arn
  uri_post_request           = aws_lambda_function.post_request_lambda.arn
  uri_get_request            = aws_lambda_function.get_request_lambda.arn # nova lambda SQS

  create_list_lambda_name    = aws_lambda_function.create_list_lambda.function_name
  get_lists_lambda_name      = aws_lambda_function.get_lists_lambda.function_name
  update_list_lambda_name    = aws_lambda_function.update_list_lambda.function_name
  create_item_lambda_name    = aws_lambda_function.create_item_lambda.function_name
  list_items_lambda_name     = aws_lambda_function.get_item_lambda.function_name
  update_item_lambda_name    = aws_lambda_function.update_item_lambda.function_name
  get_list_by_id_lambda_name = aws_lambda_function.get_list_by_id_lambda.function_name
  delete_item_lambda_name    = aws_lambda_function.delete_item_lambda.function_name
  post_request_lambda_name   = aws_lambda_function.post_request_lambda.function_name
  get_request_lambda_name    = aws_lambda_function.get_request_lambda.function_name # nova Lambda

  cognito_user_pool_arn = module.cognito.user_pool_arn
  redeployment_trigger  = timestamp()
  stage_name            = "prod"
  region                = "sa-east-1"
}


# Bucket S3 para CSVs
resource "aws_s3_bucket" "csv_bucket" {
  bucket        = "todo-csv-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "csv_bucket_encryption" {
  bucket = aws_s3_bucket.csv_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "csv_bucket_public_block" {
  bucket                  = aws_s3_bucket.csv_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "csv_bucket_policy" {
  bucket = aws_s3_bucket.csv_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowLambdaAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_api_role.arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.csv_bucket.arn,
          "${aws_s3_bucket.csv_bucket.arn}/*"
        ]
      }
    ]
  })
}

output "csv_bucket_name" {
  value       = aws_s3_bucket.csv_bucket.bucket
  description = "Nome do bucket S3 usado para armazenar os arquivos CSV"
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.request_queue.id
  description = "URL da fila SQS usada pelas Lambdas post_request e get_request"
}


