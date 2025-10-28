# Number Processing Application with Bitwise Operations

This is a Django web application that processes numerical inputs using various mathematical and bitwise operations, storing the results in a MongoDB database. The application provides a simple web interface for entering numbers and viewing processed results.

## Application Overview

The application takes five numerical inputs from the user and performs the following operations:
- Identifies negative values in the input
- Calculates the average of all numbers
- Determines if the average is above 50
- Counts positive numbers and checks if the count is even or odd using bitwise operations
- Filters values greater than 10 and sorts them
- Stores all results in a MongoDB database

## Project Structure

```
├── setup_ec2.sh                 # Script to create EC2 instances on AWS
├── install_webserver.sh         # Script to install software on WebServer
├── install_mongodb.sh           # Script to install MongoDB
├── requirements.txt             # Python dependencies
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

## Core Components

### Frontend Interface
A clean, responsive web interface built with HTML and CSS that allows users to:
- Input five numerical values
- Submit the values for processing
- View the results of various calculations
- See warnings for negative values

### Backend Processing
The Django backend performs several operations on the input data:
- **Negative Value Detection**: Checks if any input values are negative
- **Average Calculation**: Computes the mean of all input values
- **Threshold Comparison**: Determines if the average is greater than 50
- **Bitwise Even/Odd Check**: Uses bitwise operations to determine if the count of positive numbers is even or odd
- **Filtering and Sorting**: Filters values greater than 10 and sorts them in ascending order

### Database Storage
Processed results are stored in a MongoDB database with the following structure:
```json
{
  "input": [/* Original input values */],
  "result": {
    "original": [/* Copy of input values */],
    "filtered": [/* Values > 10, sorted */],
    "average": /* Calculated average */,
    "avg_above_50": /* Boolean */,
    "positive_count": /* Count of positive numbers */,
    "is_even": /* Boolean result of bitwise check */,
    "has_negative": /* Boolean */
  }
}
```

## Installation and Deployment

### Prerequisites
- AWS Account with CLI access configured
- SSH key pair for EC2 instances

### Automated Deployment
1. Run the `setup_ec2.sh` script to create two EC2 instances:
   - One for the Django web application
   - One for the MongoDB database

2. Install software on each instance:
   - Execute `install_webserver.sh` on the web server instance
   - Execute `install_mongodb.sh` on the database instance

3. Update the MongoDB connection string in [assignment6/settings.py](file:///c:/Users/ssilva/college/IST105-Assignment6/assignment6/settings.py) with the database instance's IP address

4. Run the Django application:
   ```bash
   python manage.py migrate
   python manage.py runserver 0.0.0.0:8000
   ```

## Technical Details

### Bitwise Operation Implementation
The application uses a bitwise AND operation to efficiently determine if the count of positive numbers is even or odd:
```python
is_even = (positive_count & 1) == 0
```

This approach is more efficient than using modulo operation and demonstrates low-level bit manipulation.

### Data Flow
1. User submits five numbers through the web form
2. Server-side validation ensures all inputs are valid floats
3. Calculations are performed on the input data
4. Results are formatted and stored in MongoDB
5. Results are displayed to the user through the web interface

## Dependencies
- Python 3.x
- Django 3.2+
- PyMongo 3.12+
- MongoDB 4.4