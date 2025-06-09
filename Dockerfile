# 1. Base Image (PHP-FPM සහ Alpine Linux)
FROM php:8.1-fpm-alpine

# 2. Working Directory
WORKDIR /var/www/html

# 3. අවශ්‍ය dependencies install කිරීම
RUN apk add --no-cache \
    libpng-dev \
    libzip-dev \
    jpeg-dev \
    freetype-dev \
    nodejs \
    npm \
    git \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql gd zip bcmath

# 4. Composer install කිරීම
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Application files copy කිරීම
COPY . .

# 6. Composer dependencies install කිරීම
RUN composer install --optimize-autoloader --no-dev

# 7. NPM dependencies install කරලා build කිරීම
RUN npm install && npm run build

# 8. Laravel permissions හරිගස්සන එක
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 9. Laravel optimizations
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# 10. Port එක expose කිරීම
EXPOSE 9000

# 11. Container එක start කරන command එක
CMD ["php-fpm"]
