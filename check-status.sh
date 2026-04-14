#!/bin/bash

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Erreur : Fichier .env introuvable"
    exit 1
fi

# Vérification de l'utilisateur (Non-root)
echo -n "Vérification de l'utilisateur interne... "
USER_ID=$(docker exec mango-container id -u)

if [ "$USER_ID" != "0" ]; then
    echo -e "OK (UID: $USER_ID)"
else
    echo -e "ERREUR : Le conteneur tourne en ROOT !"
    exit 1
fi

# Vérification de l'accès aux données
echo -n "Vérification de l'accès aux données ($DATABASE)... "

# On utilise les variables $USERNAME et $PASSWORD qui viennent d'être chargées du .env
COUNT=$(docker exec mango-container mongosh -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --quiet --eval "db.getSiblingDB('$DATABASE').posts.countDocuments()")

# Vérification du code de sortie ($?) et du nombre de document
if [ $? -eq 0 ] && [ "$COUNT" -ge 5 ]; then
    echo -e "OK ($COUNT articles trouvés)"
else
    echo -e "ERREUR : échec d'authentification ou base vide."
    exit 1
fi

echo -e "SUCCES : Tout est conforme !"
exit 0
