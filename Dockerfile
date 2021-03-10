FROM php:8.0-fpm-alpine3.12

ENV XDEBUG_MODE 'off'
ENV XDEBUG_HOST 'localhost'
ENV PHP_MEMORY_LIMIT '256M'
ENV PHP_UPLOAD_MAX_FILESIZE '100M'
ENV PHP_INI_DIR '/usr/local/etc/php'

WORKDIR /var/www/web

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["php-fpm-healthcheck"]

RUN set -eux; \
	\
	apk add --update vim mysql-client git patch fcgi; \
	apk add --no-cache --virtual .build-deps \
	coreutils \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libzip-dev \
	postgresql-dev \
	autoconf \
	file \
	libwebp \
	libwebp-dev \
	g++ \
	gcc \
	libc-dev \
	make \
	pkgconf \
	re2c \
	zlib-dev \
	libmemcached-dev \
	; \
	\
	printf "\n" | pecl install -o -f xdebug memcache \
	\
	docker-php-ext-configure gd \
	--with-freetype \
	--with-webp \
	--with-jpeg \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
	gd \
	opcache \
	pdo_mysql \
	pdo_pgsql \
	zip \
	; \
	\
	runDeps="$( \
	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
	| tr ',' '\n' \
	| sort -u \
	| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-network --virtual .drupal-phpexts-rundeps $runDeps; \
	docker-php-ext-enable memcache xdebug; \
	apk del --no-network .build-deps; \
	wget -O /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck; \
	chmod +x /usr/local/bin/php-fpm-healthcheck; \
	echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf;

COPY php.ini /usr/local/etc/php/php.ini

COPY --from=composer:2.0 /usr/bin/composer /usr/local/bin/

RUN composer global require drush/drush:10.4.0; \
	ln -s /root/.composer/vendor/bin/drush /usr/bin/drush; \
	apk add busybox-initscripts; \
	rc-service crond start && rc-update add crond; \
	echo "*/5 * * * * /usr/bin/drush -r /var/www/web/ core:cron > /dev/null 2>&1" >> /etc/crontabs/root;

COPY start.sh /start.sh
CMD ["/start.sh"]