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