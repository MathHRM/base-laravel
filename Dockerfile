FROM php:8.4-fpm

ARG UID=1000
ARG GID=1000

ENV APP_ENV=local \
    COMPOSER_ALLOW_SUPERUSER=1 \
    PATH="/root/.composer/vendor/bin:${PATH}"

# Install common packages and PHP extensions used by Laravel
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libpq-dev \
    zip \
    curl \
    ca-certificates \
  && docker-php-ext-configure gd --with-jpeg --with-freetype \
  && docker-php-ext-install -j$(nproc) pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd zip \
  && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create a non-root user for file ownership in the container
RUN groupadd -g ${GID} app && useradd -u ${UID} -ms /bin/bash -g app app

WORKDIR /app

# Ensure Laravel storage and bootstrap cache directories exist and are writable
RUN mkdir -p /app/storage /app/bootstrap/cache \
  && chown -R app:app /app/storage /app/bootstrap

# Copy entrypoint that will run composer install when container starts
COPY docker/app-entrypoint.sh /usr/local/bin/app-entrypoint.sh
RUN chmod +x /usr/local/bin/app-entrypoint.sh

# Copy php-fpm pool configuration to run workers as the `app` user/group
COPY docker/php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf

# Expose php-fpm port (nginx will connect to this)
EXPOSE 9000

# Use an entrypoint to run pre-start tasks (git safe.directory and composer)
ENTRYPOINT ["/usr/local/bin/app-entrypoint.sh"]

# Run php-fpm in the foreground
CMD ["php-fpm", "-F"]
