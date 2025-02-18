# sade-automation-script
Il est question de réaliser dans le présent repo : https://github.com/sylorion/sade-automation-script
Le projet ci dessous AVEC EN PLUS deux workflows (un pour la partie CI et un autre pour la partie CD).
**Les deux workflow déclenchés github action se font à chaque `push` sur la branche `« dev »`.**
- [ ] Le CI se charge de charger et executer les programmes d’exemples que tu auras réaliser (au moins trois programmes simples) qui log dans la console le nom du programme et la date.
- [ ] Le CD se charge de synchroniser le present repos sur un repos que tu auras crée sur ton espace personnel en mode public appelez le `« sade-automation-script-deployment »`.

1. **Contexte**  
   - Vous disposez de plusieurs applications Node.js à démarrer et stopper de manière simultanée.  
   - Un fichier `.env` contient la liste des applications et leurs ports respectifs (ex. `APP1_PORT`, `APP2_PORT`, etc.).  
   - L’objectif est de créer un script unique capable de :  
     1. Charger les variables définies dans le `.env`.  
     2. Lancer chacune des applications Node.js sur le port configuré.  
     3. Arrêter proprement les processus lancés.  

2. **Objectifs du test**  
   - Vérifier la capacité à automatiser le lancement et l’arrêt de plusieurs processus.  
   - Vérifier la bonne lecture des variables d’environnement via le `.env`.  
   - S’assurer que l’ensemble des processus se lancent correctement sur les ports définis.  
   - Vérifier la bonne gestion des logs, erreurs et arrêts (grâce aux PID, par exemple).

3. **Contraintes techniques à respecter**  
   - Le script doit être écrit en **Bash** (ou équivalent sur votre OS).  
   - Le script doit supporter un **mode “start”** pour lancer les applications et un **mode “stop”** pour les arrêter.  
   - L’utilisateur doit pouvoir passer en argument “start” ou “stop” au script.  
   - Les chemins vers les répertoires ou fichiers des applications Node.js doivent pouvoir être définis de manière dynamique (dans le `.env` ou dans un fichier de configuration).  

4. **Étapes du test**  
   1. **Préparer un fichier `.env`** contenant la configuration. Par exemple :  
      ```
      APP_LIST="app1,app2"
      APP1_PATH="/chemin/vers/app1"    # Chemin vers le code source de la première app
      APP1_PORT=3001
      APP2_PATH="/chemin/vers/app2"
      APP2_PORT=3002
      ```
   2. **Créer le script `manage_applications.sh`** (ou un nom équivalent) qui :  
      - Lit le fichier `.env` (par un `source .env` ou équivalent).  
      - Parse la variable `APP_LIST` pour connaître les applications à lancer.  
      - À l’option “start” : lance chaque application Node.js en arrière-plan et stocke leur PID (dans un fichier `pidfile` ou en mémoire).  
      - À l’option “stop” : lit le fichier `pidfile` et arrête tous les processus correspondants.  
   3. **Démontrer le fonctionnement** :  
      - Ouvrir plusieurs terminaux ou exécuter en arrière-plan pour vérifier le bon lancement.  
      - Vérifier la présence des PID et la bonne terminaison de chaque application.  
   4. **Contrôler le résultat** :  
      - Les logs des applications doivent s’afficher correctement ou être redirigés dans des fichiers de log.  
      - Les ports définis dans le fichier `.env` doivent être occupés par l’instance lancée pour chaque application.  

5. **Travaux supplémentaires (bonus)**  
   - Gérer un mode “restart” qui enchaîne `stop` puis `start`.  
   - Envoyer les logs dans un répertoire spécifique.  
   - Proposer un système de notification en cas d’erreur ou un script de health check.  
   - Ajouter la compatibilité avec un gestionnaire de processus comme **pm2** si souhaité.

---

### Exemple d’un début de script `manage_applications.sh`
Voici un exemple simplifié montrant comment utiliser `npm start` dans le script. L’idée est de remplacer le lancement classique via `node index.js` par un appel à `npm start`. On suppose que chaque application dispose d’un fichier `package.json` avec un script `"start"` qui lance l’application Node.js.

### Exemple de fichier `.env`
```
APP_LIST="app1,app2"

APP1_PATH="/chemin/vers/app1"
APP1_PORT=3001

APP2_PATH="/chemin/vers/app2"
APP2_PORT=3002
```

### Le script `manage_applications.sh` utilisant `npm start`
```bash
#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 {start|stop}"
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

if [ "$MODE" == "start" ]; then
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
    PORT="$APP_PORT" npm start &
    PID=$!

    # Retour dans le répertoire initial (important si plusieurs apps)
    cd - >/dev/null

    # Enregistrer l'app et son PID dans un pidfile
    echo "$APP_NAME=$PID" >> pidfile
  done
  echo "All applications started."

elif [ "$MODE" == "stop" ]; then
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

else
  echo "Invalid option. Usage: $0 {start|stop}"
  exit 1
fi
```

### Points importants
1. **Script `"start"` dans le `package.json`**  
   - Assurez-vous d’avoir une entrée `"start"` dans votre `package.json`, par exemple :  
     ```json
     {
       "name": "app1",
       "scripts": {
         "start": "node index.js"
       }
     }
     ```
   - Ainsi, la commande `npm start` exécutera `node index.js`.

2. **Passage de la variable `PORT`**  
   - Dans cet exemple, on exporte la variable `PORT="$APP_PORT"` avant l’exécution de `npm start`.  
   - Il faut que votre application Node.js lise `process.env.PORT` pour démarrer sur le port souhaité.

3. **Isolation du répertoire**  
   - On utilise `cd "$APP_PATH"` avant de lancer l’application, puis `cd -` pour revenir au répertoire initial.  
   - Cela permet d’appeler `npm start` au bon endroit et d’enregistrer l’application correspondante dans le `pidfile`.

4. **Gestion du `pidfile`**  
   - Le script stocke les PIDs des processus démarrés dans un fichier `pidfile`.  
   - Lorsque vous exécutez `./manage_applications.sh stop`, il arrête les processus dont les PIDs sont listés dans ce fichier.  

Grâce à cet exemple, vous pouvez lancer et arrêter toutes vos applications Node.js via `npm start`, en utilisant un seul script et un fichier `.env` pour la configuration.

**Explication du fonctionnement :**  
- On commence par vérifier le nombre d’arguments et on stocke “start” ou “stop” dans une variable `MODE`.  
- On charge les variables d’environnement du fichier `.env` via un `source .env`.  
- On lit la variable `APP_LIST` (p. ex. “app1,app2”) et on la sépare en un tableau `APPS`.  
- Pour chaque application, on recompose les noms de variables (ex. `APP1_PATH`) et on utilise l’opérateur `!` de Bash pour accéder à la valeur.  
- En mode “start”, on lance chaque application en arrière-plan, récupère son PID et l’écrit dans un fichier `pidfile`.  
- En mode “stop”, on lit chaque entrée du `pidfile` (app=PID), on arrête le processus concerné (commande `kill`), puis on supprime le `pidfile`.  

Les points à vérifier lors du test :  
- Les applications démarrent bien sur le port indiqué.  
- Les variables d’environnement sont correctement chargées.  
- Les PID sont correctement enregistrés et utilisés pour stopper les apps.  
- En cas d’erreur (fichier `.env` manquant, mode inconnu, etc.), le script sort avec un message explicite.  

Ce squelette peut être étendu ou modifié selon vos besoins (gestion de logs, modes supplémentaires, etc.).
