import os
os.environ["DYNAMODB_TABLE"] = "todo-list-table" 
import json
import pytest
from unittest.mock import patch, MagicMock
from hello.hello_lambda.update_item import lambda_handler


@patch("hello.hello_lambda.update_item.dynamodb.update_item")
def test_update_item_success(mock_update_item):
    # Simula resposta do DynamoDB
    mock_update_item.return_value = {
        "Attributes": {
            "PK": {"S": "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343"},
            "SK": {"S": "ITEM#49cba0b9-8840-4f9d-a7a4-7908d5e26238"},
            "name": {"S": "Comprar pão e leite"},
            "status": {"S": "feito"}
        }
    }

    event = {
        "pathParameters": {
            "pk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "sk": "49cba0b9-8840-4f9d-a7a4-7908d5e26238"
        },
        "body": json.dumps({
            "name": "Comprar pão e leite",
            "status": "feito"
        })
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 200

    body = json.loads(response["body"])
    assert body["message"] == "Item atualizado com sucesso"
    assert "updatedItem" in body
    assert body["updatedItem"]["name"]["S"] == "Comprar pão e leite"

    mock_update_item.assert_called_once()


@patch("hello.hello_lambda.update_item.dynamodb.update_item")
def test_update_item_missing_path_parameters(mock_update_item):
    event = {
        "pathParameters": {},
        "body": json.dumps({"name": "Novo nome", "status": "feito"})
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert "Erro ao atualizar item" in body["message"]
    mock_update_item.assert_not_called()


@patch("hello.hello_lambda.update_item.dynamodb.update_item", side_effect=Exception("Erro no DynamoDB"))
def test_update_item_dynamodb_exception(mock_update_item):
    event = {
        "pathParameters": {
            "pk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "sk": "49cba0b9-8840-4f9d-a7a4-7908d5e26238"
        },
        "body": json.dumps({
            "name": "Teste",
            "status": "pendente"
        })
    }

    response = lambda_handler(event, None)
    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert body["message"] == "Erro ao atualizar item"
    assert "Erro no DynamoDB" in body["error"]
