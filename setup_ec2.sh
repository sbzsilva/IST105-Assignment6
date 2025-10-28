#!/bin/bash
# Configuration
KEY_NAME="your-key-pair"  # Replace with your EC2 key pair name
SECURITY_GROUP_NAME="assignment6-sg"
WEB_INSTANCE_NAME="WebServer-EC2"
MONGO_INSTANCE_NAME="MongoDB-EC2"
AMI_ID="ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (us-east-1)
INSTANCE_TYPE="t2.micro"

# Create Security Group
SG_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Assignment6 Security Group" --output text --query 'GroupId')
echo "Created Security Group: $SG_ID"

# Configure Security Group Rules
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0  # SSH
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0  # HTTP
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 8000 --cidr 0.0.0.0/0  # Django
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 27017 --cidr 0.0.0.0/0  # MongoDB

# Launch WebServer Instance
WEB_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$WEB_INSTANCE_NAME}]" \
  --output text --query 'Instances[0].InstanceId')

# Launch MongoDB Instance
MONGO_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$MONGO_INSTANCE_NAME}]" \
  --output text --query 'Instances[0].InstanceId')

echo "WebServer Instance ID: $WEB_INSTANCE_ID"
echo "MongoDB Instance ID: $MONGO_INSTANCE_ID"

# Wait for instances to be running
aws ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID $MONGO_INSTANCE_ID

# Get Public IPs
WEB_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $WEB_INSTANCE_ID --output text --query 'Reservations[0].Instances[0].PublicIpAddress')
MONGO_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $MONGO_INSTANCE_ID --output text --query 'Reservations[0].Instances[0].PublicIpAddress')

echo "WebServer Public IP: $WEB_PUBLIC_IP"
echo "MongoDB Public IP: $MONGO_PUBLIC_IP"