FROM alpine:3.5
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight WordPress container with Nginx 1.10 & PHP-FPM 7.1 based on Alpine Linux."

# the present version of zlib is not compatible with libpng, and therefore php-gd
# upgrade all the things!
RUN apk -U upgrade

# Install packages from testing repo's
RUN apk --no-cache add php7.1 php7.1-fpm php7.1-mysqli php7.1-json php7.1-openssl php7.1-curl \
    php7.1-zlib php7.1-xml php7.1-phar php7.1-intl php7.1-dom php7.1-xmlreader php7.1-ctype \
    php7.1-mbstring php7.1-gd nginx \
    php7.1-mcrypt php7.1-opcache php7-apcu php7.1-bcmath \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/

# Install packages from stable repo's
RUN apk --no-cache add supervisor curl bash

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7.1/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php7.1/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir /var/www/wp-content
WORKDIR /var/www/wp-content
RUN chown -R nobody.nobody /var/www

# Wordpress
ENV WORDPRESS_VERSION 4.7.3
ENV WORDPRESS_SHA1 35adcd8162eae00d5bc37f35344fdc06b22ffc98

RUN mkdir -p /usr/src

# Upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
  && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
  && tar -xzf wordpress.tar.gz -C /usr/src/ \
  && rm wordpress.tar.gz \
  && chown -R nobody.nobody /usr/src/wordpress

# WP config
COPY wp-config.php /usr/src/wordpress
RUN chown nobody.nobody /usr/src/wordpress/wp-config.php && chmod 640 /usr/src/wordpress/wp-config.php

# Append WP secrets
COPY wp-secrets.php /usr/src/wordpress
RUN chown nobody.nobody /usr/src/wordpress/wp-secrets.php && chmod 640 /usr/src/wordpress/wp-secrets.php

# Add custom themes, plugins and/or uploads
# ADD wp-content /var/www/wp-content

# RUN chown -R nobody.nobody /var/www/wp-content 2> /dev/null
# RUN chown -R nobody.nobody /var/www/wp-content/uploads 2> /dev/null
# RUN chmod 755 /var/www/wp-content/uploads 2> /dev/null
# RUN chmod 777 /var/www/wp-content/cache 2> /dev/null
# RUN chmod 777 /var/www/wp-content/w3tc-config 2> /dev/null

# Entrypoint to copy wp-content
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
