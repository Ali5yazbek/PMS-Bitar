def analyze_fuel(generator, reading):
    baseline_per_hour = float(generator.get('expected_fuel_consumption_per_hour') or 0)
    baseline_per_kwh = float(generator.get('expected_fuel_consumption_per_kwh') or 0)
    
    running_hours = float(reading.get('running_hours') or 0)
    kwh_produced = float(reading.get('kwh_produced') or 0)
    actual_fuel = float(reading.get('estimated_fuel_used') or 0)
    
    # Calculate expected fuel based on what was actually done
    expected_by_hours = running_hours * baseline_per_hour
    expected_by_kwh = kwh_produced * baseline_per_kwh
    
    expected_fuel = expected_by_hours if expected_by_hours > 0 else expected_by_kwh
    
    difference = actual_fuel - expected_fuel
    
    return {
        'expected_fuel': round(expected_fuel, 2),
        'actual_fuel': round(actual_fuel, 2),
        'difference': round(difference, 2),
        'is_over_consuming': difference > (expected_fuel * 0.1) # more than 10% variance
    }
