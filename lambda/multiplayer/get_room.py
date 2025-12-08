import json
import os
import boto3
import decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])


###############################################################################


class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            if o % 1 > 0:
                return float(o)
            return int(o)
        return super(DecimalEncoder, self).default(o)


###############################################################################


def handler(event, context):
    room_code = event['pathParameters']['code']
    
    response = table.get_item(Key={'roomCode': room_code})
    room = response.get('Item')
    
    if not room:
        return build_response(404, {'error': 'Room not found'})
    
    return build_response(200, room)


###############################################################################


def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }

