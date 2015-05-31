#!/bin/bash
#
# bash < <(curl -s https://gist.github.com/jmervine/5407622/raw/nginx_w_lua.bash)

set -x
cd /tmp

if ! test -d /usr/local/include/luajit-2.0; then
  echo "Installing LuaJIT-2.0.3."
  wget "http://luajit.org/download/LuaJIT-2.0.3.tar.gz"
  tar -xzvf LuaJIT-2.0.3.tar.gz
  cd LuaJIT-2.0.3
  make
  sudo make install
else
  echo "Skipping LuaJIT-2.0.3, as it's already installed."
fi

mkdir ngx_devel_kit
cd ngx_devel_kit
wget "https://github.com/simpl/ngx_devel_kit/archive/v0.2.19.tar.gz"
tar -xzvf v0.2.19.tar.gz

NGX_DEV="/tmp/ngx_devel_kit/ngx_devel_kit-0.2.19"

cd /tmp
mkdir lua-nginx-module
cd lua-nginx-module
wget "https://github.com/openresty/lua-nginx-module/archive/v0.9.13.tar.gz"
tar -xzvf v0.9.13.tar.gz

LUA_MOD="/tmp/lua-nginx-module/lua-nginx-module-0.9.13"

cd /tmp
wget 'http://nginx.org/download/nginx-1.7.9.tar.gz'
# wget 'http://nginx.org/download/nginx-1.7.9.tar.gz.asc'
# gpg --keyserver pgpkeys.mit.edu --recv-key D4E39B36
# gpg nginx-1.7.9.tar.gz.asc
tar -xzvf nginx-1.7.9.tar.gz
cd ./nginx-1.7.9

export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.0

./configure --prefix=/opt/nginx \
--add-module=$NGX_DEV \
--add-module=$LUA_MOD

make -j2
sudo make install

unset LUAJIT_LIB
unset LUAJIT_INC


# http://mervine.net/nginx-with-lua-module

# export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
#
# # ensure default configuration location
# test "$DAEMON_OPTS" || DAEMON_OPTS="-c /etc/nginx/nginx.conf"
# PATH=/opt/nginx/sbin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# DAEMON=/opt/nginx/sbin/nginx
