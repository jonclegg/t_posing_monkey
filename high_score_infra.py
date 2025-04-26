#!/usr/bin/env python3
import aws_cdk as cdk
from aws_cdk import (
    aws_dynamodb as dynamodb,
    aws_lambda as _lambda,
    aws_apigateway as apigateway,
    Stack,
    RemovalPolicy,
    Duration
)
from constructs import Construct

class HighScoreInfraStack(Stack):
    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Create DynamoDB table
        high_score_table = dynamodb.Table(
            self, "HighScoreTable",
            partition_key=dynamodb.Attribute(
                name="id",
                type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="score",
                type=dynamodb.AttributeType.NUMBER
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY,  # Use RETAIN for production
        )
        
        # Create Lambda function for getting high scores
        get_scores_lambda = _lambda.Function(
            self, "GetHighScoresFunction",
            runtime=_lambda.Runtime.PYTHON_3_9,
            code=_lambda.Code.from_asset("lambda"),
            handler="get_scores.handler",
            environment={
                "TABLE_NAME": high_score_table.table_name
            },
            timeout=Duration.seconds(10)
        )
        
        # Create Lambda function for saving high scores
        save_score_lambda = _lambda.Function(
            self, "SaveHighScoreFunction",
            runtime=_lambda.Runtime.PYTHON_3_9,
            code=_lambda.Code.from_asset("lambda"),
            handler="save_score.handler",
            environment={
                "TABLE_NAME": high_score_table.table_name
            },
            timeout=Duration.seconds(10)
        )
        
        # Grant permissions to Lambda functions
        high_score_table.grant_read_data(get_scores_lambda)
        high_score_table.grant_read_write_data(save_score_lambda)
        
        # Create API Gateway
        api = apigateway.RestApi(
            self, "HighScoreApi",
            rest_api_name="High Score API",
            description="API for managing game high scores"
        )
        
        # Add resources and methods
        scores_resource = api.root.add_resource("scores")
        
        # GET /scores
        scores_resource.add_method(
            "GET",
            apigateway.LambdaIntegration(get_scores_lambda)
        )
        
        # POST /scores
        scores_resource.add_method(
            "POST",
            apigateway.LambdaIntegration(save_score_lambda)
        )

        # Output the API URL
        cdk.CfnOutput(
            self, "ApiUrl",
            value=api.url
        )

app = cdk.App()
HighScoreInfraStack(app, "HighScoreInfra")
app.synth() 