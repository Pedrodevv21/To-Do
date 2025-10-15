variable "uri_create_task" { type = string }
variable "uri_list_tasks" { type = string }
variable "uri_update_task" { type = string }

variable "create_list_lambda_name" { type = string }
variable "get_lists_lambda_name"   { type = string }
variable "update_list_lambda_name" { type = string }

variable "stage_name" { type = string }
variable "region"     { type = string }

variable "redeployment_trigger" {
  type        = string
  default     = ""
}
variable "cognito_user_pool_arn" {
  description = "O ARN do Cognito User Pool para usar no autorizador"
  type = string
}
