import json
import os

import boto3

lambda_client = boto3.client("lambda")
codedeploy = boto3.client("codedeploy")


def handler(event, context):
    status = "Failed"
    try:
        resp = lambda_client.invoke(
            FunctionName=os.environ["TARGET_FUNCTION"],
            Payload=json.dumps({"queryStringParameters": {"productId": "1"}}),
        )
        if json.load(resp["Payload"]).get("statusCode") == 200:
            status = "Succeeded"
    except Exception:
        pass
    codedeploy.put_lifecycle_event_hook_execution_status(
        deploymentId=event["DeploymentId"],
        lifecycleEventHookExecutionId=event["LifecycleEventHookExecutionId"],
        status=status,
    )
