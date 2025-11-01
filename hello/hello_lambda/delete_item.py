
import json
import boto3
import os

dynamodb = boto3.client('dynamodb')
TABLE_NAME = os.environ['DYNAMODB_TABLE']

def lambda_handler(event, context):
    try:
        # Extrai os parâmetros do path
        pk_raw = event["pathParameters"]["pk"]
        sk_raw = event["pathParameters"]["sk"]

        # Monta as chaves com o mesmo padrão da lambda de editar
        pk = f"LIST#{pk_raw}"
        sk = f"ITEM#{sk_raw}"

        # Deleta o item do DynamoDB
        response = dynamodb.delete_item(
            TableName=TABLE_NAME,
            Key={
                "PK": {"S": pk},
                "SK": {"S": sk}
            },
            ReturnValues="ALL_OLD"
        )

        # Verifica se o item existia
        if "Attributes" not in response:
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "message": "Item não encontrado"
                }),
                "headers": {"Content-Type": "application/json"}
            }

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Item deletado com sucesso",
                "deletedItem": response["Attributes"]
            }),
            "headers": {"Content-Type": "application/json"}
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Erro ao deletar item",
                "error": str(e)
            }),
            "headers": {"Content-Type": "application/json"}
        }
