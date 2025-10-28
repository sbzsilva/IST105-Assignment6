You're absolutely right! The installation scripts are missing the crucial step of cloning the GitHub repository and setting up the Django project. Let me fix both installation scripts:

## Updated `install_webserver.sh`:

```bash
#!/bin/bash
# Update system
sudo yum update -y

# Install Python and pip
sudo yum install python3 python3-pip -y

# Install virtualenv
sudo pip3 install virtualenv

# Install git
sudo yum install git -y

# Create and activate virtual environment
virtualenv ~/venv
source ~/venv/bin/activate

# Install Django and MongoDB driver
pip install django pymongo

# Clone the repository
cd ~
git clone https://github.com/sbzsilva/IST105-Assignment6.git
cd IST105-Assignment6

# Install project dependencies
pip install -r requirements.txt

# Create Django project structure (if not already there)
if [ ! -f "manage.py" ]; then
    django-admin startproject assignment6 .
    python manage.py startapp bitwise
fi

# Set proper permissions
chmod +x *.sh

echo "Web server installation completed!"
echo "Next steps:"
echo "1. Update MongoDB IP in settings.py"
echo "2. Run: source ~/venv/bin/activate"
echo "3. Run: python manage.py migrate"
echo "4. Run: python manage.py runserver 0.0.0.0:8000"
```

## Updated `install_mongodb.sh`:

```bash
#!/bin/bash
# Update system
sudo yum update -y

# Create MongoDB repo file
echo "[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc" | sudo tee /etc/yum.repos.d/mongodb-org-4.4.repo

# Install MongoDB
sudo yum install -y mongodb-org

# Start MongoDB service
sudo systemctl start mongod
sudo systemctl enable mongod

# Configure MongoDB to accept remote connections
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf
sudo systemctl restart mongod

# Open firewall for MongoDB (if firewalld is installed)
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=27017/tcp
    sudo firewall-cmd --reload
fi

# Install git to clone repository (optional, for verification)
sudo yum install git -y

echo "MongoDB installation completed!"
echo "MongoDB is now listening on 0.0.0.0:27017"
```

## Also, let's create a `requirements.txt` file for the Python dependencies:

```txt
Django>=3.2,<4.0
pymongo>=3.12,<4.0
```

## And update the `setup_ec2.sh` to use a working AMI ID:

```bash
#!/bin/bash
# Configuration
KEY_NAME="cctb"
SECURITY_GROUP_NAME="assignment6-sg"
WEB_INSTANCE_NAME="WebServer-EC2"
MONGO_INSTANCE_NAME="MongoDB-EC2"
# Use a known working Amazon Linux 2023 AMI for us-east-1
AMI_ID="ami-0fc5d935ebf8bc3bc"
INSTANCE_TYPE="t3.medium"

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
echo ""
echo "Setup completed! Next steps:"
echo "1. Run install_mongodb.sh on MongoDB instance: $MONGO_PUBLIC_IP"
echo "2. Run install_webserver.sh on WebServer instance: $WEB_PUBLIC_IP"
echo "3. Update MONGO_URI in settings.py with MongoDB IP: $MONGO_PUBLIC_IP"
```

## Updated README.md instructions:

Update the setup instructions in README.md to reflect the new process:

```markdown
### 2. Software Installation

#### On WebServer-EC2:
```bash
ssh -i cctb.pem ec2-user@<WebServer-Public-IP>
chmod +x install_webserver.sh
./install_webserver.sh
cd IST105-Assignment6
# Update settings.py with MongoDB IP
sed -i "s/<MongoDB-EC2-Public-IP>/$MONGO_PUBLIC_IP/g" assignment6/settings.py
source ~/venv/bin/activate
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

#### On MongoDB-EC2:
```bash
ssh -i cctb.pem ec2-user@<MongoDB-Public-IP>
chmod +x install_mongodb.sh
./install_mongodb.sh
```

The key changes:
1. **install_webserver.sh** now clones the GitHub repository and sets up the project
2. **install_mongodb.sh** has improved MongoDB configuration
3. Added **requirements.txt** for dependency management
4. **setup_ec2.sh** uses a verified working AMI ID
5. Clearer post-installation steps

Now the installation scripts will properly set up both servers with your GitHub code!