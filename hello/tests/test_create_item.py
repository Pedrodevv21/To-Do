import json
import sys
from unittest.mock import MagicMock, patch


def test_create_item_success():
    mock_table = MagicMock()
    mock_table.put_item.return_value = {
        "ResponseMetadata": {"HTTPStatusCode": 200}
    }

    
    mock_dynamodb = MagicMock()
    mock_dynamodb.Table.return_value = mock_table
    with patch("boto3.resource", return_value=mock_dynamodb):
        from hello.lambdas.create_item import lambda_handler

        event = {
            "body": json.dumps({
                "list_id": "9f7d558c-c59e-4560-b5fa-baec9d4ed343",
                "name": "Comprar pão e leite"
            })
        }

        response = lambda_handler(event, None)

        assert response["statusCode"] == 201

        body = json.loads(response["body"])
        assert body["message"] == "Item criado"
        assert body["item"]["PK"] == "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343"
        assert body["item"]["name"] == "Comprar pão e leite"
        assert body["item"]["SK"].startswith("ITEM#")
