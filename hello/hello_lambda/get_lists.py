import os
import json
import boto3
from boto3.dynamodb.conditions import Key

TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "todo-list-table")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    print(json.dumps(event)) 

    user_id = event.get("queryStringParameters", {}).get("userid")

    if not user_id:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "O parâmetro 'userid' é obrigatório"})
        }

    response = table.query(
        KeyConditionExpression=Key("PK").eq(f"USER#{user_id}") & Key("SK").begins_with("LIST#")
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"listas": response["Items"]})
    }