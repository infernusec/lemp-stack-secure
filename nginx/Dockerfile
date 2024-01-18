ARG IMAGE_TAG=9.3.20231119
FROM rockylinux:${IMAGE_TAG} AS build-stage
USER root
RUN dnf update -y; dnf upgrade -y; dnf makecache -y; dnf install -y epel-release; dnf config-manager --set-enabled crb; dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.3.rpm; dnf update -y; dnf install -y pcre-devel libxslt-devel gd-devel perl-ExtUtils-Embed zlib zlib-devel pcre-devel make gcc gcc-c++ wget git openssl-devel pcre-devel zlib-devel python python-devel gcc zlib perl libxml2 libxslt autoconf automake libtool make cmake openssl openssl-devel pcre-devel unzip git patch cmake gc libxml2-devel libxslt-devel gd-devel perl-ExtUtils-Embed perl-ExtUtils-Embed clang pcre-devel openssl-devel libxml2-devel libxslt-devel gd-devel perl-devel nginx; dnf install -y wget zip unzip epel-release; dnf update -y; dnf install -y GeoIP-devel; /usr/bin/crb enable;
WORKDIR /tmp/build-nginx
COPY ./build-nginx.sh /tmp/build-nginx/
RUN chmod +x /tmp/build-nginx/build-nginx.sh
COPY ./nginx-confs /tmp/build-nginx/nginx-confs
RUN /tmp/build-nginx/build-nginx.sh
# VOLUME [ "/etc/nginx" ]
# RUN dnf remove -y epel-release remi-release-9.3 pcre-devel libxslt-devel gd-devel perl-ExtUtils-Embed pcre-devel make gcc gcc-c++ openssl-devel pcre-devel zlib-devel gcc autoconf automake libtool make cmake pcre-devel patch cmake gc libxml2-devel libxslt-devel gd-devel perl-ExtUtils-Embed perl-ExtUtils-Embed pcre-devel openssl-devel libxml2-devel libxslt-devel gd-devel perl-devel

FROM rockylinux:${IMAGE_TAG}-minimal
USER root
RUN mkdir -p /usr/local/modsecurity/ /etc/nginx/ /var/lib/nginx /var/log/nginx /usr/share/nginx /usr/lib64/nginx /usr/local/lib64/perl5/5.32/auto/nginx
RUN useradd nginx

ENV PATH="/sbin/:${PATH}"

# Binary
COPY --from=build-stage /sbin/nginx /sbin/
COPY --from=build-stage /usr/sbin/nginx /usr/sbin/

# Folders
COPY --from=build-stage /etc/nginx/ /etc/nginx/
COPY --from=build-stage /usr/share/nginx/html/ /usr/share/nginx/html/
# Nginx Libraries
COPY --from=build-stage /var/lib/nginx/ /var/lib/nginx/
COPY --from=build-stage /usr/share/nginx/ /usr/share/nginx/
COPY --from=build-stage /usr/lib64/nginx/ /usr/lib64/nginx/
COPY --from=build-stage /usr/local/lib64/perl5 /usr/local/lib64/perl5/

# Other Libraries
COPY --from=build-stage /usr/local/modsecurity/ /usr/local/

# Lib64
COPY --from=build-stage /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/modsecurity/lib/
COPY --from=build-stage /lib64/libGeoIP.so.1 /lib64/
COPY --from=build-stage /lib64/libxml2.so.2 /lib64/
COPY --from=build-stage /lib64/libpcre.so.1 /lib64/
COPY --from=build-stage /lib64/libgcc_s.so.1 /lib64/
COPY --from=build-stage /lib64/libstdc++.so.6 /lib64/
COPY --from=build-stage /lib64/libz.so.1 /lib64/
COPY --from=build-stage /lib64/liblzma.so.5 /lib64/
# libbrotlicommon.so.1 => /lib64/libbrotlicommon.so.1 (0x00007fca18872000)

# Set prems
RUN chmod 777 -R /var/log/nginx/*; chmod -R 777 /var/lib/nginx/tmp; chmod -R 777 /usr/share/nginx/*; chown -R nginx:nginx /usr/share/nginx

# USER nginx
CMD [ "/sbin/nginx" , "-g" , "daemon off;","-c","/etc/nginx/nginx.conf" ]

#COPY --from=build-stage /bin/nginx /bin/nginx
WORKDIR /
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1/