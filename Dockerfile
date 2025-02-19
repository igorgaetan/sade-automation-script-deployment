# Utiliser une image de base avec Git et Python
FROM python:3.10.9

# Installer Git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Créer un répertoire de travail
WORKDIR /app

# Copier le script dans le conteneur
COPY script.sh /app/script.sh

# Rendre le script exécutable
RUN chmod +x /app/script.sh

# Définir le script comme point d'entrée
ENTRYPOINT ["./script.sh"]