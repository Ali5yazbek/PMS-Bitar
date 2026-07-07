import pandas as pd
from sklearn.linear_model import LinearRegression
import numpy as np

def run_predictions(conn, generator_id):
    # Fetch historical data
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT date, running_hours, kwh_produced, estimated_fuel_used, 
        current_kwh, meter_hours, previous_kwh 
        FROM generator_daily_reports 
        WHERE generator_id = %s AND status = 'Verified' 
        ORDER BY date ASC
    """, (generator_id,))
    
    rows = cursor.fetchall()
    
    # If not enough data, return baseline predictions
    if len(rows) < 3:
        cursor.execute("SELECT expected_fuel_consumption_per_hour, current_fuel FROM generators WHERE id = %s", (generator_id,))
        gen = cursor.fetchone()
        baseline = float(gen.get('expected_fuel_consumption_per_hour') or 10.0)
        current_fuel = float(gen.get('current_fuel') or 0.0)
        
        # Assume average of 8 hours a day for predictions
        return {
            'predicted_fuel_tomorrow': round(baseline * 8, 2),
            'predicted_cost_tomorrow': round(baseline * 8 * 1.5, 2), # Assuming $1.5/L
            'remaining_days': round(current_fuel / (baseline * 8), 1) if baseline > 0 else 0,
            'predicted_efficiency': 100.0
        }
        
    df = pd.DataFrame(rows)
    df['date'] = pd.to_datetime(df['date'])
    df['days_since_start'] = (df['date'] - df['date'].min()).dt.days
    
    # Simple Linear Regression to predict next day's fuel usage based on trend
    X = df[['days_since_start']]
    y = df['estimated_fuel_used']
    
    model = LinearRegression()
    model.fit(X, y)
    
    next_day = df['days_since_start'].max() + 1
    predicted_fuel = model.predict([[next_day]])[0]
    predicted_fuel = max(0, predicted_fuel)
    
    # Cost prediction (hardcoded $1.5 for now, should come from settings)
    predicted_cost = predicted_fuel * 1.5
    
    # Remaining days
    cursor.execute("SELECT current_fuel FROM generators WHERE id = %s", (generator_id,))
    gen = cursor.fetchone()
    current_fuel = float(gen.get('current_fuel') or 0.0)
    
    avg_fuel_usage = df['estimated_fuel_used'].mean()
    remaining_days = current_fuel / avg_fuel_usage if avg_fuel_usage > 0 else 0
    
    # Efficiency trend
    # Avoid div by 0
    df['efficiency'] = np.where(df['running_hours'] > 0, 
                                df['estimated_fuel_used'] / df['running_hours'], 
                                0)
    avg_efficiency_metric = df['efficiency'].mean()
    # Mocking efficiency % based on historical metrics
    predicted_efficiency = max(0, 100 - (avg_efficiency_metric * 10)) # Just a placeholder metric
    
    return {
        'predicted_fuel_tomorrow': round(float(predicted_fuel), 2),
        'predicted_cost_tomorrow': round(float(predicted_cost), 2),
        'remaining_days': round(float(remaining_days), 1),
        'predicted_efficiency': min(100.0, round(float(predicted_efficiency), 2))
    }
