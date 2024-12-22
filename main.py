import time
from flask import Flask, render_template, request, redirect, url_for, session
from random import randint
import db
from passlib.context import CryptContext
app = Flask(__name__)


password_ctx = CryptContext(schemes=['bcrypt']) # configuration de la bibliothèque

# Clef secrète utilisée pour chiffrer les cookies
app.secret_key = b'e98f5630f3f3f31745404ef51a38a843704259adc60454e1b40e6dc75e6eb772'



@app.route('/')
def index():
    if "username" and "id" in session:
        return redirect(url_for('profile'))
    return render_template('index.html') 



@app.route('/inscription', methods=['POST'])
def inscription():
    pseudo = request.form.get('pseudo', None)
    email = request.form.get('email', None)
    password = request.form.get('password', None)
    
    if pseudo == None or email == None or password == None or pseudo == "" or email == "" or password == "":
        return render_template('index.html', error=True, msgerror="Champs manquants")
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM joueur WHERE email = %s', (email,))
            user = cur.fetchone()
            if user:
                return render_template('index.html', error=True, msgerror="Email déjà utilisé")
            
            cur.execute('INSERT INTO joueur (pseudo, email, mdp, uav) VALUES (%s, %s, %s, 10)', (pseudo, email, password_ctx.hash(password)))
            
    return render_template('index.html')

     

@app.route('/login', methods=['POST'])
def login():
    if 'username' and 'id' in session:
        return redirect(url_for('profile'))
    
    email = request.form.get('email', None)
    password = request.form.get('password', None)
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM joueur WHERE email = %s', (email,))
            user = cur.fetchone()
            if user:
                if password_ctx.verify(password, user.mdp):
                    print(password_ctx.verify(password, user.mdp))
                    session['username'] = user.pseudo
                    session['id'] = user.id_joueur
                    session["infos_profile"] = user
                    return redirect(url_for('profile'))
                
    return render_template('index.html', error=True, msgerror="Identifiants incorrects")

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
            cur.execute('SELECT * FROM collectionne natural join stats_cartes where id_joueur = %s', (session['id'],))
            cartes = cur.fetchall()
    return render_template('collection.html', cartes=cartes, infos=session["infos_profile"])



#Permet de copier un deck 
@app.route('/copier_deck', methods=['POST'])
def copier_deck():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    id_deck = request.form.get('id_deck', None)
    
    if id_deck == None:
        return redirect(url_for('deck', id_deck=id_deck, error=True, msgerror="Erreur lors de la copie du deck"))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM deck where id_deck = %s', (id_deck,))
            deck = cur.fetchone()
            if deck == None:
                return redirect(url_for('deck', id_deck=id_deck, error=True, msgerror="Deck non trouvé"))
            
            
                
            
            cur.execute('INSERT INTO deck (nom, description, nom_général, id_joueur) VALUES (%s, %s, %s, %s) returning id_deck', (deck.nom, deck.description, deck.nom_général, session['id']))
            id_cpy_deck = cur.fetchone()[0]
            
            if id_cpy_deck == None:
                return redirect(url_for('deck', id_deck=id_deck, error=True, msgerror="Erreur lors de la copie du deck"))
            
            cur.execute('SELECT * FROM contient where id_deck = %s', (id_deck,))
            cartes = cur.fetchall()
            
            for carte in cartes:
                cur.execute('INSERT INTO contient (id_deck, nom) VALUES (%s, %s)', (id_cpy_deck, carte.nom))
            
                
    return redirect(url_for('deck', id_deck=id_deck))

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
            session["infos_profile"]    = user
            
    return redirect(url_for('collection'))


#Route de la page  deck
@app.route('/deck/<int:id_deck>')
def deck(id_deck):
    if 'username' not in session:
        return redirect(url_for('index'))
    
    with db.connect() as conn:
        
        with conn.cursor() as cur:
            
            #On recupere les infos du deck
            cur.execute('SELECT deck.id_deck ,deck.nom , deck.nom_général, deck.description, taux_victoire, taux_defaite, deck.id_joueur  FROM deck left join (taux_victoire_deck_solo natural join taux_defaite_solo) as t on t.id_deck = deck.id_deck where deck.id_deck = %s', (id_deck,))
            deck = cur.fetchone()
            print("deck: ", deck)
            if deck == None:
                return redirect(url_for('profile'))
            
            #On verifie si le deck est valide
            cur.execute('SELECT * FROM deck_valide where id_deck = %s', (id_deck,))
            if cur.fetchone() == None:
                valide = False
            else:
                valide = True
            
            #On recupere les cartes du deck
            cur.execute('SELECT * FROM contient natural join stats_cartes where id_deck = %s order by coc asc', (id_deck,))
            cartes = cur.fetchall()
            
            
            #On recupere la collection du joueur
            cur.execute('SELECT * FROM collectionne where id_joueur = %s', (session['id'],))
            collection = cur.fetchall()
            collection = [c.nom for c in collection]
                    
    return  render_template('deck.html', cartes=cartes, deck=deck, infos=session["infos_profile"], valide=valide, collection=collection)

#Route de la page de confrontation
@app.route("/resultat")
def resultat():
    id_deck_vainquer = request.args.get('id_deck_vainqueur', None)
    id_deck_perdant = request.args.get('id_deck_perdant', None)
    date = request.args.get('date', None)
    
    try:    
        id_deck_vainquer = int(id_deck_vainquer)
        id_deck_perdant = int(id_deck_perdant)
    except:
        return redirect(url_for('index'))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("select date_, id_deck_vainqueur , d1.nom_général as vg , d2.nom_général as pg , id_deck_perdant from confronte join deck as d1 on d1.id_deck = id_deck_vainqueur join deck as d2 on d2.id_deck = id_deck_perdant where id_deck_vainqueur = %s and id_deck_perdant = %s and date_ = %s", (id_deck_vainquer, id_deck_perdant, date))
            confrontation = cur.fetchone()
            if confrontation != None:
                return render_template('resultat.html', confronte=confrontation,  infos=session["infos_profile"])
            else:
                redirect(url_for('index'))   



 #Route de la page  creation_deck
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

#Permet de creer un deck
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
                return redirect(url_for('creation_deck', error=True, msgerror="Erreur lors de la création du deck"))
            
            #On ajoute le general au deck
            cur.execute('INSERT INTO contient (id_deck, nom) VALUES (%s, %s)', (id_deck, general))
            
    return redirect(url_for('construct', id_deck=id_deck))

#Route de la page constructiion/suggere 
@app.route("/suggerer/<int:id_deck>", endpoint='suggerer_deck')
@app.route("/construction/<int:id_deck>", endpoint='construct')
def construct(id_deck):
    
    if 'username' not in session :
        return redirect(url_for('index'))
    
    if id_deck == None:
        return redirect(url_for('creation_deck'))
    
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            
            #On verifie que le deck existe 
            cur.execute('SELECT * FROM deck where id_deck = %s ', (id_deck,) )
            deck = cur.fetchone()
            if deck == None:
                if request.endpoint == "suggerer_deck":
                    return redirect(url_for('profile', id_deck=id_deck))
                return redirect(url_for('creation_deck', error=True, msgerror="Deck non trouvé"))
            
            
            #Recuperation des cartes qui creer un deck valide
            cur.execute("select * from carte natural join cout_concat as c1 where not exists (select cout.couleur from cout where c1.nom = cout.nom except select co1.couleur from cout as co1 where co1.nom = %s) and  not exists (select 1  from contient where id_deck = %s and nom = c1.nom)", (deck.nom_général,deck.id_deck))
            cartes = cur.fetchall()
            
            #Recuperation des cartes qui synergisent avec le general
            cur.execute("select * from synergie_général where carte=%s and not exists (select 1 from contient where id_deck = %s and nom = carte_associee)", (deck.nom_général,deck.id_deck) )
            win_cartes = cur.fetchall()
            print(win_cartes)
            
            
            #Recuperation de toutes les cartes ou les cartes filtre
            recherche = request.args.get('recherche', None)
            col = request.args.get('col', None)
            
            if recherche != None and col != None:
                if col in ["nom", "types", "coc"]:
                    recherche = "%"+recherche+"%"
                    requete = f'SELECT distinct s.nom FROM stats_cartes as s where not exists ( select 1 from contient where contient.nom = s.nom and contient.id_deck = %s) and {col} like %s'
                    cur.execute(requete, (id_deck, recherche))
                    all_cartes = cur.fetchall()
                    
                elif col in ["atk_", "def_"]:
                    if not recherche.isdigit():
                        if request.endpoint == "suggerer_deck":
                            return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Valeur incorrecte"))
                        return redirect(url_for('suggerer_deck', id_deck=id_deck, error=True, msgerror="Valeur incorrecte"))
                        
                    requete = f'SELECT distinct s.nom FROM stats_cartes as s  where not exists (select 1 from contient where contient.nom = s.nom and contient.id_deck = %s) and {col} = %s'
                    cur.execute(requete, (id_deck, recherche))
                    all_cartes = cur.fetchall()
                    
            else:
                cur.execute('SELECT * FROM carte where not exists (select 1 from contient where contient.nom = carte.nom and contient.id_deck = %s)', (id_deck,))
                all_cartes = cur.fetchall()
                
            #Recuperation des cartes du deck
            cur.execute('SELECT * FROM contient natural join stats_cartes where id_deck = %s order by coc asc', (id_deck,))
            cartes_deck = cur.fetchall()
            p = cartes_deck.copy()
            #Recuperationd des noms des colonnes dans stats_cartes
            cur.execute('SELECT column_name FROM information_schema.columns WHERE table_name = %s', ('stats_cartes',))
            liste_col = [col[0] for col in cur.fetchall()]
    
    if request.endpoint == "suggerer_deck" or deck.id_joueur != session['id']:
        return render_template('suggerer.html', cartes=cartes, cartes_deck=cartes_deck, infos=session["infos_profile"], deck=deck, liste_col=liste_col, all_cartes=all_cartes, win_cartes=win_cartes)
    return render_template('construction.html', cartes=cartes, cartes_deck=cartes_deck, infos=session["infos_profile"], deck=deck, liste_col=liste_col, all_cartes=all_cartes, win_cartes=win_cartes)


#Permet d'ajouter une carte au deck
@app.route('/ajout_construct', methods=['POST'])
def ajout_construct():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    id_deck = request.form.get('id_deck', None)
    nom = request.form.get('nom', None)
    
    
    if id_deck == None or nom == None:
        return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Erreur lors de l'ajout de la carte"))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            
            #On verifie qu'on deja pas la carte
            cur.execute('SELECT * FROM contient WHERE id_deck = %s AND nom = %s', (id_deck, nom))
            carte = cur.fetchone()
            if carte != None:   
                return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Carte déjà présente dans le deck"))

            #On verifie qu'on n'as atteint la limite de carte
            cur.execute('SELECT count(*) FROM contient WHERE id_deck = %s', (id_deck,))
            nb_cartes = cur.fetchone()[0]
            
            if nb_cartes >16:
                return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Limite de carte atteinte"))
        
            #On ajoute la carte
            cur.execute('INSERT INTO contient (id_deck, nom) VALUES (%s, %s)', (id_deck, nom))
            
    return redirect(url_for('construct', id_deck=id_deck))

            
@app.route('/supprimer_construct', methods=['POST'])
def supprimer_construct():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    id_deck = request.form.get('id_deck', None)
    nom = request.form.get('nom', None)
    
    if id_deck == None or nom == None:
        return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Erreur lors de la suppression de la carte"))
    
    with db.connect() as conn:
        
        #On verifie qu'on ne supprime pas le general
        with conn.cursor() as cur:
            cur.execute('select * from deck where id_deck = %s ', (id_deck,))
            deck = cur.fetchone()
            
            if deck == None:
                return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Deck non trouvé"))
            
            nom_general = deck.nom_général
            
            if nom == nom_general:
                return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Impossible de supprimer le général"))
        
        #On supprime la carte
        with conn.cursor() as cur:
            cur.execute('DELETE FROM contient WHERE id_deck = %s AND nom = %s', (id_deck, nom))
            
    
    return redirect(url_for('construct', id_deck=id_deck))
    
    
