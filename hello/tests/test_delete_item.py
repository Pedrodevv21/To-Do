import os
import json
import pytest
from unittest.mock import patch, MagicMock

# Definindo a variável de ambiente antes de importar a Lambda
os.environ["DYNAMODB_TABLE"] = "todo-list-table"

from hello.hello_lambda.delete_item import lambda_handler

@patch("hello.hello_lambda.delete_item.dynamodb.delete_item")
def test_delete_item_success(mock_delete_item):
    mock_delete_item.return_value = {
        "Attributes": {
            "PK": {"S": "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343"},
            "SK": {"S": "ITEM#4e16afc7-fdf6-4da2-9bd7-a2430e59b75c"},
            "name": {"S": "Comprar pão e leite"},
            "created_at": {"S": "2025-10-15T22:59:57.593289"}
        }
    }

    event = {
        "pathParameters": {
            "pk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "sk": "4e16afc7-fdf6-4da2-9bd7-a2430e59b75c"
        }
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 200

    body = json.loads(response["body"])
    assert body["message"] == "Item deletado com sucesso"
    assert body["deletedItem"]["SK"]["S"] == "ITEM#4e16afc7-fdf6-4da2-9bd7-a2430e59b75c"
    mock_delete_item.assert_called_once()


@patch("hello.hello_lambda.delete_item.dynamodb.delete_item")
def test_delete_item_not_found(mock_delete_item):
    mock_delete_item.return_value = {}
    event = {
        "pathParameters": {
            "pk": "naoexiste",
            "sk": "naoexiste"
        }
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 404

    body = json.loads(response["body"])
    assert body["message"] == "Item não encontrado"
    mock_delete_item.assert_called_once()


def test_delete_item_missing_params():
    # Simula parâmetros faltando
    event = {"pathParameters": {}}
    response = lambda_handler(event, None)

    assert response["statusCode"] == 500  # porque a Lambda atual gera KeyError
    body = json.loads(response["body"])
    assert "error" in body


@patch("hello.hello_lambda.delete_item.dynamodb.delete_item", side_effect=Exception("Erro DynamoDB"))
def test_delete_item_dynamodb_exception(mock_delete_item):
    event = {
        "pathParameters": {
            "pk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "sk": "4e16afc7-fdf6-4da2-9bd7-a2430e59b75c"
        }
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 500

    body = json.loads(response["body"])
    assert body["message"] == "Erro ao deletar item"
    assert "Erro DynamoDB" in body["error"]
    mock_delete_item.assert_called_once()




