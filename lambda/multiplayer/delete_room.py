import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])


###############################################################################


def handler(event, context):
    room_code = event['pathParameters']['code']
    
    table.delete_item(Key={'roomCode': room_code})
    
    return build_response(200, {'message': 'Room deleted'})


###############################################################################


def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }

