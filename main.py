import time
from flask import Flask, render_template, request, redirect, url_for, session
from random import randint
import db
app = Flask(__name__)

# Clef secrète utilisée pour chiffrer les cookies
app.secret_key = b'e98f5630f3f3f31745404ef51a38a843704259adc60454e1b40e6dc75e6eb772'



@app.route('/')
def index():
    if "username" and "id" in session:
        return redirect(url_for('profile'))
    return render_template('index.html') 

@app.route('/login', methods=['POST'])
def login():
    if 'username' and 'id' in session:
        return redirect(url_for('profile'))
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM joueur WHERE pseudo = %s AND mdp = %s', (request.form['username'], request.form['password']))
            user = cur.fetchone()
            if user:
                session['username'] = user.pseudo
                session['id'] = user.id_joueur
                session["infos_profile"] = user
                print(user)
                print(session["infos_profile"])
                return redirect(url_for('profile'))
    return render_template('index.html', error=True)

@app.route('/profile')
def profile():
    if 'username' and "id" not in session:
        return redirect(url_for('index'))
    print(session["infos_profile"])
    
    #On recupere les 5 dernieres confrontations
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("select id_deck_vainqueur as vd , nom_général as g , id_deck_perdant as pd , date_ as date from confronte as c1 join deck as d2 on c1.id_deck_vainqueur = d2.id_deck or c1.id_deck_perdant = d2.id_deck and d2.id_joueur = %s order by date_ desc limit 5", (session['id'],))
            confrontations = cur.fetchall()
    
    
    #On recupere ses decks
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM deck where id_joueur = %s', (session['id'],))
            decks = cur.fetchall()
            
    return render_template('profile.html', infos=session["infos_profile"], decks=decks, confrontations=confrontations)

@app.route('/collection')
def collection():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM collectionne where id_joueur = %s', (session['id'],))
            cartes = cur.fetchall()
    return render_template('collection.html', cartes=cartes, infos=session["infos_profile"])



 #Permet d'ajouter une carte à la collection aleatoirement
@app.route('/ajout_carte', methods=['POST'])
def ajout_carte():
    
    print(session['id'], session['username'])
    if 'username' not in session:
        return redirect(url_for('index'))

    with db.connect() as conn:
        with conn.cursor() as cur:
            print(session['id'], session['username']
            )
            print("curl")
            #On verifie les fonds du joueur
            cur.execute('SELECT uav FROM joueur WHERE id_joueur = %s', (session['id'],))
            uav = cur.fetchone()[0]
            if uav < 0 :
                return render_template('collection.html', msgerror="Vous n'avez pas assez de fonds pour acheter une carte", error= True, infos=session["infos_profile"])
            
            #On recupeere une cartes parmi celles qu'il n'as pas 
            cur.execute('SELECT * FROM carte where not exists (select 1 from collectionne where collectionne.nom = carte.nom and id_joueur = %s)', (session['id'],))
            cartes = cur.fetchall()
            
            #Si il a toutes les cartes on lui affiche un message d'erreur
            if not cartes:
                return render_template('collection.html', msgerror="Vous avez toutes les cartes", error= True, infos=session["infos_profile"])
            
            #On prend une carte aleatoirement et on l'ajoute à la collection
            carte = cartes[randint(0, len(cartes)-1)]
            cur.execute('INSERT INTO collectionne (id_joueur, nom) VALUES (%s, %s)', (session['id'], carte.nom))
            
            #On met a jour les fonds du joueur
            cur.execute('UPDATE joueur SET uav = uav - 1 WHERE id_joueur = %s', (session['id'],))   
            
            #On met a jour les info proflis
            cur.execute('SELECT * FROM joueur WHERE id_joueur = %s', (session['id'],))
            user = cur.fetchone()
            session["infos_profile"]    = user.id_joueur
            
    return redirect(url_for('collection'))


#Route de la page  deck
@app.route('/deck/<int:id_deck>')
def deck(id_deck):
    
    with db.connect() as conn:
        
        with conn.cursor() as cur:
            
            
            
            #On recupere les infos du deck
            cur.execute('SELECT deck.id_deck ,deck.nom , deck.nom_général, deck.description, taux_victoire, taux_defaite  FROM deck left join (taux_victoire_deck_solo natural join taux_defaite_solo) as t on t.id_deck = deck.id_deck where deck.id_deck = %s', (id_deck,))
            deck = cur.fetchone()
            
            if deck == None:
                return redirect(url_for('profile'))
            
            #On recupere les cartes du deck
            cur.execute('SELECT * FROM contient natural join stats_cartes where id_deck = %s order by coc asc', (id_deck,))
            cartes = cur.fetchall()
                    
    return  render_template('deck.html', cartes=cartes, deck=deck, infos=session["infos_profile"])


@app.route("/resultat")
def resultat():
    id_deck_vainquer = request.args.get('id_deck_vainqueur', None)
    id_deck_perdant = request.args.get('id_deck_perdant', None)
    date = request.args.get('date', None)
    
    try:    
        id_deck_vainquer = int(id_deck_vainquer)
        id_deck_perdant = int(id_deck_perdant)
    except:
        print("erroir")
        return redirect(url_for('index'))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("select date_, id_deck_vainqueur , d1.nom_général as vg , d2.nom_général as pg , id_deck_perdant from confronte join deck as d1 on d1.id_deck = id_deck_vainqueur join deck as d2 on d2.id_deck = id_deck_perdant where id_deck_vainqueur = %s and id_deck_perdant = %s and date_ = %s", (id_deck_vainquer, id_deck_perdant, date))
            confrontation = cur.fetchone()
            print("confrotn: ",  confrontation)
            if confrontation != None:
                return render_template('resultat.html', confronte=confrontation,  infos=session["infos_profile"])
            else:
                redirect(url_for('index'))   




@app.route("/creation_deck")
def creation_deck():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    #On recupere les noms des cartes pour le général
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM carte' )
            cartes = cur.fetchall()
    return render_template('creation_deck.html',cartes=cartes, infos=session["infos_profile"])

@app.route('/construction', methods=['POST'])
def creation_bdd_deck():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    nom = request.form['nom']
    desc = request.form['desc']
    general = request.form['general']
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('INSERT INTO deck (nom, description, nom_général, id_joueur) VALUES (%s, %s, %s, %s) returning id_deck', (nom, desc, general, session['id']))
            id_deck = cur.fetchone()[0]
            if id_deck == None:
                return redirect(url_for('creation_deck'))
    return redirect(url_for('creation_deck'))

if __name__ == '__main__':
  app.run()
