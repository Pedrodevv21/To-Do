import unittest
import json
from lambda_function import lambda_handler

class TestLambdaFunction(unittest.TestCase):
    def test_lambda_handler_returns_hello_world(self):
        event = {}
        context = None

        response = lambda_handler(event, context)

        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(json.loads(response['body']), 'Hello World!')

if __name__ == '__main__':
    unittest.main()
