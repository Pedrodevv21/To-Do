import json
import pytest
from unittest.mock import patch
from hello.hello_lambda.get_item import lambda_handler

@patch("hello.hello_lambda.get_item.table.query")
def test_get_items_success(mock_query):
    mock_query.return_value = {
        "Items": [
            {
                "PK": "LIST#123",
                "SK": "ITEM#abc",
                "name": "Comprar pão",
                "created_at": "2025-10-15T22:59:57.593289"
            }
        ]
    }

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
    mock_query.assert_called_once()

@patch("hello.hello_lambda.get_item.table.query")
def test_get_items_success_with_prefix(mock_query):
    mock_query.return_value = {
        "Items": []
    }

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

def test_get_items_missing_list_id():
    event = {
        "queryStringParameters": None
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "error" in body
    assert body["error"] == "O parâmetro 'list_id' é obrigatório"

def test_get_items_no_query_string():
    event = {}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "error" in body
    assert body["error"] == "O parâmetro 'list_id' é obrigatório"

@patch("hello.hello_lambda.get_item.table.query", side_effect=Exception("Erro no DynamoDB"))
def test_get_items_internal_error(mock_query):
    event = {
        "queryStringParameters": {
            "list_id": "123"
        }
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert "error" in body
    assert body["error"] == "Erro interno ao listar itens"
