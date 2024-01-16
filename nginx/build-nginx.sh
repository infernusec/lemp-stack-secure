# ToDo:
# Set Inbound/outbound ports/services
# Set Chroot for each website to prevent access to other directories and files & prevent reverse shell
# Block AS Numbers with firewalld and ip-set
# Setup CA Root & Intermediate
BASE_WORKDIR=$(pwd)
NGINX_HONEYPOTNAME=$(openssl rand -hex 4)
NGINX_DEPLOY_CONTENT="./nginx-confs"


# disable_functions = chgrp, chmod, chown, dl, eval, exec, fsockopen, lchgrp, lchown, link, passthru, pcntl_fork, phpinfo, popen, proc_get_status, proc_nice, proc_open, proc_terminate, posix_initgroups, posix_kill, posix_mkfifo, posix_mknod, posix_setegid, posix_seteuid, posix_setgid, posix_setpgid, posix_setsid, posix_setuid, shell_exec, show_source, stream_select, stream_socket_client, stream_socket_server, symlink, system
# Configure nginx
echo "Configure nginx.."
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.ORG
cp -f $NGINX_DEPLOY_CONTENT/nginx.conf /etc/nginx/nginx.conf
cp -fR $NGINX_DEPLOY_CONTENT/http /etc/nginx/
cp -fR $NGINX_DEPLOY_CONTENT/server /etc/nginx/
cp -fR $NGINX_DEPLOY_CONTENT/sites /etc/nginx/
cp -fR $NGINX_DEPLOY_CONTENT/blacklist /etc/nginx/
nginx -t

# add disable_functions to fastcgi_params
cp /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.default

# This is a pool for admin control panel / rest api
cp /etc/nginx/fastcgi_params.default /etc/nginx/fastcgi_params_$REST_UNIX_USER

# Disable php functions
echo "fastcgi_param PHP_VALUE disable_functions=\"$PHP_DISABLE_FUNCTIONS\";" >> /etc/nginx/fastcgi_params



# systemctl enable --now nginx


## Required modules
# Modsecurity - V
# Quic - V
# cloudflare zlibc V
# pagespeed - OUTDATED
# brotli - V
# GeoIP2 - ?
# TestCookie - ?


#https://gist.github.com/gaptekupdate/6a942fd711b5c9c3a0ecb53788b32dfa


