data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "todo_api" {
  name        = "todo-api"
  description = "API Gateway para o projeto ToDo List"
}

### /create
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

resource "aws_api_gateway_method" "post_create" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.create.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_lists" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.lists.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "put_list" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.list_sk.id
  http_method   = "PUT"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.sk" = true
  }
}

resource "aws_api_gateway_integration" "post_create" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.create.id
  http_method             = aws_api_gateway_method.post_create.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.uri_create_task}/invocations"
}

resource "aws_api_gateway_integration" "get_lists" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.lists.id
  http_method             = aws_api_gateway_method.get_lists.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.uri_list_tasks}/invocations"
}

resource "aws_api_gateway_integration" "put_list" {
  rest_api_id             = aws_api_gateway_rest_api.todo_api.id
  resource_id             = aws_api_gateway_resource.list_sk.id
  http_method             = aws_api_gateway_method.put_list.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.uri_update_task}/invocations"
}

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

# Deployment + Stage
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.post_create,
    aws_api_gateway_integration.get_lists,
    aws_api_gateway_integration.put_list,
    var.uri_create_task,
    var.uri_list_tasks,
    var.uri_update_task
  ]

  rest_api_id = aws_api_gateway_rest_api.todo_api.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_integration.post_create,
      aws_api_gateway_integration.get_lists,
      aws_api_gateway_integration.put_list
    ]))
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}