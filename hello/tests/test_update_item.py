import json
import os
import sys
from unittest.mock import MagicMock, patch

os.environ["DYNAMODB_TABLE"] = "todo-list-table"


def _import_lambda_with_mocked_dynamodb():
    mock_boto3 = MagicMock()
    mock_dynamodb = MagicMock()

    mock_boto3.client.return_value = mock_dynamodb

    with patch.dict(sys.modules, {"boto3": mock_boto3}):
        import hello.lambdas.update_item as update_item

    return update_item, mock_dynamodb


def test_update_item_success():
    update_item, mock_dynamodb = _import_lambda_with_mocked_dynamodb()

    mock_dynamodb.update_item.return_value = {
        "Attributes": {
            "PK": {"S": "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343"},
            "SK": {"S": "ITEM#49cba0b9-8840-4f9d-a7a4-7908d5e26238"},
            "name": {"S": "Comprar pão e leite"},
            "status": {"S": "feito"},
        }
    }

    event = {
        "pathParameters": {
            "pk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "sk": "49cba0b9-8840-4f9d-a7a4-7908d5e26238",
        },
        "body": json.dumps({
            "name": "Comprar pão e leite",
            "status": "feito",
        }),
    }

    response = update_item.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert body["message"] == "Item atualizado com sucesso"
    assert body["updatedItem"]["name"]["S"] == "Comprar pão e leite"

    mock_dynamodb.update_item.assert_called_once()


def test_update_item_missing_path_parameters():
    update_item, mock_dynamodb = _import_lambda_with_mocked_dynamodb()

    event = {
        "pathParameters": {},
        "body": json.dumps({"name": "Novo nome", "status": "feito"}),
    }

    response = update_item.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 500
    assert "Erro ao atualizar item" in body["message"]

    mock_dynamodb.update_item.assert_not_called()


def test_update_item_dynamodb_exception():
    update_item, mock_dynamodb = _import_lambda_with_mocked_dynamodb()

    mock_dynamodb.update_item.side_effect = Exception("Erro no DynamoDB")

    event = {
        "pathParameters": {
            "pk": "9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "sk": "49cba0b9-8840-4f9d-a7a4-7908d5e26238",
        },
        "body": json.dumps({
            "name": "Teste",
            "status": "pendente",
        }),
    }

    response = update_item.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 500
    assert body["message"] == "Erro ao atualizar item"
    assert "Erro no DynamoDB" in body["error"]

    mock_dynamodb.update_item.assert_called_once()
