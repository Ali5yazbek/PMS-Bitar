import pymysql
import json

conn = pymysql.connect(host='localhost', user='root', password='', database='bitar_pms', cursorclass=pymysql.cursors.DictCursor)
with conn.cursor() as c:
    c.execute("SELECT * FROM daily_logs LIMIT 5")
    rows = c.fetchall()
    for r in rows:
        r['date'] = str(r['date'])
        r['created_at'] = str(r['created_at'])
    print(json.dumps(rows, indent=2))
