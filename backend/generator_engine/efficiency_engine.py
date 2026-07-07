def calculate_efficiency(generator, reading):
    running_hours = float(reading.get('running_hours') or 0)
    kwh_produced = float(reading.get('kwh_produced') or 0)
    actual_fuel = float(reading.get('estimated_fuel_used') or 0)
    
    # Efficiency is typically measured in kWh per Liter of fuel
    # Or Liter per Hour. 
    # Let's calculate a percentage based on ideal baseline
    
    baseline_per_kwh = float(generator.get('expected_fuel_consumption_per_kwh') or 0.3)
    
    if kwh_produced > 0 and actual_fuel > 0:
        actual_per_kwh = actual_fuel / kwh_produced
        # If actual_per_kwh is 0.3 and baseline is 0.3 -> 100%
        # If actual_per_kwh is 0.4 and baseline is 0.3 -> (0.3 / 0.4) * 100 = 75%
        efficiency = (baseline_per_kwh / actual_per_kwh) * 100
        return min(round(efficiency, 2), 100.0) # Cap at 100%
        
    if running_hours > 0 and actual_fuel > 0:
        baseline_per_hour = float(generator.get('expected_fuel_consumption_per_hour') or 10.0)
        actual_per_hour = actual_fuel / running_hours
        efficiency = (baseline_per_hour / actual_per_hour) * 100
        return min(round(efficiency, 2), 100.0)
        
    return 100.0 # Default if no data to prove otherwise
