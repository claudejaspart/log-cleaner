# log-cleaner
A log cleaning utility in bash

Répertoire cible : $HOME/logs (car var/log est trop compliqué à gérer avec tous les processus par défaut qui surveille ce répertoire) 

Premier lancement sans options : l’utilitaire installe les fichiers et répertoires nécessaires, et se place dans le crontab. Cette installation peut être configurée au préalable avec le fichier $HOME/.cleaner.conf  (répertoire contenant les logs, taille min des fichiers et dernière date d’accès) 

Lancement avec l’option -u : désinstalle complètement l’utilitaire et tous les logs, et enlève l’entrée dans le crontab. 

Lancement avec l’option -s (pour stash) : place les logs filtrés dans $HOME/logs dans $HOME/logs/stash. Un index issu d’une date (nombre de secondes depuis EPOCH aka 01/01/1970) est préfixé pour éviter les collisions de fichiers de logs aux noms identiques.  

Lancer l’utilitaire avec –h pour l’aide et le reste des options. 
