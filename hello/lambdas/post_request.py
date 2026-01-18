import json
import boto3
import os
import uuid

sqs = boto3.client('sqs')
QUEUE_URL = os.environ['SQS_QUEUE_URL']

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        message_id = str(uuid.uuid4())

        # Envia a mensagem para a fila
        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps({
                "id": message_id,
                "request": body
            })
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Sua solicitação foi recebida. Estamos processando-a.",
                "request_id": message_id
            })
        }

    except Exception as e:
        print("Erro:", e)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

