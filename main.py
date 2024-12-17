import time
from flask import Flask, render_template, request, redirect, url_for, session
from random import randint
import db
app = Flask(__name__)

# Clef secrète utilisée pour chiffrer les cookies
app.secret_key = b'e98f5630f3f3f31745404ef51a38a843704259adc60454e1b40e6dc75e6eb772'



@app.route('/')
def index():
    if "username" in session:
        return redirect(url_for('profile'))
    return render_template('index.html', K)

@app.route('/login', methods=['POST'])
def login():
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM joueur WHERE username = %s AND password = %s', (request.form['username'], request.form['password']))
            user = cur.fetchone()
            if user:
                session['username'] = user.username
                return redirect(url_for('profile'))
    return redirect(url_for('index', error='Invalid username or password'))

@app.route('/profile')
def profile():
    if 'username' not in session:
        return redirect(url_for('index'))
    return render_template('profile.html')




























if __name__ == '__main__':
  app.run()
