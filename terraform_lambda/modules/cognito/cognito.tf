# Cognito User Pool 
resource "aws_cognito_user_pool" "user_pool" {
  name = "todo-user-pool"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }
}

#  Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "todo-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}
