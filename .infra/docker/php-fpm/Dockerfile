ARG FROM_IMAGE=mileschou/phalcon:7.3-fpm
FROM ${FROM_IMAGE}

RUN apt-get update && apt-get install -y build-essential git netcat gnupg gnupg2 libpq-dev

RUN docker-php-ext-install pdo pdo_pgsql
RUN docker-php-ext-enable pdo pdo_pgsql
RUN docker-phalcon-install-devtools; phalcon

WORKDIR /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
