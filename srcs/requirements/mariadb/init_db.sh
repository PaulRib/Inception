#!/bin/bash

# 1. On s'assure que le dossier pour le socket existe et appartient à mysql
# C'est souvent CA qui cause l'erreur "socket not found" !
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# 2. Si la base n'existe pas, on initialise les fichiers système
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "MariaDB: Initialization of system files..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# 3. On crée un fichier SQL temporaire avec toutes tes commandes
# On utilise "cat" pour écrire le fichier proprement
cat << EOF > /tmp/setup.sql
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# 4. On lance MariaDB UNE SEULE FOIS
# --init-file va exécuter le script SQL au démarrage
# --bind-address=0.0.0.0 permet aux autres (WordPress) de se connecter
echo "MariaDB: Launching the server"
exec mysqld_safe --init-file=/tmp/setup.sql --bind-address=0.0.0.0 --port=3306