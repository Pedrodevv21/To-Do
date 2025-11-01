data "aws_region" "current" {}

# =====================================
# API Gateway principal
# =====================================
resource "aws_api_gateway_rest_api" "todo_api" {
  name        = "todo-api"
  description = "API Gateway para o projeto ToDo List"
}

# =====================================
# Recursos (paths)
# =====================================
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

# NOVO RECURSO: /requests
resource "aws_api_gateway_resource" "requests" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "requests"
}


# =====================================
# Cognito Authorizer
# =====================================
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  provider_arns = [var.cognito_user_pool_arn]
}

# =====================================
# Métodos existentes
# =====================================
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

resource "aws_api_gateway_method" "get_list_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.list_sk.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

  request_parameters = {
    "method.request.path.sk" = true
  }
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

resource "aws_api_gateway_method" "delete_items" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.items_pk_sk.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

  request_parameters = {
    "method.request.path.pk" = true
    "method.request.path.sk" = true
  }
}

# POST /requests
resource "aws_api_gateway_method" "post_requests" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.requests.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# GET /requests
resource "aws_api_gateway_method" "get_requests" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.requests.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# =====================================
# Integrações com Lambdas
# =====================================
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

resource "aws_api_gateway_integration" "get_list_by_id" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.list_sk.id
  http_method             = aws_api_gateway_method.get_list_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_get_list_by_id}/invocations"
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

resource "aws_api_gateway_integration" "put_items" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.items_pk_sk.id
  http_method             = aws_api_gateway_method.put_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_update_item}/invocations"
}

resource "aws_api_gateway_integration" "delete_items" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.items_pk_sk.id
  http_method             = aws_api_gateway_method.delete_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_delete_item}/invocations"
}

# NOVA INTEGRAÇÃO POST /requests → post_request_lambda
resource "aws_api_gateway_integration" "post_requests" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.requests.id
  http_method             = aws_api_gateway_method.post_requests.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_post_request}/invocations"
}

# NOVA INTEGRAÇÃO GET /requests → get_request_lambda
resource "aws_api_gateway_integration" "get_requests" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.requests.id
  http_method             = aws_api_gateway_method.get_requests.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.uri_get_request}/invocations"
}

# =====================================
# Permissões para Lambda
# =====================================
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

resource "aws_lambda_permission" "get_list_by_id" {
  statement_id  = "AllowGetListById"
  action        = "lambda:InvokeFunction"
  function_name = var.get_list_by_id_lambda_name
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

resource "aws_lambda_permission" "put_items" {
  statement_id  = "AllowPutItems"
  action        = "lambda:InvokeFunction"
  function_name = var.update_item_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "delete_items" {
  statement_id  = "AllowDeleteItems"
  action        = "lambda:InvokeFunction"
  function_name = var.delete_item_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

# NOVA PERMISSÃO /requests
resource "aws_lambda_permission" "post_requests" {
  statement_id  = "AllowPostRequests"
  action        = "lambda:InvokeFunction"
  function_name = var.post_request_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}

# NOVA PERMISSÃO /requests
resource "aws_lambda_permission" "get_requests" {
  statement_id  = "AllowGetRequests"
  action        = "lambda:InvokeFunction"
  function_name = var.get_request_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todo_api.execution_arn}/*/*"
}


# =====================================
# Deployment e Stage
# =====================================
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id

  depends_on = [
    aws_api_gateway_integration.post_create,
    aws_api_gateway_integration.get_lists,
    aws_api_gateway_integration.get_list_by_id,
    aws_api_gateway_integration.put_list,
    aws_api_gateway_integration.post_items,
    aws_api_gateway_integration.get_items,
    aws_api_gateway_integration.put_items,
    aws_api_gateway_integration.delete_items,
    aws_api_gateway_method.post_requests,
    aws_api_gateway_method.get_requests
  ]

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_method.post_create,
      aws_api_gateway_method.get_lists,
      aws_api_gateway_method.get_list_by_id,
      aws_api_gateway_method.put_list,
      aws_api_gateway_method.post_items,
      aws_api_gateway_method.get_items,
      aws_api_gateway_method.put_items,
      aws_api_gateway_method.delete_items,
      aws_api_gateway_integration.post_requests,
      aws_api_gateway_integration.get_requests
    ]))
  }

}


resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  stage_name    = "prod"
}











