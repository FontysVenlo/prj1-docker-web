FROM php:8.2.29-apache

# Set maintainer
LABEL maintainer="Martijn Bonajo"

# Set the working directory
WORKDIR /var/www/html

# Install dependencies, see README
RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
        libpq-dev \
        libzip-dev \
        zip \
    && docker-php-ext-install -j$(nproc) pdo \
    && docker-php-ext-install -j$(nproc) pdo_pgsql \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg IPE_GD_WITHOUTAVIF=1\
	&& docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) exif \
    && docker-php-ext-install -j$(nproc) zip \
    && rm -rf /var/lib/apt/lists/*

# Set ServerName to suppres warnings
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Use the default php.ini-development file as our php.ini
# Only replace the max upload size and post size
# TODO: create custom php.ini file
RUN mv $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini \
    && sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/g' $PHP_INI_DIR'/php.ini' \
    && sed -i 's/post_max_size = .*/post_max_size = 80M/g' ${PHP_INI_DIR}'/php.ini'

# Create a default non-root user (UID 1000)
RUN groupadd -g 1000 devgroup \
 && useradd -u 1000 -g devgroup -m devuser \
 && chown -R devuser:devgroup /var/www/html

USER devuser

# Only expose port 80
# We do not expect students to use HTTPS
EXPOSE 80