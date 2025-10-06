output "dynamodb_table_name" {
  value = aws_dynamodb_table.todo_table.name
}

output "lambda_function_name" {
  value = aws_lambda_function.create_list_lambda.function_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.todo_bucket.bucket
}

output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_api_role.arn
}
