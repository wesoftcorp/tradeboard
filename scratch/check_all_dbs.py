import sqlite3
import os

dbs = [
    'db/tradeboard3.db',
    'db/latency3.db',
    'db/logs3.db'
]

for db_path in dbs:
    if not os.path.exists(db_path):
        print(f"Skipping {db_path} (not found)")
        continue
    
    print(f"Checking {db_path}...")
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("PRAGMA integrity_check;")
        result = cursor.fetchone()
        print(f"Result for {db_path}: {result}")
        conn.close()
    except Exception as e:
        print(f"Error for {db_path}: {e}")

# Check historify.duckdb if possible (requires duckdb)
try:
    import duckdb
    print("Checking db/historify.duckdb...")
    con = duckdb.connect('db/historify.duckdb')
    con.execute("SELECT 1")
    print("Result for historify.duckdb: Success")
    con.close()
except ImportError:
    print("DuckDB not installed, skipping historify check")
except Exception as e:
    print(f"Error for historify.duckdb: {e}")
