variable "aws_region" {
  description = "Região AWS usada pelo provider e backend"
  type        = string
  default     = "sa-east-1"
}

variable "table_name" {
  description = "Nome da tabela DynamoDB usada no backend e nas Lambdas"
  type        = string
  default     = "todo-list-table"
}

variable "bucket_name" {
  description = "Nome do bucket S3 usado no backend"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime padrão para as funções Lambda"
  type        = string
  default     = "python3.9"
}
