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