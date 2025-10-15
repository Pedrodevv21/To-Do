output "api_url" {
  description = "URL base da API"
  value       = "https://${aws_api_gateway_rest_api.todo_api.id}.execute-api.${var.region}.amazonaws.com/${var.stage_name}"
}

