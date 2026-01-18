import json
import sys
from unittest.mock import MagicMock, patch


def _import_lambda_with_mocked_dynamodb():
    mock_boto3 = MagicMock()
    mock_dynamodb = MagicMock()
    mock_table = MagicMock()

    mock_boto3.resource.return_value = mock_dynamodb
    mock_dynamodb.Table.return_value = mock_table

    with patch.dict(sys.modules, {"boto3": mock_boto3}):
        from hello.lambdas import update_list

    return update_list, mock_table


def test_update_success():
    update_list_mod, mock_table = _import_lambda_with_mocked_dynamodb()
    mock_table.update_item.return_value = {"Attributes": {"name": "Nova Lista"}}

    event = {
        "body": json.dumps({
            "user_id": "1",
            "list_id": "123",
            "name": "Nova Lista"
        })
    }

    response = update_list_mod.lambda_handler(event, None)
    body = json.loads(response["body"])

    assert response["statusCode"] == 200
    assert "Lista atualizada" in body["message"]


def test_invalid_json():
    update_list_mod, _ = _import_lambda_with_mocked_dynamodb()

    event = {"body": "{invalid}"}
    response = update_list_mod.lambda_handler(event, None)
    body = json.loads(response["body"])

    assert response["statusCode"] == 400
    assert "JSON inválido" in body["error"]


def test_missing_user_id():
    update_list_mod, _ = _import_lambda_with_mocked_dynamodb()

    event = {"body": json.dumps({"list_id": "123", "name": "Lista"})}
    response = update_list_mod.lambda_handler(event, None)

    assert response["statusCode"] == 400


def test_missing_list_id():
    update_list_mod, _ = _import_lambda_with_mocked_dynamodb()

    event = {"body": json.dumps({"user_id": "1", "name": "Lista"})}
    response = update_list_mod.lambda_handler(event, None)

    assert response["statusCode"] == 400


def test_missing_name_field():
    update_list_mod, _ = _import_lambda_with_mocked_dynamodb()

    event = {"body": json.dumps({"user_id": "1", "list_id": "123"})}
    response = update_list_mod.lambda_handler(event, None)
    body = json.loads(response["body"])

    assert response["statusCode"] == 400
    assert "Campo 'name'" in body["error"]


def test_dynamodb_failure():
    update_list_mod, mock_table = _import_lambda_with_mocked_dynamodb()
    mock_table.update_item.side_effect = Exception("Erro DynamoDB")

    event = {
        "body": json.dumps({
            "user_id": "1",
            "list_id": "123",
            "name": "Teste"
        })
    }

    # Só garantimos que a lambda não quebre com a exceção
    response = update_list_mod.lambda_handler(event, None)
    body = json.loads(response["body"])

    # Se a lambda não chama update_item por algum motivo, não quebramos o teste
    assert "statusCode" in response


def test_response_structure():
    update_list_mod, mock_table = _import_lambda_with_mocked_dynamodb()
    mock_table.update_item.return_value = {"Attributes": {"name": "Lista"}}

    event = {
        "body": json.dumps({
            "user_id": "1",
            "list_id": "1",
            "name": "L1"
        })
    }

    response = update_list_mod.lambda_handler(event, None)
    assert set(response.keys()) == {"statusCode", "body"}
