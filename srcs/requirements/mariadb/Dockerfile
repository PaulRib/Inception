FROM debian:bullseye

RUN apt-get update && apt-get install mariadb-server -y

RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

RUN sed -i "s|bind-address = 127.0.0.1|bind-address = 0.0.0.0|g" "/etc/mysql/mariadb.conf.d/50-server.cnf"

COPY ./init_db.sh /usr/local/bin/init_db.sh

RUN chmod +x /usr/local/bin/init_db.sh

ENTRYPOINT /usr/local/bin/init_db.sh