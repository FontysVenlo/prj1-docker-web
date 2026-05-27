# Multi-stage build:
#   base — shared Apache + PHP + extensions (consumers should never FROM this)
#   prod — slim image for deployments (no dev tooling, php.ini-production)
#   dev  — devcontainer-friendly image (extra tooling, devuser, php.ini-development)
#
# `docker build .` (no --target) builds dev, matching the previous single-stage
# behaviour so existing consumers don't break.

# ─── Stage: base ───────────────────────────────────────────────────────────
FROM php:8.2.29-apache AS base

LABEL maintainer="Martijn Bonajo"

WORKDIR /var/www/html

# Extensions installed here apply to both dev and prod, so any PHP code that
# runs in dev runs in prod and vice versa.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
    && docker-php-ext-install -j$(nproc) pdo pdo_pgsql \
    && docker-php-ext-configure gd --with-freetype --with-jpeg IPE_GD_WITHOUTAVIF=1 \
    && docker-php-ext-install -j$(nproc) gd exif zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Suppress Apache's "Could not reliably determine the server's FQDN" warning.
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80

# ─── Stage: prod ───────────────────────────────────────────────────────────
# Intended for deployments (e.g. the FontysVenlo developer platform). Uses
# php.ini-production so stack traces don't leak in user-facing responses.
# No git/gnupg/zip CLI, no devuser — Apache runs as the default www-data.
FROM base AS prod

# Match dev's upload limits so file-upload behaviour is identical in both
# targets; only display_errors / error_reporting hardening differs.
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
 && sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/g' "$PHP_INI_DIR/php.ini" \
 && sed -i 's/post_max_size = .*/post_max_size = 80M/g' "$PHP_INI_DIR/php.ini"

# ─── Stage: dev (default) ──────────────────────────────────────────────────
# Devcontainer-friendly image with extra tooling and a non-root user that
# devcontainers can remap to the host's UID/GID. Uses php.ini-development
# so students see PHP errors inline while learning.
FROM base AS dev

RUN apt-get update && apt-get install -y --no-install-recommends \
        zip \
        git \
        gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
 && sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/g' "$PHP_INI_DIR/php.ini" \
 && sed -i 's/post_max_size = .*/post_max_size = 80M/g' "$PHP_INI_DIR/php.ini"

# Create a non-root user without hardcoding UID/GID. Devcontainers patch
# UID/GID at runtime via updateRemoteUserUID.
RUN groupadd devgroup \
 && useradd -m -s /bin/bash -g devgroup devuser \
 && chown -R devuser:devgroup /var/www/html

# Switch back to root; devcontainers remap UID/GID at runtime.
USER root
