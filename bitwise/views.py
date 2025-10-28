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