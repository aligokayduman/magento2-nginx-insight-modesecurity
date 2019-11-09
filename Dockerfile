FROM ubuntu:latest

MAINTAINER A. Gökay Duman <aligokayduman@gmail.com>

ENV NPS_VERSION 1.13.35.2-stable
ENV NGINX_VERSION 1.16.1
ENV CPU_CORE x64

#General Commands
RUN apt update \ 
    && apt upgrade -y \
    && apt install -y apt-transport-https \
                      apt-utils \
                      autoconf \
                      automake \
                      build-essential \
                      git \
                      libcurl4-openssl-dev \
                      libgeoip-dev \
                      liblmdb-dev \
                      libpcre++-dev \
                      libtool \
                      libxml2-dev \
                      libyajl-dev \
                      pkgconf \
                      wget \
                      zlib1g-dev \
                      libpcre3 \
                      libpcre3-dev \
                      unzip \
                      uuid-dev
                      
#ModSecurity Install
RUN cd \    
    && git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity \
    && git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git \
    && cd ModSecurity \
    && git submodule init \
    && git submodule update \
    && ./build.sh \
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
    && ./configure --add-dynamic-module=$HOME/incubator-pagespeed-ngx-${GPS_VERSION}-stable \
    && ./configure --with-compat --add-dynamic-module=$HOME/ModSecurity-nginx \
    && make modules \
    && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules \
    && cp objs/ngx_pagespeed.so /etc/nginx/modules \
    && make \
    && sudo make install
    
RUN useradd -r nginx \    
    && mkdir -p /var/cache/nginx \    
    && chown nginx:root /var/cache/nginx    

CMD ["nginx", "-g", "daemon off;"]
