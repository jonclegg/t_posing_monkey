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


###############################################################################


class HighScoreInfraStack(Stack):
    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

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
            removal_policy=RemovalPolicy.DESTROY,
        )

        game_rooms_table = dynamodb.Table(
            self, "GameRoomsTable",
            partition_key=dynamodb.Attribute(
                name="roomCode",
                type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY,
            time_to_live_attribute="expiresAt"
        )

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

        create_room_lambda = _lambda.Function(
            self, "CreateRoomFunction",
            runtime=_lambda.Runtime.PYTHON_3_9,
            code=_lambda.Code.from_asset("lambda/multiplayer"),
            handler="create_room.handler",
            environment={
                "TABLE_NAME": game_rooms_table.table_name
            },
            timeout=Duration.seconds(10)
        )

        get_room_lambda = _lambda.Function(
            self, "GetRoomFunction",
            runtime=_lambda.Runtime.PYTHON_3_9,
            code=_lambda.Code.from_asset("lambda/multiplayer"),
            handler="get_room.handler",
            environment={
                "TABLE_NAME": game_rooms_table.table_name
            },
            timeout=Duration.seconds(10)
        )

        update_room_lambda = _lambda.Function(
            self, "UpdateRoomFunction",
            runtime=_lambda.Runtime.PYTHON_3_9,
            code=_lambda.Code.from_asset("lambda/multiplayer"),
            handler="update_room.handler",
            environment={
                "TABLE_NAME": game_rooms_table.table_name
            },
            timeout=Duration.seconds(10)
        )

        delete_room_lambda = _lambda.Function(
            self, "DeleteRoomFunction",
            runtime=_lambda.Runtime.PYTHON_3_9,
            code=_lambda.Code.from_asset("lambda/multiplayer"),
            handler="delete_room.handler",
            environment={
                "TABLE_NAME": game_rooms_table.table_name
            },
            timeout=Duration.seconds(10)
        )

        high_score_table.grant_read_data(get_scores_lambda)
        high_score_table.grant_read_write_data(save_score_lambda)

        game_rooms_table.grant_read_write_data(create_room_lambda)
        game_rooms_table.grant_read_data(get_room_lambda)
        game_rooms_table.grant_read_write_data(update_room_lambda)
        game_rooms_table.grant_read_write_data(delete_room_lambda)

        api = apigateway.RestApi(
            self, "HighScoreApi",
            rest_api_name="High Score API",
            description="API for managing game high scores and multiplayer rooms"
        )

        scores_resource = api.root.add_resource("scores")
        scores_resource.add_method("GET", apigateway.LambdaIntegration(get_scores_lambda))
        scores_resource.add_method("POST", apigateway.LambdaIntegration(save_score_lambda))

        rooms_resource = api.root.add_resource("rooms")
        rooms_resource.add_method("POST", apigateway.LambdaIntegration(create_room_lambda))

        room_resource = rooms_resource.add_resource("{code}")
        room_resource.add_method("GET", apigateway.LambdaIntegration(get_room_lambda))
        room_resource.add_method("PUT", apigateway.LambdaIntegration(update_room_lambda))
        room_resource.add_method("DELETE", apigateway.LambdaIntegration(delete_room_lambda))

        cdk.CfnOutput(self, "ApiUrl", value=api.url)


###############################################################################


app = cdk.App()
HighScoreInfraStack(app, "HighScoreInfra")
app.synth() 