#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 {start|stop|restart|install_packages}"
  exit 1
fi

MODE=$1

# Charger le fichier .env
if [ -f .env ]; then
  source .env
else
  echo ".env file not found!"
  exit 1
fi
if [ -z "$APP_LIST" ]; then
  echo "APP_LIST not defined in .env!"
  exit 1
fi

start_apps() {
  rm -f pidfile  # Nettoyer d’éventuels anciens pidfile

  IFS=',' read -ra APPS <<< "$APP_LIST"
  for APP_NAME in "${APPS[@]}"; do
    # Construire les noms de variables
    APP_VAR_PATH="${APP_NAME^^}_PATH"  # ex: APP1_PATH
    APP_VAR_PORT="${APP_NAME^^}_PORT"  # ex: APP1_PORT

    APP_PATH="${!APP_VAR_PATH}"
    APP_PORT="${!APP_VAR_PORT}"

    echo "Starting $APP_NAME (npm start) in $APP_PATH on port $APP_PORT"

    # Se placer dans le dossier de l'application et lancer le script "start"
    # en passant la variable PORT (si l'app le supporte) :
    cd "$APP_PATH" || exit 1
    PORT="$APP_PORT" npm start > ./../logs/$APP_NAME.log 2>&1 &  
    NPM_PID=$!  
    
    # Attendre que le processus enfant soit lancé
    echo "Waiting for $APP_NAME to start..."
    CHILD_PID=""
    TIMEOUT=30  # Timeout en secondes
    START_TIME=$(date +%s)

    while [ -z "$CHILD_PID" ]; do
      # Vérifier si le processus enfant existe
      CHILD_PID=$(pgrep -P $NPM_PID) # Trouver le PID du processus enfant

      # Vérifier si le timeout est dépassé
      CURRENT_TIME=$(date +%s)
      if [ $((CURRENT_TIME - START_TIME)) -ge $TIMEOUT ]; then
        echo "Timeout: $APP_NAME did not start within $TIMEOUT seconds."
        exit 1
      fi
      # Attendre 1 seconde avant de réessayer
      sleep 1
    done

    if [ -z "$CHILD_PID" ]; then
      echo "Failed to start $APP_NAME or no child process found."
      exit 1
    fi
    #On ajuste le PID
    CHILD_PID=$((CHILD_PID + 1)) 
    
    # Retour dans le répertoire initial (important si plusieurs apps)
    cd - >/dev/null
    
    echo "$APP_NAME=$CHILD_PID" >> pidfile    

  done
  echo "All applications started."
}

stop_apps() {
  if [ ! -f pidfile ]; then
    echo "No pidfile found. Are the applications running?"
    exit 1
  fi

  while read -r line; do
    APP_NAME=$(echo "$line" | cut -d '=' -f1)
    PID=$(echo "$line" | cut -d '=' -f2)

    echo "Stopping $APP_NAME with PID $PID"
    kill "$PID" 2>/dev/null
  done < pidfile

  rm -f pidfile
  echo "All applications stopped."
}

restart_apps() {
  echo "Restarting applications..."
  stop_apps
  start_apps
  echo "Applications restarted."
}

install_packages() {

  IFS=',' read -ra APPS <<< "$APP_LIST"
  for APP_NAME in "${APPS[@]}"; do
    # Construire les noms de variables
    APP_VAR_PATH="${APP_NAME^^}_PATH"  # ex: APP1_PATH
    APP_VAR_PORT="${APP_NAME^^}_PORT"  # ex: APP1_PORT

    APP_PATH="${!APP_VAR_PATH}"
    APP_PORT="${!APP_VAR_PORT}"

    echo "Installation des pakages de $APP_NAME (npm install) dans $APP_PATH"

    # Se placer dans le dossier de l'application et lancer le script "start"
    # en passant la variable PORT (si l'app le supporte) :
    cd "$APP_PATH" || exit 1
    npm install
    
    # Retour dans le répertoire initial (important si plusieurs apps)
    cd - >/dev/null
    
  done
  echo "Packages installed"
}

# Exécuter la fonction correspondante au mode
case "$MODE" in
  "start")
    start_apps
    ;;
  "stop")
    stop_apps
    ;;
  "restart")
    restart_apps
    ;;
  "install_packages")
    install_packages
    ;;
  *)
    echo "Invalid option. Usage: $0 {start|stop|restart|install_packages}"
    exit 1
    ;;
esac

