# Stage 1: Composer dependencies ස්ථාපනය කිරීම
FROM composer:2 as vendor
WORKDIR /app
COPY database/ database/
COPY composer.json composer.json
COPY composer.lock composer.lock
RUN composer install --no-interaction --no-plugins --no-scripts --prefer-dist --optimize-autoloader

# Stage 2: Frontend assets build කිරීම
FROM node:18-alpine as frontend
WORKDIR /app
COPY package.json package.json
COPY package-lock.json package-lock.json
COPY vite.config.js vite.config.js
COPY resources/ resources/
RUN npm ci && npm run build

# Stage 3: අවසාන Production Image එක සෑදීම
FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

# අවශ්‍ය PHP extensions install කිරීම
# libpq-dev එක PostgreSQL වලට, libzip-dev එක zip වලට.
RUN apk add --no-cache oniguruma-dev libxml2-dev libzip-dev libpq-dev && \
    docker-php-ext-install bcmath ctype fileinfo mbstring pdo pdo_mysql pdo_pgsql tokenizer xml zip

# Nginx install කිරීම
RUN apk add --no-cache nginx

# Nginx configuration file එක copy කිරීම
COPY docker/nginx.conf /etc/nginx/nginx.conf

# කලින් stages වලින් build කරපු දේවල් copy කිරීම
COPY --from=vendor /app/vendor/ /var/www/html/vendor/
COPY --from=frontend /app/public/build /var/www/html/public/build
COPY . .

# Permissions සහ ownership සකස් කිරීම
# www-data කියන්නේ php-fpm සහ nginx වල default user/group එක
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Application එකේ entrypoint script එක copy කරලා execute permission දෙනවා
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Port 80 expose කරනවා
EXPOSE 80

# Entrypoint එක run කරනවා
ENTRYPOINT ["entrypoint.sh"]
