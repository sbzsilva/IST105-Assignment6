# IST105 Assignment 6

This project involves creating a Django web application that processes number inputs using bitwise operations and stores the results in a MongoDB database, all deployed on AWS EC2 instances.

## Project Structure

```
├── setup_ec2.sh                 # Script to create EC2 instances on AWS
├── install_webserver.sh         # Script to install software on WebServer EC2
├── install_mongodb.sh           # Script to install MongoDB on MongoDB EC2
├── assignment6/                 # Django project
│   ├── settings.py             # Django settings with MongoDB configuration
│   └── urls.py                 # Main URL configuration
├── bitwise/                     # Django application
│   ├── forms.py                # Form definition for number inputs
│   ├── views.py                # View logic for processing numbers
│   ├── urls.py                 # URL configuration for the app
│   └── templates/
│       └── bitwise/
│           └── index.html      # HTML template for the UI
└── README.md                   # This file
```

## Setup Instructions

### 1. AWS EC2 Setup

1. Run the `setup_ec2.sh` script to create two EC2 instances:
   - WebServer-EC2 for the Django application
   - MongoDB-EC2 for the database

```bash
chmod +x setup_ec2.sh
./setup_ec2.sh
```

Note the public IPs for both instances.

### 2. Software Installation

#### On WebServer-EC2:
```bash
ssh -i your-key-pair.pem ec2-user@<WebServer-Public-IP>
chmod +x install_webserver.sh
./install_webserver.sh
```

#### On MongoDB-EC2:
```bash
ssh -i your-key-pair.pem ec2-user@<MongoDB-Public-IP>
chmod +x install_mongodb.sh
./install_mongodb.sh
```

### 3. Django Project Setup

On WebServer-EC2:
```bash
cd ~/assignment6
source venv/bin/activate
django-admin startproject assignment6 .
python manage.py startapp bitwise
```

### 4. Configuration

1. Update `assignment6/settings.py`:
   - Add 'bitwise' to INSTALLED_APPS
   - Configure MongoDB connection with the MongoDB EC2 public IP

2. Create all Django application files as specified.

### 5. Running the Application

```bash
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Access the application at `http://<WebServer-Public-IP>:8000`

### 6. GitHub Repository Setup

```bash
cd ~/assignment6
git init
git add .
git commit -m "Initial commit"
git branch development
git branch feature1
git checkout main
git remote add origin https://github.com/your-username/IST105-Assignment6.git
git push -u origin main
git push origin development
git push origin feature1
```

## Verification

### On MongoDB-EC2:
```bash
# Check MongoDB service
sudo systemctl status mongod

# Verify data insertion
mongo
use assignment6_db
db.results.find().pretty()
```

## Submission Requirements

Create a Word document `Assignment6_YourName.docx` containing:
1. GitHub Repository URL
2. Screenshots:
   - Application running in browser with input and output
   - MongoDB service running on EC2
   - MongoDB terminal with inserted data
   - Security group rules for both EC2 instances