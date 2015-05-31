#!/bin/bash

sudo apt-get install -y libtool autoconf automake libjansson-dev libmagic-dev pkg-config openssl flex
cd /tmp
git clone --recursive --branch v3.3.0 git://github.com/plusvic/yara
cd /tmp/yara
autoreconf -i
./configure --enable-cuckoo --enable-magic
make
sudo make install
echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf
sudo ldconfig
cd yara-python
python setup.py build
sudo python setup.py install
