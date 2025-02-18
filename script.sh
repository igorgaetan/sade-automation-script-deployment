#!/bin/bash

# Vérifier que les arguments nécessaires sont fournis
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <REPO_URL_WITH_TOKEN> <BRANCH>"
    exit 1
fi

# Récupérer les arguments
REPO_URL_WITH_TOKEN=$1
BRANCH=$2

# Afficher les informations pour vérification
echo "Repository URL: $REPO_URL_WITH_TOKEN"
echo "Branch: $BRANCH"

# Configuration de Git
git config --global user.email "igorkwenja@github.com"
git config --global user.name "igorgaetan"

# Cloner le dépôt
git clone -b $BRANCH $REPO_URL_WITH_TOKEN /app/repo

# Se déplacer dans le répertoire du dépôt
cd /app/repo

# Supprimer tout le contenu du dépôt (sauf le répertoire .git)
echo "Suppression de tout le contenu du dépôt..."
find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Ajouter les modifications
git add .

# Commiter les modifications
git commit -m "Suppression de tout le contenu du dépôt"

# Pousser les modifications
git push origin $BRANCH --force

echo "Opération terminée."