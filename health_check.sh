#!/bin/bash

# Vérification des arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <email_destinataire> <port>"
    exit 1
fi

EMAIL_DEST="$1"
PORT="$2"

# Chargement des variables d'environnement
if [ ! -f .env_healthCheck ]; then
    echo "Erreur: Fichier .env_healthCheck non trouvé"
    exit 1
fi

# Lecture du fichier .env
source .env_healthCheck

# Vérification des variables SMTP requises
if [ -z "$SMTP_HOST" ] || [ -z "$SMTP_PORT" ] || [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ] || [ -z "$SMTP_FROM" ]; then
    echo "Erreur: Variables SMTP manquantes dans le fichier .env"
    echo "Requis: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM"
    exit 1
fi

# Fonction pour envoyer un email
send_email() {
    local subject="$1"
    local body="$2"
    
    echo "Subject: $subject" > email.txt
    echo "From: $SMTP_FROM" >> email.txt
    echo "To: $EMAIL_DEST" >> email.txt
    echo "" >> email.txt
    echo "$body" >> email.txt
    
    curl --silent --ssl-reqd \
        --url "smtp://$SMTP_HOST:$SMTP_PORT" \
        --user "$SMTP_USER:$SMTP_PASS" \
        --mail-from "$SMTP_FROM" \
        --mail-rcpt "$EMAIL_DEST" \
        --upload-file email.txt
    
    rm email.txt
}

# Fonction de surveillance du port
check_port() {
    nc -z localhost $PORT >/dev/null 2>&1
    return $?
}

echo "Démarrage de la surveillance du port $PORT..."

# Boucle principale
while true; do
    if ! check_port; then
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        subject="ALERTE - Application inaccessible sur le port $PORT"
        body="L'application sur le port $PORT n'est pas accessible."
        
        echo "Erreur détectée ! Envoi d'une notification..."
        send_email "$subject" "$body"
        
        # Attendre 5 minutes avant de renvoyer une autre alerte
        sleep 300
    else
        # Vérification toutes les 30 secondes
        sleep 30
    fi
done