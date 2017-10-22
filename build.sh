#!/bin/sh
#update and install dependencies
apt-get update
apt-get install -y git wget build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev libcurl4-openssl-dev supervisor libaprutil1

#make modsecurity
cd /usr/src/
git clone https://github.com/SpiderLabs/ModSecurity.git /usr/src/modsecurity
cd /usr/src/modsecurity
git checkout tags/$MODSECURITY_VERSION
./autogen.sh
./configure --enable-standalone-module --disable-mlogc
make

#make nginx
cd /
wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar xvzf nginx-$NGINX_VERSION.tar.gz
cd ../nginx-$NGINX_VERSION
./configure 	--user=www-data  \
		--group=www-data \
		--with-ipv6 \
		--with-http_ssl_module \
		--with-http_v2_module \
		--without-http_access_module \
		--without-http_auth_basic_module \
		--without-http_autoindex_module \
		--without-http_empty_gif_module \
		--without-http_fastcgi_module \
		--without-http_referer_module \
		--without-http_memcached_module \
		--without-http_scgi_module \
		--without-http_split_clients_module \
		--without-http_ssi_module \
		--with-http_realip_module \
		--without-http_uwsgi_module \
		--with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
		--with-ld-opt='-Wl,-z,relro -Wl,--as-needed' \
		--add-module=/usr/src/modsecurity/nginx/modsecurity
make
make install

#configure env
ln -s /usr/local/nginx/sbin/nginx /bin/nginx
cp /usr/src/modsecurity/unicode.mapping /usr/local/nginx/conf/
mkdir -p /opt/modsecurity/var/audit/

#install signature
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/src/owasp-modsecurity-crs
cd /usr/src/owasp-modsecurity-crs
git checkout tags/$OWASP_CRS_VERSION
cp -R /usr/src/owasp-modsecurity-crs/rules/ /usr/local/nginx/conf/
mv /usr/local/nginx/conf/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf{.example,}
mv /usr/local/nginx/conf/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf{.example,}

apt-get purge -y build-essential wget git
#apt-get remove -qy --purge dpkg-dev apache2-dev libpcre3-dev libxml2-dev
apt-get -qy autoremove
apt-get install -y --reinstall libaprutil1


rm /nginx-$NGINX_VERSION.tar.gz
rm -rf /usr/src/modsecurity/nginx/modsecurity
rm -rf /nginx-$NGINX_VERSION
rm -rf /var/lib/apt/lists/*
rm -rf /usr/src/owasp-modsecurity-crs


