

Based on the assignment requirements, I'll provide a comprehensive step-by-step guide with commands and scripts to complete this project. The solution includes AWS setup scripts, Django application files, and MongoDB configuration.

### 1. AWS EC2 Setup Scripts

#### `setup_ec2.sh` (Creates EC2 instances)
```bash
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
```

### 2. Software Installation Scripts

#### `install_webserver.sh` (Run on WebServer-EC2)
```bash
#!/bin/bash
# Update system
sudo yum update -y

# Install Python and pip
sudo yum install python3 python3-pip -y

# Install virtualenv
sudo pip3 install virtualenv

# Create and activate virtual environment
virtualenv venv
source venv/bin/activate

# Install Django and MongoDB driver
pip install django pymongo

# Install git
sudo yum install git -y

# Create project directory
mkdir -p ~/assignment6
cd ~/assignment6
```

#### `install_mongodb.sh` (Run on MongoDB-EC2)
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
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
sudo systemctl restart mongod

# Open firewall for MongoDB
sudo firewall-cmd --permanent --add-port=27017/tcp
sudo firewall-cmd --reload
```

### 3. Django Application Files

#### `assignment6/settings.py` (Partial configuration)
```python
# Add to INSTALLED_APPS
INSTALLED_APPS = [
    ...
    'bitwise',
]

# Add to bottom of file
# MongoDB Configuration
MONGO_URI = 'mongodb://<MongoDB-EC2-Public-IP>:27017/'
MONGO_DB = 'assignment6_db'
```

#### `bitwise/forms.py`
```python
from django import forms

class NumberForm(forms.Form):
    a = forms.FloatField(label='Number a', required=True)
    b = forms.FloatField(label='Number b', required=True)
    c = forms.FloatField(label='Number c', required=True)
    d = forms.FloatField(label='Number d', required=True)
    e = forms.FloatField(label='Number e', required=True)
```

#### `bitwise/views.py`
```python
from django.shortcuts import render
from .forms import NumberForm
from pymongo import MongoClient
from django.conf import settings

def index(request):
    form = NumberForm()
    result = None
    error = None
    
    if request.method == 'POST':
        form = NumberForm(request.POST)
        if form.is_valid():
            # Get form data
            data = form.cleaned_data
            numbers = [data['a'], data['b'], data['c'], data['d'], data['e']]
            
            # Check for negative values
            has_negative = any(num < 0 for num in numbers)
            
            # Calculate average
            average = sum(numbers) / len(numbers)
            avg_above_50 = average > 50
            
            # Count positive numbers and check parity with bitwise
            positive_count = sum(1 for num in numbers if num > 0)
            is_even = (positive_count & 1) == 0  # Bitwise AND to check even/odd
            
            # Create filtered list (>10) and sort
            filtered = [num for num in numbers if num > 10]
            filtered.sort()
            
            # Prepare result dictionary
            result = {
                'original': numbers,
                'filtered': filtered,
                'average': round(average, 2),
                'avg_above_50': avg_above_50,
                'positive_count': positive_count,
                'is_even': is_even,
                'has_negative': has_negative
            }
            
            # Save to MongoDB
            try:
                client = MongoClient(settings.MONGO_URI)
                db = client[settings.MONGO_DB]
                collection = db['results']
                
                document = {
                    'input': numbers,
                    'result': result
                }
                collection.insert_one(document)
                client.close()
            except Exception as e:
                error = f"Database error: {str(e)}"
        else:
            error = "Invalid input. Please enter valid numbers."
    
    return render(request, 'bitwise/index.html', {
        'form': form, 
        'result': result,
        'error': error
    })
