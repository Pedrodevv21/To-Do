import os
import sys
from unittest.mock import MagicMock, patch


def _import_lambda_with_mocked_dynamodb(side_effect=None, return_value=None):
    os.environ["DYNAMODB_TABLE"] = "test-table"

    mock_dynamodb = MagicMock()

    if side_effect:
        mock_dynamodb.delete_item.side_effect = side_effect
    else:
        mock_dynamodb.delete_item.return_value = return_value or {}

    with patch("boto3.client", return_value=mock_dynamodb):
        if "hello.lambdas.delete_item" in sys.modules:
            del sys.modules["hello.lambdas.delete_item"]

        from hello.lambdas.delete_item import lambda_handler

    return lambda_handler, mock_dynamodb


def test_delete_item_success():
    lambda_handler, mock_client = _import_lambda_with_mocked_dynamodb(
        return_value={"ResponseMetadata": {"HTTPStatusCode": 200}}
    )

    event = {
        "pathParameters": {
            "pk": "pk-test",
            "sk": "sk-test"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 404
    mock_client.delete_item.assert_called_once()


def test_delete_item_not_found():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb(
        return_value={"ResponseMetadata": {"HTTPStatusCode": 200}}
    )

    event = {
        "pathParameters": {
            "pk": "pk-test",
            "sk": "sk-test"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 404


def test_delete_item_missing_params():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb()

    event = {
        "pathParameters": {
            "pk": "pk-test"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 500


def test_delete_item_dynamodb_exception():
    lambda_handler, _ = _import_lambda_with_mocked_dynamodb(
        side_effect=Exception("Erro DynamoDB")
    )

    event = {
        "pathParameters": {
            "pk": "pk-test",
            "sk": "sk-test"
        }
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 500




