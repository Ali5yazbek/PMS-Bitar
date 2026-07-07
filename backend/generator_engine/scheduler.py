import time
import schedule
import requests
import mysql.connector
from datetime import datetime

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'bitar_pms'
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

def run_nightly_predictions():
    print(f"[{datetime.now()}] Running nightly predictions...")
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # Get all active generators
        cursor.execute("SELECT id FROM generators")
        generators = cursor.fetchall()
        
        for gen in generators:
            generator_id = gen['id']
            # Call the prediction endpoint internally or via HTTP
            try:
                response = requests.post('http://localhost:5000/analyze/predict', json={'generator_id': generator_id}, timeout=10)
                if response.status_code == 200:
                    print(f"Successfully ran predictions for Generator {generator_id}")
                else:
                    print(f"Failed predictions for Generator {generator_id}: {response.text}")
            except Exception as e:
                print(f"Error calling predict for Generator {generator_id}: {str(e)}")
                
    except Exception as e:
        print(f"Error in nightly prediction job: {str(e)}")
    finally:
        cursor.close()
        conn.close()

# Schedule the job to run every day at 1 AM
schedule.every().day.at("01:00").do(run_nightly_predictions)

# For demonstration purposes, run it once immediately on startup
run_nightly_predictions()

if __name__ == "__main__":
    print("Scheduler started. Waiting for jobs...")
    while True:
        schedule.run_pending()
        time.sleep(60)
