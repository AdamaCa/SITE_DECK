import psycopg2
import psycopg2.extras

def connect():
  conn = psycopg2.connect(
    dbname = 'cshamaloow',
    host = 'localhost',
    password = 'Camaraa77100.',
    cursor_factory = psycopg2.extras.NamedTupleCursor
  )
  conn.autocommit = True
  return conn
