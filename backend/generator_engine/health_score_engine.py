def calculate_score(generator, reading, efficiency):
    score = 100
    
    # Penalty for low efficiency
    if efficiency < 90:
        score -= (90 - efficiency) * 0.5
        
    if efficiency < 70:
        score -= 20
        
    # Penalty for upcoming maintenance
    running_hours = float(reading.get('meter_hours') or 0)
    maintenance_interval = float(generator.get('maintenance_interval_hours') or 250)
    last_maintenance = float(generator.get('last_maintenance_hours') or 0)
    
    hours_since_maintenance = running_hours - last_maintenance
    
    if hours_since_maintenance > maintenance_interval:
        score -= 30 # Overdue
    elif hours_since_maintenance > (maintenance_interval * 0.9):
        score -= 10 # Due soon
        
    return max(0, int(score))