echo "Checking for latest version of nginx"
mkdir $BASE_WORKDIR/install
cd $BASE_WORKDIR/install
CHECK_NGINX_LATEST_STABLE_VERSION=$(curl -s http://nginx.org/en/download.html | grep 'Stable version' | grep -o 'Stable version.*' | cut -d '"' -f10 | sed 's/.tar.gz//g' | cut -d '-' -f2)
echo "Nginx Latest Stable version is: $CHECK_NGINX_LATEST_STABLE_VERSION"
rm -rf $BASE_WORKDIR/install/nginx-$CHECK_NGINX_LATEST_STABLE_VERSION
rm -rf $BASE_WORKDIR/install/nginx-$CHECK_NGINX_LATEST_STABLE_VERSION.tar.gz
wget -O - http://nginx.org/download/nginx-$CHECK_NGINX_LATEST_STABLE_VERSION.tar.gz | tar -xz
cd $BASE_WORKDIR/install/nginx-$CHECK_NGINX_LATEST_STABLE_VERSION

# Information disclousre
sed -i "s@\"nginx/\"@\"$NGINX_HONEYPOTNAME/\"@g" src/core/nginx.h
sed -i "s/Server: nginx/Server: $NGINX_HONEYPOTNAME/g" src/http/ngx_http_header_filter_module.c
sed -i 's@r->headers_out.server == NULL@0@g' src/http/ngx_http_header_filter_module.c
sed -i 's@r->headers_out.server == NULL@0@g' src/http/v2/ngx_http_v2_filter_module.c
sed -i 's@<hr><center>nginx</center>@@g' src/http/ngx_http_special_response.c

mkdir $BASE_WORKDIR/nginx_modules
cd $BASE_WORKDIR/nginx_modules

# zlib-cloudflare
echo "Download Nginx Module & Compile [zlib-cloudflare]"
git clone --depth=1 https://github.com/cloudflare/zlib.git zlib-cloudflare
cd zlib-cloudflare && ./configure && make -j 8
cd $BASE_WORKDIR/nginx_modules

#openssl
echo "Download Nginx Module [openssl]"
git clone https://github.com/openssl/openssl

# brotli
echo "Download Nginx Module [brotli]"
git clone https://github.com/google/ngx_brotli.git && cd ngx_brotli && git submodule update --init
cd $BASE_WORKDIR/nginx_modules

# ModSecurity
echo "Download Modsecurity Module & Compile"
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
make install

mkdir -p /etc/nginx/modsec/ruleset/
cat $BASE_WORKDIR/nginx_modules/ModSecurity/modsecurity.conf-recommended | sed 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' > /etc/nginx/modsec/modsecurity.conf
cp $BASE_WORKDIR/nginx_modules/ModSecurity/unicode.mapping /etc/nginx/modsec/

# Download ruleset
# https://coreruleset.org/docs/deployment/install/
echo "Download OWASP Modsecurity Ruleset.."
cd /etc/nginx/modsec/ruleset
wget -O - https://github.com/coreruleset/coreruleset/archive/refs/tags/v3.3.4.tar.gz | tar -xz
cd coreruleset-3.3.4/ 
mv crs-setup.conf.example crs-setup.conf

echo "include /etc/nginx/modsec/modsecurity.conf" > /etc/nginx/modsec/main.conf
echo "include /etc/nginx/modsec/ruleset/coreruleset-3.3.4/crs-setup.conf" >> /etc/nginx/modsec/main.conf
echo "include /etc/nginx/modsec/ruleset/coreruleset-3.3.4/rules/*.conf" >> /etc/nginx/modsec/main.conf


cd $BASE_WORKDIR/nginx_modules
echo "Download Modsecurity Modules [ModSecurity-nginx, rDns, Cache-purge]"
git clone --depth 1 http://github.com/SpiderLabs/ModSecurity-nginx.git
git clone https://github.com/flant/nginx-http-rdns.git
git clone https://github.com/FRiCKLE/ngx_cache_purge.git


echo "Prepare nginx to compile [Build Args]"
NGINX_CONF=$(nginx -V 2>&1 | sed -n '/configure/s/configure arguments: //gp;')
APPEND_NGINX_MODULES="--with-http_geoip_module"
APPEND_NGINX_MODULES="$APPEND_NGINX_MODULES --add-module=$BASE_WORKDIR/nginx_modules/nginx-http-rdns"
# APPEND_NGINX_MODULES="$APPEND_NGINX_MODULES --add-module=$BASE_WORKDIR/nginx_modules/ngx_cache_purge"
APPEND_NGINX_MODULES="$APPEND_NGINX_MODULES --add-module=$BASE_WORKDIR/nginx_modules/ModSecurity-nginx"
APPEND_NGINX_MODULES="$APPEND_NGINX_MODULES --add-module=$BASE_WORKDIR/nginx_modules/ngx_brotli"
APPEND_NGINX_MODULES="$APPEND_NGINX_MODULES --with-openssl=$BASE_WORKDIR/nginx_modules/openssl"
APPEND_NGINX_MODULES="$APPEND_NGINX_MODULES --with-zlib=$BASE_WORKDIR/nginx_modules/zlib-cloudflare"
NGINX_WITH_MODULES_FLAGS="--with-pcre-opt='-g -Ofast -fPIC -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2' --with-zlib-opt='-g -Ofast -fPIC -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2' --with-openssl-opt='enable-tls1_3 no-ssl3 enable-ec_nistp_64_gcc_128 -fPIC -g -Ofast -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2'"
NGINX_BUILD_ARGS=$(echo "$NGINX_CONF" | sed "s|--with-threads|--with-threads $APPEND_NGINX_MODULES|g" | awk "{sub(/--with-ld-opt=/,\"$NGINX_WITH_MODULES_FLAGS &\")}1")

cd $BASE_WORKDIR/install/nginx-$CHECK_NGINX_LATEST_STABLE_VERSION
eval "./configure $NGINX_BUILD_ARGS"
echo "Compile Nginx..."
make
make install