@app.route('/suggestion', methods=['POST'])
def suggestion():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    id_deck = request.form.get('id_deck', None)
    if id_deck == None:
        return redirect(url_for('suggerer_deck', id_deck=id_deck, error=True, msgerror="Erreur lors de la suggestion"))
    
    a_enlever = request.form.get("carte_a_enlever", None)
    a_ajouter = request.form.get("carte_a_ajouter", None)
    
    if a_enlever == None or a_ajouter == None:
        return redirect(url_for('suggerer_deck', id_deck=id_deck, error=True, msgerror="Erreur lors de la suggestion"))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            
            #On verifie qu'on ne supprime pas le general
            cur.execute('select * from deck where id_deck = %s ', (id_deck,))
            deck = cur.fetchone()
            
            if deck == None:
                return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Deck non trouvé"))
            
            nom_general = deck.nom_général
            
            if a_enlever == nom_general:
                return redirect(url_for('suggerer_deck', id_deck=id_deck, error=True, msgerror="Impossible de supprimer le général"))
            

            #On verifie que la carte a ajouter existe
            cur.execute('SELECT * FROM carte where nom = %s', (a_ajouter,))
            carte = cur.fetchone()
            if carte == None:
                return redirect(url_for('suggerer_deck', id_deck=id_deck, error=True, msgerror="Carte à ajouter non trouvée"))
            
            #On verifie que la carte a enlever existe
            cur.execute('SELECT * FROM carte where nom = %s', (a_enlever,))
            carte = cur.fetchone()
            if carte == None:
                return redirect(url_for('suggerer_deck', id_deck=id_deck, error=True, msgerror="Carte à enlever non trouvée"))
            
            #On verifie que la suggestion n'existe pas
            cur.execute('SELECT * FROM suggérer WHERE id_deck = %s AND id_joueur = %s AND carte_ajoutée = %s AND carte_retirée = %s', (id_deck, session["id"], a_ajouter, a_enlever))
            suggestion = cur.fetchone()
            if suggestion != None:
                return redirect(url_for('suggerer_deck', id_deck=id_deck, error=True, msgerror="Suggestion déjà existante"))
            
            
           #On cree une suggestion
            cur.execute('INSERT INTO suggérer (id_deck, id_joueur, carte_ajoutée, carte_retirée, id_proprio) VALUES (%s, %s, %s, %s, %s)', (id_deck,session["id"], a_ajouter, a_enlever, deck.id_joueur))
            
    return redirect(url_for('suggerer_deck', id_deck=id_deck))
         
@app.route("/propositions")
def propositon():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT s1.id_deck as id_deck, s1.id_joueur as id_joueur, s1.id_proprio as id_proprio, s1.carte_ajoutée as nom_ac , sa1.types as types_ac , sa1.coc as coc_ac , sa1.atk_ as atk_ac , sa1.def_ as def_ac , s1.carte_retirée as nom_ec , sa2.types as types_ec , sa2.coc as coc_ec , sa2.atk_ as atk_ec , sa2.def_ as def_ec FROM suggérer as s1 join stats_cartes as sa1 on sa1.nom = s1.carte_ajoutée join stats_cartes as sa2 on sa2.nom = s1.carte_retirée   where id_proprio = %s", (session['id'],))
            suggestions = cur.fetchall()
            print(suggestions)
            
    return render_template('proposition.html', propositions=suggestions, infos=session["infos_profile"])   

