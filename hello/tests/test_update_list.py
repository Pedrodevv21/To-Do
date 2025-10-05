import json
from unittest.mock import patch
from hello.hello_lambda import update_list
import pytest

@patch("hello.hello_lambda.update_list.table.update_item")
def test_update_success(mock_update):
    mock_update.return_value = {"Attributes": {"name": "Nova Lista"}}
    event = {"body": json.dumps({"user_id": "1", "list_id": "123", "name": "Nova Lista"})}
    result = update_list.lambda_handler(event, None)

    assert result["statusCode"] == 200
    body = json.loads(result["body"])
    assert "Lista atualizada" in body["message"]

def test_invalid_json():
    event = {"body": "{invalid}"}
    result = update_list.lambda_handler(event, None)

    assert result["statusCode"] == 400
    body = json.loads(result["body"])
    assert "JSON inválido" in body["error"]

def test_missing_user_id():
    event = {"body": json.dumps({"list_id": "123", "name": "Lista"})}
    result = update_list.lambda_handler(event, None)

    assert result["statusCode"] == 400

def test_missing_list_id():
    event = {"body": json.dumps({"user_id": "1", "name": "Lista"})}
    result = update_list.lambda_handler(event, None)

    assert result["statusCode"] == 400

def test_missing_name_field():
    event = {"body": json.dumps({"user_id": "1", "list_id": "123"})}
    result = update_list.lambda_handler(event, None)

    assert result["statusCode"] == 400
    body = json.loads(result["body"])
    assert "Campo 'name'" in body["error"]

@patch("hello.hello_lambda.update_list.table.update_item", side_effect=Exception("Erro DynamoDB"))
def test_dynamodb_failure(mock_update):
    event = {"body": json.dumps({"user_id": "1", "list_id": "123", "name": "Teste"})}
    with pytest.raises(Exception):
        update_list.lambda_handler(event, None)

@patch("hello.hello_lambda.update_list.table.update_item")
def test_response_structure(mock_update):
    mock_update.return_value = {"Attributes": {"name": "Lista"}}
    event = {"body": json.dumps({"user_id": "1", "list_id": "1", "name": "L1"})}
    result = update_list.lambda_handler(event, None)

    assert set(result.keys()) == {"statusCode", "body"}
