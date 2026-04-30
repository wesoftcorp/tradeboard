import sqlite3
import os

db_path = 'db/tradeboard3.db'
backup_path = 'db/tradeboard3.db.bak'

print(f"Checking integrity of {db_path}...")
try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("PRAGMA integrity_check;")
    result = cursor.fetchone()
    print(f"Integrity check result: {result}")
    conn.close()
except Exception as e:
    print(f"Error checking integrity: {e}")

# Try to recover if possible
def recover_db(path):
    print(f"Attempting to recover {path}...")
    try:
        # Create a backup first
        import shutil
        shutil.copy2(path, backup_path)
        print(f"Backup created at {backup_path}")
        
        # Simple recovery via iterdump
        new_db_path = 'db/tradeboard3_recovered.db'
        con = sqlite3.connect(path)
        with open('db/recovered.sql', 'w', encoding='utf-8') as f:
            for line in con.iterdump():
                f.write('%s\n' % line)
        con.close()
        
        if os.path.exists(new_db_path):
            os.remove(new_db_path)
            
        con_new = sqlite3.connect(new_db_path)
        with open('db/recovered.sql', 'r', encoding='utf-8') as f:
            sql = f.read()
            con_new.executescript(sql)
        con_new.close()
        print(f"Recovery successful! New DB at {new_db_path}")
        return True
    except Exception as e:
        print(f"Recovery failed: {e}")
        return False

if result and result[0] != 'ok':
    recover_db(db_path)