```

#### `bitwise/templates/bitwise/index.html`
```html
<!DOCTYPE html>
<html>
<head>
    <title>Assignment 6 - Data Processing</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; }
        input[type="text"] { width: 100%; padding: 8px; }
        button { background-color: #4CAF50; color: white; padding: 10px 15px; border: none; cursor: pointer; }
        .result { margin-top: 30px; padding: 15px; background-color: #f0f0f0; border-radius: 5px; }
        .error { color: red; margin-top: 10px; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>Number Processing Application</h1>
    
    <form method="post">
        {% csrf_token %}
        <div class="form-group">
            {{ form.a.label_tag }} {{ form.a }}
        </div>
        <div class="form-group">
            {{ form.b.label_tag }} {{ form.b }}
        </div>
        <div class="form-group">
            {{ form.c.label_tag }} {{ form.c }}
        </div>
        <div class="form-group">
            {{ form.d.label_tag }} {{ form.d }}
        </div>
        <div class="form-group">
            {{ form.e.label_tag }} {{ form.e }}
        </div>
        <button type="submit">Process Numbers</button>
    </form>
    
    {% if error %}
        <div class="error">{{ error }}</div>
    {% endif %}
    
    {% if result %}
        <div class="result">
            <h2>Processing Results:</h2>
            <p><strong>Original Values:</strong> {{ result.original }}</p>
            <p><strong>Filtered Values (>10):</strong> {{ result.filtered }}</p>
            <p><strong>Average:</strong> {{ result.average }}</p>
            <p><strong>Average > 50:</strong> {{ result.avg_above_50|yesno:"Yes,No" }}</p>
            <p><strong>Count of Positive Numbers:</strong> {{ result.positive_count }}</p>
            <p><strong>Positive Count is Even:</strong> {{ result.is_even|yesno:"Yes,No" }}</p>
            {% if result.has_negative %}
                <p class="warning"><strong>Warning:</strong> Some values are negative!</p>
            {% endif %}
        </div>
    {% endif %}
</body>
</html>
```

#### `bitwise/urls.py`
```python
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
]
```

#### `assignment6/urls.py`
```python
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('bitwise.urls')),
]
```

### 4. Execution Steps

1. **Create EC2 Instances:**
   ```bash
   chmod +x setup_ec2.sh
   ./setup_ec2.sh
   ```
   Note the public IPs for both instances

2. **Install Software on WebServer-EC2:**
   ```bash
   ssh -i your-key-pair.pem ec2-user@<WebServer-Public-IP>
   chmod +x install_webserver.sh
   ./install_webserver.sh
   ```

3. **Install Software on MongoDB-EC2:**
   ```bash
   ssh -i your-key-pair.pem ec2-user@<MongoDB-Public-IP>
   chmod +x install_mongodb.sh
   ./install_mongodb.sh
   ```

4. **Create Django Project on WebServer-EC2:**
   ```bash
   cd ~/assignment6
   source venv/bin/activate
   django-admin startproject assignment6 .
   python manage.py startapp bitwise
   ```

5. **Update Configuration Files:**
   - Replace `<MongoDB-EC2-Public-IP>` in `settings.py` with actual IP
   - Create all Django files as shown above

6. **Run Django Application:**
   ```bash
   python manage.py migrate
   python manage.py runserver 0.0.0.0:8000
   ```

7. **Access Application:**
   - Open browser to `http://<WebServer-Public-IP>:8000`

### 5. GitHub Repository Setup

1. **Initialize Repository:**
   ```bash
   cd ~/assignment6
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. **Create Branches:**
   ```bash
   git branch development
   git branch feature1
   git checkout main
   ```

3. **Connect to GitHub:**
   ```bash
   git remote add origin https://github.com/your-username/IST105-Assignment6.git
   git push -u origin main
   git push origin development
   git push origin feature1
   ```

### 6. Verification Commands

#### On MongoDB-EC2:
```bash
# Check MongoDB service
sudo systemctl status mongod

# Verify data insertion
mongo
use assignment6_db
db.results.find().pretty()
```

#### On WebServer-EC2:
```bash
# Check Django logs
tail -f /var/log/django.log
```

### 7. Submission Requirements

Create a Word document `Assignment6_YourName.docx` containing:
1. GitHub Repository URL: `https://github.com/your-username/IST105-Assignment6`
2. Screenshots:
   - Application running in browser with input and output
   - MongoDB service running on EC2 (`sudo systemctl status mongod`)
   - MongoDB terminal with inserted data (`db.results.find()`)
   - Security group rules for both EC2 instances

This comprehensive solution provides all necessary scripts, configuration files, and commands to successfully complete the assignment. Remember to replace placeholder values (like key pair names, IPs, and GitHub username) with your actual information.