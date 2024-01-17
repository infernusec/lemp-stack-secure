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
COPY --from=build-stage /sbin/nginx /sbin/
#COPY --from=build-stage /bin/nginx /bin/nginx
WORKDIR /