#!/bin/bash

# Install Redis Dependancies
sudo apt-get install tcl8.5 -y

# Download and install Redis
cd /tmp
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
make test
sudo make install

# Install redis-server
cd utils
sudo ./install_server.sh

# Set redis to start at boot
sudo update-rc.d redis_6379 defaults
