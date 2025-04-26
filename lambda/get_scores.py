import json
import os
import boto3
import decimal
from boto3.dynamodb.conditions import Key

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

# Helper class to convert Decimal to int/float for JSON serialization
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            if o % 1 > 0:
                return float(o)
            else:
                return int(o)
        return super(DecimalEncoder, self).default(o)

def handler(event, context):
    try:
        # Get query parameters
        query_params = event.get('queryStringParameters', {}) or {}
        limit = int(query_params.get('limit', 10))
        
        if limit < 1 or limit > 100:
            return build_response(400, {'error': 'Limit must be between 1 and 100'})
            
        # Query high scores (ordered by score descending)
        response = table.scan(Limit=limit)
        items = response.get('Items', [])
        
        # Sort by score (descending)
        items.sort(key=lambda x: x.get('score', 0), reverse=True)
        items = items[:limit]
        
        return build_response(200, {'scores': items})
    except Exception as e:
        return build_response(500, {'error': str(e)})

def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    } 