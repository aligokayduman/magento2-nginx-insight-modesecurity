FROM ubuntu:latest

MAINTAINER A. Gökay Duman <smyrnof@gmail.com>

ENV GPS_VERSION 1.13.35.2
ENV NGINX_VERSION 1.16.1
ENV CPU_CORE x64

#General Commands
RUN apt update \ 
    && apt upgrade -y \
    && apt install -y apt-transport-https \ 
                      build-essential \
                      zlib1g-dev \
                      libpcre3 \
                      libpcre3-dev \
                      unzip \
                      uuid-dev \
                      wget \
                      libssl-dev \
                      g++ \
                      flex \
                      bison \
                      curl \
                      doxygen \
                      libyajl-dev \
                      libgeoip-dev \
                      libtool \
                      dh-autoreconf \
                      libcurl4-gnutls-dev \
                      libxml2 \
                      libpcre++-dev \
                      libxml2-dev \
                      git \
    && useradd -r nginx

#ModSecurity Install
RUN cd \    
    && git clone https://github.com/SpiderLabs/ModSecurity \
    && git clone https://github.com/SpiderLabs/ModSecurity-nginx \
    && cd ModSecurity \
    && git checkout -b v3/master origin/v3/master \
    && sh build.sh \
    && git submodule init \
    && git submodule update \
    && ./configure \
    && make \
    && make install    

#Google PageSpeed Install
RUN cd \
    && wget https://github.com/pagespeed/ngx_pagespeed/archive/v${GPS_VERSION}-stable.zip \
    && unzip v${GPS_VERSION}-stable.zip \
    && cd incubator-pagespeed-ngx-${GPS_VERSION}-stable/ \
    && wget https://dl.google.com/dl/page-speed/psol/${GPS_VERSION}-${CPU_CORE}.tar.gz \
    && tar -xzvf ${GPS_VERSION}-${CPU_CORE}.tar.gz

#Nginx Install
RUN cd \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xvzf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION}/ \
    && ./configure \
    --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module \
    --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module \
    --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module \
    --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module \
    --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module \
    --with-stream_ssl_module --with-stream_ssl_preread_module \
    --add-module=$HOME/incubator-pagespeed-ngx-${GPS_VERSION}-stable \
    --add-module=$HOME/ModSecurity-nginx \
    && make \
    && make install \
    && mkdir -p /var/cache/nginx \    
    && chown nginx:root /var/cache/nginx

CMD ["nginx", "-g", "daemon off;"]
