import os
os.environ["DYNAMODB_TABLE"] = "todo-list-table"
import json
import pytest
from unittest.mock import patch, MagicMock
from hello.hello_lambda.get_list_by_id import lambda_handler


@patch("hello.hello_lambda.get_list_by_id.table.get_item")
def test_get_list_by_id_success(mock_get_item):
    # Simula retorno de uma lista válida
    mock_get_item.return_value = {
        "Item": {
            "PK": "USER#123",
            "SK": "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "name": "Lista de compras"
        }
    }

    event = {
        "pathParameters": {"sk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343"},
        "requestContext": {"authorizer": {"claims": {"sub": "123"}}}
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 200

    body = json.loads(response["body"])
    assert "lista" in body
    assert body["lista"]["name"] == "Lista de compras"
    mock_get_item.assert_called_once()


@patch("hello.hello_lambda.get_list_by_id.table.get_item")
def test_get_list_by_id_not_found(mock_get_item):
    # Simula quando a lista não é encontrada
    mock_get_item.return_value = {}
    event = {
        "pathParameters": {"sk": "LIST#naoexiste"},
        "requestContext": {"authorizer": {"claims": {"sub": "123"}}}
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 404

    body = json.loads(response["body"])
    assert body["error"] == "Lista não encontrada"
    mock_get_item.assert_called_once()


def test_get_list_by_id_missing_params():
    # Simula quando parâmetros obrigatórios estão faltando
    event = {"pathParameters": {}, "requestContext": {}}
    response = lambda_handler(event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "Parâmetros obrigatórios" in body["error"]


@patch("hello.hello_lambda.get_list_by_id.table.get_item", side_effect=Exception("Erro DynamoDB"))
def test_get_list_by_id_dynamodb_exception(mock_get_item):
    event = {
        "pathParameters": {"sk": "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343"},
        "requestContext": {"authorizer": {"claims": {"sub": "123"}}}
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 500

    body = json.loads(response["body"])
    assert body["error"] == "Erro interno ao buscar lista"
    mock_get_item.assert_called_once()
