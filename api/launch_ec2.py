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
        subnet_id = event_body.get('subnet_id')

        if not instance_type or not subnet_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Missing required parameters: instance_type and subnet_id are required.'
                })
            }

        # Load configuration from environment variables
        region = os.environ['AWS_REGION']
        ami_id = os.environ['AMI_ID']
        subnet_1_id = os.environ.get('SUBNET_1_ID', None)
        subnet_2_id = os.environ.get('SUBNET_2_ID', None)
        subnet_3_id = os.environ.get('SUBNET_3_ID', None)

        key_name_map = {
            subnet_1_id: 'web1',
            subnet_2_id: 'web2',
            subnet_3_id: 'web3'
        }

        # Validate the subnet ID
        if subnet_id not in [subnet_1_id, subnet_2_id, subnet_3_id]:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': f'Invalid subnet_id. Must be one of: {subnet_1_id}, {subnet_2_id}, {subnet_3_id}.'
                })
            }
        
        # Get the key name based on the subnet ID
        key_name = key_name_map.get(subnet_id)
        if not key_name:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': f'No key name configured for subnet_id: {subnet_id}.'
                })
            }
        
        security_group_map = {
            subnet_1_id: os.environ.get('SECURITY_GROUP_1_ID'),
            subnet_2_id: os.environ.get('SECURITY_GROUP_2_ID'),
            subnet_3_id: os.environ.get('SECURITY_GROUP_3_ID')
        }

        # Get the security group ID based on the subnet ID
        security_group_id = security_group_map.get(subnet_id)
        if not security_group_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': f'No security group configured for subnet_id: {subnet_id}.'
                })
            }

        # Create an EC2 client
        ec2_client = boto3.client('ec2', region_name=region)
        
        # Launch the EC2 instance
        response = ec2_client.run_instances(
            ImageId=ami_id,
            InstanceType=instance_type,
            KeyName=key_name,
            SubnetId=subnet_id,
            MinCount=1,
            MaxCount=1,
            SecurityGroupIds=[security_group_id],
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

        # Add ec2 instance to the specified target group for load balancing
        target_group_arn = os.environ.get('TARGET_GROUP_ARN')

        if target_group_arn:
            elbv2_client = boto3.client('elbv2', region_name=region)
            private_ip = response['Instances'][0]['PrivateIpAddress']
            elbv2_client.register_targets(
                TargetGroupArn=target_group_arn,
                Targets=[{'Id': private_ip, 'Port': 80, 'AvailabilityZone': 'all'}]
            )
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'TARGET_GROUP_ARN environment variable is not set.'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'EC2 instance launched successfully',
                'instance_id': response['Instances'][0]['InstanceId'],
                'instance_public_ip': response['Instances'][0].get('PublicIpAddress', 'N/A'),
                'instance_private_ip': response['Instances'][0]['PrivateIpAddress']
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': str(e)
            })
        }
