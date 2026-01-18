import os
import json
import boto3
from boto3.dynamodb.conditions import Key

TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "todo-list-table")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    print("Event recebido:", json.dumps(event))  # Log pra debug

    
    params = event.get("queryStringParameters") or {}
    list_id = params.get("list_id")

   
    if not list_id:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "O parâmetro 'list_id' é obrigatório"}),
            "headers": {"Content-Type": "application/json"}
        }

   
    if not list_id.startswith("LIST#"):
        list_id = f"LIST#{list_id}"

    try:
        
        response = table.query(
            KeyConditionExpression=Key("PK").eq(list_id) & Key("SK").begins_with("ITEM#")
        )

        items = response.get("Items", [])

        return {
            "statusCode": 200,
            "body": json.dumps({"items": items}),
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        }

    except Exception as e:
        print("Erro:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Erro interno ao listar itens"}),
            "headers": {"Content-Type": "application/json"}
        }
