#Se placer dans le repertoire  du projet avec la console
#attribuer le droit d'execution a manage_applications
chmod +x manage_applications.sh

#lancer le script
./manage_applications.sh 

#Lancer le script en precisant des options
./manage_applications.sh install_packages
./manage_applications.sh start

#En cas d'erreur au demarrage consulter les logs dans le dossiers logs
#Tester les deux dernieres options







#health_check.sh
#installer ssmtp
sudo apt install ssmtp


chmod +x health_check.sh

#configurer le .env_healthCheck a partir de .env_healthCheck-exemple
#tester 
./health_check.sh email@gmail.com 3000
