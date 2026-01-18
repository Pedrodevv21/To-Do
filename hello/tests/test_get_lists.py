import os
import json
import sys
from unittest.mock import MagicMock, patch
import pytest

os.environ["DYNAMODB_TABLE"] = "todo-list-table"


def _import_lambda_with_mocked_dynamodb(query_return=None, side_effect=None):
    mock_table = MagicMock()

    if side_effect:
        mock_table.query.side_effect = side_effect
    else:
        mock_table.query.return_value = query_return or {"Items": []}

    mock_dynamodb = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    # garante import limpo
    sys.modules.pop("hello.lambdas.get_lists", None)

    with patch("boto3.resource", return_value=mock_dynamodb):
        from hello.lambdas.get_lists import lambda_handler

    return lambda_handler, mock_table


def test_get_lists_success():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        query_return={
            "Items": [
                {"PK": "USER#1", "SK": "LIST#1", "name": "Teste"}
            ]
        }
    )

    event = {
        "queryStringParameters": {
            "userid": "1"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 200

    body = json.loads(response["body"])
    assert isinstance(body["listas"], list)
    assert len(body["listas"]) == 1
    assert body["listas"][0]["name"] == "Teste"

    mock_table.query.assert_called_once()


def test_empty_list():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        query_return={"Items": []}
    )

    event = {
        "queryStringParameters": {
            "userid": "1"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 200

    body = json.loads(response["body"])
    assert body["listas"] == []

    mock_table.query.assert_called_once()


def test_missing_user_id():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb()

    event = {
        "queryStringParameters": {}
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 400
    assert "userid" in response["body"]


def test_no_query_string():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb()

    event = {}

    response = lambda_handler(event, None)

    assert response["statusCode"] == 400


def test_dynamodb_failure():
    lambda_handler, mock_table = _import_lambda_with_mocked_dynamodb(
        side_effect=Exception("Erro DynamoDB")
    )

    event = {
        "queryStringParameters": {
            "userid": "1"
        }
    }

    with pytest.raises(Exception, match="Erro DynamoDB"):
        lambda_handler(event, None)

    mock_table.query.assert_called_once()


def test_response_format():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb(
        query_return={"Items": []}
    )

    event = {
        "queryStringParameters": {
            "userid": "1"
        }
    }

    response = lambda_handler(event, None)

    assert set(response.keys()) == {"statusCode", "body"}

