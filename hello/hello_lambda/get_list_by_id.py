import os
import json
import boto3

TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "todo-list-table")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    print("Evento recebido:", json.dumps(event))

    # Pegando user_id (query string ou Cognito)
    user_id = (
        event.get("queryStringParameters", {}).get("userid") or
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {}).get("sub")
    )

    # Pegando id da lista do path parameter
    list_id = event.get("pathParameters", {}).get("sk")

    if not user_id or not list_id:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Parâmetros obrigatórios: 'user_id' e 'sk'"})
        }

    try:
        response = table.get_item(
            Key={
                "PK": f"USER#{user_id}",
                "SK": f"LIST#{list_id}"
            }
        )

        item = response.get("Item")

        if not item:
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Lista não encontrada"})
            }

        return {
            "statusCode": 200,
            "body": json.dumps({"lista": item})
        }

    except Exception as e:
        print("Erro ao buscar lista:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Erro interno ao buscar lista"})
        }


