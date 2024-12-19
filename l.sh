#!/bin/bash

# Nombre de requêtes à lancer
n=70

# URL de la requête
url="http://localhost:5000/ajout_carte"

# Cookie de session
session_cookie="eyJpZCI6MywidXNlcm5hbWUiOiJhYyJ9.Z2KVRQ.7BVleMNKDo8Yk_L5tx8zQkHx0vE"

# Boucle pour lancer `n` requêtes
for ((i=1; i<=n; i++))
do
    echo "Lancement de la requête $i"
    curl -X POST "$url" -b "$session_cookie"
    echo ""
done
