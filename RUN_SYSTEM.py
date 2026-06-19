import sys
# This line forces Python to ignore any local folders and use your official Anaconda libraries first!
sys.path.insert(0, r"C:\Users\gphei\anaconda3\Lib\site-packages")

import mysql.connector
import pandas as pd

def connect_to_system():
    """Establishes database connection cleanly."""
    return mysql.connector.connect(
        host="localhost",
        port=@@@@,
        user="root",        
        password="##############", 
        database="aviation_ops"
    )

def fetch_delayed_flights():
    """Queries the operational database for flights currently flagged as delayed."""
    conn = connect_to_system()
    query = """
        SELECT f.flight_id, f.flight_number, f.airline, f.passenger_count, 
               f.arrival_ap, SUM(d.duration_minutes) as total_delay,
               GROUP_CONCAT(d.delay_type) as delay_reasons
        FROM flights f
        JOIN delay_logs d ON f.flight_id = d.flight_id
        WHERE f.flight_status = 'Delayed'
        GROUP BY f.flight_id;
    """
    df = pd.read_sql(query, conn)
    conn.close()
    return df

def calculate_disruption_impact(df):
    """Calculates priority scores for airport resource allocation."""
    if df.empty:
        return df
    scores = []
    for idx, row in df.iterrows():
        base_score = (row['total_delay'] * 1.2) + (row['passenger_count'] * 0.8)
        penalty = 0
        if 'Mechanical' in str(row['delay_reasons']):
            penalty += 50
        if 'Carrier' in str(row['delay_reasons']):
            penalty += 30
        total_score = base_score + penalty
        scores.append(round(total_score, 2))
    df['disruption_impact_score'] = scores
    return df.sort_values(by='disruption_impact_score', ascending=False)

def optimize_gate_allocation():
    """Matches prioritized flights with available airport infrastructure."""
    print("Executing Hub Optimization Analysis...\n")
    
    delayed_df = fetch_delayed_flights()
    
    if delayed_df.empty:
        print("System Check: Found 0 delayed flights in the database.")
        print("[Notice] No delayed flights currently require gate optimization.")
        return
        
    prioritized_flights = calculate_disruption_impact(delayed_df)
    
    print("--- Priority Intervention Queue ---")
    print(prioritized_flights[['flight_number', 'airline', 'total_delay', 'passenger_count', 'disruption_impact_score']])
    
    conn = connect_to_system()
    cursor = conn.cursor()
    cursor.execute("SELECT gate_id FROM gates WHERE airport_code = 'JNB' AND gate_status = 'Available'")
    available_gates = [item[0] for item in cursor.fetchall()]
    
    print(f"\nAvailable Gates Detected at JNB: {available_gates}")
    
    for idx, row in prioritized_flights.iterrows():
        if available_gates:
            assigned_gate = available_gates.pop(0)
            print(f"Action: Directing Flight {row['flight_number']} to critical priority bay: {assigned_gate}")
            
            update_query = "UPDATE flights SET gate_id = %s, flight_status = 'Active' WHERE flight_id = %s"
            flight_id_clean = int(row['flight_id'].item()) if hasattr(row['flight_id'], 'item') else int(row['flight_id'])
            cursor.execute(update_query, (assigned_gate, flight_id_clean))
            
            cursor.execute("UPDATE gates SET gate_status = 'Occupied' WHERE gate_id = %s", (assigned_gate,))
        else:
            print(f"Alert: Infrastructure Bottleneck! No open gates for Flight {row['flight_number']}. Holding pattern required.")
            
    conn.commit()
    cursor.close()
    conn.close()
    print("\nSystem state synchronized with updated operations.")

if __name__ == "__main__":
    optimize_gate_allocation()
