FROM alpine:latest
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight WordPress container with Nginx 1.10 & PHP-FPM 7 based on Alpine Linux."

# Install packages from testing repo's
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk -U upgrade && \
    apk --no-cache add php7 php7-fpm php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-xmlwriter php7-xmlreader php7-phar php7-intl php7-dom \ 
    php7-simplexml php7-ctype php7-mbstring php7-gd php7-session nginx \
    php7-mcrypt php7-opcache php7-apcu php7-bcmath \
    supervisor curl bash

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir /var/www/wp-content
WORKDIR /var/www/wp-content
RUN chown -R nobody.nobody /var/www

# Wordpress
ENV WORDPRESS_VERSION 4.7.5
ENV WORDPRESS_SHA1 fbe0ee1d9010265be200fe50b86f341587187302

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
