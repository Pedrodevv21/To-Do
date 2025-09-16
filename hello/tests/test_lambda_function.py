import json
import pytest
from hello.hello_lambda.lambda_function import lambda_handler

def test_lambda_handler_returns_hello_world():
    event = {}
    context = None
    response = lambda_handler(event, context)
    
    assert response['statusCode'] == 200
    assert json.loads(response['body']) == 'Hello World!'
