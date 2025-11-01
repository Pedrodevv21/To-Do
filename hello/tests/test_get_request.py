import json
from unittest.mock import patch, MagicMock
from hello.hello_lambda.get_request import lambda_handler

@patch("hello.hello_lambda.get_request.ses", new_callable=MagicMock)
@patch("hello.hello_lambda.get_request.s3", new_callable=MagicMock)
@patch("hello.hello_lambda.get_request.table", new_callable=MagicMock)
@patch("hello.hello_lambda.get_request.tempfile.NamedTemporaryFile")
def test_lambda_handler_success(mock_tempfile, mock_table, mock_s3, mock_ses):
    sqs_event = {"Records": [{"body": json.dumps({"user_id": "123"})}]}

    mock_table.query.return_value = {
        "Items": [{"PK": "USER#123", "SK": "TODO#1", "title": "Task", "completed": False}]
    }

    mock_s3.upload_file.return_value = None
    mock_s3.generate_presigned_url.return_value = "https://s3.presigned.url/test.csv"
    mock_ses.send_email.return_value = {"MessageId": "fake-msg-id"}

    mock_file = MagicMock()
    mock_file.__enter__.return_value.name = "/tmp/fake.csv"
    mock_tempfile.return_value = mock_file

    response = lambda_handler(sqs_event, None)
    body = json.loads(response["body"])

    assert response["statusCode"] == 200
    assert "Processamento concluído" in body["message"]
    mock_table.query.assert_called_once()
    mock_s3.upload_file.assert_called_once()
    mock_s3.generate_presigned_url.assert_called_once()
    mock_ses.send_email.assert_called_once()

def test_lambda_handler_invalid_message():
    event = {"Records": [{"body": "{}"}]}
    response = lambda_handler(event, None)
    body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert "Processamento concluído" in body["message"]

def test_lambda_handler_no_items():
    event = {"Records": [{"body": json.dumps({"user_id": "999"})}]}
    with patch("hello.hello_lambda.get_request.table") as mock_table:
        mock_table.query.return_value = {"Items": []}
        response = lambda_handler(event, None)
        body = json.loads(response["body"])
        assert response["statusCode"] == 200
        assert "Processamento concluído" in body["message"]

def test_lambda_handler_exception():
    event = {"Records": [{"body": json.dumps({"user_id": "123"})}]}
    with patch("hello.hello_lambda.get_request.table") as mock_table:
        mock_table.query.side_effect = Exception("Erro simulado")
        response = lambda_handler(event, None)
        body = json.loads(response["body"])
        assert response["statusCode"] == 500
        assert "Erro simulado" in body["error"]
