FROM ubuntu:latest

MAINTAINER A. Gökay Duman <aligokayduman@gmail.com>

ENV GPS_VERSION 1.13.35.2-stable
ENV NGINX_VERSION 1.16.1

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
    && wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.zip \
    && unzip v${NPS_VERSION}.zip \
    && nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d) \
    && cd "$nps_dir" \
    && NPS_RELEASE_NUMBER=${NPS_VERSION/beta/} \
    && NPS_RELEASE_NUMBER=${NPS_VERSION/stable/} \
    && psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz \
    && [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) \
    && wget ${psol_url} \
    && tar -xzvf $(basename ${psol_url})

#Nginx Install
RUN cd \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xvzf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION}/ \
    && ./configure --add-dynamic-module=$HOME/$nps_dir ${PS_NGX_EXTRA_FLAGS} \
    && ./configure --with-compat --add-dynamic-module=$HOME/ModSecurity-nginx \
    && make modules \
    && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules \
    && cp objs/ngx_pagespeed.so /etc/nginx/modules \
    && make \
    && sudo make install

CMD ["nginx", "-g", "daemon off;"]
