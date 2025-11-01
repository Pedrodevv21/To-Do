import json
import boto3
import os

dynamodb = boto3.client('dynamodb')
TABLE_NAME = os.environ['DYNAMODB_TABLE']

def lambda_handler(event, context):
    try:
    
        pk_raw = event["pathParameters"]["pk"]
        sk_raw = event["pathParameters"]["sk"]   

       
        pk = f"LIST#{pk_raw}"
        sk = f"ITEM#{sk_raw}"

        
        body = json.loads(event["body"])
        nome = body.get("name")
        status = body.get("status")

        
        update_expression = "SET #n = :name, #s = :status"
        expression_attribute_names = {
            "#n": "name",
            "#s": "status"
        }
        expression_attribute_values = {
            ":name": {"S": nome},
            ":status": {"S": status}
        }

       
        response = dynamodb.update_item(
            TableName=TABLE_NAME,
            Key={
                "PK": {"S": pk},
                "SK": {"S": sk}
            },
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )

       
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Item atualizado com sucesso",
                "updatedItem": response.get("Attributes")
            }),
            "headers": {
                "Content-Type": "application/json"
            }
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Erro ao atualizar item",
                "error": str(e)
            }),
            "headers": {
                "Content-Type": "application/json"
            }
        }







