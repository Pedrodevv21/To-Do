import json
from unittest.mock import patch
from hello.hello_lambda.create_item import lambda_handler  # ajuste o import para o caminho do seu arquivo

@patch("hello.hello_lambda.create_item.table.put_item")
def test_create_item_success(mock_put_item):
    mock_put_item.return_value = {"ResponseMetadata": {"HTTPStatusCode": 200}}


    event = {
        "body": json.dumps({
            "list_id": "9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "name": "Comprar pão e leite"
        })
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 201

    body = json.loads(response["body"])
    assert body["message"] == "Item criado"
    assert "item" in body
    assert body["item"]["PK"] == "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343"
    assert body["item"]["name"] == "Comprar pão e leite"  # corrigido para bater com o event
    assert body["item"]["SK"].startswith("ITEM#")

@patch("hello.hello_lambda.create_item.table.put_item")
def test_create_item_success_with_prefixed_list_id(mock_put_item):
    mock_put_item.return_value = {"ResponseMetadata": {"HTTPStatusCode": 200}}

    
    event = {
        "body": json.dumps({
            "list_id": "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343",
            "name": "Comprar leite"
        })
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 201

    body = json.loads(response["body"])
    assert body["item"]["PK"] == "LIST#9f7d558c-c59e-4560-b5fa-baec9d4ed343"

def test_create_item_invalid_json():
    event = {"body": "{invalid json}"}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "JSON inválido" in body["error"]

def test_create_item_missing_list_id():
    event = {"body": json.dumps({"name": "Sem list_id"})}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "Campos 'list_id' e 'name' são obrigatórios" in body["error"]

def test_create_item_missing_name():
    event = {"body": json.dumps({"list_id": "123"})}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "Campos 'list_id' e 'name' são obrigatórios" in body["error"]

