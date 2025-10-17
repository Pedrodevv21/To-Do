output "dynamodb_table_name" {
  value = aws_dynamodb_table.todo_table.name
}


output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_api_role.arn
}
