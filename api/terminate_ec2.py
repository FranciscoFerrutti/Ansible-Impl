import json
import boto3
import os

def terminate_ec2_handler(event, context):
    """
    Lambda function to terminate an EC2 instance.
    """
    try:
        event_body = json.loads(event.get('body', '{}'))
        # Check if the required parameters are provided in the event body
        instance_id = event_body.get('instance_id')

        if not instance_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Instance ID is required'
                })
            }

        # Load configuration from environment variables
        region = os.environ['AWS_REGION']
        
        # Create an EC2 client
        ec2_client = boto3.client('ec2', region_name=region)
        
        # Terminate the EC2 instance
        response = ec2_client.terminate_instances(
            InstanceIds=[instance_id]
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'EC2 instance terminated successfully',
                'instance_id': instance_id,
                'termination_state': response['TerminatingInstances'][0]['CurrentState']['Name']
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': str(e)
            })
        }

