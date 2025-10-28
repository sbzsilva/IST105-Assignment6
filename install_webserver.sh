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