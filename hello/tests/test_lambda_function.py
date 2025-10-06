import json
from unittest.mock import patch
from hello.hello_lambda import lambda_function

@patch("hello.hello_lambda.lambda_function.table.put_item")
def test_lambda_success(mock_put_item):
    mock_put_item.return_value = {"ResponseMetadata": {"HTTPStatusCode": 200}}

    event = {"body": json.dumps({"user_id": "123", "name": "Minha Lista"})}
    response = lambda_function.lambda_handler(event, None)

    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    assert "Lista criada" in body["message"]
    assert "item" in body

def test_invalid_json():
    event = {"body": "{invalid json}"}
    response = lambda_function.lambda_handler(event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "JSON inválido" in body["error"]

def test_missing_user_id():
    event = {"body": json.dumps({"name": "Lista sem user_id"})}
    response = lambda_function.lambda_handler(event, None)

    assert response["statusCode"] == 400

def test_missing_name():
    event = {"body": json.dumps({"user_id": "123"})}
    response = lambda_function.lambda_handler(event, None)

    assert response["statusCode"] == 400