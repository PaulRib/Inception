FROM debian:bullseye

RUN apt-get update && apt-get install nginx -y && apt-get install openssl -y

RUN openssl req -x509 -nodes -keyout /etc/ssl/private/nginx.key -out /etc/ssl/certs/nginx.crt -subj "/C=FR/ST=Alsace/L=Mulhouse/O=42/CN=pribolzi.42.fr"

COPY ./default.conf /etc/nginx/conf.d/default.conf

#A REMETTRE POUR PUSH
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]