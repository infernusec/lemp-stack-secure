FROM php:fpm-alpine

RUN rm -f /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/www.conf
COPY conf/custom-php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

COPY conf/custom-php.ini /usr/local/etc/php/conf.d/vinhjaxt-custom-php.ini

RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/etc/php/php.ini /usr/local/etc/php/conf.d/*