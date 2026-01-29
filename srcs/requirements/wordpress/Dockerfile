FROM debian:bullseye

#Necessaire lors de l'installation de php-fpm
RUN mkdir /run/php

RUN apt-get update && apt-get install php7.4 -y && apt-get install php7.4-fpm -y && apt-get install php7.4-mysql -y && apt-get install wget -y && apt-get install mariadb-client -y

WORKDIR /var/www/html

RUN sed -i "s|listen = /run/php/php7.4-fpm.sock|listen = 9000|g" "/etc/php/7.4/fpm/pool.d/www.conf"

COPY ./init_wordpress.sh /usr/local/bin/init_wordpress.sh

RUN chmod +x /usr/local/bin/init_wordpress.sh

CMD ["/usr/local/bin/init_wordpress.sh"]