from flask import Flask, request, jsonify
import mysql.connector
from datetime import datetime

# Import custom engine modules
import fuel_analysis
import efficiency_engine
import prediction_engine
import anomaly_detection
import health_score_engine

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'bitar_pms'
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

@app.route('/analyze/daily', methods=['POST'])
def analyze_daily():
    data = request.json
    generator_id = data.get('generator_id')
    date = data.get('date', datetime.now().strftime('%Y-%m-%d'))
    
    if not generator_id:
        return jsonify({'error': 'generator_id is required'}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # Fetch generator details and baseline
        cursor.execute("SELECT * FROM generators WHERE id = %s", (generator_id,))
        generator = cursor.fetchone()
        
        # Fetch the reading for the date
        cursor.execute("SELECT * FROM generator_daily_reports WHERE generator_id = %s AND date = %s", (generator_id, date))
        reading = cursor.fetchone()
        
        if not reading:
            return jsonify({'error': 'No reading found for this date'}), 404
            
        # --- 1. Fuel Analysis ---
        fuel_metrics = fuel_analysis.analyze_fuel(generator, reading)
        
        # --- 2. Efficiency Engine ---
        efficiency = efficiency_engine.calculate_efficiency(generator, reading)
        
        # --- 3. Health Score ---
        health_score = health_score_engine.calculate_score(generator, reading, efficiency)
        
        # --- 4. Anomaly Detection ---
        anomalies = anomaly_detection.detect_anomalies(generator, reading, fuel_metrics, efficiency)
        
        # Save Analysis
        cursor.execute("""
            INSERT INTO generator_analysis 
            (generator_id, reading_date, expected_fuel, actual_fuel, fuel_difference, efficiency, health_score, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'Analyzed')
            ON DUPLICATE KEY UPDATE
            expected_fuel = VALUES(expected_fuel),
            actual_fuel = VALUES(actual_fuel),
            fuel_difference = VALUES(fuel_difference),
            efficiency = VALUES(efficiency),
            health_score = VALUES(health_score),
            status = 'Analyzed',
            created_at = NOW()
        """, (
            generator_id, date, 
            fuel_metrics['expected_fuel'], 
            fuel_metrics['actual_fuel'], 
            fuel_metrics['difference'], 
            efficiency, 
            health_score
        ))
        
        # Save Alerts/Anomalies
        # First clear previous alerts for this date to avoid duplicates
        cursor.execute("DELETE FROM generator_alerts WHERE generator_id = %s AND DATE(created_at) = %s", (generator_id, date))
        
        for anomaly in anomalies:
            cursor.execute("""
                INSERT INTO generator_alerts (generator_id, alert_type, severity, message)
                VALUES (%s, %s, %s, %s)
            """, (generator_id, anomaly['type'], anomaly['severity'], anomaly['message']))
        
        conn.commit()
        
        return jsonify({
            'status': 'success',
            'analysis': {
                'fuel_metrics': fuel_metrics,
                'efficiency': efficiency,
                'health_score': health_score
            },
            'anomalies_detected': len(anomalies)
        })
        
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/analyze/predict', methods=['POST'])
def predict_future():
    data = request.json
    generator_id = data.get('generator_id')
    
    if not generator_id:
        return jsonify({'error': 'generator_id is required'}), 400

    conn = get_db_connection()
    try:
        # Pass connection to prediction engine to load historical data
        predictions = prediction_engine.run_predictions(conn, generator_id)
        
        # Save predictions
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO generator_predictions 
            (generator_id, prediction_date, predicted_fuel, predicted_cost, predicted_remaining_days, predicted_efficiency)
            VALUES (%s, CURDATE(), %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
            predicted_fuel = VALUES(predicted_fuel),
            predicted_cost = VALUES(predicted_cost),
            predicted_remaining_days = VALUES(predicted_remaining_days),
            predicted_efficiency = VALUES(predicted_efficiency)
        """, (
            generator_id, 
            predictions['predicted_fuel_tomorrow'],
            predictions['predicted_cost_tomorrow'],
            predictions['remaining_days'],
            predictions['predicted_efficiency']
        ))
        conn.commit()
        
        return jsonify({
            'status': 'success',
            'predictions': predictions
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
