import json
import os
from datetime import datetime
import boto3
import uuid

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

    if not body.get("user_id") or not body.get("name"):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Campos 'user_id' e 'name' são obrigatórios"})
        }

    user_id = body["user_id"]
    list_id = str(uuid.uuid4()) 
    now = datetime.utcnow().isoformat()

    item = {
        "PK": f"USER#{user_id}",
        "SK": f"LIST#{list_id}",
        "name": body["name"],
        "created_at": now
    }

    table.put_item(Item=item)

    return {
        "statusCode": 201,
        "body": json.dumps({"message": "Lista criada", "item": item})
    }