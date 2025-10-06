import os
import json
import boto3

TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "todo-list-table")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
    except Exception:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "JSON inválido"})
        }

    user_id = body.get("user_id")
    list_id = body.get("list_id")

    if not user_id or not list_id:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Campos 'user_id' e 'list_id' são obrigatórios"})
        }

    if "name" not in body:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Campo 'name' é obrigatório para atualização"})
        }

    response = table.update_item(
        Key={
            "PK": f"USER#{user_id}",
            "SK": f"LIST#{list_id}"
        },
        UpdateExpression="SET #n = :name",
        ExpressionAttributeNames={
            "#n": "name"
        },
        ExpressionAttributeValues={
            ":name": body["name"]
        },
        ReturnValues="ALL_NEW"
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Lista atualizada com sucesso",
            "item": response["Attributes"]
        })
    }
