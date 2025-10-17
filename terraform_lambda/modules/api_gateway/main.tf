data "aws_region" "current" {}

# ============================
#  API Gateway principal
# ============================
resource "aws_api_gateway_rest_api" "todo_api" {
  name        = "todo-api"
  description = "API Gateway para o projeto ToDo List"
}

# ============================
#  Recursos (paths)
# ============================
resource "aws_api_gateway_resource" "create" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "create"
}

resource "aws_api_gateway_resource" "lists" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "lists"
}

resource "aws_api_gateway_resource" "list" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "list"
}

resource "aws_api_gateway_resource" "list_sk" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_resource.list.id
  path_part   = "{sk}"
}

resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "items"
}

# === Novo recurso para update item: /items/{pk}/{sk}
resource "aws_api_gateway_resource" "items_pk" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_resource.items.id
  path_part   = "{pk}"
}

resource "aws_api_gateway_resource" "items_pk_sk" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_resource.items_pk.id
  path_part   = "{sk}"
}

# ============================
#  Cognito Authorizer
# ============================
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  provider_arns = [var.cognito_user_pool_arn]
}

# ============================
#  Métodos
# ============================
resource "aws_api_gateway_method" "post_create" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.create.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_method" "get_lists" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.lists.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_method" "put_list" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.list_sk.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
  request_parameters = {
    "method.request.path.sk" = true
  }
}

resource "aws_api_gateway_method" "post_items" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_method" "get_items" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# === Novo método PUT para update item ===
resource "aws_api_gateway_method" "put_items" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.items_pk_sk.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
  request_parameters = {
    "method.request.path.pk" = true
    "method.request.path.sk" = true
  }
}

# ============================
#  Integrações com Lambdas
# ============================
resource "aws_api_gateway_integration" "post_create" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.create.id
  http_method             = aws_api_gateway_method.post_create.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_create_task}/invocations"
}

resource "aws_api_gateway_integration" "get_lists" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.lists.id
  http_method             = aws_api_gateway_method.get_lists.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_list_tasks}/invocations"
}

resource "aws_api_gateway_integration" "put_list" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.list_sk.id
  http_method             = aws_api_gateway_method.put_list.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_update_task}/invocations"
}

resource "aws_api_gateway_integration" "post_items" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.post_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_create_item}/invocations"
}

resource "aws_api_gateway_integration" "get_items" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.get_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_list_items}/invocations"
}

# === Nova integração PUT para update item ===
resource "aws_api_gateway_integration" "put_items" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.items_pk_sk.id
  http_method             = aws_api_gateway_method.put_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_update_item}/invocations"
}

# ============================
#  Permissões para Lambda
# ============================
resource "aws_lambda_permission" "post_create" {
  statement_id  = "AllowPostCreate"
  action        = "lambda:InvokeFunction"
  function_name = var.create_list_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_lists" {
  statement_id  = "AllowGetLists"
  action        = "lambda:InvokeFunction"
  function_name = var.get_lists_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "put_list" {
  statement_id  = "AllowPutList"
  action        = "lambda:InvokeFunction"
  function_name = var.update_list_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "post_items" {
  statement_id  = "AllowPostItems"
  action        = "lambda:InvokeFunction"
  function_name = var.create_item_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_items" {
  statement_id  = "AllowGetItems"
  action        = "lambda:InvokeFunction"
  function_name = var.list_items_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

# === Nova permissão para update item ===
resource "aws_lambda_permission" "put_items" {
  statement_id  = "AllowPutItems"
  action        = "lambda:InvokeFunction"
  function_name = var.update_item_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

# ============================
#  Deployment e Stage
# ============================
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id

  depends_on = [
    aws_api_gateway_integration.post_create,
    aws_api_gateway_integration.get_lists,
    aws_api_gateway_integration.put_list,
    aws_api_gateway_integration.post_items,
    aws_api_gateway_integration.get_items,
    aws_api_gateway_integration.put_items
  ]

  triggers = {
    redeployment = sha1(join("", [
      aws_api_gateway_integration.post_create.id,
      aws_api_gateway_integration.get_lists.id,
      aws_api_gateway_integration.put_list.id,
      aws_api_gateway_integration.post_items.id,
      aws_api_gateway_integration.get_items.id,
      aws_api_gateway_integration.put_items.id,
      var.redeployment_trigger
    ]))
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}








