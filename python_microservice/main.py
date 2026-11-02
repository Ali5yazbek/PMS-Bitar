import os
from typing import List, Optional
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
from google import genai
from datetime import datetime
import json
import io
from fastapi.responses import Response
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Generator Management API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration for Gemini API
# Make sure to set GEMINI_API_KEY in your environment variables
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "YOUR_DEFAULT_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

class DailyLogSubmission(BaseModel):
    generator_id: int
    submission_date: str
    submitted_hours: float
    previous_day_hours: Optional[float] = None
    calculated_hours_worked: Optional[float] = None  # Pre-computed by PHP decision tree
    input_method: Optional[str] = 'Meter Only'       # 'Hours Only', 'Meter Only', 'Both', 'Both (Mismatch)'
    factory_burn_rate_per_hour: float
    # Tank & Fuel fields
    previous_tank_level: Optional[float] = None      # Tank level at start of day
    fuel_added_today: Optional[float] = 0.0          # Fuel deliveries received today
    agent_reported_tank: Optional[float] = None      # Physical tank reading by agent
    fuel_price_per_liter: Optional[float] = 850.0    # CFA per liter (default 850)
    historical_logs: List[dict] = []

@app.post("/api/v1/generator/analyze")
async def analyze_generator_log(submission: DailyLogSubmission):
    try:
        input_method = submission.input_method or 'Meter Only'

        # ── Step 1: Determine Real Run Time ──────────────────────────────────
        if submission.calculated_hours_worked is not None:
            hours_worked_today = float(submission.calculated_hours_worked)
            is_baseline = (hours_worked_today == 0)
        else:
            is_baseline = False
            if submission.previous_day_hours is None or submission.previous_day_hours == 0 \
               or submission.previous_day_hours == submission.submitted_hours:
                is_baseline = True
                hours_worked_today = 0.0
            else:
                hours_worked_today = submission.submitted_hours - submission.previous_day_hours

        if hours_worked_today < 0:
            raise HTTPException(status_code=400, detail="Submitted hours cannot be less than previous day hours.")
        if hours_worked_today > 24:
            raise HTTPException(status_code=400, detail="A single day cannot exceed 24 hours. Invalid meter reading.")

        # ── Step 2: Resolve fuel values ───────────────────────────────────────
        previous_tank   = submission.previous_tank_level if submission.previous_tank_level is not None else 800.0
        fuel_added      = submission.fuel_added_today or 0.0
        agent_tank      = submission.agent_reported_tank  # None if not reported
        fuel_price      = submission.fuel_price_per_liter or 850.0
        consumption_rate = submission.factory_burn_rate_per_hour

        agent_tank_display = agent_tank if agent_tank is not None else "NOT_PROVIDED"

        system_prompt = f"""
SYSTEM ROLE:
You are an expert Enterprise Generator & Fuel Management AI Engine. Your job is to analyze daily generator logs, calculate fuel burn rates, integrate fuel deliveries, and detect theft or mechanical anomalies (The "VOL" Flag) based on strict mathematical rules.

=== LIVE INPUT DATA ===
Input Method Used: {input_method}
Previous Meter Hours: {submission.previous_day_hours}
Current Meter Hours: {submission.submitted_hours}
Pre-Calculated Run Time (by system): {hours_worked_today} hours
Factory Consumption Rate: {consumption_rate} L/h
Previous Tank Level: {previous_tank} L
Fuel Added Today (Refills): {fuel_added} L
Agent Reported Current Tank: {agent_tank_display}
Fuel Price Per Liter: {fuel_price} CFA/L

=== SYSTEM RULES & LOGIC ===

STEP 1: DETERMINE REAL RUN TIME
- Trust the Pre-Calculated Run Time of {hours_worked_today} hours already computed by the system.
- If Input Method is "Both (Mismatch)": Immediately flag vol_theft_alert=true, error_type="DATA_ENTRY_MISMATCH".
- IF Run Time > 24 hours: Return status "error" with error_type "RUNTIME_EXCEEDS_24H".
- IF Run Time == 0: This is a BASELINE SETUP. Set all fuel fields to 0, no anomaly.

STEP 2: THE ESTIMATES (THE BASELINE)
- Estimated Fuel Spent = Run Time * Factory Consumption Rate = {hours_worked_today} * {consumption_rate}
- Estimated Tank Remaining = (Previous Tank Level + Fuel Added Today) - Estimated Fuel Spent = ({previous_tank} + {fuel_added}) - Estimated Fuel Spent

STEP 3: THE ACTUALS & VARIANCE
If Agent Reported Current Tank is NOT "NOT_PROVIDED":
- Actual Fuel Spent = (Previous Tank Level + Fuel Added Today) - Agent Reported Current Tank = ({previous_tank} + {fuel_added}) - {agent_tank_display}
- Actual Consumption Rate (L/h) = Actual Fuel Spent / Run Time
- Missing Fuel Variance (Liters) = Actual Fuel Spent - Estimated Fuel Spent
- Financial Loss = Missing Fuel Variance * {fuel_price} (ONLY if variance > 0)
If Agent Reported Current Tank is "NOT_PROVIDED":
- Set actual_fuel_spent_l = null, actual_consumption_rate_lh = null, missing_fuel_variance_l = 0.0, financial_loss_amount = 0.0

STEP 4: THE "VOL" ANOMALY THRESHOLD
- IF Actual Consumption Rate > Factory Consumption Rate by more than 5%: Set vol_theft_alert = true
- IF Actual Fuel Spent is massively lower than expected (>5% extra fuel remaining): Flag "SENSOR_ERROR_OR_UNRECORDED_REFILL" in ai_diagnosis_message
- IF Input Method is "Both (Mismatch)": Set vol_theft_alert = true, error_type = "DATA_ENTRY_MISMATCH"

=== REQUIRED JSON OUTPUT FORMAT ===
Respond STRICTLY in valid JSON. No markdown. No extra text. Exact keys:
{{
  "status": "success" | "error",
  "engine_run_time_hours": float,
  "estimated_fuel_spent_l": float,
  "estimated_remaining_tank_l": float,
  "actual_fuel_spent_l": float or null,
  "actual_consumption_rate_lh": float or null,
  "missing_fuel_variance_l": float,
  "financial_loss_amount": float,
  "vol_theft_alert": boolean,
  "ai_diagnosis_message": "string"
}}
"""
        response = client.models.generate_content(
            model='gemini-3.5-flash',
            contents=system_prompt,
        )

        # Clean up markdown formatting if present
        raw_text = response.text.strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:]
        if raw_text.startswith("```"):
            raw_text = raw_text[3:]
        if raw_text.endswith("```"):
            raw_text = raw_text[:-3]

        try:
            ai_result = json.loads(raw_text.strip())
        except json.JSONDecodeError:
            raise HTTPException(status_code=500, detail=f"Failed to parse AI response as JSON. Raw: {raw_text[:200]}")

        # Map new schema back to frontend-compatible response
        return {
            "status": "success" if ai_result.get("status") == "success" else "error",
            "metrics": {
                "hours_worked_today":        ai_result.get("engine_run_time_hours", 0.0),
                "expected_fuel_burn_factory": ai_result.get("estimated_fuel_spent_l", 0.0),
                "ml_predicted_fuel_burn":    None,  # Requires kWh data — not available
                "predicted_remaining_fuel":  ai_result.get("estimated_remaining_tank_l", 0.0),
                "actual_fuel_spent":         ai_result.get("actual_fuel_spent_l"),
                "actual_consumption_rate":   ai_result.get("actual_consumption_rate_lh"),
                "missing_fuel_variance":     ai_result.get("missing_fuel_variance_l", 0.0),
                "financial_loss_cfa":        ai_result.get("financial_loss_amount", 0.0),
                "anomaly_detected":          ai_result.get("vol_theft_alert", False),
                "vol_theft_alert":           ai_result.get("vol_theft_alert", False),
            },
            "ai_report": ai_result.get("ai_diagnosis_message", "Analysis complete.")
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



@app.post("/api/v1/generator/import")
async def import_legacy_data(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        xls = pd.ExcelFile(io.BytesIO(contents))
        
        # 1. Parse Baselines
        if 'BARRIMAGE' not in xls.sheet_names:
            raise HTTPException(status_code=400, detail="Sheet 'BARRIMAGE' not found in the excel file.")
            
        barrimage_df = pd.read_excel(xls, sheet_name='BARRIMAGE')
        
        generators = []
        for index, row in barrimage_df.iterrows():
            if pd.notna(row.get('Batiment')) and pd.notna(row.get('Normal_Cons_LH')):
                generators.append({
                    "name": str(row['Batiment']).strip(),
                    "factory_burn_rate_per_hour": float(row['Normal_Cons_LH'])
                })
        
        # 2. Parse Daily Logs
        daily_logs = []
        sheet_names = [s for s in xls.sheet_names if s.isdigit()] # Sheets '1' to '30'
        
        for sheet in sheet_names:
            df = pd.read_excel(xls, sheet_name=sheet)
            
            for index, row in df.iterrows():
                generator_name = str(row.get('Batiment', '')).strip()
                hours = row.get('HEURE COUNT', 0)
                fuel = row.get('TOTAL GAZOIL', 0)
                
                # 4. Data Cleaning Rule
                if pd.isna(hours) or hours < 0:
                    if generator_name == "C.MODERNE" and hours == -2491.24:
                        continue # Ignore known anomaly
                    if hours < 0:
                        continue # Ignore other negative hours as per rule

                if generator_name and not pd.isna(hours):
                    daily_logs.append({
                        "generator_name": generator_name,
                        "date": f"2026-06-{int(sheet):02d}", # Assuming JUIN 2026
                        "submitted_hours": float(hours),
                        "fuel_used": float(fuel) if not pd.isna(fuel) else 0.0
                    })

        return {
            "status": "success",
            "data": {
                "generators": generators,
                "daily_logs": daily_logs
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


from export_utils import generate_export
from typing import Optional

@app.get("/api/v1/generator/export")
async def export_data(start_date: str, end_date: str, generator_id: Optional[int] = None):
    return generate_export(start_date, end_date, generator_id)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
