import os
import json
import sys
from unittest.mock import MagicMock, patch

os.environ["DYNAMODB_TABLE"] = "todo-list-table"


def _import_lambda_with_mocked_dynamodb(get_item_return=None, side_effect=None):
    mock_table = MagicMock()

    if side_effect:
        mock_table.get_item.side_effect = side_effect
    else:
        mock_table.get_item.return_value = get_item_return or {}

    mock_dynamodb = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    # força import limpo
    sys.modules.pop("hello.lambdas.get_list_by_id", None)

    with patch("boto3.resource", return_value=mock_dynamodb):
        from hello.lambdas.get_list_by_id import lambda_handler

    return lambda_handler, mock_table


def test_get_list_by_id_success():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        get_item_return={
            "Item": {
                "PK": "USER#123",
                "SK": "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343",
                "name": "Lista de compras",
            }
        }
    )

    event = {
        "pathParameters": {
            "sk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343"
        },
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": "123"
                }
            }
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 200

    body = json.loads(response["body"])
    assert body["lista"]["name"] == "Lista de compras"

    mock_table.get_item.assert_called_once()


def test_get_list_by_id_not_found():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        get_item_return={}
    )

    event = {
        "pathParameters": {
            "sk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343"
        },
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": "123"
                }
            }
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 404

    body = json.loads(response["body"])
    assert body["error"] == "Lista não encontrada"

    mock_table.get_item.assert_called_once()


def test_get_list_by_id_missing_params():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb()

    event = {
        "pathParameters": {},
        "requestContext": {}
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 400

    body = json.loads(response["body"])
    assert "Parâmetros obrigatórios" in body["error"]


def test_get_list_by_id_dynamodb_exception():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        side_effect=Exception("Erro DynamoDB")
    )

    event = {
        "pathParameters": {
            "sk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343"
        },
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": "123"
                }
            }
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 500

    body = json.loads(response["body"])
    assert body["error"] == "Erro interno ao buscar lista"

    mock_table.get_item.assert_called_once()
