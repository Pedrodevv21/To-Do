import json
import sys
from unittest.mock import MagicMock, patch


def _import_lambda_with_mocked_aws():
    mock_boto3 = MagicMock()
    mock_dynamodb_resource = MagicMock()
    mock_table = MagicMock()

    mock_dynamodb_resource.Table.return_value = mock_table
    mock_boto3.resource.return_value = mock_dynamodb_resource

    with patch.dict(sys.modules, {"boto3": mock_boto3}):
        from hello.lambdas import lambda_function

    return lambda_function, mock_table


def test_lambda_success():
    lambda_function, mock_table = _import_lambda_with_mocked_aws()

    mock_table.put_item.return_value = {
        "ResponseMetadata": {"HTTPStatusCode": 200}
    }

    event = {"body": json.dumps({"user_id": "123", "name": "Minha Lista"})}
    response = lambda_function.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 201
    assert "Lista criada" in body["message"]
    assert "item" in body
    mock_table.put_item.assert_called_once()


def test_invalid_json():
    lambda_function, _ = _import_lambda_with_mocked_aws()

    event = {"body": "{invalid json}"}
    response = lambda_function.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 400
    assert "JSON inválido" in body["error"]


def test_missing_user_id():
    lambda_function, _ = _import_lambda_with_mocked_aws()

    event = {"body": json.dumps({"name": "Lista sem user_id"})}
    response = lambda_function.lambda_handler(event, None)

    assert response["statusCode"] == 400


def test_missing_name():
    lambda_function, _ = _import_lambda_with_mocked_aws()

    event = {"body": json.dumps({"user_id": "123"})}
    response = lambda_function.lambda_handler(event, None)

    assert response["statusCode"] == 400
