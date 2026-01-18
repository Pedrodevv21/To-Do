import json
import os
import sys
from unittest.mock import MagicMock, patch

os.environ["SQS_QUEUE_URL"] = "https://sqs.us-east-1.amazonaws.com/123456789012/test-queue"


def _import_lambda_with_mocked_aws():
    mock_boto3 = MagicMock()
    mock_sqs = MagicMock()

    mock_boto3.client.return_value = mock_sqs

    with patch.dict(sys.modules, {"boto3": mock_boto3}):
        import hello.lambdas.post_request as post_request

    return post_request, mock_sqs


def test_lambda_handler_success():
    post_request, mock_sqs = _import_lambda_with_mocked_aws()

    mock_sqs.send_message.return_value = {"MessageId": "abc123"}

    with patch.object(post_request.uuid, "uuid4", return_value="fake-uuid-123"):
        event = {"body": json.dumps({"user": "joao", "action": "criar"})}
        response = post_request.lambda_handler(event, None)

    body = json.loads(response["body"])

    assert response["statusCode"] == 200
    assert body["message"] == "Sua solicitação foi recebida. Estamos processando-a."
    assert body["request_id"] == "fake-uuid-123"

    mock_sqs.send_message.assert_called_once_with(
        QueueUrl=os.environ["SQS_QUEUE_URL"],
        MessageBody=json.dumps({
            "id": "fake-uuid-123",
            "request": {"user": "joao", "action": "criar"}
        })
    )


def test_lambda_handler_send_message_error():
    post_request, mock_sqs = _import_lambda_with_mocked_aws()

    mock_sqs.send_message.side_effect = Exception("Erro ao enviar SQS")

    event = {"body": json.dumps({"data": "teste"})}
    response = post_request.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 500
    assert "Erro ao enviar SQS" in body["error"]
    mock_sqs.send_message.assert_called_once()


def test_lambda_handler_invalid_body():
    post_request, mock_sqs = _import_lambda_with_mocked_aws()

    event = {"body": "não é um JSON válido"}
    response = post_request.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 500
    assert "Expecting value" in body["error"]
    mock_sqs.send_message.assert_not_called()


def test_lambda_handler_no_body():
    post_request, mock_sqs = _import_lambda_with_mocked_aws()

    with patch.object(post_request.uuid, "uuid4", return_value="id-teste"):
        event = {}
        response = post_request.lambda_handler(event, None)

    body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert body["request_id"] == "id-teste"
    mock_sqs.send_message.assert_called_once()
