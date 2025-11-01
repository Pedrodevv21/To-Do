import os
os.environ["SQS_QUEUE_URL"] = "https://sqs.us-east-1.amazonaws.com/123456789012/test-queue"

import json
import pytest
from unittest.mock import patch, MagicMock
from hello.hello_lambda.post_request import lambda_handler


@patch("hello.hello_lambda.post_request.sqs.send_message")
@patch("hello.hello_lambda.post_request.uuid.uuid4", return_value="fake-uuid-123")
def test_lambda_handler_success(mock_uuid, mock_send_message):
    event = {"body": json.dumps({"user": "joao", "action": "criar"})}
    mock_send_message.return_value = {"MessageId": "abc123"}

    response = lambda_handler(event, None)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["message"] == "Sua solicitação foi recebida. Estamos processando-a."
    assert body["request_id"] == "fake-uuid-123"

    mock_uuid.assert_called_once()
    mock_send_message.assert_called_once_with(
        QueueUrl=os.environ["SQS_QUEUE_URL"],
        MessageBody=json.dumps({
            "id": "fake-uuid-123",
            "request": {"user": "joao", "action": "criar"}
        })
    )


@patch("hello.hello_lambda.post_request.sqs.send_message", side_effect=Exception("Erro ao enviar SQS"))
def test_lambda_handler_send_message_error(mock_send_message):
    event = {"body": json.dumps({"data": "teste"})}

    response = lambda_handler(event, None)
    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert "Erro ao enviar SQS" in body["error"]
    mock_send_message.assert_called_once()


@patch("hello.hello_lambda.post_request.sqs.send_message")
def test_lambda_handler_invalid_body(mock_send_message):
    event = {"body": "não é um JSON válido"}

    response = lambda_handler(event, None)
    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert "Expecting value" in body["error"]


@patch("hello.hello_lambda.post_request.sqs.send_message")
@patch("hello.hello_lambda.post_request.uuid.uuid4", return_value="id-teste")
def test_lambda_handler_no_body(mock_uuid, mock_send_message):
    event = {}

    response = lambda_handler(event, None)
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["request_id"] == "id-teste"

    mock_send_message.assert_called_once()
