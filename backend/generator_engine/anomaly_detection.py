def detect_anomalies(generator, reading, fuel_metrics, efficiency):
    anomalies = []
    
    # 1. Fuel Difference (Significant discrepancy between expected and actual)
    if fuel_metrics['difference'] > (fuel_metrics['expected_fuel'] * 0.2):
        anomalies.append({
            'type': 'Significant Fuel Difference',
            'severity': 'Critical',
            'message': f"Actual fuel consumption is {fuel_metrics['difference']}L higher than the system estimate."
        })
    elif fuel_metrics['difference'] > (fuel_metrics['expected_fuel'] * 0.1):
        anomalies.append({
            'type': 'Moderate Fuel Difference',
            'severity': 'High',
            'message': f"Actual fuel consumption is {fuel_metrics['difference']}L higher than the system estimate."
        })
        
    # 2. Efficiency Drop
    if efficiency < 70:
        anomalies.append({
            'type': 'Low Efficiency',
            'severity': 'High',
            'message': f"Generator efficiency has dropped to {efficiency}%."
        })
        
    # 3. Abnormal Running Hours
    running_hours = float(reading.get('running_hours') or 0)
    if running_hours > 24:
        anomalies.append({
            'type': 'Abnormal Readings',
            'severity': 'Critical',
            'message': f"Running hours ({running_hours}h) exceeds 24 hours in a single day."
        })
        
    # 4. Maintenance Due
    meter_hours = float(reading.get('meter_hours') or 0)
    maintenance_interval = float(generator.get('maintenance_interval_hours') or 250)
    last_maintenance = float(generator.get('last_maintenance_hours') or 0)
    
    if (meter_hours - last_maintenance) >= maintenance_interval:
        anomalies.append({
            'type': 'Maintenance Overdue',
            'severity': 'High',
            'message': f"Generator is overdue for maintenance by {(meter_hours - last_maintenance) - maintenance_interval} hours."
        })
        
    return anomalies
