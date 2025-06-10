import json
import boto3
import os

def launch_ec2_handler(event, context):
    """
    Lambda function to launch an EC2 instance.
    """
    try:

        event_body = json.loads(event.get('body', '{}'))
        # Check if the required parameters are provided in the event body
        instance_type = event_body.get('instance_type')
        key_name = event_body.get('key_name')

        # Load configuration from environment variables
        region = os.environ['AWS_REGION']
        ami_id = os.environ['AMI_ID']
        
        # Create an EC2 client
        ec2_client = boto3.client('ec2', region_name=region)
        
        # Launch the EC2 instance
        response = ec2_client.run_instances(
            ImageId=ami_id,
            InstanceType=instance_type,
            KeyName=key_name,
            MinCount=1,
            MaxCount=1,
            TagSpecifications=[
                {
                    'ResourceType': 'instance',
                    'Tags': [
                        {
                            'Key': 'Name',
                            'Value': key_name
                        }
                    ]
                }
            ]
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'EC2 instance launched successfully',
                'instance_id': response['Instances'][0]['InstanceId'],
                'instance_public_ip': response['Instances'][0].get('PublicIpAddress', 'N/A'),
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': str(e)
            })
        }
    
