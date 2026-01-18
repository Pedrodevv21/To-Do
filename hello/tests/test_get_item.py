import json
import sys
from unittest.mock import MagicMock, patch


def _import_lambda_with_mocked_dynamodb(query_return=None, side_effect=None):
    """
    Importa a lambda com boto3.resource mockado ANTES do import
    """

    mock_table = MagicMock()

    if side_effect:
        mock_table.query.side_effect = side_effect
    else:
        mock_table.query.return_value = query_return or {"Items": []}

    mock_dynamodb = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    # Garante import limpo
    sys.modules.pop("hello.lambdas.get_item", None)

    with patch("boto3.resource", return_value=mock_dynamodb):
        from hello.lambdas.get_item import lambda_handler

    return lambda_handler, mock_table


def test_get_items_success():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        query_return={
            "Items": [
                {
                    "PK": "LIST#123",
                    "SK": "ITEM#abc",
                    "name": "Comprar pão",
                    "created_at": "2025-10-15T22:59:57.593289",
                }
            ]
        }
    )

    event = {
        "queryStringParameters": {
            "list_id": "123"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 200

    body = json.loads(response["body"])
    assert "items" in body
    assert len(body["items"]) == 1
    assert body["items"][0]["PK"] == "LIST#123"

    mock_table.query.assert_called_once()


def test_get_items_success_with_prefix():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        query_return={"Items": []}
    )

    event = {
        "queryStringParameters": {
            "list_id": "LIST#123"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 200

    body = json.loads(response["body"])
    assert isinstance(body["items"], list)
    assert len(body["items"]) == 0

    mock_table.query.assert_called_once()


def test_get_items_missing_list_id():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb()

    event = {
        "queryStringParameters": None
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 400

    body = json.loads(response["body"])
    assert body["error"] == "O parâmetro 'list_id' é obrigatório"


def test_get_items_no_query_string():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb()

    event = {}

    response = lambda_handler(event, None)

    assert response["statusCode"] == 400

    body = json.loads(response["body"])
    assert body["error"] == "O parâmetro 'list_id' é obrigatório"


def test_get_items_internal_error():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        side_effect=Exception("Erro no DynamoDB")
    )

    event = {
        "queryStringParameters": {
            "list_id": "123"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 500

    body = json.loads(response["body"])
    assert body["error"] == "Erro interno ao listar itens"

    mock_table.query.assert_called_once()
