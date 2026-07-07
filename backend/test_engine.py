import requests
import json

response = requests.post(
    'http://localhost:5000/analyze/daily', 
    json={'generator_id': 3, 'date': '2026-06-29'}
)
print(response.text)
