import pymysql
import openpyxl
from openpyxl.styles import Font, Alignment, Border, Side, PatternFill
import io
from fastapi.responses import Response
from datetime import datetime, timedelta
import calendar

import os
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    return pymysql.connect(
        host=os.getenv('DB_HOST', '127.0.0.1'),
        user=os.getenv('DB_USERNAME', 'root'),
        password=os.getenv('DB_PASSWORD', ''),
        database=os.getenv('DB_DATABASE', 'bitar_pms'),
        cursorclass=pymysql.cursors.DictCursor
    )

def generate_export(start_date: str, end_date: str, generator_id: int = None):
    start_dt = datetime.strptime(start_date, '%Y-%m-%d')
    end_dt = datetime.strptime(end_date, '%Y-%m-%d')
    delta = (end_dt - start_dt).days + 1

    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Get generators
            if generator_id:
                cursor.execute("SELECT id, name, capacity_kva, fuel_capacity, expected_fuel_consumption_per_hour FROM generators WHERE id = %s ORDER BY id", (generator_id,))
            else:
                cursor.execute("SELECT id, name, capacity_kva, fuel_capacity, expected_fuel_consumption_per_hour FROM generators ORDER BY id")
            generators = cursor.fetchall()
            
            # Fetch all logs for the date range
            if generator_id:
                cursor.execute("SELECT * FROM daily_logs WHERE date >= %s AND date <= %s AND generator_id = %s ORDER BY id ASC", (start_date, end_date, generator_id))
            else:
                cursor.execute("SELECT * FROM daily_logs WHERE date >= %s AND date <= %s ORDER BY id ASC", (start_date, end_date))
            logs = cursor.fetchall()
    finally:
        conn.close()

    # Group logs by date and generator_id
    logs_by_date_gen = {}
    for log in logs:
        date_str = log['date'].strftime('%Y-%m-%d')
        if date_str not in logs_by_date_gen:
            logs_by_date_gen[date_str] = {}
        logs_by_date_gen[date_str][log['generator_id']] = log

    wb = openpyxl.Workbook()
    
    # Border style
    thin_border = Border(left=Side(style='thin'), right=Side(style='thin'), top=Side(style='thin'), bottom=Side(style='thin'))
    header_fill = PatternFill(start_color="DDDDDD", end_color="DDDDDD", fill_type="solid")
    
    # Create sheets for each date in range
    for day_index in range(delta):
        current_dt = start_dt + timedelta(days=day_index)
        date_str = current_dt.strftime('%Y-%m-%d')
        sheet_title = current_dt.strftime('%b-%d')
        
        if day_index == 0:
            ws = wb.active
            ws.title = sheet_title
        else:
            ws = wb.create_sheet(title=sheet_title)
        
        # Grid layout: 4 columns, 4 rows of generators
        for idx, gen in enumerate(generators):
            row_idx = (idx // 4) * 7 + 1
            col_idx = (idx % 4) * 6 + 1
            
            log = logs_by_date_gen.get(date_str, {}).get(gen['id'])
            
            # Row 1: Generator Name
            cell = ws.cell(row=row_idx, column=col_idx, value=gen['name'])
            cell.font = Font(bold=True)
            ws.merge_cells(start_row=row_idx, start_column=col_idx, end_row=row_idx, end_column=col_idx+4)
            
            # Row 2: Headers
            headers = ['CAPACITE :', 'APPRO', '', 'CONS', 'L/H']
            for i, header in enumerate(headers):
                c = ws.cell(row=row_idx+1, column=col_idx+i, value=header)
                c.border = thin_border
                c.fill = header_fill
            
            # Row 3: Values
            capacity_text = f"{gen['capacity_kva']} KVA/{gen['fuel_capacity']} L"
            added_fuel = "" # Not currently in DB, leave blank for 'APPRO'
            
            if log:
                cons_fuel = log['ml_predicted_fuel_burn'] if log['ml_predicted_fuel_burn'] is not None else 0
                if log['admin_actual_fuel'] is not None:
                    cons_fuel = log['admin_actual_fuel']
                lh_rate = log['calculated_hours_worked']
                if lh_rate > 0:
                    lh = cons_fuel / lh_rate
                else:
                    lh = 0
                vals = [capacity_text, added_fuel, '', round(cons_fuel, 2), round(lh, 2)]
            else:
                vals = [capacity_text, added_fuel, '', '', '']
                
            for i, val in enumerate(vals):
                c = ws.cell(row=row_idx+2, column=col_idx+i, value=val)
                c.border = thin_border
            
            # Row 4: HEURE COUNT
            c1 = ws.cell(row=row_idx+3, column=col_idx, value='HEURE COUNT')
            c1.border = thin_border
            c1.fill = header_fill
            c2 = ws.cell(row=row_idx+3, column=col_idx+1, value=log['submitted_hours'] if log else '')
            c2.border = thin_border
            ws.merge_cells(start_row=row_idx+3, start_column=col_idx+1, end_row=row_idx+3, end_column=col_idx+2)
            
            # Row 5: TOTAL GAZOIL
            c1 = ws.cell(row=row_idx+4, column=col_idx, value='TOTAL GAZOIL')
            c1.border = thin_border
            c1.fill = header_fill
            c2 = ws.cell(row=row_idx+4, column=col_idx+1, value=round(cons_fuel, 2) if log else '')
            c2.border = thin_border
            ws.merge_cells(start_row=row_idx+4, start_column=col_idx+1, end_row=row_idx+4, end_column=col_idx+2)
            
            # Adjust column widths
            ws.column_dimensions[openpyxl.utils.get_column_letter(col_idx)].width = 15
            ws.column_dimensions[openpyxl.utils.get_column_letter(col_idx+1)].width = 10
            ws.column_dimensions[openpyxl.utils.get_column_letter(col_idx+2)].width = 10
            ws.column_dimensions[openpyxl.utils.get_column_letter(col_idx+3)].width = 10
            ws.column_dimensions[openpyxl.utils.get_column_letter(col_idx+4)].width = 10

    # ── D.B Sheet ────────────────────────────────────────────────────────────
    # Master aggregator: sums fuel used & hours worked per generator across all days
    # Mirrors the original =SUM('31-05:29'!D5) 3D-reference pattern
    ws_db = wb.create_sheet(title='D.B')

    # Style helpers
    db_header_fill  = PatternFill(start_color="FFD966", end_color="FFD966", fill_type="solid")  # Yellow
    db_data_fill    = PatternFill(start_color="FFF2CC", end_color="FFF2CC", fill_type="solid")  # Light yellow
    db_ratio_fill   = PatternFill(start_color="D9EAD3", end_color="D9EAD3", fill_type="solid")  # Light green
    db_title_font   = Font(bold=True, size=11)
    db_center       = Alignment(horizontal='center', vertical='center')

    # Title row
    c = ws_db.cell(row=1, column=1, value=f"D.B -- Aggregated Summary ({start_date} to {end_date})")
    c.font = Font(bold=True, size=14)
    ws_db.merge_cells(start_row=1, start_column=1, end_row=1, end_column=4)
    ws_db.row_dimensions[1].height = 24

    # Column headers row 2
    for col, hdr in enumerate(['BATIMENT', 'Carburant Consommé (L)', 'Compteur (H)', 'Ratio (L/H)'], 1):
        c = ws_db.cell(row=2, column=col, value=hdr)
        c.font = db_title_font
        c.fill = db_header_fill
        c.border = thin_border
        c.alignment = db_center

    ws_db.column_dimensions['A'].width = 28
    ws_db.column_dimensions['B'].width = 22
    ws_db.column_dimensions['C'].width = 18
    ws_db.column_dimensions['D'].width = 14

    # Get the list of all daily sheet names (for the 3D-style reference comment)
    if delta > 0:
        first_sheet = start_dt.strftime('%b-%d')
        last_sheet  = (start_dt + timedelta(days=delta - 1)).strftime('%b-%d')
    else:
        first_sheet = last_sheet = start_dt.strftime('%b-%d')

    # Pre-compute per-generator totals from Python data (equivalent to 3D SUM)
    db_row = 3
    for gen in generators:
        gen_logs = [log for log in logs if log['generator_id'] == gen['id']]

        # Total fuel consumed
        total_fuel = 0.0
        for log in gen_logs:
            if log['admin_actual_fuel'] is not None:
                total_fuel += float(log['admin_actual_fuel'])
            elif log['ml_predicted_fuel_burn'] is not None:
                total_fuel += float(log['ml_predicted_fuel_burn'])

        # Total hours worked
        total_hours = sum(float(log['calculated_hours_worked'] or 0) for log in gen_logs)

        # Write generator name
        c_name = ws_db.cell(row=db_row, column=1, value=gen['name'])
        c_name.font = Font(bold=True)
        c_name.border = thin_border
        c_name.fill = db_data_fill

        # Fuel total
        c_fuel = ws_db.cell(row=db_row, column=2, value=round(total_fuel, 2))
        c_fuel.border = thin_border
        c_fuel.fill = db_data_fill
        c_fuel.number_format = '#,##0.00'

        # Hours total
        c_hours = ws_db.cell(row=db_row, column=3, value=round(total_hours, 2))
        c_hours.border = thin_border
        c_hours.fill = db_data_fill
        c_hours.number_format = '#,##0.00'

        # Ratio formula: =B{row}/C{row}  (mirrors C2=B2/B3 pattern)
        c_ratio = ws_db.cell(row=db_row, column=4,
                             value=f"=IF(C{db_row}>0, B{db_row}/C{db_row}, 0)")
        c_ratio.border = thin_border
        c_ratio.fill = db_ratio_fill
        c_ratio.number_format = '#,##0.00'
        c_ratio.font = Font(italic=True)

        # Add a small comment showing which sheets were summed (mirrors the 3D ref)
        c_fuel.comment = None  # skip openpyxl comment (requires extra lib)

        db_row += 1

    # Totals row
    total_row = db_row
    c_tot_lbl = ws_db.cell(row=total_row, column=1, value="TOTAL")
    c_tot_lbl.font = Font(bold=True)
    c_tot_lbl.border = thin_border
    c_tot_lbl.fill = db_header_fill

    c_tot_fuel = ws_db.cell(row=total_row, column=2, value=f"=SUM(B3:B{total_row-1})")
    c_tot_fuel.font = Font(bold=True)
    c_tot_fuel.border = thin_border
    c_tot_fuel.fill = db_header_fill
    c_tot_fuel.number_format = '#,##0.00'

    c_tot_hrs = ws_db.cell(row=total_row, column=3, value=f"=SUM(C3:C{total_row-1})")
    c_tot_hrs.font = Font(bold=True)
    c_tot_hrs.border = thin_border
    c_tot_hrs.fill = db_header_fill
    c_tot_hrs.number_format = '#,##0.00'

    c_tot_ratio = ws_db.cell(row=total_row, column=4,
                              value=f"=IF(C{total_row}>0, B{total_row}/C{total_row}, 0)")
    c_tot_ratio.font = Font(bold=True, italic=True)
    c_tot_ratio.border = thin_border
    c_tot_ratio.fill = db_header_fill
    c_tot_ratio.number_format = '#,##0.00'

    # Note explaining 3D reference origin
    note_row = total_row + 2
    ws_db.cell(row=note_row, column=1,
               value=f"Source: Daily sheets [{first_sheet} → {last_sheet}] — equivalent to =SUM('{first_sheet}:{last_sheet}'!cell)")
    ws_db.cell(row=note_row, column=1).font = Font(italic=True, color="888888", size=9)

    # ── BARRIMAGE sheet ───────────────────────────────────────────────────────
    ws_barr = wb.create_sheet(title='BARRIMAGE')
    headers = [
        'BATIMENT', 
        'NORMAL CONSOMMATION PAR HEURE', 
        'Quantite Carburant Consommée (L)',
        'COMPTEUR (H)', 
        'MOYENNE DE CONSOMATTION (L/H)', 
        'QUANTITE CARBURANT NORMAL (L)', 
        'DIFF CARBURANT SURPLUS (L)', 
        'VALEUR SURPLUS (CFA)', 
        'DIFF CARBURANT MANQUANT (L)', 
        'VALEUR MANQUANT (CFA)'
    ]
    for col_idx, header in enumerate(headers, 1):
        c = ws_barr.cell(row=1, column=col_idx, value=header)
        c.font = Font(bold=True)
        c.fill = header_fill
        c.border = thin_border
        ws_barr.column_dimensions[openpyxl.utils.get_column_letter(col_idx)].width = 25
    
    # Calculate monthly aggregates per generator
    row_idx = 2
    for gen in generators:
        gen_logs = [log for log in logs if log['generator_id'] == gen['id']]
        
        total_hours = sum(log['calculated_hours_worked'] for log in gen_logs)
        total_fuel = 0
        for log in gen_logs:
            if log['admin_actual_fuel'] is not None:
                total_fuel += log['admin_actual_fuel']
            elif log['ml_predicted_fuel_burn'] is not None:
                total_fuel += log['ml_predicted_fuel_burn']
                
        normal_cons = float(gen['expected_fuel_consumption_per_hour'] or 0)
        
        # Excel formulas based on row index
        avg_lh_formula = f"=IF(D{row_idx}>0, C{row_idx}/D{row_idx}, 0)"
        expected_fuel_formula = f"=D{row_idx}*B{row_idx}"
        surplus_l_formula = f"=IF((F{row_idx}-C{row_idx})>0, F{row_idx}-C{row_idx}, 0)"
        surplus_cfa_formula = f"=G{row_idx}*1200"
        manquant_l_formula = f"=IF((F{row_idx}-C{row_idx})<0, C{row_idx}-F{row_idx}, 0)"
        manquant_cfa_formula = f"=I{row_idx}*1200"
        
        vals = [
            gen['name'],
            normal_cons,
            round(total_fuel, 2),
            round(total_hours, 2),
            avg_lh_formula,
            expected_fuel_formula,
            surplus_l_formula,
            surplus_cfa_formula,
            manquant_l_formula,
            manquant_cfa_formula
        ]
        
        for col_idx, val in enumerate(vals, 1):
            c = ws_barr.cell(row=row_idx, column=col_idx, value=val)
            c.border = thin_border
            
            # Add some styling for formula columns to match image
            if col_idx == 2 or col_idx == 5: # Light green
                c.fill = PatternFill(start_color="D9EAD3", end_color="D9EAD3", fill_type="solid")
            elif col_idx == 3 or col_idx == 4 or col_idx == 6: # Light orange
                c.fill = PatternFill(start_color="FCE5CD", end_color="FCE5CD", fill_type="solid")
            elif col_idx == 7: # Yellow
                c.fill = PatternFill(start_color="FFFF00", end_color="FFFF00", fill_type="solid")
            elif col_idx == 8 or col_idx == 1: # Light blue
                c.fill = PatternFill(start_color="C9DAF8", end_color="C9DAF8", fill_type="solid")
            elif col_idx == 9: # Grey
                c.fill = PatternFill(start_color="D9D9D9", end_color="D9D9D9", fill_type="solid")
            elif col_idx == 10: # Dark blue
                c.fill = PatternFill(start_color="A4C2F4", end_color="A4C2F4", fill_type="solid")
            
        row_idx += 1

    # Totals Row
    c = ws_barr.cell(row=row_idx, column=1, value="TOTAL")
    c.font = Font(bold=True)
    c.alignment = Alignment(horizontal='right')
    
    for col_idx, letter in zip(range(3, 11), ['C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']):
        if letter == 'E': # Moyenne De Consommation is not summed usually, maybe average? Or sum?
            formula = f"=IF(D{row_idx}>0, C{row_idx}/D{row_idx}, 0)"
        else:
            formula = f"=SUM({letter}2:{letter}{row_idx-1})"
        
        c = ws_barr.cell(row=row_idx, column=col_idx, value=formula)
        c.font = Font(bold=True)
        c.border = thin_border
        
    # Red Box: DIFFERENCE SURPLUS/MANQUANT
    red_fill = PatternFill(start_color="FF0000", end_color="FF0000", fill_type="solid")
    c_title = ws_barr.cell(row=5, column=12, value="DIFFERENCE SURPLUS/MANQUANT")
    c_title.font = Font(bold=True, color="FFFFFF")
    c_title.fill = red_fill
    c_title.border = thin_border
    ws_barr.column_dimensions['L'].width = 30
    
    c_val = ws_barr.cell(row=6, column=12, value=f"=H{row_idx}-J{row_idx}") # Total Surplus (H) - Total Manquant (J)
    c_val.font = Font(bold=True)
    c_val.border = thin_border
    c_val.alignment = Alignment(horizontal='right')

    output = io.BytesIO()
    wb.save(output)
    output.seek(0)
    
    headers = {
        'Content-Disposition': f'attachment; filename="export_{start_date}_to_{end_date}.xlsx"',
        'Access-Control-Expose-Headers': 'Content-Disposition'
    }
    return Response(
        content=output.getvalue(), 
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
        headers=headers
    )