@app.route("/choix_proposition", methods=['POST'])
def choix_prop():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    choix = request.form.get('choix', None)
    ac = request.form.get('ac', None)
    ec = request.form.get('ec', None)
    id_deck = request.form.get('id_deck', None)
    id_joueur = request.form.get('id_joueur', None)
    id_proprio = request.form.get('id_proprio', None)
    
    if ac == None or ec == None or id_deck == None or id_joueur == None or id_proprio == None or choix == None:
        return redirect(url_for('propositon', error=True, msgerror="Erreur lors du choix de la proposition"))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            #on verifie que la proposition existe
            cur.execute('SELECT * FROM suggérer WHERE id_deck = %s AND id_joueur = %s AND carte_ajoutée = %s AND carte_retirée = %s AND id_proprio = %s', (id_deck, id_joueur, ac, ec, id_proprio))
            suggestion = cur.fetchone()
            if suggestion == None:
                return redirect(url_for('propositon', error=True, msgerror="Erreur lors du choix de la proposition"))
            
            if choix == "accepter":
                #On ajoute la carte 
                cur.execute('INSERT INTO contient (id_deck, nom) VALUES (%s, %s)', (id_deck, ac))
                #On supprime la carte
                cur.execute('DELETE FROM contient WHERE id_deck = %s AND nom = %s', (id_deck, ec))
                #On supprime les autres propositions ou carte_retirée est implique
                cur.execute('DELETE FROM suggérer WHERE id_deck = %s AND carte_retirée = %s', (id_deck, ec))
                
            #On supprime la proposition
            cur.execute('DELETE FROM suggérer WHERE id_deck = %s AND id_joueur = %s AND carte_ajoutée = %s AND carte_retirée = %s AND id_proprio = %s', (id_deck, id_joueur, ac, ec, id_proprio))
            
            
    return redirect(url_for('propositon'))


@app.route('/supprimer_deck', methods=['POST'])
def supprimer_deck():
    
    if 'username' not in session:
        return redirect(url_for('index'))
    
    
    id_deck = request.form.get('id_deck', None)
    
    
    if id_deck == None or id_deck == "":
        return redirect(url_for('profile'))
    
    
    with db.connect() as conn:
        
        with conn.cursor() as cur:
            #On verifie que le deck existe
            cur.execute('SELECT * FROM deck where id_deck = %s', (id_deck,))
            deck = cur.fetchone()
            if deck == None:
                return redirect(url_for('profile'))
            
            #On verifie que le deck appartient au joueur
            if deck.id_joueur != session['id']:
                return redirect(url_for('profile'))
            
            #On supprime le deck
            cur.execute('DELETE FROM deck WHERE id_deck = %s', (id_deck,))
            
    return redirect(url_for('profile'))
            
@app.route('/decks')
def decks():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM deck ')
            decks = cur.fetchall()
            
    return render_template('decks.html', decks=decks, infos=session["infos_profile"])

@app.route('/recherche_deck')
def recherche_deck():
    if 'username' not in session:
        return redirect(url_for('index'))
    
    recherche = request.args.get('recherche', None)
    
    if recherche == None or recherche == "":
        return redirect(url_for('decks'))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            recherche = "%"+recherche+"%"
            cur.execute('SELECT * FROM deck where nom like %s', (recherche,) )
            decks = cur.fetchall()
                
    return render_template('decks.html', decks=decks, infos=session["infos_profile"])

@app.route('/renommer_deck', methods=['POST'])
def renommer_deck():
    
    if 'username' not in session:
        return redirect(url_for('index'))
    
    id_deck = request.form.get('id_deck', None)
    
    if id_deck == None or id_deck == "":
        return redirect(url_for('profile'))
    
    nom = request.form.get('nom', None)
    
    
    if nom == None or nom == "":
        return redirect(url_for('construct', id_deck=id_deck, error=True, msgerror="Impossible de nommer le deck avec un nom vide"))
    
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('UPDATE deck SET nom = %s WHERE id_deck = %s', (nom, id_deck))
            
    return redirect(url_for('construct', id_deck=id_deck))
    
@app.route('/changer_description_deck', methods=['POST'])
def changer_description_deck():
    
    if 'username' not in session:
        return redirect(url_for('index'))
    
    id_deck = request.form.get('id_deck', None)
    
    if id_deck == None or id_deck == "":
        return redirect(url_for('profile'))
    
    desc = request.form.get('desc', None)
  
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute('UPDATE deck SET description = %s WHERE id_deck = %s', (desc, id_deck))
            
    return redirect(url_for('construct', id_deck=id_deck))
    
        
if __name__ == '__main__':
  app.run()
