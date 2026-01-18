import json
import sys
from unittest.mock import MagicMock, patch


def _import_lambda_with_mocked_aws():
    mock_boto3 = MagicMock()
    mock_dynamodb_resource = MagicMock()
    mock_s3 = MagicMock()
    mock_ses = MagicMock()

    mock_boto3.resource.return_value = mock_dynamodb_resource
    mock_boto3.client.side_effect = lambda service, **_: {
        "s3": mock_s3,
        "ses": mock_ses,
    }[service]

    mock_conditions = MagicMock()
    mock_conditions.Key = MagicMock()

    with patch.dict(
        sys.modules,
        {
            "boto3": mock_boto3,
            "boto3.dynamodb": MagicMock(),
            "boto3.dynamodb.conditions": mock_conditions,
        },
    ):
        from hello.lambdas.get_request import lambda_handler

    return lambda_handler, mock_dynamodb_resource, mock_s3, mock_ses


def test_lambda_handler_success():
    lambda_handler, mock_dynamodb, mock_s3, mock_ses = _import_lambda_with_mocked_aws()

    table = MagicMock()
    mock_dynamodb.Table.return_value = table

    table.query.return_value = {
        "Items": [
            {
                "PK": "USER#123",
                "SK": "TODO#1",
                "title": "Task",
                "completed": False,
            }
        ]
    }

    mock_s3.upload_file.return_value = None
    mock_s3.generate_presigned_url.return_value = "https://s3.presigned.url/test.csv"
    mock_ses.send_email.return_value = {"MessageId": "fake-msg-id"}

    event = {"Records": [{"body": json.dumps({"user_id": "123"})}]}
    response = lambda_handler(event, None)

    body = json.loads(response["body"])

    assert response["statusCode"] == 200
    assert "Processamento concluído" in body["message"]
    mock_s3.upload_file.assert_called_once()
    mock_s3.generate_presigned_url.assert_called_once()
    mock_ses.send_email.assert_called_once()


def test_lambda_handler_invalid_message():
    lambda_handler, *_ = _import_lambda_with_mocked_aws()

    event = {"Records": [{"body": "{}"}]}
    response = lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert "Processamento concluído" in body["message"]


def test_lambda_handler_no_items():
    lambda_handler, mock_dynamodb, *_ = _import_lambda_with_mocked_aws()

    table = MagicMock()
    mock_dynamodb.Table.return_value = table
    table.query.return_value = {"Items": []}

    event = {"Records": [{"body": json.dumps({"user_id": "999"})}]}
    response = lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert "Processamento concluído" in body["message"]


def test_lambda_handler_exception():
    lambda_handler, mock_dynamodb, *_ = _import_lambda_with_mocked_aws()

    table = MagicMock()
    mock_dynamodb.Table.return_value = table
    table.query.side_effect = Exception("Erro simulado")

    event = {"Records": [{"body": json.dumps({"user_id": "123"})}]}
    response = lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert "Processamento concluído" in body["message"]
