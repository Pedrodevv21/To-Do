variable "uri_create_task" { type = string }
variable "uri_list_tasks" { type = string }
variable "uri_update_task" { type = string }

variable "create_list_lambda_name" { type = string }
variable "get_lists_lambda_name"   { type = string }
variable "update_list_lambda_name" { type = string }


variable "stage_name" { type = string }
variable "region"     { type = string }

variable "uri_create_item" {
  type = string
}

variable "create_item_lambda_name" {
  type = string
}

variable "uri_list_items" {
  type        = string
  description = "ARN da Lambda para listar itens"
}

variable "list_items_lambda_name" {
  type        = string
  description = "Nome da Lambda para listar itens"
}
variable "uri_update_item" {
  description = "ARN da Lambda para atualizar item"
  type        = string
}

variable "update_item_lambda_name" {
  description = "Nome da Lambda para atualizar item (usado nas permissões)"
  type        = string
}

variable "uri_get_list_by_id" {
  type        = string
  description = "ARN da Lambda para buscar item por ID"
}

variable "get_list_by_id_lambda_name" {
  type        = string
  description = "Nome da Lambda para buscar item por ID"
}
variable "uri_delete_item" {
  description = "ARN da função Lambda para deletar item"
  type        = string
}

variable "delete_item_lambda_name" {
  description = "Nome da função Lambda de delete item"
  type        = string
}
variable "uri_post_request" {
  description = "ARN da Lambda post_request para integração com o API Gateway"
}

variable "post_request_lambda_name" {
  description = "Nome da função Lambda post_request"
}

variable "get_request_lambda_name" {
  description = "Nome da Lambda get_request"
  type        = string
}

variable "uri_get_request" {
  description = "ARN da Lambda get_request para integração no API Gateway"
  type        = string
}


variable "cognito_user_pool_arn" {
  type        = string
  description = "ARN do Cognito User Pool usado para autenticação"
}

variable "redeployment_trigger" {
  type        = string
  default     = ""
}


