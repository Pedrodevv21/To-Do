import os
import json
import boto3
import csv
import tempfile
from datetime import datetime
from boto3.dynamodb.conditions import Key


DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "todo-list-table")
S3_BUCKET = os.environ.get("S3_BUCKET", "todo-csv-bucket")
REGION = os.environ.get("AWS_REGION", "sa-east-1")

# E-mails SES
FROM_EMAIL = "pedroxxdroxx@gmail.com"
TO_EMAIL = "pedroalves.devv@gmail.com"


dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(DYNAMODB_TABLE)
s3 = boto3.client("s3", region_name=REGION)
ses = boto3.client("ses", region_name=REGION)


def lambda_handler(event, context):
    """
    Função Lambda acionada via SQS.
    Cada mensagem da fila deve conter um JSON com o user_id, ex:
    {
        "user_id": "123"
    }
    """
    try:
        for record in event["Records"]:
            message = json.loads(record["body"])
            user_id = message.get("user_id")

            if not user_id:
                print("Mensagem inválida recebida:", message)
                continue

           
            response = table.query(
                KeyConditionExpression=Key("PK").eq(f"USER#{user_id}")
            )
            items = response.get("Items", [])

            if not items:
                print(f"Nenhum item encontrado para o usuário {user_id}")
                continue

            # === 2️⃣ Gera CSV temporário ===
            with tempfile.NamedTemporaryFile(mode="w", delete=False, newline="") as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=items[0].keys())
                writer.writeheader()
                writer.writerows(items)
                csv_path = csvfile.name

            # === 3️⃣ Upload para S3 ===
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            s3_key = f"exports/{user_id}_todo_data_{timestamp}.csv"
            s3.upload_file(csv_path, S3_BUCKET, s3_key)

            # === 4️⃣ Gera link pré-assinado ===
            s3_url = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": S3_BUCKET, "Key": s3_key},
                ExpiresIn=3600  # 1 hora
            )

           
            ses.send_email(
                Source=FROM_EMAIL,
                Destination={"ToAddresses": [TO_EMAIL]},
                Message={
                    "Subject": {"Data": f"Relatório ToDo List - Usuário {user_id}"},
                    "Body": {
                        "Text": {
                            "Data": (
                                f"Olá!\n\n"
                                f"O relatório de tarefas do usuário {user_id} foi gerado.\n"
                                f"Baixe o CSV aqui (válido por 1 hora):\n\n{s3_url}\n\n"
                                f"Atenciosamente,\nLambda ToDo 🚀"
                            )
                        }
                    },
                },
            )

            print(f"✅ CSV enviado para {TO_EMAIL} com sucesso: {s3_url}")

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Processamento concluído com sucesso"})
        }

    except Exception as e:
        print("❌ Erro:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }





