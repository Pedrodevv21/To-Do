import json
from unittest.mock import patch
from hello.hello_lambda import get_lists

@patch("hello.hello_lambda.get_lists.table.query")
def test_get_lists_success(mock_query):
    mock_query.return_value = {
        "Items": [{"PK": "USER#1", "SK": "LIST#1", "name": "Teste"}]
    }
    event = {"queryStringParameters": {"userid": "1"}}
    response = get_lists.lambda_handler(event, None)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert isinstance(body["listas"], list)
    assert len(body["listas"]) == 1
    assert body["listas"][0]["name"] == "Teste"

def test_missing_user_id():
    event = {"queryStringParameters": {}}
    response = get_lists.lambda_handler(event, None)

    assert response["statusCode"] == 400
    assert "userid" in response["body"]

def test_no_query_string():
    event = {}
    response = get_lists.lambda_handler(event, None)

    assert response["statusCode"] == 400

@patch("hello.hello_lambda.get_lists.table.query", side_effect=Exception("Erro DynamoDB"))
def test_dynamodb_failure(mock_query):
    event = {"queryStringParameters": {"userid": "1"}}
    import pytest
    with pytest.raises(Exception):
        get_lists.lambda_handler(event, None)

@patch("hello.hello_lambda.get_lists.table.query")
def test_empty_list(mock_query):
    mock_query.return_value = {"Items": []}
    event = {"queryStringParameters": {"userid": "1"}}
    response = get_lists.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert body["listas"] == []

@patch("hello.hello_lambda.get_lists.table.query")
def test_response_format(mock_query):
    mock_query.return_value = {"Items": []}
    event = {"queryStringParameters": {"userid": "1"}}
    result = get_lists.lambda_handler(event, None)

    assert set(result.keys()) == {"statusCode", "body"}
